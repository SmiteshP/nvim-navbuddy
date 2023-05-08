local USER_FOLDMETHOD = vim.o.foldmethod  -- get user foldmethod preference to restore it

local actions = {}

function actions.close(display)
	display:close()
	vim.api.nvim_win_set_cursor(display.for_win, display.start_cursor)
end

function actions.next_sibling(display)
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

function actions.previous_sibling(display)
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

function actions.parent(display)
	if display.focus_node.parent.is_root then
		return
	end

	local parent_node = display.focus_node.parent
	display.focus_node = parent_node

	display:redraw()
end

function actions.children(display)
	if display.focus_node.children == nil then
		actions.select(display)
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

function actions.root(display)
	if display.focus_node.parent.is_root then
		return
	end

	while not display.focus_node.parent.is_root do
		display.focus_node.parent.memory = display.focus_node.index
		display.focus_node = display.focus_node.parent
	end

	display:redraw()
end

function actions.select(display)
	display:close()
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

function actions.yank_name(display)
	display:close()
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

function actions.yank_scope(display)
	display:close()
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

function actions.visual_name(display)
	display:close()
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

function actions.visual_scope(display)
	display:close()
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

function actions.insert_name(display)
	display:close()
	vim.api.nvim_win_set_cursor(
		display.for_win,
		{ display.focus_node.name_range["start"].line, display.focus_node.name_range["start"].character }
	)
	vim.api.nvim_feedkeys("i", "n", false)
end

function actions.insert_scope(display)
	display:close()
	vim.api.nvim_win_set_cursor(
		display.for_win,
		{ display.focus_node.scope["start"].line, display.focus_node.scope["start"].character }
	)
	vim.api.nvim_feedkeys("i", "n", false)
end

function actions.append_name(display)
	display:close()
	vim.api.nvim_win_set_cursor(
		display.for_win,
		{ display.focus_node.name_range["end"].line, display.focus_node.name_range["end"].character - 1 }
	)
	vim.api.nvim_feedkeys("a", "n", false)
end

function actions.append_scope(display)
	display:close()
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

function actions.rename(display)
	display:close()
	vim.lsp.buf.rename()
end

function actions.delete(display)
	actions.visual_scope(display)
	vim.api.nvim_command("normal! d")
end

local is_manual_foldmethod = function(display)
	if display.config.folding.foldmethod_auto_set_manual == true then
		vim.o.foldmethod = "manual"
		return true
	end
	if USER_FOLDMETHOD ~= "manual" then
		vim.notify("Fold create action works only when foldmethod is 'manual'", vim.log.levels.ERROR)
		return false
	end
	return true
end

local reinit_foldmethod = function()
	vim.o.foldmethod = USER_FOLDMETHOD
end

local comment_trailing_space = function(display)
	vim.api.nvim_set_current_line(vim.api.nvim_get_current_line() .. string.rep(" ", display.config.folding.leading_spaces))
end

local clean_trailing_space = function()
	vim.api.nvim_set_current_line(""..vim.api.nvim_get_current_line():gsub("%s+$", ""))
end

function actions.fold_create(display)
	local foldmarker_o, foldmarker_c = vim.o.foldmarker:match("([^,]+),([^,]+)")

	if is_manual_foldmethod(display) == false then
		return
	end

	display.state.leaving_window_for_action = true
	vim.api.nvim_set_current_win(display.for_win)
	vim.api.nvim_win_set_cursor(
		display.for_win,
		{ display.focus_node.scope["start"].line, display.focus_node.scope["start"].character }
	)

	-- avoid duplicate fold marker comment string
	if vim.api.nvim_get_current_line():find(foldmarker_o) or vim.api.nvim_get_current_line():find(foldmarker_c) then
		vim.api.nvim_set_current_win(display.mid.winid)
		display.state.leaving_window_for_action = false
		return
	end

	comment_trailing_space(display)
	vim.api.nvim_command("normal! v")
	vim.api.nvim_win_set_cursor(
		display.for_win,
		{ display.focus_node.scope["end"].line, display.focus_node.scope["end"].character - 1 }
	)
	comment_trailing_space(display)
	vim.api.nvim_command("normal! zf")
	vim.api.nvim_set_current_win(display.mid.winid)
	display.state.leaving_window_for_action = false

	reinit_foldmethod()
end

function actions.fold_delete(display)
	local start_line = display.focus_node.scope["start"].line
	local end_line = display.focus_node.scope["end"].line

	if is_manual_foldmethod(display) == false then
		return
	end

	display.state.leaving_window_for_action = true
	vim.api.nvim_set_current_win(display.for_win)
	vim.api.nvim_win_set_cursor(
		display.for_win,
		{ start_line, display.focus_node.scope["start"].character }
	)
	vim.api.nvim_win_set_cursor(
		display.for_win,
		{ end_line, display.focus_node.scope["end"].character - 1 }
	)
	pcall(vim.api.nvim_command, "normal! zd")
	vim.api.nvim_win_set_cursor(display.for_win, { start_line, 0 })
	clean_trailing_space()
	vim.api.nvim_win_set_cursor(display.for_win, { end_line, 0 })
	clean_trailing_space()
	vim.api.nvim_set_current_win(display.mid.winid)
	display.state.leaving_window_for_action = false

	reinit_foldmethod()
end

function actions.comment(display)
	local status_ok, comment = pcall(require, "Comment.api")
	if not status_ok then
		vim.notify("Comment.nvim not found", vim.log.levels.ERROR)
		return
	end

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

local function swap_nodes(for_buf, nodeA, nodeB)
	-- nodeA
	--   ^
	--   |
	--   v
	-- nodeB

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

function actions.move_down(display)
	if display.focus_node.next == nil then
		return
	end

	swap_nodes(display.for_buf, display.focus_node, display.focus_node.next)

	display:redraw()
end

function actions.move_up(display)
	if display.focus_node.prev == nil then
		return
	end

	swap_nodes(display.for_buf, display.focus_node.prev, display.focus_node)

	display:redraw()
end

function actions.toggle_preview(display)
	if vim.api.nvim_win_get_buf(display.right.winid) == display.right.bufnr then
		display:show_preview()
	else
		display:hide_preview()
	end
end

function actions.telescope(opts)
	return function(display)
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
end

return actions
