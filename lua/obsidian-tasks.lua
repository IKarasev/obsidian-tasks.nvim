local config = require("obsidian-tasks.config")

local M = {}

--- returns current config
---@return table
M.getConfig = function()
	return config.config
end

local searchAutocomplete = function() end

---@param opts table|nil [obsidian-tasks.config.default_config]
M.setup = function(opts)
	config.setup(opts)

	local cfg = config.getConfig()

	for hl_name, hl_opts in pairs(cfg.hl) do
		vim.api.nvim_set_hl(0, hl_name, hl_opts)
	end

	if cfg.snippets then
		local snippets = require("obsidian-tasks.snippets")
		snippets.add_snippets()
	end

	local taskline = require("obsidian-tasks.taskline")
	if cfg.userCmd.enabled then
		vim.api.nvim_create_user_command(
			cfg.userCmd.taskComplete,
			taskline.completeTask,
			{ desc = "Complite obsidian task at current line" }
		)
		vim.api.nvim_create_user_command(
			cfg.userCmd.taskCancel,
			taskline.cancelTask,
			{ desc = "Canacel obsidian task at current line" }
		)
	end

	if cfg.search then
		local srch = require("obsidian-tasks.search")
		local picker = require("obsidian-tasks.picker")
		if cfg.userCmd.enabled then
			vim.api.nvim_create_user_command(cfg.userCmd.taskFind, function()
				local s = srch.getSearcher(cfg.searcher)
				if s == nil then
					print("Searcher " .. cfg.searcher .. " not found")
					return
				end
				local tasks = s.findActive()
				picker.telescope(tasks)
			end, { desc = "Find tasks" })
		end
	end
end

return M
