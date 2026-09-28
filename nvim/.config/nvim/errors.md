# errors

## 1.blink.cmp

```shell
Error executing vim.schedule lua callback: runtime error: Failed to create frecency database directory: Is a directory (os error 21)
stack traceback:
	[C]: in function 'init_db'
	...l/share/nvim/lazy/blink.cmp/lua/blink/cmp/fuzzy/init.lua:23: in function 'init_db'
	...l/share/nvim/lazy/blink.cmp/lua/blink/cmp/fuzzy/init.lua:89: in function 'fuzzy'
	...re/nvim/lazy/blink.cmp/lua/blink/cmp/completion/list.lua:134: in function 'fuzzy'
	...re/nvim/lazy/blink.cmp/lua/blink/cmp/completion/list.lua:108: in function 'show'
	...re/nvim/lazy/blink.cmp/lua/blink/cmp/completion/init.lua:53: in function <...re/nvim/lazy/blink.cmp/lua/blink/cmp/completion/init.lua:29>
```

已执行的修复： 已删除错误的目录 `~/.local/state/nvim/blink/cmp/frecency.dat`