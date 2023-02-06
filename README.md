# nap.nvim (next and previous)

Quickly jump between next and previous NeoVim buffer, tab, file, quickfix, diagnostic, etc.

A lightweight plugin inspired by [unimpaired.vim](https://github.com/tpope/vim-unimpaired), but:
* Focus on navigation, not editing or option toggling.
* Jump back and forth easily with a single key, instead of two keys.
* Written in Lua.

## TLDR

`<Enter>` to jump to next, `<Tab>` to jump to previous (similar to [leap](https://github.com/ggandor/leap.nvim)).

Using `b` (buffer) as an example:

* `<Enter>b` jump to next buffer, `<Tab>b` jump to previous buffer. Then just pressing
`<Enter><Enter><Enter><Tab><Tab>...` to cycle through buffers.
* `<Enter>B` and `<Tab>B` jump to last/first buffer. 

## Install

Add `liangxianzhe/nap-nvim` to your plugin manager. Then add `require("nap").setup()`. See
[Config](#Config) if you want to customize the prefix keys.

## Operators

| Operator    | Description   |
| ----------- | -----------   |
| a, A        | Argument      |
| b, B        | Buffer        |
| d           | Diagnostic    |
| l, L, C-l   | Location list |
| q, Q, C-q   | Quickfix      |
| s           | Spell         |
| t, T, C-t   | Tag           |

## Add new operator

You can add/override operators or easily. For example, with [Gitsigns](https://github.com/lewis6991/gitsigns.nvim) installed, then:
```
require("nap").nap('h', "GitSigns next_hunk", "GitSigns prev_hunk", "Next diff", "Previous diff")
```

## Config

The default config just defines the keys:
```
require("nap").setup({
    next_prefix = "<cr>"
    prev_prefix = "<tab>"
    next_repeat = "<cr>"
    prev_repeat = "<tab>"
})
```
You will need two pairs of keys: "prefix" keys to trigger the first jump, and "repeat" keys to
repeat with a single press. `<Enter>` and `<Tab>` are choosing because most people don't map them.

However, using the same key for "prefix" and "repeat" has one issue. When you press `<Enter>`, vim
will need to wait [timeoutlen] to see if you press a operator or not. 

To make it smoother, I use `<Space>` and `C-<Space>` as the prefix keys, and use `<Enter>` and
`<Tab>` as repeat keys. This is because I use `;` as leader (thanks to leap, `<Enter>` `<Tab>`
replaces the default `;` ','), so `<Space>` is available.

So you need find a pair of keys works for your setup, for example, `Enter` `Tab`, `Space` `C-Space`,
';' ',', etc.

## Credits

* [unimpaired.vim](https://github.com/tpope/vim-unimpaired), which I like. 
