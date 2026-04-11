local config = require("nvimtex.config")
local util = require("nvimtex.util")

local M = {}

local sessions = {}

local function is_bibtex_tool(tool)
  return tool.name == "bibtex" or tool.command:match("bibtex$") ~= nil
end

local function finish_session(session, ok, context, message)
  local opts = config.get_opts()
  session.current = nil
  session.running = false
  session.queue_announced = false

  if ok then
    if opts.show_success then
      util.notify(
        string.format(
          "compiled %s with %s in %s",
          context.target_name,
          context.recipe.name,
          util.format_elapsed(context.started_at)
        ),
        vim.log.levels.INFO
      )
    end
  else
    util.notify(message, vim.log.levels.ERROR)
  end

  local pending = session.pending
  session.pending = nil
  if pending then
    M.start_compile(session, pending)
  end
end

local function build_command(tool, context)
  if is_bibtex_tool(tool) then
    return {
      args = {
        context.target_stem,
      },
      command = tool.command,
      cwd = context.out_dir,
      display = util.format_command(tool.command, { context.target_stem }),
    }
  end

  local args = {}
  for _, arg in ipairs(tool.args or {}) do
    local expanded = arg
    expanded = expanded:gsub("%%OUTDIR%%", context.out_dir)
    expanded = expanded:gsub("%%DOCFILE%%", context.target_rel)
    args[#args + 1] = expanded
  end

  return {
    args = args,
    command = tool.command,
    cwd = context.root,
    display = util.format_command(tool.command, args),
  }
end

local function run_step(session, context, index)
  local tool_name = context.recipe.tools[index]
  local tool = context.settings.tool_map[tool_name]
  if not tool then
    finish_session(
      session,
      false,
      context,
      string.format("recipe %s references unknown tool %s", context.recipe.name, tool_name)
    )
    return
  end

  local command = build_command(tool, context)
  if not util.ensure_dir(context.out_dir) then
    finish_session(session, false, context, string.format("failed to create out directory: %s", context.out_dir))
    return
  end

  session.current = vim.system(
    vim.list_extend({ command.command }, command.args),
    {
      cwd = command.cwd,
      text = true,
    },
    function(result)
      vim.schedule(function()
        if result.code == 0 then
          if index == #context.recipe.tools then
            finish_session(session, true, context)
          else
            run_step(session, context, index + 1)
          end
          return
        end

        local output = util.trim(result.stderr or "")
        if output == "" then
          output = util.trim(result.stdout or "")
        end
        if output == "" then
          output = "no compiler output captured"
        end

        finish_session(
          session,
          false,
          context,
          string.format(
            "compile failed (%s, exit %d)\ncommand: %s\n%s",
            context.target_name,
            result.code,
            command.display,
            output
          )
        )
      end)
    end
  )
end

function M.start_compile(session, request)
  session.running = true
  session.pending = nil

  local context, err = config.build_context(request.root, request.source_path)
  if not context then
    finish_session(session, false, {
      recipe = { name = "unknown" },
      started_at = (vim.uv or vim.loop).hrtime(),
      target_name = util.basename(request.source_path),
    }, err)
    return
  end

  run_step(session, context, 1)
end

function M.request_compile(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local source_path = util.normalize(vim.api.nvim_buf_get_name(bufnr))
  if source_path == "" or not util.is_tex(source_path) then
    return
  end

  local root = util.cwd()
  local session = sessions[root] or {}
  sessions[root] = session

  local request = {
    root = root,
    source_path = source_path,
  }

  if session.running then
    session.pending = request
    if not session.queue_announced then
      session.queue_announced = true
      util.notify("compile already running; queued the latest save", vim.log.levels.INFO)
    end
    return
  end

  M.start_compile(session, request)
end

return M
