local uv = vim.uv or vim.loop

local M = {}

function M.trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.strip_quotes(value)
  if #value < 2 then
    return value
  end

  local first = value:sub(1, 1)
  local last = value:sub(-1)
  if (first == '"' and last == '"') or (first == "'" and last == "'") then
    return value:sub(2, -2)
  end

  return value
end

function M.normalize(path)
  if not path or path == "" then
    return path
  end

  return vim.fs.normalize(path)
end

function M.join(...)
  local parts = { ... }
  return M.normalize(table.concat(parts, "/"))
end

function M.read_file(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end

  local content = fd:read("*a")
  fd:close()
  return content
end

function M.is_absolute(path)
  if not path or path == "" then
    return false
  end

  return path:match("^/") ~= nil or path:match("^%a:[/\\]") ~= nil
end

function M.exists(path)
  return uv.fs_stat(path) ~= nil
end

function M.is_file(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == "file"
end

function M.is_dir(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == "directory"
end

function M.ensure_dir(path)
  if M.is_dir(path) then
    return true
  end

  return vim.fn.mkdir(path, "p") == 1
end

function M.basename(path)
  return vim.fs.basename(path)
end

function M.dirname(path)
  return vim.fs.dirname(path)
end

function M.stem(path)
  return (M.basename(path):gsub("%.[^.]+$", ""))
end

function M.is_tex(path)
  return type(path) == "string" and path:lower():sub(-4) == ".tex"
end

function M.is_within(path, root)
  local normalized_path = M.normalize(path)
  local normalized_root = M.normalize(root)

  if normalized_path == normalized_root then
    return true
  end

  return normalized_path:sub(1, #normalized_root + 1) == (normalized_root .. "/")
end

function M.relative_to(path, root)
  local normalized_path = M.normalize(path)
  local normalized_root = M.normalize(root)

  if normalized_path == normalized_root then
    return "."
  end

  local prefix = normalized_root .. "/"
  if normalized_path:sub(1, #prefix) ~= prefix then
    return nil
  end

  return normalized_path:sub(#prefix + 1)
end

function M.cwd()
  return M.normalize(uv.cwd())
end

function M.notify(message, level)
  vim.schedule(function()
    vim.notify(message, level or vim.log.levels.INFO, { title = "nvimtex" })
  end)
end

function M.has_bib(root)
  local stack = { M.normalize(root) }
  local skipped = {
    [".git"] = true,
  }

  while #stack > 0 do
    local current = table.remove(stack)
    local ok, iterator = pcall(vim.fs.dir, current)
    if ok and iterator then
      for name, kind in iterator do
        local path = M.join(current, name)
        if kind == "file" and name:lower():sub(-4) == ".bib" then
          return true
        end

        if kind == "directory" and not skipped[name] then
          stack[#stack + 1] = path
        end
      end
    end
  end

  return false
end

function M.format_command(command, args)
  local parts = { command }
  vim.list_extend(parts, args or {})
  return table.concat(parts, " ")
end

function M.format_elapsed(started_at)
  local elapsed_ms = ((uv.hrtime() - started_at) / 1e6)
  return string.format("%.0fms", elapsed_ms)
end

return M
