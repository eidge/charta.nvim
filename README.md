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
  dependencies = { "nvim-lua/plenary.nvim" }
}
```

## Usage

### Default Keymaps

- `<leader>a` - Add current line/selection as bookmark
- `<leader>h` - Open charta window

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
