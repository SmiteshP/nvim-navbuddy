local navic = require("nvim-navic.lib")

local nui_menu = require("nui.menu")

local display = require("nvim-navbuddy.display")
local actions = require("nvim-navbuddy.actions")

local config = {
	window = {
		border = "single",
		size = "60%",
		position = "50%",
		scrolloff = nil,
		sections = {
			left = {
				size = "20%",
			},
			mid = {
				size = "40%",
			},
			right = {
				preview = "leaf",
			},
		},
	},
	node_markers = {
		enabled = true,
		icons = {
			leaf = "  ",
			leaf_selected = " → ",
			branch = " ",
		},
	},
	icons = {
		[1] = "󰈙 ", -- File
		[2] = " ", -- Module
		[3] = "󰌗 ", -- Namespace
		[4] = " ", -- Package
		[5] = "󰌗 ", -- Class
		[6] = "󰆧 ", -- Method
		[7] = " ", -- Property
		[8] = " ", -- Field
		[9] = " ", -- Constructor
		[10] = "󰕘", -- Enum
		[11] = "󰕘", -- Interface
		[12] = "󰊕 ", -- Function
		[13] = "󰆧 ", -- Variable
		[14] = "󰏿 ", -- Constant
		[15] = " ", -- String
		[16] = "󰎠 ", -- Number
		[17] = "◩ ", -- Boolean
		[18] = "󰅪 ", -- Array
		[19] = "󰅩 ", -- Object
		[20] = "󰌋 ", -- Key
		[21] = "󰟢 ", -- Null
		[22] = " ", -- EnumMember
		[23] = "󰌗 ", -- Struct
		[24] = " ", -- Event
		[25] = "󰆕 ", -- Operator
		[26] = "󰊄 ", -- TypeParameter
		[255] = "󰉨 ", -- Macro
	},
	use_default_mappings = true,
	mappings = {
		["<esc>"] = actions.close(),
		["q"] = actions.close(),

		["j"] = actions.next_sibling(),
		["k"] = actions.previous_sibling(),

		["h"] = actions.parent(),
		["l"] = actions.children(),
		["0"] = actions.root(),

		["v"] = actions.visual_name(),
		["V"] = actions.visual_scope(),

		["y"] = actions.yank_name(),
		["Y"] = actions.yank_scope(),

		["i"] = actions.insert_name(),
		["I"] = actions.insert_scope(),

		["a"] = actions.append_name(),
		["A"] = actions.append_scope(),

		["r"] = actions.rename(),

		["d"] = actions.delete(),

		["f"] = actions.fold_create(),
		["F"] = actions.fold_delete(),

		["c"] = actions.comment(),

		["<enter>"] = actions.select(),
		["o"] = actions.select(),

		["J"] = actions.move_down(),
		["K"] = actions.move_up(),

		["s"] = actions.toggle_preview(),

		["<C-v>"] = actions.vsplit(),
		["<C-s>"] = actions.hsplit(),

		["t"] = actions.telescope({
			layout_strategy = "horizontal",
			layout_config = {
				height = 0.60,
				width = 0.60,
				prompt_position = "top",
				preview_width = 0.50,
			},
		}),

		["g?"] = actions.help(),
	},
	lsp = {
		auto_attach = false,
		preference = nil,
	},
	source_buffer = {
		follow_node = true,
		highlight = true,
		reorient = "smart",
		scrolloff = nil,
	},
	custom_hl_group = nil,
}

setmetatable(config.icons, {
	__index = function()
		return "? "
	end,
})

local navbuddy_attached_clients = {}

-- @Private Methods

local function choose_lsp_menu(for_buf, make_request)
	local style = nil

	if config.window.border ~= nil and config.window.border ~= "None" then
		style = config.window.border
	else
		style = "single"
	end

	local min_width = 23
	local lines = {}

	for _, v in ipairs(navbuddy_attached_clients[for_buf]) do
		min_width = math.max(min_width, #v.name)
		table.insert(lines, nui_menu.item(v.id .. ":" .. v.name))
	end

	local min_height = #lines

	local menu = nui_menu({
		relative = "editor",
		position = "50%",
		border = {
			style = style,
			text = {
				top = "[Choose LSP Client]",
				top_align = "center",
			},
		},
	}, {
		lines = lines,
		min_width = min_width,
		min_height = min_height,
		keymap = {
			focus_next = { "j", "<Down>", "<Tab>" },
			focus_prev = { "k", "<Up>", "<S-Tab>" },
			close = { "<Esc>", "q", "<C-c>" },
			submit = { "<CR>", "<Space>", "l" },
		},
		on_close = function() end,
		on_submit = function(item)
			local id = tonumber(string.match(item.text, "%d+"))
			for _, check_client in ipairs(navbuddy_attached_clients[for_buf]) do
				if id == check_client.id then
					make_request(check_client)
					return
				end
			end
		end,
	})

	menu:mount()
end

local function request(for_buf, handler)
	local function make_request(client)
		navic.request_symbol(for_buf, function(bufnr, symbols)
			navic.update_data(bufnr, symbols)
			navic.update_context(bufnr)
			local context_data = navic.get_context_data(bufnr)

			local curr_node = context_data[#context_data]

			handler(for_buf, curr_node, client.name)
		end, client)
	end

	if navbuddy_attached_clients[for_buf] == nil then
		vim.notify("No lsp servers attached", vim.log.levels.ERROR)
	elseif #navbuddy_attached_clients[for_buf] == 1 then
		make_request(navbuddy_attached_clients[for_buf][1])
	elseif config.lsp.preference ~= nil then
		local found = false

		for _, preferred_lsp in ipairs(config.lsp.preference) do
			for _, attached_lsp in ipairs(navbuddy_attached_clients[for_buf]) do
				if preferred_lsp == attached_lsp.name then
					navbuddy_attached_clients[for_buf] = { attached_lsp }
					found = true
					make_request(attached_lsp)
					break
				end
			end

			if found then
				break
			end
		end

		if not found then
			choose_lsp_menu(for_buf, make_request)
		end
	else
		choose_lsp_menu(for_buf, make_request)
	end
end

local function handler(bufnr, curr_node, lsp_name)
	if curr_node.is_root then
		if curr_node.children then
			local curr_line = vim.api.nvim_win_get_cursor(0)[1]
			local closest_dist = math.abs(curr_line - curr_node.children[1].scope["start"].line)
			local closest_node = curr_node.children[1]

			for _, node in ipairs(curr_node.children) do
				if math.abs(curr_line - node.scope["start"].line) < closest_dist then
					closest_dist = math.abs(curr_line - node.scope["start"].line)
					closest_node = node
				end
			end

			curr_node = closest_node
		else
			return
		end
	end

	display:new({
		for_buf = bufnr,
		for_win = vim.api.nvim_get_current_win(),
		start_cursor = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win()),
		focus_node = curr_node,
		config = config,
		lsp_name = lsp_name,
	})
end

-- @Public Methods

local M = {}

function M.open(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	request(bufnr, handler)
end

function M.attach(client, bufnr)
	if not client.server_capabilities.documentSymbolProvider then
		if not vim.g.navbuddy_silence then
			vim.notify(
				'nvim-navbuddy: Server "' .. client.name .. '" does not support documentSymbols.',
				vim.log.levels.ERROR
			)
		end
		return
	end

	if navbuddy_attached_clients[bufnr] == nil then
		navbuddy_attached_clients[bufnr] = {}
	end

	-- Check if already attached
	for _, c in ipairs(navbuddy_attached_clients[bufnr]) do
		if c.id == client.id then
			return
		end
	end

	-- Check for stopped lsp servers
	for i, c in ipairs(navbuddy_attached_clients[bufnr]) do
		if c.is_stopped then
			table.remove(navbuddy_attached_clients[bufnr], i)
		end
	end

	table.insert(navbuddy_attached_clients[bufnr], client)

	local navbuddy_augroup = vim.api.nvim_create_augroup("navbuddy", { clear = false })
	vim.api.nvim_clear_autocmds({
		buffer = bufnr,
		group = navbuddy_augroup,
	})
	vim.api.nvim_create_autocmd("BufDelete", {
		callback = function()
			navic.clear_buffer_data(bufnr)
			navbuddy_attached_clients[bufnr] = nil
		end,
		group = navbuddy_augroup,
		buffer = bufnr,
	})
	vim.api.nvim_create_autocmd("LspDetach", {
		callback = function()
			if navbuddy_attached_clients[bufnr] ~= nil then
				for i, c in ipairs(navbuddy_attached_clients[bufnr]) do
					if c.id == client.id then
						table.remove(navbuddy_attached_clients[bufnr], i)
						break
					end
				end
				if #navbuddy_attached_clients[bufnr] == 0 then
					navbuddy_attached_clients[bufnr] = nil
				end
			end
		end,
		group = navbuddy_augroup,
		buffer = bufnr,
	})

	vim.api.nvim_buf_create_user_command(bufnr, "Navbuddy", function()
		M.open(bufnr)
	end, {})
end

function M.setup(user_config)
	if user_config ~= nil then
		if user_config.window ~= nil then
			config.window = vim.tbl_deep_extend("keep", user_config.window, config.window)
		end

		-- If one is set, default for others should be none
		if
			config.window.sections.left.border ~= nil
			or config.window.sections.mid.border ~= nil
			or config.window.sections.right.border ~= nil
		then
			config.window.sections.left.border = config.window.sections.left.border or "none"
			config.window.sections.mid.border = config.window.sections.mid.border or "none"
			config.window.sections.right.border = config.window.sections.right.border or "none"
		end

		if user_config.node_markers ~= nil then
			config.node_markers = vim.tbl_deep_extend("keep", user_config.node_markers, config.node_markers)
		end

		if user_config.icons ~= nil then
			for k, v in pairs(user_config.icons) do
				if navic.adapt_lsp_str_to_num(k) then
					config.icons[navic.adapt_lsp_str_to_num(k)] = v
				end
			end
		end

		if user_config.use_default_mappings ~= nil then
			config.use_default_mappings = user_config.use_default_mappings
		end

		if user_config.mappings ~= nil then
			if config.use_default_mappings then
				config.mappings = vim.tbl_deep_extend("keep", user_config.mappings, config.mappings)
			else
				config.mappings = user_config.mappings
			end
		end

		if user_config.lsp ~= nil then
			config.lsp = vim.tbl_deep_extend("keep", user_config.lsp, config.lsp)
		end

		if user_config.source_buffer ~= nil then
			config.source_buffer = vim.tbl_deep_extend("keep", user_config.source_buffer, config.source_buffer)
		end

		if user_config.custom_hl_group ~= nil then
			config.custom_hl_group = user_config.custom_hl_group
		end
	end

	if config.lsp.auto_attach == true then
		local navbuddy_augroup = vim.api.nvim_create_augroup("navbuddy", { clear = false })
		vim.api.nvim_clear_autocmds({
			group = navbuddy_augroup,
		})
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local bufnr = args.buf
				if args.data == nil and args.data.client_id == nil then
					return
				end
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if not client.server_capabilities.documentSymbolProvider then
					return
				end
				M.attach(client, bufnr)
			end,
		})

		--- Attach to already active clients.
		local all_clients = vim.lsp.get_clients()

		local supported_clients = vim.tbl_filter(function(client)
			return client.server_capabilities.documentSymbolProvider
		end, all_clients)

		for _, client in ipairs(supported_clients) do
			local buffers_of_client = vim.lsp.get_buffers_by_client_id(client.id)

			for _, buffer_number in ipairs(buffers_of_client) do
				M.attach(client, buffer_number)
			end
		end
	end
end

return M
