local script = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(script, ':h:h')
vim.opt.runtimepath:append(root)
vim.cmd('set noswapfile')

local ascii = {
  { 'paren inside', { 'a(b)c' }, { 1, 2 }, 'di(' },
  { 'paren on open', { 'a(b)c' }, { 1, 1 }, 'di(' },
  { 'paren on text', { 'a(b)c' }, { 1, 3 }, 'di(' },
  { 'paren on close', { 'a(b)c' }, { 1, 4 }, 'di(' },
  { 'paren before open', { 'a(b)c' }, { 1, 0 }, 'di(' },
  { 'paren after close around', { 'a(b)c' }, { 1, 4 }, 'da(' },
  { 'paren after close inside', { 'a(b)c' }, { 1, 5 }, 'di(' },
  { 'paren alias ib', { 'a(b)c' }, { 1, 2 }, 'dib' },
  { 'paren alias ab', { 'a(b)c' }, { 1, 2 }, 'dab' },
  { 'paren alias i)', { 'a(b)c' }, { 1, 2 }, 'di)' },
  { 'paren empty', { 'a()c' }, { 1, 2 }, 'di(' },
  { 'paren nested inner', { '((a))' }, { 1, 2 }, 'di(' },
  { 'paren nested count', { '((a))' }, { 1, 2 }, 'd2i(' },
  { 'paren nested count open', { '((a))' }, { 1, 1 }, 'd2i(' },
  { 'paren nested around', { '((a))' }, { 1, 2 }, 'da(' },
  { 'paren multiline', { 'x(a', 'b)y' }, { 1, 2 }, 'di(' },
  { 'paren multiline around', { 'x(a', 'b)y' }, { 1, 2 }, 'da(' },
  { 'paren forward', { 'abc', 'x(y)z' }, { 1, 0 }, 'di(' },
  { 'paren forward far', { 'abc', 'def', 'ghi', 'x(y)z' }, { 1, 0 }, 'di(' },
  { 'paren several pairs', { '(a) (b) (c)' }, { 1, 6 }, 'di(' },
  { 'paren several pairs around', { '(a) (b) (c)' }, { 1, 6 }, 'da(' },
  { 'paren gap', { '(b) x' }, { 1, 4 }, 'da(' },
  { 'paren yank', { 'a(b)c' }, { 1, 2 }, 'yi(' },
  { 'bracket inside', { 'a[b]c' }, { 1, 2 }, 'di[' },
  { 'bracket alias', { 'a[b]c' }, { 1, 2 }, 'di]' },
  { 'bracket alias ib', { 'a[b]c' }, { 1, 2 }, 'dib' },
  { 'brace inside', { 'a{b}c' }, { 1, 2 }, 'di{' },
  { 'brace alias B', { 'a{b}c' }, { 1, 2 }, 'diB' },
  { 'brace alias', { 'a{b}c' }, { 1, 2 }, 'di}' },
  { 'angle inside', { 'a<b>c' }, { 1, 2 }, 'di<' },
  { 'angle alias', { 'a<b>c' }, { 1, 2 }, 'di>' },
  { 'quote inside', { 'x"ab"y' }, { 1, 3 }, 'di"' },
  { 'quote around', { 'x"ab"y' }, { 1, 3 }, 'da"' },
  { 'quote before', { 'x"ab"y' }, { 1, 0 }, 'di"' },
  { 'quote two pairs space', { '"a" "b"' }, { 1, 4 }, 'di"' },
  { 'quote two pairs inside first', { '"a" "b"' }, { 1, 1 }, 'di"' },
  { 'quote two pairs inside second', { '"a" "b"' }, { 1, 6 }, 'di"' },
  { 'quote two pairs on close', { '"a" "b"' }, { 1, 2 }, 'di"' },
  { 'quote adjacent middle', { '"a""b"' }, { 1, 3 }, 'di"' },
  { 'quote unmatched', { '"a" b' }, { 1, 5 }, 'di"' },
  { 'quote escaped', { 'a \\"x\\" b' }, { 1, 4 }, 'di"' },
  { 'quote multiline', { '"a', 'b"' }, { 1, 1 }, 'di"' },
  { 'single quote inside', { "x'ab'y" }, { 1, 3 }, "di'" },
  { 'single quote apostrophe', { "it's here" }, { 1, 3 }, "di'" },
  { 'backtick inside', { 'a`bc`d' }, { 1, 3 }, 'di`' },
  { 'paren count siblings', { '(a) (b) (c)' }, { 1, 6 }, 'd2i(' },
  { 'paren on last close', { '((a))' }, { 1, 4 }, 'di(' },
  { 'quote around two pairs', { '"a" "b"' }, { 1, 4 }, 'da"' },
  { 'quote around adjacent', { '"a""b"' }, { 1, 3 }, 'da"' },
  { 'paren visual', { 'a(b)c' }, { 1, 2 }, 'vi(y' },
  { 'quote visual', { '"a" "b"' }, { 1, 1 }, 'vi"y' },
  { 'brace multiline', { 'x{a', 'b}y' }, { 1, 2 }, 'di{' },
  { 'angle multiline', { 'x<a', 'b>y' }, { 1, 2 }, 'da<' },
  { 'paren change', { 'a(b)c' }, { 1, 2 }, 'ci(N\27' },
  { 'quote around trailing space', { 'x "ab" y' }, { 1, 4 }, 'da"' },
  { 'quote around no space', { ' "ab"' }, { 1, 2 }, 'da"' },
  { 'quote around two spaces', { '"a"  "b"' }, { 1, 6 }, 'da"' },
  { 'single quote around trailing', { "x 'ab' y" }, { 1, 4 }, "da'" },
}

local cjk = {
  { 'cjk paren inside', { '测试（中文括号）结束' }, { 1, 9 }, 'di(', { lines = { '测试（）结束' } } },
  { 'cjk paren around', { '测试（中文括号）结束' }, { 1, 9 }, 'da(', { lines = { '测试结束' } } },
  { 'cjk paren yank', { '测试（中文括号）结束' }, { 1, 9 }, 'yi(', { reg = '中文括号' } },
  { 'cjk paren on open', { '测试（中文括号）结束' }, { 1, 6 }, 'di(', { lines = { '测试（）结束' } } },
  { 'cjk paren on close', { '测试（中文括号）结束' }, { 1, 21 }, 'di(', { lines = { '测试（）结束' } } },
  { 'cjk paren after close', { '测试（中文括号）结束' }, { 1, 24 }, 'di(', {
    lines = { '测试（中文括号）结束' },
  } },
  { 'cjk bracket', { '标签【正文】结束' }, { 1, 9 }, 'di[', { lines = { '标签【】结束' } } },
  { 'cjk lenticular', { '标签〖正文〗结束' }, { 1, 9 }, 'di[', { lines = { '标签〖〗结束' } } },
  { 'cjk tortoise', { '文件〔正文〕结束' }, { 1, 9 }, 'di[', { lines = { '文件〔〕结束' } } },
  { 'cjk fullwidth bracket', { '标签［正文］结束' }, { 1, 9 }, 'di[', { lines = { '标签［］结束' } } },
  { 'cjk brace', { '代码｛正文｝结束' }, { 1, 9 }, 'di{', { lines = { '代码｛｝结束' } } },
  { 'cjk title', { '读《书名》了' }, { 1, 7 }, 'di<', { lines = { '读《》了' } } },
  { 'cjk angle', { '读〈书名〉了' }, { 1, 7 }, 'di<', { lines = { '读〈〉了' } } },
  { 'cjk fullwidth angle', { '读＜书名＞了' }, { 1, 7 }, 'di<', { lines = { '读＜＞了' } } },
  { 'cjk double quote', { '说“中文引号”了' }, { 1, 10 }, 'di"', { lines = { '说“”了' } } },
  { 'cjk corner quote', { '说「角引号」了' }, { 1, 10 }, 'di"', { lines = { '说「」了' } } },
  { 'cjk white corner quote', { '说『双角引』了' }, { 1, 10 }, 'di"', { lines = { '说『』了' } } },
  { 'cjk fullwidth quote', { '说＂中文＂了' }, { 1, 10 }, 'di"', { lines = { '说＂＂了' } } },
  { 'cjk single quote', { '说‘单引号’了' }, { 1, 10 }, 'di\'', { lines = { '说‘’了' } } },
  { 'cjk quote nested corner', { '“外层「内层」外层”' }, { 1, 16 }, 'di"', {
    lines = { '“外层「」外层”' },
  } },
  { 'cjk quote nested count', { '“外层「内层」外层”' }, { 1, 16 }, 'd2i"', { lines = { '“”' } } },
  { 'cjk paren nested', { '嵌套（外（内）外）结束' }, { 1, 15 }, 'di(', { lines = { '嵌套（外（）外）结束' } } },
  { 'cjk paren nested count', { '嵌套（外（内）外）结束' }, { 1, 15 }, 'd2i(', { lines = { '嵌套（）结束' } } },
  { 'cjk mixed nesting', { '嵌套（外(中)外）结束' }, { 1, 15 }, 'di(', { lines = { '嵌套（外()外）结束' } } },
  { 'cjk mixed nesting count', { '嵌套（外(中)外）结束' }, { 1, 15 }, 'd2i(', { lines = { '嵌套（）结束' } } },
  { 'cjk ascii inside', { '中文(括号)结束' }, { 1, 9 }, 'di(', { lines = { '中文()结束' } } },
  { 'cjk paren multiline', { '开始（第一行', '第二行）结束' }, { 1, 12 }, 'di(', {
    lines = { '开始（）结束' },
  } },
  { 'cjk forward next line', { '没有括号', '下一行（目标）结束' }, { 1, 0 }, 'di(', {
    lines = { '没有括号', '下一行（）结束' },
  } },
  { 'cjk empty paren', { '测试（）结束' }, { 1, 9 }, 'di(', { lines = { '测试（）结束' } } },
  { 'cjk quote linewise', { '“开头', '结尾”' }, { 1, 4 }, 'di"', { lines = { '“开头', '结尾”' } } },
  { 'cjk combine', { '改（甲）和（乙）' }, { 1, 4 }, 'ci(新\27', { lines = { '改（新）和（乙）' }, reg = '甲' } },
  { 'cjk surround angles', { 'x《书名》y' }, { 1, 7 }, 'da<', { lines = { 'xy' } } },
  { 'cjk paren around inner', { '嵌套（外（内）外）结束' }, { 1, 15 }, 'da(', {
    lines = { '嵌套（外外）结束' },
  } },
  { 'cjk quote around', { '说“中文引号”了' }, { 1, 10 }, 'da"', { lines = { '说了' } } },
  { 'cjk corner quote around', { '说「角引」了' }, { 1, 10 }, 'da"', { lines = { '说了' } } },
  { 'cjk bracket forward', { '无', '第二行【目标】尾' }, { 1, 0 }, 'di[', {
    lines = { '无', '第二行【】尾' },
  } },
  { 'cjk mixed quote kinds', { '“甲”和「乙」' }, { 1, 13 }, 'di"', { lines = { '“甲”和「」' } } },
  { 'cjk quote around trailing space', { '说“甲” 了' }, { 1, 10 }, 'da"', { lines = { '说了' } } },
}

local function run(case)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, case[2])
  vim.fn.setreg('"', '')
  vim.api.nvim_win_set_cursor(0, case[3])
  pcall(vim.cmd, 'normal ' .. case[4])
  return { lines = vim.api.nvim_buf_get_lines(0, 0, -1, false), reg = vim.fn.getreg('"') }
end

local native = {}
for _, case in ipairs(ascii) do
  native[case[1]] = run(case)
end

require('cjk_pairs').setup()

local failures, total = 0, 0
local function check(name, got, want)
  total = total + 1
  local lines_ok = want.lines == nil or vim.deep_equal(want.lines, got.lines)
  local reg_ok = want.reg == nil or want.reg == got.reg
  if lines_ok and reg_ok then return end
  failures = failures + 1
  print(('FAIL %s\n  want %s\n  got  %s'):format(name, vim.inspect(want), vim.inspect(got)))
end

for _, case in ipairs(ascii) do
  check('native parity: ' .. case[1], run(case), native[case[1]])
end

for _, case in ipairs(cjk) do
  check(case[1], run(case), case[5])
end

print(('%d/%d passed'):format(total - failures, total))
if failures > 0 then os.exit(1) end
