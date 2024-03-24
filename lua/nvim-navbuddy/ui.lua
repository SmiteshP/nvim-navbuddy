local navic = require("nvim-navic.lib")

local ui = {}

function ui.get_border_chars(style, section)
	if style ~= "single" and style ~= "rounded" and style ~= "double" and style ~= "solid" then
		return style
	end

	-- stylua: ignore
	local border_chars = {
		top_left = {
			single  = "┌",
			rounded = "╭",
			double  = "╔",
			solid   = "▛",
		},
		top = {
			single  = "─",
			rounded = "─",
			double  = "═",
			solid   = "▀",
		},
		top_right = {
			single  = "┐",
			rounded = "╮",
			double  = "╗",
			solid   = "▜",
		},
		right = {
			single  = "│",
			rounded = "│",
			double  = "║",
			solid   = "▐",
		},
		bottom_right = {
			single  = "┘",
			rounded = "╯",
			double  = "╝",
			solid   = "▟",
		},
		bottom = {
			single  = "─",
			rounded = "─",
			double  = "═",
			solid   = "▄",
		},
		bottom_left = {
			single  = "└",
			rounded = "╰",
			double  = "╚",
			solid   = "▙",
		},
		left = {
			single  = "│",
			rounded = "│",
			double  = "║",
			solid   = "▌",
		},
		top_T = {
			single  = "┬",
			rounded = "┬",
			double  = "╦",
			solid   = "▛",
		},
		bottom_T = {
			single  = "┴",
			rounded = "┴",
			double  = "╩",
			solid   = "▙",
		},
		blank = "",
	}

	local border_chars_map = {
		left = {
			style = {
				border_chars.top_left[style],
				border_chars.top[style],
				border_chars.top[style],
				border_chars.blank,
				border_chars.bottom[style],
				border_chars.bottom[style],
				border_chars.bottom_left[style],
				border_chars.left[style],
			},
		},
		mid = {
			style = {
				border_chars.top_T[style],
				border_chars.top[style],
				border_chars.top[style],
				border_chars.blank,
				border_chars.bottom[style],
				border_chars.bottom[style],
				border_chars.bottom_T[style],
				border_chars.left[style],
			},
		},
		right = {
			border_chars.top_T[style],
			border_chars.top[style],
			border_chars.top_right[style],
			border_chars.right[style],
			border_chars.bottom_right[style],
			border_chars.bottom[style],
			border_chars.bottom_T[style],
			border_chars.left[style],
		},
	}
	return border_chars_map[section]
end

function ui.highlight_setup(config)
	for lsp_num = 1, 26 do
		local navbuddy_ok, _ =
			pcall(vim.api.nvim_get_hl_by_name, "Navbuddy" .. navic.adapt_lsp_num_to_str(lsp_num), false)
		local navic_ok, navic_hl =
			pcall(vim.api.nvim_get_hl_by_name, "NavicIcons" .. navic.adapt_lsp_num_to_str(lsp_num), true)

		if not navbuddy_ok and navic_ok then
			navic_hl = navic_hl["foreground"]

			vim.api.nvim_set_hl(0, "Navbuddy" .. navic.adapt_lsp_num_to_str(lsp_num), {
				fg = navic_hl,
			})
		end

		local ok, navbuddy_hl =
			pcall(vim.api.nvim_get_hl_by_name, "Navbuddy" .. navic.adapt_lsp_num_to_str(lsp_num), true)
		if ok then
			navbuddy_hl = navbuddy_hl["foreground"]

			local highlight
			if config.custom_hl_group ~= nil then
				highlight = { link = config.custom_hl_group }
			else
				highlight = { bg = navbuddy_hl  }
			end
			vim.api.nvim_set_hl(0, "NavbuddyCursorLine" .. navic.adapt_lsp_num_to_str(lsp_num), highlight)
		else
			local _, normal_hl = pcall(vim.api.nvim_get_hl_by_name, "Normal", true)
			normal_hl = normal_hl["foreground"]
			vim.api.nvim_set_hl(0, "Navbuddy" .. navic.adapt_lsp_num_to_str(lsp_num), { fg = normal_hl })

			local highlight
			if config.custom_hl_group ~= nil then
				highlight = { link = config.custom_hl_group }
			else
				highlight = { bg = normal_hl  }
			end
			vim.api.nvim_set_hl(0, "NavbuddyCursorLine" .. navic.adapt_lsp_num_to_str(lsp_num), highlight)
		end
	end

	local ok, _ = pcall(vim.api.nvim_get_hl_by_name, "NavbuddyCursorLine", false)
	if not ok then
		local highlight
		if config.custom_hl_group ~= nil then
			highlight = { link = config.custom_hl_group }
		else
			highlight = { reverse = true, bold = true }
		end
		vim.api.nvim_set_hl(0, "NavbuddyCursorLine", highlight)
	end

	ok, _ = pcall(vim.api.nvim_get_hl_by_name, "NavbuddyCursor", false)
	if not ok then
		vim.api.nvim_set_hl(0, "NavbuddyCursor", {
			bg = "#000000",
			blend = 100,
		})
	end

	ok, _ = pcall(vim.api.nvim_get_hl_by_name, "NavbuddyName", false)
	if not ok then
		vim.api.nvim_set_hl(0, "NavbuddyName", { link = "IncSearch" })
	end

	ok, _ = pcall(vim.api.nvim_get_hl_by_name, "NavbuddyScope", false)
	if not ok then
		vim.api.nvim_set_hl(0, "NavbuddyScope", { link = "Visual" })
	end

	ok, _ = pcall(vim.api.nvim_get_hl_by_name, "NavbuddyFloatBorder", false)
	if not ok then
		vim.api.nvim_set_hl(0, "NavbuddyFloatBorder", { link = "FloatBorder" })
	end

	ok, _ = pcall(vim.api.nvim_get_hl_by_name, "NavbuddyNormalFloat", false)
	if not ok then
		vim.api.nvim_set_hl(0, "NavbuddyNormalFloat", { link = "NormalFloat" })
	end
end

return ui
