# Delete buffer 如何配置？

> [!Question] 问题
> Delete current buffer如何配置？
> <kbd>LEADER</kbd> + <kbd>bd</kbd>

```lua
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })
```
