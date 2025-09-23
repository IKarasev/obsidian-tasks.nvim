local M = {}

M.telescope = function(tasks)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local previewers = require("telescope.previewers")

	local custom_picker = function(entries)
		pickers
			.new({}, {
				prompt_title = "Tasks List",
				layout_strategy = "vertical",
				finder = finders.new_table({
					results = entries,
					entry_maker = function(entry)
						return {
							value = entry,
							display = function()
								local noteText = vim.trim(entry.text)
								local text = string.format("%s  %s", noteText, entry.file)
								local hl = { { { #noteText, #text }, "Comment" } }

								return text, hl
							end,
							ordinal = entry.text .. " " .. entry.file,
							filename = entry.file,
							lnum = entry.line,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				previewer = previewers.new_buffer_previewer({
					title = "Note",
					define_preview = function(self, entry, status)
						if entry.filename ~= nil then
							conf.buffer_previewer_maker(entry.filename, self.state.bufnr, {
								bufname = self.state.bufname,
								callback = function(bufnr)
									vim.api.nvim_buf_call(bufnr, function()
										local line = entry.lnum or 1
										pcall(vim.fn.cursor, entry.lnum, 0)
										vim.cmd("normal! zz") -- center line
										vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
										-- Highlight target line
										vim.api.nvim_buf_add_highlight(
											bufnr,
											-1,
											"TelescopePreviewLine", -- highlight group (defined by telescope)
											line - 1, -- 0-indexed
											0,
											-1
										)
									end)
								end,
							})
						end
					end,
				}),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						local selection = action_state.get_selected_entry()
						actions.close(prompt_bufnr)
						vim.cmd(string.format("edit +%d %s", selection.lnum, selection.filename))
					end)
					return true
				end,
			})
			:find()
	end

	custom_picker(tasks)
end

return M
