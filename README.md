# 🗺️ nvim-navbuddy

A simple popup display that provides breadcrumbs like navigation feature but
in keyboard centric manner inspired by ranger file manager.

![2023-03-26 09-48-54](https://user-images.githubusercontent.com/43147494/227755128-6421972e-b2b4-4d69-8906-81baa7a82eeb.gif)

## ⚡️ Requirements

* Neovim >= 0.8.0
* [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
* [nvim-navic](https://github.com/SmiteshP/nvim-navic)
* [nui.nvim](https://github.com/MunifTanjim/nui.nvim)

## 📦 Installation

Install the plugin with your preferred package manager:

### [packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "SmiteshP/nvim-navbuddy",
    requires = {
        "neovim/nvim-lspconfig",
        "SmiteshP/nvim-navic",
        "MunifTanjim/nui.nvim"
    }
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug "neovim/nvim-lspconfig"
Plug "SmiteshP/nvim-navic"
Plug "MunifTanjim/nui.nvim"
Plug "SmiteshP/nvim-navbuddy"
```

## ⚙️ Setup

nvim-navbuddy needs to be attached to lsp servers of the buffer to work. You can pass the
navbuddy's `attach` function as `on_attach` while setting up the lsp server. You can skip this
step if you have enabled `auto_attach` option in setup function.

Example:
```lua
local navbuddy = require("nvim-navbuddy")

require("lspconfig").clangd.setup {
	on_attach = function(client, bufnr)
		navbuddy.attach(client, bufnr)
	end
}
```

## 🪄 Customise

Use `setup` to override any of the default options

* `icons` : Indicate the type of symbol captured. Default icons assume you have nerd-fonts.
* `window` : Set options related to window's "border", "size", "position".
* `mappings` : Actions to be triggered for specified keybindings.
* `lsp` :
	* `auto_attach` : Enable to have Navbuddy automatically attach to every LSP for current buffer. Its disabled by default.
	* `preference` : Table ranking lsp_servers. Lower the index, higher the priority of the server. If there are more than one server attached to a buffer, navbuddy will refer to this list to make a decision on which one to use.
			for example - In case a buffer is attached to clangd and ccls both and the preference list is `{ "clangd", "pyright" }`. Then clangd will be prefered.

```lua
local navbuddy = require("nvim-navbuddy")
local actions = require("nvim-navbuddy.actions")

navbuddy.setup {
    window = {
        border = "single",  -- "rounded", "double", "solid", "none"
                            -- or an array with eight chars building up the border in a clockwise fashion
                            -- starting with the top-left corner. eg: { "╔", "═" ,"╗", "║", "╝", "═", "╚", "║" }.
        size = "60%",
        position = "50%",
        sections = {
            left = {
                size = "20%",
                border = nil -- You can set border style for each section individually as well.
            },
            mid = {
                size = "40%"
            },
            right = {
                size = "40%" -- These should ideally add up to 100%
            }
        }
    },
    icons = {
        File          = " ",
        Module        = " ",
        Namespace     = " ",
        Package       = " ",
        Class         = " ",
        Method        = " ",
        Property      = " ",
        Field         = " ",
        Constructor   = " ",
        Enum          = "練",
        Interface     = "練",
        Function      = " ",
        Variable      = " ",
        Constant      = " ",
        String        = " ",
        Number        = " ",
        Boolean       = "◩ ",
        Array         = " ",
        Object        = " ",
        Key           = " ",
        Null          = "ﳠ ",
        EnumMember    = " ",
        Struct        = " ",
        Event         = " ",
        Operator      = " ",
        TypeParameter = " ",
    },
    mappings = {
        ["<esc>"] = actions.close,        -- Close and cursor to original location
        ["q"] = actions.close,

        ["j"] = actions.next_sibling,     -- down
        ["k"] = actions.previous_sibling, -- up

        ["h"] = actions.parent,           -- Move to left panel
        ["l"] = actions.children,         -- Move to right panel

        ["v"] = actions.visual_name,      -- Visual selection of name
        ["V"] = actions.visual_scope,     -- Visual selection of scope

        ["y"] = actions.yank_name,        -- Yank the name to system clipboard "+
        ["Y"] = actions.yank_scope,       -- Yank the scope to system clipboard "+

        ["i"] = actions.insert_name,      -- Insert at start of name
        ["I"] = actions.insert_scope,     -- Insert at start of scope

        ["a"] = actions.append_name,      -- Insert at end of name
        ["A"] = actions.append_scope,     -- Insert at end of scope

        ["r"] = actions.rename,           -- Rename currently focused symbol

        ["d"] = actions.delete,           -- Delete scope

        ["f"] = actions.fold_create,      -- Create fold of current scope
        ["F"] = actions.fold_delete,      -- Delete fold of current scope

        ["c"] = actions.comment,          -- Comment out current scope

        ["<enter>"] = actions.select,     -- Goto selected symbol
        ["o"] = actions.select,
    },
    lsp = {
        auto_attach = false,  -- If set to true, you don't need to manually use attach function
        preference = nil  -- list of lsp server names in order of preference
    }
}
```

## 🚀 Usage

`Navbuddy` command can be used to open navbuddy.

```
:Navbuddy
```

And alternatively lua function `open` can also be used to open navbuddy.

```
:lua require("nvim-navbuddy").open()
```

