return {
  -- Nvim-tree 文件浏览器插件
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- 依赖文件图标插件
    },
    cmd = { "NvimTreeToggle", "NvimTreeFindFile" }, -- 懒加载：仅在需要时加载
    config = function()
      require("nvim-tree").setup({
        -- 排序设置
        sort_by = "case_sensitive",

        -- 视图设置
        view = {
          width = 30, -- 文件树宽度
          side = "left", -- 显示在左侧
        },

        -- 渲染器设置
        renderer = {
          group_empty = true, -- 将空文件夹分组
          highlight_git = true, -- 高亮显示 Git 状态
          icons = {
            show = {
              file = true, -- 显示文件图标
              folder = true, -- 显示文件夹图标
              folder_arrow = true, -- 显示文件夹箭头
            },
          },
        },

        -- 过滤器设置
        filters = {
          dotfiles = false, -- 显示隐藏文件
          custom = { -- 自定义过滤规则
            ".git",
            "node_modules",
            ".cache",
          },
        },

        -- Git 集成设置
        git = {
          enable = true, -- 启用 Git 集成
          ignore = false, -- 不忽略 Git 状态
        },
      })
    end,
  },
}
