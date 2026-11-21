local defaults = require('cjk_pairs.pairs')
local textobj = require('cjk_pairs.textobj')

local M = {}

local function primary(key)
  return defaults.aliases[key] or key
end

M.defaults = {
  families = defaults.families,
  matchpairs = {},
}

local function install(key, family)
  for _, prefix in ipairs({ 'i', 'a' }) do
    for _, mode in ipairs({ 'x', 'o' }) do
      local around = prefix == 'a'
      local linewise = defaults.linewise[primary(key)] == true
      vim.keymap.set(mode, prefix .. key, function()
        local region = textobj.find(family, linewise, around, vim.v.count1)
        if not region then return mode == 'o' and '<Esc>' or '' end
        return ('<Cmd>lua require("cjk_pairs.textobj").apply(%d, %d, %d, %d, %s)<CR>'):format(
          region.from[1],
          region.from[2],
          region.to[1],
          region.to[2],
          tostring(mode == 'o')
        )
      end, { expr = true, remap = true, desc = (around and 'around ' or 'inner ') .. key })
    end
  end
end

function M.setup(opts)
  opts = opts or {}

  local families = {}
  for key, family in pairs(defaults.families) do
    families[key] = family
  end
  for key, family in pairs(opts.families or {}) do
    families[primary(key)] = family
  end

  local targets = {}
  for key in pairs(defaults.families) do
    targets[key] = key
  end
  for key in pairs(defaults.aliases) do
    targets[key] = primary(key)
  end
  for key in pairs(opts.families or {}) do
    targets[key] = primary(key)
  end

  for key, name in pairs(targets) do
    local family = families[name]
    if type(family) == 'table' and #family > 0 then install(key, family) end
  end

  for _, entry in ipairs(opts.matchpairs or {}) do
    vim.opt.matchpairs:append(entry)
  end
end

return M
