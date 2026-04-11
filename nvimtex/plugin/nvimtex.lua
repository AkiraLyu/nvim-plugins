if vim.g.loaded_nvimtex_autobuild == 1 then
  return
end

vim.g.loaded_nvimtex_autobuild = 1

if vim.g.nvimtex_disable_auto_setup then
  return
end

require("nvimtex").setup()
