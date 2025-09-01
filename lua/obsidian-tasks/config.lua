local M = {}

M.recurOnCompliteOptions = {
	replace = "replace",
	addAfter = "add_after",
	addBefore = "add_before",
}

local default_config = {
	dateFormat = "%Y-%m-%d",
	taskTag = "#task",
	snippets = true,
	taskIcon = {
		due = "⏳",
		scheduled = "📅",
		start = "🛫",
		recur = "🔁",
		created = "➕",
		complited = "✅",
		canceled = "❌",
	},
	taskMark = {
		todo = " ",
		done = "x",
		canceled = "-",
		inprogress = "/",
		nontask = "~",
	},
	dateOpts = {
		pat = "(%d%d%d%d)%-(%d%d)%-(%d%d)",
		order = {
			Y = 1,
			m = 2,
			d = 3,
		},
	},
	userCmd = { -- names for plugin cuser commands
		enabled = true,
		taskComplete = "ObTaskComplete",
		taskCancel = "ObTaskCancel",
	},
	recurOnComplite = "replace", -- "replace", "add_after", "add_before"
	hl = {
		ObTaskSnipHint = { fg = "#737aa2", italic = true },
	},
}

M.config = {}

--- validates dateOpts field
---@param tbl table dateOpts table to validate
---@return boolean
local isValidDateOpts = function(tbl)
	local isValidPos = function(a)
		return type(a) == "number" and a % 1 == 0 and a > 0 and a < 4
	end
	local ok = pcall(function()
		vim.validate({
			["tbl"] = { tbl, "t" },
			["tbl.pat"] = { tbl.pat, "s" },
			["tbl.order"] = { tbl.order, "t" },
			["tbl.order.Y"] = { tbl.order.Y, isValidPos },
			["tbl.order.m"] = { tbl.order.m, isValidPos },
			["tbl.order.d"] = { tbl.order.d, isValidPos },
		})
	end)

	if not ok then
		return false
	end
	return tbl.order.Y ~= tbl.order.m and tbl.order.Y ~= tbl.order.d and tbl.order.m ~= tbl.order.d
end

--- parses date format and builds string pattern from it
---@param fmt string format
---@return table [{Y=1,m=2,d=3}]
---@return string [pattern]
local buildDatePattern = function(fmt)
	local map = {
		Y = { key = "y", pat = "(%d%d%d%d)" }, -- year: 4 digits
		m = { key = "m", pat = "(%d%d)" }, -- month: 2 digits
		d = { key = "d", pat = "(%d%d)" }, -- day: 2 digits
	}

	local order = {
		Y = 0,
		m = 0,
		d = 0,
	}
	local i = 1

	local date_pat = fmt:gsub("[^%w%%]", "%%%0")

	date_pat = date_pat:gsub("%%([Ymd])", function(c)
		local part = map[c]
		if not part then
			return nil, nil
		end
		order[c] = i
		i = i + 1
		return part.pat
	end)

	if i ~= 4 then
		error("obsidian-tasks:taskline: Invalid date format")
	end

	return order, date_pat
end

M.getConfig = function()
	if M.config then
		return M.config
	end
	return default_config
end

M.setup = function(opts)
	if opts == nil then
		M.config = default_config
		return
	end

	local validDatePat = isValidDateOpts(opts.dateOpts)
	if not validDatePat then
		opts.dateOpts = nil
	end

	M.config = vim.tbl_deep_extend("force", default_config, opts)

	-- if dateFormat not default - build new date pattern
	if not validDatePat and M.config.dateFormat ~= default_config.dateFormat then
		local ok, order, pat = pcall(buildDatePattern, M.config.dateFormat)
		if ok then
			M.config.dateOpts.order = order
			M.config.dateOpts.pat = pat
		else
			M.config.dateFormat = default_config.dateFormat
			M.config.dateOpts = default_config.dateOpts
		end
	end
end

return M
