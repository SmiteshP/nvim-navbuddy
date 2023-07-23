local actions = {}

local function fix_end_character_position(bufnr, name_range_or_scope)
	if name_range_or_scope["end"].character == 0 and (name_range_or_scope["end"].line - name_range_or_scope["start"].line) > 0 then
		name_range_or_scope["end"].line = name_range_or_scope["end"].line - 1
		name_range_or_scope["end"].character = string.len(vim.api.nvim_buf_get_lines(bufnr, name_range_or_scope["end"].line - 1, name_range_or_scope["end"].line, false)[1])
	end
end

function actions.close()
	local callback = function(display)
		display:close()
		vim.api.nvim_win_set_cursor(display.for_win, display.start_cursor)
	end

	return {
		callback = callback,
		description = "Close Navbuddy"
	}
end

function actions.next_sibling()
	local callback = function(display)
		if display.focus_node.next == nil then
			return
		end

		for _ = 1, vim.v.count1 do
			local next_node = display.focus_node.next
			if next_node == nil then
				break
			end
			display.focus_node = next_node
		end

		display:redraw()
	end

	return {
		callback = callback,
		description = "Move down to next node"
	}
end

function actions.previous_sibling()
	local callback = function(display)
		if display.focus_node.prev == nil then
			return
		end

		for _ = 1, vim.v.count1 do
			local prev_node = display.focus_node.prev
			if prev_node == nil then
				break
			end
			display.focus_node = prev_node
		end

		display:redraw()
	end

	return {
		callback = callback,
		description = "Move up to previous node"
	}
end

function actions.parent()
	local callback = function(display)
		if display.focus_node.parent.is_root then
			return
		end

		local parent_node = display.focus_node.parent
		display.focus_node = parent_node

		display:redraw()
	end

	return {
		callback = callback,
		description = "Move left to parent level"
	}
end

function actions.children()
	local callback = function(display)
		if display.focus_node.children == nil then
			actions.select().callback(display)
			return
		end

		local child_node
		if display.focus_node.memory then
			child_node = display.focus_node.children[display.focus_node.memory]
		else
			child_node = display.focus_node.children[1]
		end
		display.focus_node = child_node

		display:redraw()
	end

	return {
		callback = callback,
		description = "Move right to child node level"
	}
end

function actions.root()
	local callback = function(display)
		if display.focus_node.parent.is_root then
			return
		end

		while not display.focus_node.parent.is_root do
			display.focus_node.parent.memory = display.focus_node.index
			display.focus_node = display.focus_node.parent
		end

		display:redraw()
	end

	return {
		callback = callback,
		description = "Move to top most node"
	}
end

function actions.select()
	local callback = function(display)
		display:close()
		fix_end_character_position(display.for_buf, display.focus_node.name_range)
		fix_end_character_position(display.for_buf, display.focus_node.scope)
		-- to push location to jumplist:
		-- move display to start_cursor, set mark ', then move to new location
		vim.api.nvim_win_set_cursor(display.for_win, display.start_cursor)
		vim.api.nvim_command("normal! m'")
		vim.api.nvim_win_set_cursor(
		display.for_win,
		{ display.focus_node.name_range["start"].line, display.focus_node.name_range["start"].character }
		)

		if display.config.source_buffer.reorient == "smart" then
			local total_lines = display.focus_node.scope["end"].line - display.focus_node.scope["start"].line + 1

			if total_lines >= vim.api.nvim_win_get_height(display.for_win) then
				vim.api.nvim_command("normal! zt")
			else
				local mid_line =
				bit.rshift(display.focus_node.scope["start"].line + display.focus_node.scope["end"].line, 1)
				vim.api.nvim_win_set_cursor(display.for_win, { mid_line, 0 })
				vim.api.nvim_command("normal! zz")
				vim.api.nvim_win_set_cursor(
				display.for_win,
				{ display.focus_node.name_range["start"].line, display.focus_node.name_range["start"].character }
				)
			end
		elseif display.config.source_buffer.reorient == "mid" then
			vim.api.nvim_command("normal! zz")
		elseif display.config.source_buffer.reorient == "top" then
			vim.api.nvim_command("normal! zt")
		end
	end

	return {
		callback = callback,
		description = "Select and Goto current node"
	}
end

function actions.yank_name()
	local callback = function(display)
		display:close()
		fix_end_character_position(display.for_buf, display.focus_node.name_range)
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.name_range["start"].line, display.focus_node.name_range["start"].character }
		)
		vim.api.nvim_command("normal! v")
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.name_range["end"].line, display.focus_node.name_range["end"].character - 1 }
		)
		vim.api.nvim_command('normal! "+y')
	end

	return {
		callback = callback,
		description = "Yank node name"
	}
end

function actions.yank_scope()
	local callback = function(display)
		display:close()
		fix_end_character_position(display.for_buf, display.focus_node.scope)
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.scope["start"].line, display.focus_node.scope["start"].character }
		)
		vim.api.nvim_command("normal! v")
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.scope["end"].line, display.focus_node.scope["end"].character - 1 }
		)
		vim.api.nvim_command('normal! "+y')
	end

	return {
		callback = callback,
		description = "Yank node scope"
	}
end

function actions.visual_name()
	local callback = function(display)
		display:close()
		fix_end_character_position(display.for_buf, display.focus_node.name_range)
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.name_range["start"].line, display.focus_node.name_range["start"].character }
		)
		vim.api.nvim_command("normal! v")
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.name_range["end"].line, display.focus_node.name_range["end"].character - 1 }
		)
	end

	return {
		callback = callback,
		description = "Visual select node name"
	}
end

function actions.visual_scope()
	local callback = function(display)
		display:close()
		fix_end_character_position(display.for_buf, display.focus_node.scope)
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.scope["start"].line, display.focus_node.scope["start"].character }
		)
		vim.api.nvim_command("normal! v")
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.scope["end"].line, display.focus_node.scope["end"].character - 1 }
		)
	end

	return {
		callback = callback,
		description = "Visual select node scope"
	}
end

function actions.insert_name()
	local callback = function(display)
		display:close()
		fix_end_character_position(display.for_buf, display.focus_node.name_range)
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.name_range["start"].line, display.focus_node.name_range["start"].character }
		)
		vim.api.nvim_feedkeys("i", "n", false)
	end

	return {
		callback = callback,
		description = "Insert node name"
	}
end

function actions.insert_scope()
	local callback = function(display)
		display:close()
		fix_end_character_position(display.for_buf, display.focus_node.scope)
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.scope["start"].line, display.focus_node.scope["start"].character }
		)
		vim.api.nvim_feedkeys("i", "n", false)
	end

	return {
		callback = callback,
		description = "Insert node scope"
	}
end

function actions.append_name()
	local callback = function(display)
		display:close()
		fix_end_character_position(display.for_buf, display.focus_node.name_range)
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.name_range["end"].line, display.focus_node.name_range["end"].character - 1 }
		)
		vim.api.nvim_feedkeys("a", "n", false)
	end

	return {
		callback = callback,
		description = "Append node name"
	}
end

function actions.append_scope()
	local callback = function(display)
		display:close()
		fix_end_character_position(display.for_buf, display.focus_node.scope)
		if
			string.len(
				vim.api.nvim_buf_get_lines(
					display.for_buf,
					display.focus_node.scope["end"].line - 1,
					display.focus_node.scope["end"].line,
					false
				)[1]
			) == display.focus_node.scope["end"].character
		then
			vim.api.nvim_win_set_cursor(
				display.for_win,
				{ display.focus_node.scope["end"].line, display.focus_node.scope["end"].character }
			)
		else
			vim.api.nvim_win_set_cursor(
				display.for_win,
				{ display.focus_node.scope["end"].line, display.focus_node.scope["end"].character - 1 }
			)
		end
		vim.api.nvim_feedkeys("a", "n", false)
	end

	return {
		callback = callback,
		description = "Append node scope"
	}
end

function actions.rename()
	local callback = function(display)
		display:close()
		vim.lsp.buf.rename()
	end

	return {
		callback = callback,
		description = "Rename"
	}
end

function actions.delete()
	local callback = function(display)
		actions.visual_scope().callback(display)
		vim.api.nvim_command("normal! d")
	end

	return {
		callback = callback,
		description = "Delete"
	}
end

function actions.fold_create()
	local callback = function(display)
		if vim.o.foldmethod ~= "manual" then
			vim.notify("Fold create action works only when foldmethod is 'manual'", vim.log.levels.ERROR)
			return
		end

		fix_end_character_position(display.for_buf, display.focus_node.scope)
		display.state.leaving_window_for_action = true
		vim.api.nvim_set_current_win(display.for_win)
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.scope["start"].line, display.focus_node.scope["start"].character }
		)
		vim.api.nvim_command("normal! v")
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.scope["end"].line, display.focus_node.scope["end"].character - 1 }
		)
		vim.api.nvim_command("normal! zf")
		vim.api.nvim_set_current_win(display.mid.winid)
		display.state.leaving_window_for_action = false
	end

	return {
		callback = callback,
		description = "Create fold"
	}
end

function actions.fold_delete()
	local callback = function(display)
		if vim.o.foldmethod ~= "manual" then
			vim.notify("Fold delete action works only when foldmethod is 'manual'", vim.log.levels.ERROR)
			return
		end

		fix_end_character_position(display.for_buf, display.focus_node.scope)
		display.state.leaving_window_for_action = true
		vim.api.nvim_set_current_win(display.for_win)
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.scope["start"].line, display.focus_node.scope["start"].character }
		)
		vim.api.nvim_command("normal! v")
		vim.api.nvim_win_set_cursor(
			display.for_win,
			{ display.focus_node.scope["end"].line, display.focus_node.scope["end"].character - 1 }
		)
		pcall(vim.api.nvim_command, "normal! zd")
		vim.api.nvim_set_current_win(display.mid.winid)
		display.state.leaving_window_for_action = false
	end

	return {
		callback = callback,
		description = "Delete fold"
	}
end

function actions.comment()
	local callback = function(display)
		local status_ok, comment = pcall(require, "Comment.api")
		if not status_ok then
			vim.notify("Comment.nvim not found", vim.log.levels.ERROR)
			return
		end

		fix_end_character_position(display.for_buf, display.focus_node.scope)
		display.state.leaving_window_for_action = true
		vim.api.nvim_set_current_win(display.for_win)
		vim.api.nvim_buf_set_mark(
			display.for_buf,
			"<",
			display.focus_node.scope["start"].line,
			display.focus_node.scope["start"].character,
			{}
		)
		vim.api.nvim_buf_set_mark(
			display.for_buf,
			">",
			display.focus_node.scope["end"].line,
			display.focus_node.scope["end"].character,
			{}
		)
		comment.locked("toggle.linewise")("v")
		vim.api.nvim_set_current_win(display.mid.winid)
		display.state.leaving_window_for_action = false
	end

	return {
		callback = callback,
		description = "Comment"
	}
end

local function swap_nodes(for_buf, nodeA, nodeB)
	-- nodeA
	--   ^
	--   |
	--   v
	-- nodeB

	fix_end_character_position(for_buf, nodeA.scope)
	fix_end_character_position(for_buf, nodeB.scope)

	if nodeA.scope["end"].line >= nodeB.scope["start"].line and nodeA.parent == nodeB.parent then
		vim.notify("Cannot swap!", vim.log.levels.ERROR)
		return
	end

	local nodeA_text = vim.api.nvim_buf_get_lines(for_buf, nodeA.scope["start"].line-1, nodeA.scope["end"].line-1+1, false)
	local mid_text = vim.api.nvim_buf_get_lines(for_buf, nodeA.scope["end"].line-1+1, nodeB.scope["start"].line-1, false)
	local nodeB_text = vim.api.nvim_buf_get_lines(for_buf, nodeB.scope["start"].line-1, nodeB.scope["end"].line-1+1, false)

	local start_line = nodeA.scope["start"].line-1
	local nodeA_line_cnt = nodeA.scope["end"].line + 1 - nodeA.scope["start"].line
	local mid_line_cnt = nodeB.scope["start"].line - nodeA.scope["end"].line - 1
	local nodeB_line_cnt = nodeB.scope["end"].line + 1 - nodeB.scope["start"].line

	-- Swap pointers
	nodeA.next = nodeB.next
	nodeB.next = nodeA

	nodeB.prev = nodeA.prev
	nodeA.prev = nodeB

	-- Swap index
	local nodeB_index = nodeB.index
	nodeB.index = nodeA.index
	nodeA.index = nodeB_index

	-- Swap in parent's children array
	local parent = nodeA.parent
	parent.children[nodeA.index] = nodeA
	parent.children[nodeB.index] = nodeB

	-- Adjust line numbers
	nodeA.scope["start"].line = nodeA.scope["start"].line + nodeB_line_cnt + mid_line_cnt
	nodeA.scope["end"].line = nodeA.scope["end"].line + nodeB_line_cnt + mid_line_cnt
	nodeA.name_range["start"].line = nodeA.name_range["start"].line + nodeB_line_cnt + mid_line_cnt
	nodeA.name_range["end"].line = nodeA.name_range["end"].line + nodeB_line_cnt + mid_line_cnt

	nodeB.scope["start"].line = nodeB.scope["start"].line - nodeA_line_cnt - mid_line_cnt
	nodeB.scope["end"].line = nodeB.scope["end"].line - nodeA_line_cnt - mid_line_cnt
	nodeB.name_range["start"].line = nodeB.name_range["start"].line - nodeA_line_cnt - mid_line_cnt
	nodeB.name_range["end"].line = nodeB.name_range["end"].line - nodeA_line_cnt - mid_line_cnt

	-- Set lines
	vim.api.nvim_buf_set_lines(for_buf, start_line, start_line + nodeB_line_cnt, false, nodeB_text)
	vim.api.nvim_buf_set_lines(for_buf, start_line + nodeB_line_cnt, start_line + nodeB_line_cnt + mid_line_cnt, false, mid_text)
	vim.api.nvim_buf_set_lines(for_buf, start_line + nodeB_line_cnt + mid_line_cnt, start_line + nodeB_line_cnt + mid_line_cnt + nodeA_line_cnt, false, nodeA_text)
end

function actions.move_down()
	local callback = function(display)
		if display.focus_node.next == nil then
			return
		end

		swap_nodes(display.for_buf, display.focus_node, display.focus_node.next)

		display:redraw()
	end

	return {
		callback = callback,
		description = "Move code block down"
	}
end

function actions.move_up()
	local callback = function(display)
		if display.focus_node.prev == nil then
			return
		end

		swap_nodes(display.for_buf, display.focus_node.prev, display.focus_node)

		display:redraw()
	end

	return {
		callback = callback,
		description = "Move code block up"
	}
end

function actions.toggle_preview()
	local callback = function(display)
		if vim.api.nvim_win_get_buf(display.right.winid) == display.right.bufnr then
			display:show_preview()
		else
			display:hide_preview()
		end
	end

	return {
		callback = callback,
		description = "Show preview of current node"
	}
end

function actions.vsplit()
	local callback = function(display)
		actions.close().callback(display)
		vim.api.nvim_command("vsplit")
		display.for_win = vim.api.nvim_get_current_win()
		actions.select().callback(display)
		vim.api.nvim_command("normal! zv")
	end

	return {
		callback = callback,
		description = "Open selected node in a vertical split"
	}
end

function actions.hsplit()
	local callback = function(display)
		actions.close().callback(display)
		vim.api.nvim_command("split")
		display.for_win = vim.api.nvim_get_current_win()
		actions.select().callback(display)
		vim.api.nvim_command("normal! zv")
	end

	return {
		callback = callback,
		description = "Open selected node in a horizontal split"
	}
end

function actions.telescope(opts)
	local callback = function(display)
		local status_ok, _ = pcall(require, "telescope")
		if not status_ok then
			vim.notify("telescope.nvim not found", vim.log.levels.ERROR)
			return
		end

		local navic = require("nvim-navic.lib")
		local pickers = require("telescope.pickers")
		local entry_display = require("telescope.pickers.entry_display")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local t_actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		local displayer = entry_display.create({
			separator = " ",
			items = {
				{ width = 14 },
				{ remaining = true },
			},
		})

		local function make_display(entry)
			local node = entry.value
			local kind = navic.adapt_lsp_num_to_str(node.kind)
			local kind_hl = "Navbuddy"..kind
			local name_hl = "NavbuddyNormalFloat"
			local columns = {
				{ string.lower(kind), kind_hl },
				{ node.name, name_hl},
			}
			return displayer(columns)
		end

		local function make_entry(node)
			return {
				value = node,
				display = make_display,
				name = node.name,
				ordinal = string.lower(navic.adapt_lsp_num_to_str(node.kind)).." "..node.name,
				lnum = node.name_range["start"].line,
				col = node.name_range["start"].character,
				bufnr = display.for_buf,
				filename = vim.api.nvim_buf_get_name(display.for_buf),
			}
		end

		display:close()
		pickers.new(opts, {
			prompt_title = "Fuzzy Search",
			finder = finders.new_table({
				results = display.focus_node.parent.children,
				entry_maker = make_entry
			}),
			sorter = conf.generic_sorter(opts),
			previewer = conf.qflist_previewer(opts),
			attach_mappings = function(prompt_bufnr, _)
				t_actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					display.focus_node = selection.value
					t_actions.close(prompt_bufnr)
				end)
				t_actions.close:enhance({
					post = function()
						display = require("nvim-navbuddy.display"):new(display)
					end
				})
				return true
			end,
		}):find()
	end

	return {
		callback = callback,
		description = "Fuzzy search current level with telescope"
	}
end

function actions.help()
	local callback = function(display)
		display:close()

		local nui_popup = require("nui.popup")

		local help_popup = nui_popup({
			relative = "editor",
			position = display.config.window.position,
			size = display.config.window.size,
			enter = true,
			focusable = true,
			border = display.config.window.border,
			win_options = {
				winhighlight = "Normal:NavbuddyNormalFloat,FloatBorder:NavbuddyFloatBorder",
			},
			buf_options = {
				modifiable = false,
			},
		})

		local function quit_help()
			help_popup:unmount()
			require("nvim-navbuddy.display"):new(display)
		end

		help_popup:map("n", "q", quit_help)
		help_popup:map("n", "<esc>", quit_help)

		help_popup:mount()

		local max_keybinding_len = 0
		for k, _ in pairs(display.config.mappings) do
			max_keybinding_len = math.max(#k, max_keybinding_len)
		end

		local lines = {}
		for k, v in pairs(display.config.mappings) do
			local text = "  " .. k .. string.rep(" ", max_keybinding_len - #k) .. " | " .. v.description
			table.insert(lines, text)
		end
		table.sort(lines)
		table.insert(lines, 1, " Navbuddy Mappings" .. string.rep(" ", math.max(1, vim.api.nvim_win_get_width(help_popup.winid) - 18*2)) .. "press 'q' to exit ")
		table.insert(lines, 2, string.rep("-", vim.api.nvim_win_get_width(help_popup.winid)))

		vim.api.nvim_buf_set_option(help_popup.bufnr, "modifiable", true)
		vim.api.nvim_buf_set_lines(help_popup.bufnr, 0, -1, false, lines)
		vim.api.nvim_buf_set_option(help_popup.bufnr, "modifiable", false)

		vim.api.nvim_buf_add_highlight(
			help_popup.bufnr,
			-1,
			"NavbuddyFunction",
			0,
			0,
			-1
		)
		for i = 2, #lines do
			vim.api.nvim_buf_add_highlight(
				help_popup.bufnr,
				-1,
				"NavbuddyKey",
				i - 1,
				0,
				max_keybinding_len + 3
			)
		end
	end

	return {
		callback = callback,
		description = "Show mappings"
	}
end

return actions
