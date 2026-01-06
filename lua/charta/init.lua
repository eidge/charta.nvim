local ChartaUI = require('charta.ui')

local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Initialize config with user options
  local config = require('charta.config')
  config.setup(opts)

  -- Create user commands
  vim.api.nvim_create_user_command("ChartaOpen", function(cmd_opts)
    local charta_name = cmd_opts.args ~= "" and cmd_opts.args or nil
    ChartaUI:open_charta(charta_name)
  end, { nargs = "?", desc = "Open charta window" })

  vim.api.nvim_create_user_command("ChartaList", function()
    ChartaUI:open_list()
  end, { desc = "List and select a charta to open" })
end

-- Public API functions for keybindings
function M.add_bookmark()
  ChartaUI:add_bookmark()
end

function M.open_charta(charta_name)
  ChartaUI:open_charta(charta_name)
end

return M
