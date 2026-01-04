local Path = require('plenary.path')

local M = {}

-- Hardcoded configuration options
local UI_WIDTH_RATIO = 0.667
local UI_HEIGHT_RATIO = 0.667
local DEFAULT_WIDTH = 200
local DEFAULT_HEIGHT = 10

-- Get project name from current working directory
local function get_project_name()
  local cwd = vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(cwd, ":t")
  return project_name
end

-- Get window width based on UI ratio
function M.window_width()
  local wins = vim.api.nvim_list_uis()
  if #wins > 0 then
    return math.floor(wins[1].width * UI_WIDTH_RATIO)
  end
  return DEFAULT_WIDTH
end

-- Get window height based on UI ratio
function M.window_height()
  local wins = vim.api.nvim_list_uis()
  if #wins > 0 then
    return math.floor(wins[1].height * UI_HEIGHT_RATIO)
  end
  return DEFAULT_HEIGHT
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
