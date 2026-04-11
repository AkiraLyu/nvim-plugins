# nvim-plugins

个人 Neovim 插件集合仓库。

## 目录

- [`nvimtex/`](nvimtex/README.md): 保存 `*.tex` 时自动触发编译的插件，支持读取项目根目录 `settings.json`，并通过 `vimtex.conf` 覆盖 `target` 与 `recipe`

## 结构说明

这个仓库按子目录收纳插件，每个插件目录都是独立的 Lua 插件源码。

当前已收录：

- `nvimtex`

## 使用方式

如果你把整个仓库克隆到本地，可以把具体插件子目录加入 runtimepath，或在插件管理器里以本地目录方式引用对应子目录。
