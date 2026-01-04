local Path = require('plenary.path')
local config = require('charta.config')

local ChartaUI = {}
local augroup = vim.api.nvim_create_augroup("Charta", {})


local function get_file_path(charta_name)
  if not charta_name then
    error("No charta name provided")
  end
  return config.data_path():joinpath(charta_name)
end

function ChartaUI:open_charta(charta_name)
  config.ensure_data_path()

  -- If no charta name provided and no current charta, open the list
  if not charta_name and not self.current_charta then
    self:open_list()
    return
  end

  -- Store the current charta name (remember previous if not specified)
  self.current_charta = charta_name or self.current_charta
  local file_path = get_file_path(self.current_charta)

  -- If window already exists and is valid, focus it
  if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
    vim.api.nvim_set_current_win(self.win_id)
    return
  end

  local width = config.window_width()
  local height = config.window_height()

  local buffer = vim.fn.bufadd(file_path:absolute())
  vim.fn.bufload(buffer)

  local win_id = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    title = "Charta: " .. self.current_charta,
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

  -- Set up keymap for going to the list view
  vim.keymap.set("n", "-", function()
    -- Save the buffer
    vim.api.nvim_buf_call(buffer, function()
      vim.cmd("write")
    end)

    -- Close the window
    if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
      vim.api.nvim_win_close(self.win_id, true)
      self.win_id = nil
    end

    -- Open the list
    self:open_list()
  end, { buffer = buffer, desc = "Go to charta list" })
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

  -- Exit visual mode if we were in visual mode
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end

  -- If no current charta, store bookmark and open list
  if not self.current_charta then
    self.pending_bookmark = bookmark
    self:open_list()
    return
  end

  local path = get_file_path(self.current_charta)
  local contents = path:exists() and path:read() or ""

  if contents ~= "" and not contents:match("\n$") then
    contents = contents .. "\n"
  end

  path:write(contents .. bookmark .. "\n", "w")
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

function ChartaUI:open_list()
  config.ensure_data_path()

  -- Get list of charta files in the current project's directory
  local chartas = {}

  local data_path = config.data_path()
  if data_path:exists() then
    for entry_name, entry_type in vim.fs.dir(data_path:absolute()) do
      if entry_type == "file" then
        table.insert(chartas, entry_name)
      end
    end
  end

  -- Sort alphabetically
  table.sort(chartas)

  -- Add "Create new charta" option at the top
  local display_items = { "Create new charta", "" }
  for _, charta in ipairs(chartas) do
    table.insert(display_items, charta)
  end

  local width = math.min(60, config.window_width())
  local height = math.min(#display_items, config.window_height())

  -- Create a scratch buffer
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, display_items)

  local win_id = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    title = "Select Charta",
    title_pos = "center",
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

  vim.api.nvim_set_option_value("number", false, { win = win_id })
  vim.api.nvim_set_option_value("cursorline", true, { win = win_id })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buffer })

  -- Set up keymap for selecting a charta
  vim.keymap.set("n", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor[1]
    local selected = display_items[line_num]

    if line_num == 1 then
      -- Create new charta
      vim.api.nvim_win_close(win_id, true)
      vim.ui.input({ prompt = "Enter charta name: " }, function(input)
        if input and input ~= "" then
          self.current_charta = input

          -- If there's a pending bookmark, add it
          if self.pending_bookmark then
            local path = get_file_path(input)
            local contents = path:exists() and path:read() or ""
            if contents ~= "" and not contents:match("\n$") then
              contents = contents .. "\n"
            end
            path:write(contents .. self.pending_bookmark .. "\n", "w")
            print("Bookmark added to: " .. input)
            self.pending_bookmark = nil
          else
            self:open_charta(input)
          end
        else
          -- Clear pending bookmark if cancelled
          self.pending_bookmark = nil
        end
      end)
    elseif selected and selected ~= "" then
      vim.api.nvim_win_close(win_id, true)

      -- If there's a pending bookmark, add it
      if self.pending_bookmark then
        self.current_charta = selected
        local path = get_file_path(selected)
        local contents = path:exists() and path:read() or ""
        if contents ~= "" and not contents:match("\n$") then
          contents = contents .. "\n"
        end
        path:write(contents .. self.pending_bookmark .. "\n", "w")
        print("Bookmark added to: " .. selected)
        self.pending_bookmark = nil
      else
        self:open_charta(selected)
      end
    end
  end, { buffer = buffer, desc = "Open selected charta" })

  -- Set up keymap for closing the window
  vim.keymap.set("n", "<Esc>", function()
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_close(win_id, true)
    end
    -- Clear pending bookmark if cancelled
    self.pending_bookmark = nil
  end, { buffer = buffer, desc = "Close charta list" })

  -- Set up keymap for deleting a charta
  vim.keymap.set("n", "dd", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor[1]
    local selected = display_items[line_num]

    -- Don't allow deleting the "Create new charta" option or empty lines
    if line_num <= 2 or not selected or selected == "" then
      return
    end

    -- Ask for confirmation
    vim.ui.input({ prompt = "Delete '" .. selected .. "'? (y/n): " }, function(input)
      if input and (input:lower() == "y" or input:lower() == "yes") then
        local file_path = get_file_path(selected)
        if file_path:exists() then
          file_path:rm()
          print("Deleted charta: " .. selected)

          -- Close and reopen the list to refresh
          if vim.api.nvim_win_is_valid(win_id) then
            vim.api.nvim_win_close(win_id, true)
          end
          self:open_list()
        end
      end
    end)
  end, { buffer = buffer, desc = "Delete charta" })
end

local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Set up keymaps
  vim.keymap.set({"n", "v"}, "<leader>a", function()
    print("Adding bookmark")
    ChartaUI:add_bookmark()
  end, { desc = "Add bookmark to Charta" })

  vim.keymap.set({"n", "v"}, "<leader>h", function()
    ChartaUI:open_charta()
  end, { desc = "Open charta" })

  -- Create user commands
  vim.api.nvim_create_user_command("ChartaOpen", function(cmd_opts)
    local charta_name = cmd_opts.args ~= "" and cmd_opts.args or nil
    ChartaUI:open_charta(charta_name)
  end, { nargs = "?", desc = "Open charta window" })

  vim.api.nvim_create_user_command("ChartaList", function()
    ChartaUI:open_list()
  end, { desc = "List and select a charta to open" })
end

return M
