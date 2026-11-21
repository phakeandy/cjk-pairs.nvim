local M = {}

local function pos_lt(a, b)
  return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
end

local function pos_eq(a, b)
  return a[1] == b[1] and a[2] == b[2]
end

local function reader()
  local cache, size = {}, 200
  return function(n)
    if n < 1 then return nil end
    if cache[n] == nil then
      local from = math.floor((n - 1) / size) * size + 1
      local got = vim.api.nvim_buf_get_lines(0, from - 1, from + size - 1, false)
      if #got == 0 then return nil end
      for i, text in ipairs(got) do cache[from + i - 1] = text end
    end
    return cache[n]
  end
end

local function char_start(line, col)
  local i = col
  while i > 0 do
    local b = line:byte(i + 1)
    if b and b >= 0x80 and b < 0xC0 then i = i - 1 else break end
  end
  return i
end

local function before(read, pos)
  if pos[2] > 0 then return { pos[1], char_start(read(pos[1]), pos[2] - 1) } end
  if pos[1] == 1 then return nil end
  local prev = read(pos[1] - 1)
  if prev == '' then return { pos[1] - 1, 0 } end
  return { pos[1] - 1, char_start(prev, #prev - 1) }
end

local function vim_pattern(text)
  return '\\V' .. text:gsub('\\', '\\\\')
end

local function last_occurrence(text, pattern, before)
  local found, from = nil, 1
  while true do
    local pos = text:find(pattern, from, true)
    if not pos or pos >= before then break end
    found, from = pos, pos + 1
  end
  return found
end

local function find_close(read, open_line, open_col, open, close)
  local depth, line_nr = 1, open_line
  local from = open_col + #open + 1
  while true do
    local text = read(line_nr)
    if not text then return nil end
    while true do
      local o = text:find(open, from, true)
      local c = text:find(close, from, true)
      if not o and not c then break end
      if o and (not c or o < c) then
        depth, from = depth + 1, o + #open
      else
        depth = depth - 1
        if depth == 0 then return line_nr, c - 1 end
        from = c + #close
      end
    end
    line_nr, from = line_nr + 1, 1
  end
end

local function find_open(read, close_line, close_col, open, close)
  local depth, line_nr = 1, close_line
  local before = close_col + 1
  while line_nr >= 1 do
    local text = read(line_nr)
    if not text then return nil end
    if not before then before = #text + 1 end
    while before > 1 do
      local c = last_occurrence(text, close, before)
      local o = last_occurrence(text, open, before)
      if not c and not o then break end
      if c and (not o or c > o) then
        depth, before = depth + 1, c
      else
        depth = depth - 1
        if depth == 0 then return line_nr, o - 1 end
        before = o
      end
    end
    line_nr, before = line_nr - 1, nil
  end
end

local function span(open_text, close_text, open_pos, close_pos)
  return { open = open_pos, close = close_pos, open_text = open_text, close_text = close_text }
end

local function bracket_spans(read, open, close, cur)
  local spans = {}
  local text = read(cur[1])
  local at_close = text:sub(cur[2] + 1, cur[2] + #close) == close
  local at_open = text:sub(cur[2] + 1, cur[2] + #open) == open

  local start = cur
  if at_close then
    local ol, oc = find_open(read, cur[1], cur[2], open, close)
    if not ol then return spans end
    spans[#spans + 1] = span(open, close, { ol, oc }, { cur[1], cur[2] })
    start = before(read, { ol, oc })
  elseif at_open then
    local cl, cc = find_close(read, cur[1], cur[2], open, close)
    if not cl then return spans end
    spans[#spans + 1] = span(open, close, { cur[1], cur[2] }, { cl, cc })
    start = before(read, cur)
  end

  if start then
    local saved = vim.api.nvim_win_get_cursor(0)
    local from = start
    for _ = 1, 32 do
      vim.api.nvim_win_set_cursor(0, { from[1], from[2] })
      local o = vim.fn.searchpairpos(vim_pattern(open), '', vim_pattern(close), 'bcnW')
      if o[1] == 0 then break end
      local ol, oc = o[1], o[2] - 1
      local cl, cc = find_close(read, ol, oc, open, close)
      if not cl then break end
      if pos_lt(cur, { cl, cc }) or pos_eq(cur, { cl, cc }) then
        spans[#spans + 1] = span(open, close, { ol, oc }, { cl, cc })
      end
      if oc == 0 then
        if ol == 1 then break end
        local prev = read(ol - 1)
        from = { ol - 1, math.max(#prev - 1, 0) }
      else
        from = { ol, char_start(read(ol), oc - 1) }
      end
    end
    vim.api.nvim_win_set_cursor(0, saved)
  end

  if #spans > 0 then return spans end

  local line_nr, col = cur[1], cur[2]
  while true do
    local text_n = read(line_nr)
    if not text_n then return spans end
    local o = text_n:find(open, col + 1, true)
    while o do
      local cl, cc = find_close(read, line_nr, o - 1, open, close)
      if cl then
        spans[#spans + 1] = span(open, close, { line_nr, o - 1 }, { cl, cc })
        return spans
      end
      o = text_n:find(open, o + #open, true)
    end
    line_nr, col = line_nr + 1, 0
    if line_nr > vim.api.nvim_buf_line_count(0) then return spans end
  end
end

local function escaped(text, pos)
  return pos > 1 and text:sub(pos - 1, pos - 1) == '\\'
end

local function same_char_spans(text, ch)
  local spans, from = {}, 1
  while true do
    local s = text:find(ch, from, true)
    if not s then return spans end
    if escaped(text, s) then
      from = s + #ch
    else
      local next_from, closed = s + #ch, nil
      while true do
        local e = text:find(ch, next_from, true)
        if not e then break end
        if escaped(text, e) then next_from = e + #ch else closed = e break end
      end
      if not closed then return spans end
      spans[#spans + 1] = { s, closed }
      from = closed + #ch
    end
  end
end

local function distinct_spans(text, open, close)
  local spans, depth, start, from = {}, 0, nil, 1
  while true do
    local o = text:find(open, from, true)
    local c = text:find(close, from, true)
    if not o and not c then return spans end
    if o and (not c or o <= c) then
      if escaped(text, o) then
        from = o + #open
      else
        if depth == 0 then start = o end
        depth, from = depth + 1, o + #open
      end
    else
      if escaped(text, c) then
        from = c + #close
      else
        if depth > 0 then
          depth = depth - 1
          if depth == 0 then spans[#spans + 1] = { start, c } end
        end
        from = c + #close
      end
    end
  end
end

local function quote_spans(read, family, cur)
  local text = read(cur[1])
  local spans = {}
  for _, pair in ipairs(family) do
    local found = pair[1] == pair[2] and same_char_spans(text, pair[1])
      or distinct_spans(text, pair[1], pair[2])
    for _, item in ipairs(found) do
      spans[#spans + 1] = span(pair[1], pair[2], { cur[1], item[1] - 1 }, { cur[1], item[2] - 1 })
    end
  end
  return spans
end

local function pick(spans, cur, count)
  local containing = {}
  for _, item in ipairs(spans) do
    if not pos_lt(cur, item.open) and not pos_lt(item.close, cur) then
      containing[#containing + 1] = item
    end
  end
  table.sort(containing, function(a, b) return pos_lt(b.open, a.open) end)
  if #containing > 0 then return containing[count] end

  local forward = {}
  for _, item in ipairs(spans) do
    if pos_lt(cur, item.open) then forward[#forward + 1] = item end
  end
  table.sort(forward, function(a, b) return pos_lt(a.open, b.open) end)
  return forward[count]
end

function M.find(family, linewise, around, count)
  if type(family) ~= 'table' or #family == 0 then return nil end
  local read = reader()
  local cur = vim.api.nvim_win_get_cursor(0)
  local spans = {}

  if linewise then
    spans = quote_spans(read, family, cur)
  else
    for _, pair in ipairs(family) do
      for _, item in ipairs(bracket_spans(read, pair[1], pair[2], cur)) do
        spans[#spans + 1] = item
      end
    end
  end

  local found = pick(spans, cur, count or 1)
  if not found then return nil end

  local from, to
  if around then
    from = found.open
    to = { found.close[1], char_start(read(found.close[1]), found.close[2] + #found.close_text - 1) }
    if linewise then
      local text = read(found.close[1])
      local after = found.close[2] + #found.close_text
      local next_char = text:sub(after + 1, after + 1)
      if next_char == ' ' or next_char == '\t' then
        local col = after
        while text:sub(col + 1, col + 1) == ' ' or text:sub(col + 1, col + 1) == '\t' do col = col + 1 end
        to = { found.close[1], col - 1 }
      else
        local col = found.open[2]
        while col > 0 and (text:sub(col, col) == ' ' or text:sub(col, col) == '\t') do col = col - 1 end
        if col < found.open[2] then from = { found.open[1], col } end
      end
    end
  else
    from = { found.open[1], found.open[2] + #found.open_text }
    to = before(read, found.close)
    if not to or pos_lt(to, from) then return nil end
  end

  return { from = from, to = to }
end

function M.apply(from_line, from_col, to_line, to_col, operator_pending)
  if operator_pending then
    if vim.fn.getcmdwintype() == '' then vim.cmd('normal! \28\14') end
  else
    vim.cmd('normal! \27')
  end
  vim.api.nvim_win_set_cursor(0, { from_line, from_col })
  vim.cmd('normal! v')
  vim.api.nvim_win_set_cursor(0, { to_line, to_col })
end

return M
