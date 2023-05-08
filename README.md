# nap.nvim (next and previous)

[中文](/README_cn.md)

Quickly jump between next and previous NeoVim buffer, tab, file, quickfix, diagnostic, etc.

A lightweight plugin inspired by [unimpaired.vim](https://github.com/tpope/vim-unimpaired), but:

* 🌱 Focus on navigation, not editing or option toggling.
* 🚀 Jump back and forth easily with a single key, instead of two keys.
* :rainbow: Written in Lua.

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
| c           | Change list   |
| d           | Diagnostic    |
| f, F        | File          |
| j           | Jump list     |
| l, L, C-l   | Location list |
| m           | Mark          |
| q, Q, C-q   | Quickfix      |
| s           | Spell         |
| t, T, C-t   | Tag           |
| z           | Fold          |

<details>

<summary>
Expand to see how they are defined.
</summary>

```lua
operators = {
    ["a"] = {
        next = { command = "tabnext", desc = "Next tab", },
        prev = { command = "tabprevious", desc = "Prev tab", },
    },
    ["A"] = {
        next = { command = "tablast", desc = "Last tab", },
        prev = { command = "tabfirst", desc = "First tab", },
    },
    ["b"] = {
        next = { command = "bnext", desc = "Next buffer", },
        prev = { command = "bprevious", desc = "Prev buffer", },
    },
    ["B"] = {
        next = { command = "blast", desc = "Last buffer", },
        prev = { command = "bfirst", desc = "First buffer", },
    },
    ["c"] = {
        next = { command = "normal! g,", desc = "Next change-list item", },
        prev = { command = "normal! g;", desc = "Prev change-list item", }
    },
    ["d"] = {
        next = { command = vim.diagnostic.goto_next, desc = "Next diagnostic", },
        prev = { command = vim.diagnostic.goto_prev, desc = "Prev diagnostic", },
        mode = { "n", "v", "o" }
    },
    ["f"] = {
        next = { command = M.next_file, desc = "Next file", },
        prev = { command = M.prev_file, desc = "Prev file", },
    },
    ["F"] = {
        next = { command = M.last_file, desc = "Last file", },
        prev = { command = M.first_file, desc = "First file", },
    },
    ["j"] = {
        next = { command = M.next_jump_list, desc = "Next jump-list item", },
        prev = { command = M.prev_jump_list, desc = "Prev jump-list item" },
    },
    ["l"] = {
        next = { command = "lnext", desc = "Next loclist item", },
        prev = { command = "lprevious", desc = "Prev loclist item" },
    },
    ["L"] = {
        next = { command = "llast", desc = "Last loclist item", },
        prev = { command = "lfirst", desc = "First loclist item" },
    },
    ["<C-l>"] = {
        next = { command = "lnfile", desc = "Next loclist item in different file", },
        prev = { command = "lpfile", desc = "Prev loclist item in different file" },
    },
    ["m"] = {
        next = { command = "normal! ]`", desc = "Next lowercase mark", },
        prev = { command = "normal! [`", desc = "Prev lowercase mark" },
    },
    ["q"] = {
        next = { command = "cnext", desc = "Next quickfix item", },
        prev = { command = "cprevious", desc = "Prev quickfix item" },
    },
    ["Q"] = {
        next = { command = "clast", desc = "Last quickfix item", },
        prev = { command = "cfirst", desc = "First quickfix item" },
    },
    ["<C-q>"] = {
        next = { command = "cnfile", desc = "Next quickfix item in different file", },
        prev = { command = "cpfile", desc = "Prev quickfix item in different file" },
    },
    ["s"] = {
        next = { command = "normal! ]s", desc = "Next spell error", },
        prev = { command = "normal! [s", desc = "Prev spell error", },
    },
    ["t"] = {
        next = { command = "tnext", desc = "Next tag", },
        prev = { command = "tprevious", desc = "Prev tag" },
    },
    ["T"] = {
        next = { command = "tlast", desc = "Last tag", },
        prev = { command = "tfirst", desc = "First tag" },
    },
    ["<C-t>"] = {
        next = { command = "ptnext", desc = "Next tag in previous window", },
        prev = { command = "ptprevious", desc = "Prev tag in previous window" },
    },
    ["z"] = {
        next = { command = "normal! zj", desc = "Next fold", },
        prev = { command = "normal! zk", desc = "Prev fold", },
        mode = { "n", "v", "o" },
    },
```

</details>

## Add new operator 

You can add/override operators easily, for example:
```lua
require("nap").operator("h", {
  next = { command = function() require("gitsigns").next_hunk({ preview = true }) end, desc = "Next diff", },
  prev = { command = function() require("gitsigns").prev_hunk({ preview = true }) end, desc = "Prev diff", },
  mode = { "n", "v", "o" },
})
```

Helper functions are provided for the following plugins to save your time:

* With [Gitsigns](https://github.com/lewis6991/gitsigns.nvim)
```lua
require("nap").operator('h', require("nap").gitsigns())
```
* With [Aerial](https://github.com/stevearc/aerial.nvim)
```lua
require("nap").operator('o', require("nap").aerial())
```
* With [vim-illuminate](https://github.com/RRethy/vim-illuminate)
```lua
require("nap").operator('r', require("nap").illuminate())
```

To remove a default operator:
```lua
require("nap").operator("a", false)
```

You can also add/remove operators inside setup call if you prefer to put them in a central place,
see next section.

## Install and config

Add `liangxianzhe/nap-nvim` to your plugin manager. Call `require("nap").setup()` to use defaults:

```lua
require("nap").setup({
    next_prefix = "<c-n>",
    prev_prefix = "<c-p>",
    next_repeat = "<c-n>",
    prev_repeat = "<c-p>",
    operators = {
        ...
    },
})
```

We need two pairs of keys: `prefix` keys to trigger the first jump, and `repeat` keys to repeat with
a single press. `<c-n>` and `<c-p>` are chosen as defaults because most people don't map them.

However, setting `prefix` and `repeat` to the same key has one issue. When pressing `<c-n>` to
repeat jump, vim will need to wait
[timeoutlen](https://neovim.io/doc/user/options.html#'timeoutlen') to determine whether its is
`<c-n>` or `<c-n>b`.

Personally I use the following setup so I can cycle through using `<Enter>` `<C-Enter>` much faster.

```lua
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
