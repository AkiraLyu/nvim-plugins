local config = require("nvimtex.config")
local compiler = require("nvimtex.compiler")

local M = {}

local initialized = false

function M.setup(opts)
  config.setup(opts)

  if initialized then
    return
  end

  local group = vim.api.nvim_create_augroup("NvimTexAutoBuild", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.tex",
    callback = function(args)
      if not config.get_opts().auto_build then
        return
      end

      compiler.request_compile(args.buf)
    end,
    desc = "Compile TeX files after save",
  })

  vim.api.nvim_create_user_command("NvimTexCompile", function()
    compiler.request_compile(0)
  end, {
    desc = "Compile the configured TeX target for the current workspace",
  })

  initialized = true
end

function M.compile(bufnr)
  compiler.request_compile(bufnr or 0)
end

return M
