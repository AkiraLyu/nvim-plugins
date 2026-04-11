if vim.g.loaded_fcitx_switch == 1 then
  return
end

vim.g.loaded_fcitx_switch = 1

if vim.g.fcitx_switch_disable_auto_setup then
  return
end

require("fcitx_switch").setup()
