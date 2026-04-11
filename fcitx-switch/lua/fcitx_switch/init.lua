local M = {}

local defaults = {
  command = "fcitx5-remote",
}

local state = {
  initialized = false,
  input_status = 0,
  opts = vim.deepcopy(defaults),
}

local function has_fcitx5()
  return vim.fn.executable(state.opts.command) == 1
end

local function run_command(args)
  local result = vim.system(args, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end

  return vim.trim(result.stdout or "")
end

local function get_input_status()
  local output = run_command({ state.opts.command })
  return tonumber(output) or 0
end

local function switch_to_english()
  if not has_fcitx5() then
    return
  end

  state.input_status = get_input_status()
  if state.input_status ~= 0 then
    run_command({ state.opts.command, "-c" })
  end
end

local function restore_input_method()
  if not has_fcitx5() then
    return
  end

  if state.input_status == 2 then
    run_command({ state.opts.command, "-o" })
  end
end

function M.setup(opts)
  state.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  if state.initialized then
    return
  end

  local group = vim.api.nvim_create_augroup("FcitxSwitch", { clear = true })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    pattern = "*",
    callback = switch_to_english,
    desc = "Switch to English input method when leaving insert mode",
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    pattern = "*",
    callback = restore_input_method,
    desc = "Restore fcitx input method when entering insert mode",
  })

  state.initialized = true
end

return M
