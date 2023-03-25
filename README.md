# 🗺️ nvim-navbuddy

A simple popup display that provides breadcrumbs like navigation feature but
in keyboard centric manner inspired by ranger file manager.

![2023-03-25 21-33-42](https://user-images.githubusercontent.com/43147494/227728581-f57be77a-48ac-4dc0-9e6c-49522af962d7.gif)

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
        ["<esc>"] = actions.close,
        ["q"] = actions.close,

        ["j"] = actions.next_sibling,
        ["k"] = actions.previous_sibling,

        ["h"] = actions.parent,
        ["l"] = actions.children,

        ["v"] = actions.visual,

        ["i"] = actions.insert_name,
        ["I"] = actions.insert_scope,

        ["a"] = actions.append_name,
        ["A"] = actions.append_scope,

        ["r"] = actions.rename,

        ["d"] = actions.delete,

        ["f"] = actions.fold_create,
        ["F"] = actions.fold_delete,

        ["c"] = actions.comment,

        ["<enter>"] = actions.select,
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

