# fcitx-switch

在 Neovim 的插入模式和普通模式之间自动切换 `fcitx5` 输入法状态的小插件。

## 行为

- 离开插入模式时，记录当前 `fcitx5-remote` 状态
- 如果离开时不是英文状态，则执行 `fcitx5-remote -c` 切回英文
- 重新进入插入模式时，如果离开时原本是激活状态，则执行 `fcitx5-remote -o` 恢复输入法
- 系统里没有 `fcitx5-remote` 命令时，不做任何动作

这就是从个人 `autocmds.lua` 中抽出来的那段自动切换输入法逻辑，整理成了独立插件。

## 依赖

- Neovim 0.10+
- `fcitx5-remote`

## 安装

如果你已经把整个仓库克隆到本地，可以直接把 `fcitx-switch/` 子目录作为插件目录使用，然后在配置中调用：

```lua
require("fcitx_switch").setup()
```

如果你希望自行控制初始化，可以先设置：

```lua
vim.g.fcitx_switch_disable_auto_setup = 1
```

## 配置

默认配置：

```lua
require("fcitx_switch").setup({
  command = "fcitx5-remote",
})
```

## 说明

- 插件只上传了抽取后的源码和文档，没有包含原始 `autocmds.lua`
- 当前实现保留了原始逻辑的状态判断方式：仅当离开插入模式时记录到的状态为 `2` 时，重新进入插入模式才恢复输入法
