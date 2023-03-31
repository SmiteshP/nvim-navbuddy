local actions = {}

function actions.close(display)
	display:close()
	vim.api.nvim_win_set_cursor(display.for_win, display.start_cursor)
end

function actions.next_sibling(display)
	if display.focus_node.next == nil then
		return
	end

	local next_node = display.focus_node.next
	display.focus_node = next_node

	display:redraw()
end

function actions.previous_sibling(display)
	if display.focus_node.prev == nil then
		return
	end

	local prev_node = display.focus_node.prev
	display.focus_node = prev_node

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

return actions
