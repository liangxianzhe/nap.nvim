# nap.nvim (next and previous)

Quickly jump between next and previous NeoVim buffer, tab, file, quickfix, diagnostic, etc.

A lightweight plugin inspired by [unimpaired.vim](https://github.com/tpope/vim-unimpaired), but:
* Focus on navigation, not editing or option toggling.
* Jump back and forth easily with a single key, instead of two keys.
* Written in Lua.

## TLDR

`<Enter>` to jump to next, `<Tab>` to jump to previous (similar to [leap](https://github.com/ggandor/leap.nvim)).

Use `b` (buffer) as an example:

* `<Enter>b` jump to next buffer, `<Tab>b` jump to previous buffer. Then just pressing
`<Enter><Enter><Enter><Tab><Tab>...` to cycle through buffers.
* `<Enter>B` and `<Tab>B` jump to last/first buffer. 

## Install

Add `liangxianzhe/nap-nvim` to your plugin manager. Then add `require("nap").setup()`. See
[Config](#Config) if you want to customize the prefix keys.

## Operators

| Operator    | Description   |
| ----------- | -----------   |
| a, A        | Tab           |
| b, B        | Buffer        |
| d           | Diagnostic    |
| l, L, C-l   | Location list |
| q, Q, C-q   | Quickfix      |
| s           | Spell         |
| t, T, C-t   | Tag           |

These are not yet supported, feel free to suggest others:
- [ ] Add File operator, similar to unimpaired.
- [ ] Support count.

## Add new operator

You can add/override operators or easily. For example: 
* With [Gitsigns](https://github.com/lewis6991/gitsigns.nvim), `require("nap").nap('h', "GitSigns next_hunk", "GitSigns prev_hunk", "Next diff", "Previous diff")`
* With [Aerial](https://github.com/stevearc/aerial.nvim), `require("nap").nap("o", "AerialNext", "AerialPrev", "Next outline symbol", "Previous outline symbol")`

## Config

The default config defines the keys:

```
require("nap").setup({
    next_prefix = "<cr>"
    prev_prefix = "<tab>"
    next_repeat = "<cr>"
    prev_repeat = "<tab>"
})
```

We need two pairs of keys: `prefix` keys to trigger the first jump, and `repeat` keys to repeat with
a single press. `<Enter>` and `<Tab>` are choosing as defaults because most people don't map them.

However, setting "prefix" and "repeat" to the same key has one issue. When pressing `<Enter>` to
repeat jump, vim will need to wait
[timeoutlen](https://neovim.io/doc/user/options.html#'timeoutlen') to determine whether its is
`<Enter>` or `<Enter>b`.

To make it smoother, personally I use `<Space>` and `<Space><Space>` as prefix keys, leaving 
`<Enter>` and `<Tab>` dedicated for repeating purpose.

You can choose keys work for your setup, for example: 
* `<Enter>` and `<Tab>`
* `<Space>` and `<Space><Space>`
* `;` and `,` (use Leap or similar plugins to free these two keys)
* `]` and `[` (":help ]" to check default mappings)
* `>` and `<` (":help >" to check default mappings)

## Credits

* [unimpaired.vim](https://github.com/tpope/vim-unimpaired)
