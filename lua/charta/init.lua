local ChartaUI = require('charta.ui')

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
