# nap.nvim（上下）

以下内容由ChatGPT翻译。

快速跳转到下一个和上一个NeoVim缓冲区，标签页，文件，快速修复，诊断等。

一个轻量级的插件，灵感来自于[unimpaired.vim](https://github.com/tpope/vim-unimpaired)，但是：

* 专注于导航，而不是编辑或选项切换。
* 使用单个键轻松前后跳转，而不是两个键。
* 用Lua编写。

## TLDR

以“b”（缓冲区）为例：

* `<c-n>b` / `<c-p>b`跳转到下一个/上一个缓冲区。然后只需按下
`<c-n><c-n><c-n><c-p><c-p>...` 循环浏览缓冲区。
* `<c-n>B` / `<c-p>B`跳转到最后一个/第一个缓冲区。

## 运算符

| 运算符      | 描述          |
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
展开以查看它们的定义。
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
        modes = { "n", "v", "o" }
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
        prev = { command = "normal [`", desc = "Prev lowercase mark" },
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

## 添加新操作符

你可以轻松地添加/覆盖操作符，例如:
```lua
require("nap").operator("h", {
  next = { command = function() require("gitsigns").next_hunk({ preview = true }) end, desc = "Next diff", },
  prev = { command = function() require("gitsigns").prev_hunk({ preview = true }) end, desc = "Prev diff", },
  mode = { "n", "v", "o" },
})
```

以下一些插件还提供了帮助函数：

* [Gitsigns](https://github.com/lewis6991/gitsigns.nvim)
```lua
-- The provided implementation takes care of some edge cases, such as falling back to ]c [c in diff mode.
require("nap").operator('h', require("nap").gitsigns())
```
* [Aerial](https://github.com/stevearc/aerial.nvim)
```lua
require("nap").operator('o', require("nap").aerial())
```
* [vim-illuminate](https://github.com/RRethy/vim-illuminate)
```lua
require("nap").operator('r', require("nap").illuminate())
```

删除默认运算符：
```lua
require("nap").operator("a", false)
```

你也可以在`setup`中添加/删除运算符，如果你喜欢将它们放在一起，请参见下一节。

## 安装和配置

将 `liangxianzhe/nap-nvim` 添加到您的插件管理器中。调用 `require("nap").setup()` 使用默认值：

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

我们需要两组键：`prefix`键用于触发第一次跳转，`repeat`键用于以单击方式重复。选择`<c-n>`和`<c-p>`作为默认值，因为大多数人没有映射它们。

但是，将`prefix`和`repeat`设置为相同的键存在一个问题。当按下`<c-n>`以重复跳转时，vim将需要等待[timeoutlen](https://neovim.io/doc/user/options.html#'timeoutlen')以确定它是`<c-n>`还是`<c-n>b`。

我自己使用以下设置，以便我可以更快地进行循环。

```lua
require("nap").setup({
    next_prefix = "<space>", -- I use ; as leader so space is free
    prev_prefix = "<c-space>", -- Used much less 
    next_repeat = "<c-n>",
    prev_repeat = "<c-p>",
})
```

最适合您的配置取决于您的 Leader 键和终端。以下是一些示例，请尝试：

* `<C-n>` 和 `<C-p>`
* `<Enter>` 和 `<C-Enter>`（某些终端不支持 `C-Enter`）
* `<Enter>` 和 `\`（如果您重新映射 Leader 键，则原始 Leader 键靠近 Enter）
* `<Space>` 和 `<C-Space>`
* `;` 和 `,`（使用 Leap/Flit 或类似插件来释放这两个键）
* `]` 和 `[`（“:help ]”以查看默认映射）
* `>` 和 `<`（“:help >”以查看默认映射）
* 一些以 `Alt` 为前缀的键（需要终端支持）

## 感谢

* [unimpaired.vim](https://github.com/tpope/vim-unimpaired)
