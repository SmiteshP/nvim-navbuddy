local navic = require("nvim-navic.lib")

local nui_popup = require("nui.popup")
local nui_layout = require("nui.layout")

local ns = vim.api.nvim_create_namespace("nvim-navbuddy")

local function highlight_setup()
	for lsp_num = 1,26 do
		local navbuddy_ok, _ = pcall(vim.api.nvim_get_hl_by_name, "Navbuddy"..navic.adapt_lsp_num_to_str(lsp_num), false)
		local navic_ok, navic_hl = pcall(vim.api.nvim_get_hl_by_name, "NavicIcons"..navic.adapt_lsp_num_to_str(lsp_num), true)

		if not navbuddy_ok and navic_ok then
			navic_hl = navic_hl["foreground"]

			vim.api.nvim_set_hl(0, "Navbuddy"..navic.adapt_lsp_num_to_str(lsp_num), {
				fg = navic_hl,
			})
		end

		local ok, navbuddy_hl = pcall(vim.api.nvim_get_hl_by_name, "Navbuddy"..navic.adapt_lsp_num_to_str(lsp_num), true)
		if ok then
			navbuddy_hl = navbuddy_hl["foreground"]
			vim.api.nvim_set_hl(0, "NavbuddyCursorLine"..navic.adapt_lsp_num_to_str(lsp_num), { bg = navbuddy_hl })
		else
			local _, normal_hl = pcall(vim.api.nvim_get_hl_by_name, "Normal", true)
			normal_hl = normal_hl["foreground"]
			vim.api.nvim_set_hl(0, "NavbuddyCursorLine"..navic.adapt_lsp_num_to_str(lsp_num), { bg = normal_hl })
		end
	end

	local ok, _ = pcall(vim.api.nvim_get_hl_by_name, "NavbuddyCursorLine", false)
	if not ok then
		vim.api.nvim_set_hl(0, "NavbuddyCursorLine", {
			reverse = true,
			bold = true
		})
	end

	ok, _ = pcall(vim.api.nvim_get_hl_by_name, "NavbuddyCursor", false)
	if not ok then
		vim.api.nvim_set_hl(0, "NavbuddyCursor", {
			bg = "#000000",
			blend = 100
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
end

local function clear_buffer(buf)
	vim.api.nvim_buf_set_option(buf.bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf.bufnr, 0, -1, false, {})
	vim.api.nvim_buf_set_option(buf.bufnr, "modifiable", false)
end

local function fill_buffer(buf, node, config)
	local cursor_pos = vim.api.nvim_win_get_cursor(buf.winid)
	clear_buffer(buf)

	local parent = node.parent

	local lines = {}
	for _, child_node in ipairs(parent.children) do
		local text = " "..config.icons[child_node.kind] .. child_node.name
		table.insert(lines, text)
	end

	vim.api.nvim_buf_set_option(buf.bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf.bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf.bufnr, "modifiable", false)

	for i, child_node in ipairs(parent.children) do
		vim.api.nvim_buf_add_highlight(buf.bufnr, ns, "Navbuddy"..navic.adapt_lsp_num_to_str(child_node.kind), i-1, 0, -1)
	end

	if cursor_pos[1] ~= node.index then
		cursor_pos[1] = node.index
	end

	vim.api.nvim_buf_add_highlight(buf.bufnr, ns, "NavbuddyCursorLine", cursor_pos[1]-1, 0, -1)
	vim.api.nvim_buf_set_extmark(buf.bufnr, ns, cursor_pos[1]-1, #lines[cursor_pos[1]], {
		end_row = cursor_pos[1],
		hl_eol = true,
		hl_group = "NavbuddyCursorLine"..navic.adapt_lsp_num_to_str(node.kind)
	})
	vim.api.nvim_win_set_cursor(buf.winid, cursor_pos)
end


local display = {}

function display:new(obj)
	highlight_setup()

	-- Object
	setmetatable(obj, self)
	self.__index = self

	local config = obj.config

	-- NUI elements
	local left_popup = nui_popup({
		focusable = false,
		border = config.window.sections.left.border or config.window.border,
		buf_options = {
			modifiable = false,
		},
	})

	local mid_popup = nui_popup({
		enter = true,
		border = config.window.sections.mid.border or config.window.border,
		buf_options = {
			modifiable = false,
		},
	})

	local lsp_name = {
		bottom = "["..obj.lsp_name.."]",
		bottom_align = "right"
	}

	if config.window.sections.right.border == "none" or config.window.border == "none" then
		lsp_name = nil
	end

	local right_popup = nui_popup({
		focusable = false,
		border = {
			style = config.window.sections.right.border or config.window.border,
			text = lsp_name
		},
		win_options = {
			winhighlight = "Normal:NavbuddyFloatBorder,FloatBorder:NavbuddyFloatBorder",
		},
		buf_options = {
			modifiable = false,
		},
	})

	local layout = nui_layout(
		{
			relative = "editor",
			position = config.window.position,
			size = config.window.size,
		},
		nui_layout.Box({
			nui_layout.Box(left_popup, { size = config.window.sections.left.size }),
			nui_layout.Box(mid_popup, { size = config.window.sections.mid.size }),
			nui_layout.Box(right_popup, { size = config.window.sections.right.size }),
		}, { dir = "row" })
	)

	obj.layout = layout
	obj.left = left_popup
	obj.mid = mid_popup
	obj.right = right_popup

	-- Hidden cursor
	local user_gui_cursor = vim.api.nvim_get_option("guicursor")
	vim.api.nvim_set_option("guicursor", "a:NavbuddyCursor")

	-- Autocmds
	local augroup = vim.api.nvim_create_augroup("Navbuddy", { clear = false })
	vim.api.nvim_clear_autocmds({ buffer = obj.mid.bufnr })
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = augroup,
		buffer = obj.mid.bufnr,
		callback = function()
			local cursor_pos = vim.api.nvim_win_get_cursor(obj.mid.winid)
			if obj.focus_node ~= obj.focus_node.parent.children[cursor_pos[1]] then
				obj.focus_node = obj.focus_node.parent.children[cursor_pos[1]]
				obj:redraw()
			end

			obj.focus_node.parent.memory = obj.focus_node.index

			obj:clear_highlights()
			obj:focus_range()
		end
	})
	vim.api.nvim_create_autocmd("BufLeave", {
		group = augroup,
		buffer = obj.mid.bufnr,
		callback = function()
			if obj.navbuddy_leaving_window_for_action ~= true then
				vim.api.nvim_set_option("guicursor", user_gui_cursor)
				layout:unmount()
				obj:clear_highlights()
			end
		end
	})

	-- Mappings
	for i, v in pairs(config.mappings) do
		obj.mid:map("n", i, function() v(obj) end)
	end

	-- Display
	layout:mount()
	obj:redraw()
	obj:focus_range()

	return obj
end

function display:focus_range()
	local ranges = nil

	if vim.deep_equal(self.focus_node.scope, self.focus_node.name_range) then
		ranges = {{"NavbuddyScope", self.focus_node.scope}}
	else
		ranges = {{"NavbuddyScope", self.focus_node.scope}, {"NavbuddyName", self.focus_node.name_range}}
	end

	for _, v in ipairs(ranges) do
		local highlight, range = unpack(v)

		if range["start"].line == range["end"].line then
			vim.api.nvim_buf_add_highlight(self.for_buf, ns, highlight, range["start"].line-1, range["start"].character, range["end"].character)
		else
			vim.api.nvim_buf_add_highlight(self.for_buf, ns, highlight, range["start"].line-1, range["start"].character, -1)
			vim.api.nvim_buf_add_highlight(self.for_buf, ns, highlight, range["end"].line-1, 0, range["end"].character)
			for i = range["start"].line, range["end"].line-2, 1 do
				vim.api.nvim_buf_add_highlight(self.for_buf, ns, highlight, i, 0, -1)
			end
		end

		vim.api.nvim_win_set_cursor(self.for_win, {range["start"].line, range["end"].character})
	end
end

function display:clear_highlights()
	vim.api.nvim_buf_clear_highlight(self.for_buf, ns, 0, -1)
end

function display:redraw()
	local node = self.focus_node
	fill_buffer(self.mid, node, self.config)

	if node.children then
		if node.memory then
			fill_buffer(self.right, node.children[node.memory], self.config)
		else
			fill_buffer(self.right, node.children[1], self.config)
		end
	else
		clear_buffer(self.right)
	end

	if node.parent.is_root then
		clear_buffer(self.left)
	else
		fill_buffer(self.left, node.parent, self.config)
	end
end

function display:close()
	self.layout:unmount()
	self:clear_highlights()
end

return display
