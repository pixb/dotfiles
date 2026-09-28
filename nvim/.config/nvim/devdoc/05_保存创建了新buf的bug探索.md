我来帮你查找每次保存打开新标签/buffer的问题。让我搜索相关的配置：
          
根据我的分析，我找到了可能导致"每次保存打开新标签/buffer"的问题原因：

## 问题分析

### 关键发现

1. **formatexpr 配置**：在 [config/options.lua#L104](file:///Users/pix/.config/nvim/lua/config/options.lua#L104) 中设置了：
   ```lua
   opt.formatexpr = "v:lua.PixVim.format.formatexpr()"
   ```

2. **formatexpr 函数**：在 [pixvim/util/format.lua#L26-30](file:///Users/pix/.config/nvim/lua/pixvim/util/format.lua#L26-30) 中定义：
   ```lua
   function M.formatexpr()
     if PixVim.has("conform.nvim") then
       return require("conform").formatexpr()
     end
     return vim.lsp.formatexpr({ timeout_ms = 3000 })
   end
   ```

3. **formatexpr 的作用**：`formatexpr` 是 Neovim 的一个选项，用于定义格式化表达式。它在以下情况下会被调用：
   - 使用 `gq` 命令格式化文本时
   - 某些自动格式化操作时
   - **可能被某些 autocmd 或插件在保存时触发**

4. **自动格式化**：在 [pixvim/util/format.lua#L162-167](file:///Users/pix/.config/nvim/lua/pixvim/util/format.lua#L162-167) 中有 `BufWritePre` autocmd：
   ```lua
   vim.api.nvim_create_autocmd("BufWritePre", {
     group = vim.api.nvim_create_augroup("LazyFormat", {}),
     callback = function(event)
       M.format({ buf = event.buf })
     end,
   })
   ```

### 可能的问题原因

**`formatexpr` 可能在某些情况下被意外触发**，导致 conform.nvim 或 LSP 格式化器执行了某些操作，比如：
- 打开临时文件进行格式化
- 创建新的 buffer 来显示格式化结果
- 某些 LSP 服务器在格式化时创建了新的窗口或 buffer

### 解决方案

#### 方案 1：禁用 formatexpr（推荐测试）

临时禁用 `formatexpr` 来确认是否是这个问题：

```lua
-- 在 config/options.lua 中注释掉或删除这一行
-- opt.formatexpr = "v:lua.PixVim.format.formatexpr()"
```

#### 方案 2：检查 conform.nvim 配置

检查是否有 conform.nvim 的配置文件，查看是否有 `format_on_save` 或类似的配置：

```bash
# 查找 conform 相关配置
grep -r "conform" ~/.config/nvim/lua/plugins/
```

#### 方案 3：禁用自动格式化

临时禁用自动格式化来确认：

```lua
-- 在 config/options.lua 中设置
vim.g.autoformat = false
```

#### 方案 4：调试 formatexpr 调用

在 [pixvim/util/format.lua#L26](file:///Users/pix/.config/nvim/lua/pixvim/util/format.lua#L26) 中添加调试信息：

```lua
function M.formatexpr()
  print("formatexpr called!")  -- 添加调试信息
  if PixVim.has("conform.nvim") then
    return require("conform").formatexpr()
  end
  return vim.lsp.formatexpr({ timeout_ms = 3000 })
end
```

### 建议的排查步骤

1. **先禁用 formatexpr**，看问题是否消失
2. **检查是否有 conform.nvim 插件配置**
3. **查看 Neovim 的消息日志**，保存时是否有错误或警告
4. **使用 `:messages` 命令**查看是否有相关信息

需要我帮你修改配置来测试这些方案吗？