# charta.nvim

A Neovim plugin for managing project-specific code pointers. Quickly capture, organize and navigate to code locations across your project.

<img width="864" height="489" alt="image" src="https://github.com/user-attachments/assets/544cf7b2-9839-4e43-b022-bd72a0cc8bc9" />

## Features

- Create multiple code pointer collections (chartas) per project
- Add bookmarks from any file location with a single keypress
- Support for both single-line and range bookmarks
- Jump back to bookmarked locations instantly
- Per-project storage keeps bookmarks organized

## Requirements

- Neovim >= 0.7.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

Add to your plugins directory (e.g., `~/.config/nvim/lua/plugins/charta-nvim.lua`):

```lua
return {
  "eidge/charta.nvim",
  opts = {},
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>a", function() require("charta").add_bookmark() end, mode = {"n", "v"}, desc = "Add bookmark to Charta" },
    { "<leader>h", function() require("charta").open_charta() end, mode = {"n", "v"}, desc = "Open charta" },
  }
}
```

## Configuration

You can customize the plugin by passing options to the `opts` table:

```lua
return {
  "eidge/charta.nvim",
  opts = {
    ui_width_ratio = 0.8,     -- Width of charta window as ratio of screen (default: 0.667)
    ui_height_ratio = 0.8,    -- Height of charta window as ratio of screen (default: 0.667)
    default_width = 300,      -- Fallback width when screen size unavailable (default: 200)
    default_height = 20       -- Fallback height when screen size unavailable (default: 10)
  },
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>a", function() require("charta").add_bookmark() end, mode = {"n", "v"}, desc = "Add bookmark to Charta" },
    { "<leader>h", function() require("charta").open_charta() end, mode = {"n", "v"}, desc = "Open charta" },
  }
}
```

**Note**: Ratios must be between 0 and 1. Invalid values will show a warning and use defaults.

## Usage

### Keymaps

Keymaps are configured via lazy.nvim's `keys` field (see Installation section above). The suggested keymaps are:

- `<leader>a` - Add current line/selection as bookmark
- `<leader>h` - Open charta window

You can customize these to any keybindings you prefer.

### Commands

- `:ChartaOpen [name]` - Open a specific charta or list if no name provided
- `:ChartaList` - Show list of chartas for the current project

### Charta Window Keymaps

When inside a charta window:

- `<CR>` - Jump to the bookmark under cursor
- `<Esc>` - Save and close the charta
- `-` - Go back to charta list

### Charta List Keymaps

When viewing the charta list:

- `<CR>` - Open selected charta (or create new one)
- `dd` - Delete the charta under cursor
- `<Esc>` - Close the list

### Workflow

1. **Create collections**: When adding your first bookmark, you'll be prompted to create or select a charta

2. **Add bookmarks**: Navigate to any location in your code and press `<leader>a` to add it to your current charta
   - In visual mode, it will bookmark the entire selected range

3. **Jump back**: Press `<leader>h` to open your charta, then `<CR>` on any bookmark to jump to that location

4. **Organize**: Create multiple chartas for different tasks or features (e.g., "bug-123", "feature-auth", "refactor-api")

## How It Works

- Chartas are stored per-project based on your current working directory
- Storage location: `~/.local/share/nvim/charta/chartas/<project-name>/`
- Each charta is a plain text file containing bookmarks
- Bookmarks use relative paths from your project root so they're easily shareable

## License

MIT
