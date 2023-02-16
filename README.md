# nap.nvim (next and previous)

Quickly jump between next and previous NeoVim buffer, tab, file, quickfix, diagnostic, etc.

A lightweight plugin inspired by [unimpaired.vim](https://github.com/tpope/vim-unimpaired), but:

* Focus on navigation, not editing or option toggling.
* Jump back and forth easily with a single key, instead of two keys.
* Written in Lua.

## TLDR

Use `b` (buffer) as an example:

* `<c-n>b`/`<c-p>b` jump to next/previous buffer. Then just pressing
`<c-n><c-n><c-n><c-p><c-p>...` to cycle through buffers.
* `<c-n>B`/`<c-p>B` jump to last/first buffer. 

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

The following are not yet supported, feel free to suggest others:
- [ ] Add File operator, similar to unimpaired.
- [ ] Support count.

## Add new operator

You can add/override operators or easily. For example: 

* With [Gitsigns](https://github.com/lewis6991/gitsigns.nvim), `require("nap").nap('c', "Gitsigns next_hunk", "Gitsigns prev_hunk", "Next diff", "Previous diff")`
* With [Aerial](https://github.com/stevearc/aerial.nvim), `require("nap").nap("o", "AerialNext", "AerialPrev", "Next outline symbol", "Previous outline symbol")`

## Install and config

Add `liangxianzhe/nap-nvim` to your plugin manager. 

Add `require("nap").setup()` to use default keys. Or change these default keys:

```
require("nap").setup({
    next_prefix = "<c-n>",
    prev_prefix = "<c-p>",
    next_repeat = "<c-n>",
    prev_repeat = "<c-p>",
})
```

We need two pairs of keys: `prefix` keys to trigger the first jump, and `repeat` keys to repeat with
a single press. `<c-n>` and `<c-p>` are chosen as defaults because most people don't map them.

However, setting `prefix` and `repeat` to the same key has one issue. When pressing `<c-n>` to
repeat jump, vim will need to wait
[timeoutlen](https://neovim.io/doc/user/options.html#'timeoutlen') to determine whether its is
`<c-n>` or `<c-n>b`.

Personally I use the following setup so I can cycle through using `<Enter>` `<C-Enter>` much faster.
```
require("nap").setup({
    next_prefix = "<space>", -- I use ; as leader so space is free
    prev_prefix = "<c-space>", -- Used much less 
    next_repeat = "<cr>", -- Enter is easy to press
    prev_repeat = "<c-cr>", -- C-Enter is easy too
})
```

The best config for you depends on your leader key and your terminal. Here are a few examples,
feel free to try it out:

* `<C-n>` and `<C-p>`
* `<Enter>` and `<C-Enter>` (Some terminal doesn't support `C-Enter`)
* `<Enter>` and `\` (If you remap leader key, the original leader key is near Enter)
* `<Space>` and `<C-Space>`
* `;` and `,` (use Leap/Flit or similar plugins to free these two keys)
* `]` and `[` (":help ]" to check default mappings)
* `>` and `<` (":help >" to check default mappings)
* Some `Alt` prefixed keys (Need terminal supports)

## Credits

* [unimpaired.vim](https://github.com/tpope/vim-unimpaired)
