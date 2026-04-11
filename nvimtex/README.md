# nvimtex

保存 `*.tex` 文件时自动触发编译的 Neovim 插件。

## 功能

- 默认读取根目录 `settings.json`，使用其中的 `latex-workshop.latex.tools`、`latex-workshop.latex.recipes`、`latex-workshop.latex.recipe.default` 和 `latex-workshop.latex.outDir`
- 根目录下检测到任意 `.bib` 文件时，默认使用 `xelatex -> bibtex -> xelatex -> xelatex`
- 没有 `.bib` 文件时，默认使用 `xelatex`
- 根目录存在 `vimtex.conf` 时，优先使用其中的 `target` 和 `recipe`
- `target` 必须是相对根目录的路径
- 同一工作目录同时只会跑一个编译；连续保存时会在当前编译结束后补跑一次最新请求

根目录定义为 Neovim 当前工作目录，也就是 `:pwd` 的结果。

## 依赖

- Neovim 0.10+
- 本地可执行的 `xelatex`、`bibtex`，以及你在 `settings.json` 中配置的其它工具

## 安装

如果你已经把整个仓库克隆到本地，可以直接把 `nvimtex/` 子目录作为插件目录使用，然后在配置中调用：

```lua
require("nvimtex").setup()
```

如果你希望自行控制初始化，可以先设置：

```lua
vim.g.nvimtex_disable_auto_setup = 1
```

## 项目配置

插件默认读取当前工作目录下的 `settings.json`。仓库里附带了一个示例文件 [settings.json.example](settings.json.example)，格式与 LaTeX Workshop 的 JSONC 配置保持一致。

## `vimtex.conf`

示例见 [vimtex.conf.example](vimtex.conf.example)。

格式为简单的 `key=value`：

```conf
target=main.tex
recipe=xelatex -> bibtex -> xelatex*2
```

也可以只写其中一个字段：

```conf
target=docs/thesis.tex
```

```conf
recipe=xelatex
```

## 手动命令

- `:NvimTexCompile`：立即对当前工作目录触发一次编译

## 说明

- `bibtex` 会在输出目录里以目标文件 stem 运行，例如 `main.tex` 会执行 `bibtex main`
- `settings.json` 是 JSONC，插件会先去掉注释和尾逗号再解析；解析失败时会回退到内置默认值
