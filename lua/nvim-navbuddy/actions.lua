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

function actions.fold_create(display)
	if vim.o.foldmethod ~= "manual" then
		vim.notify("Fold create action works only when foldmethod is 'manual'", vim.log.levels.ERROR)
		return
	end

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

function actions.fold_delete(display)
	if vim.o.foldmethod ~= "manual" then
		vim.notify("Fold delete action works only when foldmethod is 'manual'", vim.log.levels.ERROR)
		return
	end

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

function actions.telescope(display)
	local status_ok, _ = pcall(require, "telescope")
	if not status_ok then
		vim.notify("telescope.nvim not found", vim.log.levels.ERROR)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local t_actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local previewer = require("telescope.previewers")

	local ns = vim.api.nvim_create_namespace("nvim-navbuddy-telescope")

	local function focus_range(node)
		local ranges = nil

		if vim.deep_equal(node.scope, node.name_range) then
			ranges = { { "NavbuddyScope", node.scope } }
		else
			ranges = { { "NavbuddyScope", node.scope }, { "NavbuddyName", node.name_range } }
		end

		if display.config.source_buffer.highlight then
			for _, v in ipairs(ranges) do
				local highlight, range = unpack(v)

				if range["start"].line == range["end"].line then
					vim.api.nvim_buf_add_highlight(
						display.for_buf,
						ns,
						highlight,
						range["start"].line - 1,
						range["start"].character,
						range["end"].character
					)
				else
					vim.api.nvim_buf_add_highlight(
						display.for_buf,
						ns,
						highlight,
						range["start"].line - 1,
						range["start"].character,
						-1
					)
					vim.api.nvim_buf_add_highlight(
						display.for_buf,
						ns,
						highlight,
						range["end"].line - 1,
						0,
						range["end"].character
					)
					for i = range["start"].line, range["end"].line - 2, 1 do
						vim.api.nvim_buf_add_highlight(display.for_buf, ns, highlight, i, 0, -1)
					end
				end
			end
		end
	end

	local function fuzzy_search(opts)
		opts = opts or {}
		pickers.new(opts, {
			prompt_title = "Fuzzy Search",
			finder = finders.new_table({
				results = display.focus_node.parent.children,
				entry_maker = function(node)
					return {
						value = node,
						display = node.name,
						ordinal = node.name,
					}
				end
			}),
			previewer = previewer.new({
				preview_fn = function(_, entry, status)
					if vim.api.nvim_win_get_buf(status.preview_win) ~= display.for_buf then
						vim.api.nvim_win_set_buf(status.preview_win, display.for_buf)

						vim.api.nvim_win_set_option(status.preview_win, "signcolumn", "no")
						vim.api.nvim_win_set_option(status.preview_win, "foldlevel", 100)
						vim.api.nvim_win_set_option(status.preview_win, "wrap", false)
					end

					local node = entry.value
					vim.api.nvim_win_set_cursor(status.preview_win, {node.name_range["start"].line, 0})

					vim.api.nvim_buf_clear_highlight(display.for_buf, ns, 0, -1)
					focus_range(node)
				end
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, _)
				t_actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					display.focus_node = selection.value
					t_actions.close(prompt_bufnr)
				end)
				t_actions.close:enhance({
					post = function()
						vim.api.nvim_buf_clear_highlight(display.for_buf, ns, 0, -1)
						display = require("nvim-navbuddy.display"):new(display)
					end
				})
				return true
			end,
		}):find()
	end

	display:close()
	fuzzy_search()
end

return actions
