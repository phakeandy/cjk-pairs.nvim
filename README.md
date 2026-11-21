# cjk-pairs.nvim

写中文时括号和引号是「（）、【】、《》、「」、“”」，而 nvim 原生的 `i(` `i"` `i<` 只认半角。
光标停在 `测试（正文）结束` 里按 `di(` 不会选中 `正文`，按 `ci"` 也选不到 `“引号”`，遇到整行没有半角
括号时原生还会跳到别的行去找。

这个插件让同一组键位同时认半角和全角。装好之后 `di(` 和 `di）` 一样能删掉 `（正文）` 里的字。

## 键位

    i(  i)  ib       ( )  （ ）
    a(  a)  ab

    i[  i]           [ ]  【 】  〖 〗  〔 〕  ［ ］
    a[  a]

    i{  i}  iB       { }  ｛ ｝
    a{  a}  aB

    i<  i>           < >  《 》  〈 〉  ＜ ＞
    a<  a>

    i"               " "  “ ”  ＂ ＂  「 」  『 』
    a"

    i'               ' '  ‘ ’  ＇ ＇
    a'

    i`               ` `
    a`

## 行为

跟原生对齐。光标在成对符号内部、在符号上、或在开符号之前，都选中这一对；不在任何配对里时向前
找下一对；`[count]` 向外一层；空的 `（）` 不选中任何东西。`a` 版本包含符号本身，引号类的 `a`
还会像原生一样带上旁边那串空格。

半角部分的行为是拿原生逐条对拍的，测试在 `tests/`。

## 安装

    {
      'phakeandy/cjk-pairs.nvim',
      opts = {},
    }

## 配置

`families` 的键是 text object 的键名，值是这组键认的符号。给已有的键就是替换，给新的键就是新增
一个 text object。某个键写成 `false` 就是关掉它。

    opts = {
      families = {
        ['('] = { { '(', ')' }, { '（', '）' }, { '﹙', '﹚' } },
        ['q'] = { { '「', '」' }, { '『', '』' } },
        ['}'] = false,
      },
      matchpairs = { '（:）', '【:】', '《:》' },
    }

`matchpairs` 里的条目会追加到 `'matchpairs'`，让 `%` 也能在中文括号之间跳，默认不动这个选项。

## 限制

引号类的配对只在本行内查找，跟原生一样，所以跨行写开的 `“……”` 不会被选中。

在可视模式里重复按 `i"` 不会像原生那样把引号也选进来，用 `a"` 代替。

## English

Make nvim's native text objects (`i(`, `i"`, `i<`, `i[`, `i{`, `i'`, and the `a` variants) work on the
full-width pairs used in Chinese and Japanese: （）【】〖〗〔〕［］｛｝《》〈〉＜＞“”＂＂「」『』‘’．

Behavior follows the builtin text objects: inside, on, or just before a pair; forward search when
there is no enclosing pair; `[count]` walks outward; empty pairs select nothing. ASCII behavior is
tested against the builtin one.

## License

MIT
