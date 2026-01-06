local Path = require('plenary.path')

local M = {}

-- Configuration state with default values
local config_state = {
  ui_width_ratio = 0.667,
  ui_height_ratio = 0.667,
  default_width = 200,
  default_height = 10,
}

-- Get project name from current working directory
local function get_project_name()
  local cwd = vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(cwd, ":t")
  return project_name
end

-- Validate user configuration options
local function validate_opts(opts)
  local valid = true

  if opts.ui_width_ratio then
    if type(opts.ui_width_ratio) ~= "number" or opts.ui_width_ratio <= 0 or opts.ui_width_ratio >= 1 then
      vim.notify("charta.nvim: ui_width_ratio must be a number between 0 and 1", vim.log.levels.WARN)
      valid = false
    end
  end

  if opts.ui_height_ratio then
    if type(opts.ui_height_ratio) ~= "number" or opts.ui_height_ratio <= 0 or opts.ui_height_ratio >= 1 then
      vim.notify("charta.nvim: ui_height_ratio must be a number between 0 and 1", vim.log.levels.WARN)
      valid = false
    end
  end

  if opts.default_width then
    if type(opts.default_width) ~= "number" or opts.default_width <= 0 then
      vim.notify("charta.nvim: default_width must be a positive number", vim.log.levels.WARN)
      valid = false
    end
  end

  if opts.default_height then
    if type(opts.default_height) ~= "number" or opts.default_height <= 0 then
      vim.notify("charta.nvim: default_height must be a positive number", vim.log.levels.WARN)
      valid = false
    end
  end

  return valid
end

-- Setup function to merge user options with defaults
function M.setup(opts)
  opts = opts or {}

  if validate_opts(opts) then
    config_state = vim.tbl_deep_extend("force", config_state, opts)
  end
end

-- Get window width based on UI ratio
function M.window_width()
  local wins = vim.api.nvim_list_uis()
  if #wins > 0 then
    return math.floor(wins[1].width * config_state.ui_width_ratio)
  end
  return config_state.default_width
end

-- Get window height based on UI ratio
function M.window_height()
  local wins = vim.api.nvim_list_uis()
  if #wins > 0 then
    return math.floor(wins[1].height * config_state.ui_height_ratio)
  end
  return config_state.default_height
end

-- Get data path for the current project
function M.data_path()
  local base_data_path = Path:new(string.format("%s/charta/chartas", vim.fn.stdpath("data")))
  local project_name = get_project_name()
  return base_data_path:joinpath(project_name)
end

-- Ensure data path exists
function M.ensure_data_path()
  local path = Path:new(M.data_path())
  if not path:exists() then
    path:mkdir({ parents = true })
  end
end

return M
