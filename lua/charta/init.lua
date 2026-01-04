local Path = require('plenary.path')

function make_opts()
  return {
    ui_width_ratio = 0.667,
    ui_height_ratio = 0.667,
  }
end

local opts = make_opts()

local ChartaUI = {}
local augroup = vim.api.nvim_create_augroup("Charta", {})

local function get_project_name()
    local cwd = vim.fn.getcwd()
    -- Get the last component of the path as project name
    local project_name = vim.fn.fnamemodify(cwd, ":t")
    return project_name
end

local base_data_path = Path:new(string.format("%s/charta/chartas", vim.fn.stdpath("data")))
local project_name = get_project_name()
local data_path = base_data_path:joinpath(project_name)

local ensured_data_path = false
local function ensure_data_path()
    if ensured_data_path then
        return
    end

    local path = Path:new(data_path)
    if not path:exists() then
        path:mkdir({ parents = true })
    end
    ensured_data_path = true
end

ensure_data_path()
local charta_name = "default"
local file_path = data_path:joinpath(charta_name)

function ChartaUI:open_window()
  -- If window already exists and is valid, focus it
  if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
    vim.api.nvim_set_current_win(self.win_id)
    return
  end

  local wins = vim.api.nvim_list_uis()

  local width = 200
  local height = 10

  if #wins > 0 then
    width = math.floor(wins[1].width * opts.ui_width_ratio)
    height = math.floor(wins[1].height * opts.ui_height_ratio)
  else
    error("Could not set relative width & height, falling back to static size.")
  end

  local buffer = vim.fn.bufadd(file_path:absolute())
  vim.fn.bufload(buffer)

  local win_id = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    title = "Charta",
    title_pos = "left",
    row = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = "minimal",
    border = "single",
  })

  if win_id == 0 then
    error("failed to open window")
  end

  self.win_id = win_id

  vim.api.nvim_set_option_value("number", false, { win = win_id })
  vim.api.nvim_set_option_value("filetype", "charta", { buf = buffer })

  -- Set up keymap for opening bookmarks
  vim.keymap.set("n", "<CR>", function()
    ChartaUI:open_bookmark()
  end, { buffer = buffer, desc = "Open bookmark" })

  -- Set up keymap for saving and closing the window
  vim.keymap.set("n", "<Esc>", function()
    -- Save the buffer
    vim.api.nvim_buf_call(buffer, function()
      vim.cmd("write")
    end)

    -- Close the window
    if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
      vim.api.nvim_win_close(self.win_id, true)
      self.win_id = nil
    end
  end, { buffer = buffer, desc = "Save and close charta window" })
end

function ChartaUI:add_bookmark()
  local current_file = vim.api.nvim_buf_get_name(0)
  local mode = vim.api.nvim_get_mode().mode

  -- Make path relative to project root
  local root = vim.fn.getcwd()
  local relative_file = Path:new(current_file):make_relative(root)

  local bookmark
  if mode == "v" or mode == "V" or mode == "\22" then
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end

    if start_line == end_line then
      bookmark = string.format("%s:%d", relative_file, start_line)
    else
      bookmark = string.format("%s:%d-%d", relative_file, start_line, end_line)
    end
  else
    local line_number = vim.api.nvim_win_get_cursor(0)[1]
    bookmark = string.format("%s:%d", relative_file, line_number)
  end

  local path = file_path
  local contents = path:exists() and path:read() or ""

  if contents ~= "" and not contents:match("\n$") then
    contents = contents .. "\n"
  end

  path:write(contents .. bookmark .. "\n", "w")

  -- Exit visual mode if we were in visual mode
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end
end

function ChartaUI:open_bookmark()
  local buffer = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]

  -- Pattern to match bookmarks: filename:line or filename:line-line
  local bookmark_pattern = "^(.+):(%d+)%-?(%d*)$"

  while line_num > 0 do
    local line = vim.api.nvim_buf_get_lines(buffer, line_num - 1, line_num, false)[1]

    -- Skip empty lines
    if line and line ~= "" then
      local file, start_line, end_line = line:match(bookmark_pattern)

      if file then
        -- Make file path absolute based on project root
        local root = vim.fn.getcwd()
        local absolute_file = root .. "/" .. file

        -- Close the charta window
        if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
          vim.api.nvim_win_close(self.win_id, true)
          self.win_id = nil
        end

        -- Open the file
        vim.cmd("edit " .. vim.fn.fnameescape(absolute_file))

        -- Jump to the line, or end of file if line doesn't exist
        local target_start = tonumber(start_line)
        local last_line = vim.api.nvim_buf_line_count(0)
        if target_start > last_line then
          target_start = last_line
        end
        vim.api.nvim_win_set_cursor(0, {target_start, 0})

        -- If this is a range bookmark, select it in visual mode
        if end_line and end_line ~= "" then
          local target_end = tonumber(end_line)
          if target_end > last_line then
            target_end = last_line
          end

          -- Enter visual line mode and select the range
          vim.cmd("normal! V")
          vim.api.nvim_win_set_cursor(0, {target_end, 0})
        end

        -- Center the cursor
        vim.cmd("normal! zz")

        return
      end
    end

    line_num = line_num - 1
  end

  error("No file to open")
end

-- Move this to key configuration that gets called in setup
vim.keymap.set({"n", "v"}, "<leader>a", function()
  print("Adding bookmark")
  ChartaUI:add_bookmark()
end, { desc = "Add bookmark to Charta" })

vim.keymap.set({"n", "v"}, "<leader>h", function()
  ChartaUI:open_window()
end, { desc = "Open charta" })

local M = {}

function M:setup(opts)
  opts = opts or {}

  print("Setup function ran")
end

return M
