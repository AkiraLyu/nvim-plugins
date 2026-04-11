local defaults = require("nvimtex.defaults")
local util = require("nvimtex.util")

local M = {}

local state = {
  opts = vim.deepcopy(defaults.options),
  warnings = {},
}

local function warn_once(key, message)
  if state.warnings[key] then
    return
  end

  state.warnings[key] = true
  util.notify(message, vim.log.levels.WARN)
end

local function strip_jsonc_comments(raw)
  local output = {}
  local index = 1
  local in_string = false

  while index <= #raw do
    local current = raw:sub(index, index)
    local next_char = raw:sub(index + 1, index + 1)

    if in_string then
      output[#output + 1] = current
      if current == "\\" and index < #raw then
        output[#output + 1] = next_char
        index = index + 2
      elseif current == '"' then
        in_string = false
        index = index + 1
      else
        index = index + 1
      end
    elseif current == '"' then
      in_string = true
      output[#output + 1] = current
      index = index + 1
    elseif current == "/" and next_char == "/" then
      index = index + 2
      while index <= #raw and raw:sub(index, index) ~= "\n" do
        index = index + 1
      end
    elseif current == "/" and next_char == "*" then
      index = index + 2
      while index <= #raw - 1 do
        if raw:sub(index, index + 1) == "*/" then
          index = index + 2
          break
        end

        index = index + 1
      end
    else
      output[#output + 1] = current
      index = index + 1
    end
  end

  return table.concat(output)
end

local function decode_jsonc(raw)
  local without_comments = strip_jsonc_comments(raw)
  local normalized = without_comments:gsub(",(%s*[}%]])", "%1")
  local ok, decoded = pcall(vim.json.decode, normalized)
  if ok then
    return decoded
  end

  return nil, decoded
end

local function normalize_recipe_value(value)
  local normalized = util.trim(value:lower())
  normalized = normalized:gsub("%s*->%s*", " -> ")
  normalized = normalized:gsub("%s+", " ")
  return normalized
end

local function recipe_signature(recipe)
  return normalize_recipe_value(table.concat(recipe.tools or {}, " -> "))
end

local function extract_settings(raw_settings)
  return {
    default_recipe = raw_settings["latex-workshop.latex.recipe.default"],
    out_dir = raw_settings["latex-workshop.latex.outDir"],
    recipes = raw_settings["latex-workshop.latex.recipes"],
    tools = raw_settings["latex-workshop.latex.tools"],
  }
end

function M.setup(opts)
  state.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults.options), opts or {})
end

function M.get_opts()
  return state.opts
end

function M.load_settings(root)
  local settings = vim.deepcopy(defaults.project_settings)
  local settings_path = util.join(root, state.opts.settings_path)

  if util.is_file(settings_path) then
    local content = util.read_file(settings_path)
    if content then
      local decoded, err = decode_jsonc(content)
      if decoded then
        local extracted = extract_settings(decoded)
        if type(extracted.default_recipe) == "string" and extracted.default_recipe ~= "" then
          settings.default_recipe = extracted.default_recipe
        end
        if type(extracted.out_dir) == "string" and extracted.out_dir ~= "" then
          settings.out_dir = extracted.out_dir
        end
        if type(extracted.tools) == "table" and #extracted.tools > 0 then
          settings.tools = extracted.tools
        end
        if type(extracted.recipes) == "table" and #extracted.recipes > 0 then
          settings.recipes = extracted.recipes
        end
      else
        warn_once(
          "settings:" .. settings_path,
          string.format("failed to parse %s: %s; using built-in defaults", settings_path, err)
        )
      end
    end
  end

  settings.tool_map = {}
  for _, tool in ipairs(settings.tools) do
    settings.tool_map[tool.name] = tool
  end

  return settings
end

function M.load_project_conf(root)
  local conf_path = util.join(root, state.opts.project_conf)
  if not util.is_file(conf_path) then
    return {}
  end

  local conf = {}
  local content = util.read_file(conf_path)
  if not content then
    return conf
  end

  for _, line in ipairs(vim.split(content, "\n", { plain = true })) do
    local trimmed = util.trim(line)
    if trimmed ~= "" and not trimmed:match("^#") and not trimmed:match("^;") then
      local key, value = trimmed:match("^([^=]+)=(.*)$")
      if key and value then
        key = util.trim(key)
        value = util.strip_quotes(util.trim(value))
        if key == "recipe" or key == "target" then
          conf[key] = value
        end
      end
    end
  end

  return conf
end

function M.resolve_recipe(settings, requested_recipe)
  if type(requested_recipe) ~= "string" or requested_recipe == "" then
    return nil
  end

  local wanted = normalize_recipe_value(requested_recipe)

  for _, recipe in ipairs(settings.recipes or {}) do
    if normalize_recipe_value(recipe.name or "") == wanted then
      return recipe
    end
  end

  for _, recipe in ipairs(settings.recipes or {}) do
    if recipe_signature(recipe) == wanted then
      return recipe
    end
  end

  for _, recipe in ipairs(settings.recipes or {}) do
    if #recipe.tools == 1 and normalize_recipe_value(recipe.tools[1]) == wanted then
      return recipe
    end
  end

  return nil
end

function M.resolve_target(root, source_path, target)
  if type(target) ~= "string" or target == "" then
    return util.normalize(source_path)
  end

  local absolute_target = util.is_absolute(target) and util.normalize(target) or util.join(root, target)
  if not util.is_within(absolute_target, root) then
    return nil, string.format("target must stay inside root: %s", target)
  end

  return absolute_target
end

function M.resolve_out_dir(root, target_path, out_dir)
  if type(out_dir) ~= "string" or out_dir == "" then
    return util.dirname(target_path)
  end

  local target_dir = util.dirname(target_path)
  local resolved = util.trim(out_dir)
  resolved = resolved:gsub("%%DIR%%", target_dir)
  resolved = resolved:gsub("%%WORKSPACE_FOLDER%%", root)
  resolved = resolved:gsub("%%ROOT%%", root)

  if not util.is_absolute(resolved) then
    resolved = util.join(root, resolved)
  end

  return util.normalize(resolved)
end

function M.build_context(root, source_path)
  local settings = M.load_settings(root)
  local project_conf = M.load_project_conf(root)
  local target_path, target_err = M.resolve_target(root, source_path, project_conf.target)
  if not target_path then
    return nil, target_err
  end

  if not util.is_file(target_path) then
    return nil, string.format("target does not exist: %s", target_path)
  end

  if not util.is_tex(target_path) then
    return nil, string.format("target is not a .tex file: %s", target_path)
  end

  local recipe
  if project_conf.recipe then
    recipe = M.resolve_recipe(settings, project_conf.recipe)
    if not recipe then
      return nil, string.format("unknown recipe in %s: %s", state.opts.project_conf, project_conf.recipe)
    end
  else
    local default_recipe = util.has_bib(root) and "xelatex -> bibtex -> xelatex*2" or "xelatex"
    recipe = M.resolve_recipe(settings, default_recipe) or M.resolve_recipe(settings, settings.default_recipe)
    if not recipe then
      return nil, string.format("no recipe matches %s", default_recipe)
    end
  end

  local out_dir = M.resolve_out_dir(root, target_path, settings.out_dir)
  local target_rel = util.relative_to(target_path, root)

  return {
    out_dir = out_dir,
    project_conf = project_conf,
    recipe = recipe,
    root = root,
    settings = settings,
    started_at = (vim.uv or vim.loop).hrtime(),
    target_name = util.basename(target_path),
    target_path = target_path,
    target_rel = target_rel or target_path,
    target_stem = util.stem(target_path),
  }
end

return M
