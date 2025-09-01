local config = require("obsidian-tasks.config")
local cfg = config.getConfig()
local nlp = require("obsidian-tasks.nlp")

local M = {}

--- checks if given string is task line
---@param line string target string
---@return boolean
local isTaskLine = function(line)
	local re = vim.re.compile("[' ',\t]*'- ['.'] " .. cfg.taskTag .. " '")
	local r = vim.re.find(line, re)
	return r ~= nil
end

--- check if task line is recur task
---@param line string
---@return boolean
local isRecurTask = function(line)
	local s, _ = line:find(cfg.taskIcon.recur)
	return s ~= nil
end

--- checks if recur rule string contains "when done"
---@param line string
---@return boolean
local isRecurWhenDone = function(line)
	local s, _ = line:find("when%s*done")
	return s ~= nil
end

--- replaces char in string at given position
---@param str string target string
---@param pos integer position
---@param ch string replace text
---@return string
local strReplaceChar = function(str, pos, ch)
	return table.concat({ str:sub(1, pos - 1), ch, str:sub(pos + 1) })
end

--- removes char and everything after it in given string
---@param str string target string
---@param ch string char to remove after (inclusive)
---@return string
local strRemoveCharAfter = function(str, ch)
	local si, _ = str:find("%s*" .. ch)
	if not si then
		return str
	end
	local newstr = str:sub(1, si - 1)
	return newstr
end

--- sets mark in task line
---@param line string target line
---@param mark string mark
---@return string
local taskLineSetStatus = function(line, mark)
	local si, ei = line:find("- %[")
	if not si then
		return line
	end

	line = strReplaceChar(line, ei + 1, mark)

	return line
end

--- checks if date is valid
---@param y (integer|string) year
---@param m (integer|string) month
---@param d (integer|string) day
---@return boolean
local checkDate = function(y, m, d)
	y, m, d = tonumber(y), tonumber(m), tonumber(d)
	if not (y and m and d) then
		return false
	end

	-- Create a Date object (uses os.time for validation)
	local date = os.time({ year = y, month = m, day = d })
	if not date then
		return false
	end

	-- Check if components match (accounts for overflow)
	local check = os.date("*t", date)
	return check.year == y and check.month == m and check.day == d
end

--- identifies year, month, day by position defined in format order in config
---@param parts table[3]
---@return any Year,any Month,any Day
local identifyDateParts = function(parts)
	if #parts ~= 3 then
		return nil, nil, nil
	end
	local y = parts[cfg.dateOpts.order.Y]
	local m = parts[cfg.dateOpts.order.m]
	local d = parts[cfg.dateOpts.order.d]
	return y, m, d
end

--- repalaces target date in task line with the given date
---@param line string
---@param newDate string
---@return string
local replaceTargetDate = function(line, newDate)
	local datePatt = cfg.dateOpts.pat:gsub("([^%%])%(", "%1"):gsub("([^%%])%)", "%1"):gsub("^%(", ""):gsub("^%)", "")
	datePatt = "(" .. datePatt .. ")"
	local patt =
		string.format("[%s,%s,%s]%%s*%s", cfg.taskIcon.scheduled, cfg.taskIcon.due, cfg.taskIcon.start, datePatt)
	local i, j = line:find(patt)
	if i == nil or j == nil then
		return line
	end
	local newLine = table.concat({ line:sub(1, i + 1), newDate, line:sub(j + 1) }, "")
	return newLine
end

--- retrieves recurrence string from task line
---@param line string
---@return string
M.getRecurString = function(line)
	local patt = string.format(
		"%s%%s*(.-)[%s,%s,%s,%s]",
		cfg.taskIcon.recur,
		cfg.taskIcon.due,
		cfg.taskIcon.scheduled,
		cfg.taskIcon.start,
		cfg.taskIcon.created
	)
	local rule = line:match(patt)
	if rule == nil then
		return ""
	end
	return rule
end

--- gets date from task line identified by given mark
---@param line string
---@param mark string
---@return integer|nil
M.getMarkedDate = function(line, mark)
	local targetDatePat = string.format("%s%%s*%s", mark, cfg.dateOpts.pat)
	local y, m, d = identifyDateParts(line:match(targetDatePat))
	if y == nil then
		return nil
	end
	if checkDate(y, m, d) then
		return os.time({ year = y, month = m, day = d })
	end
	return nil
end

--- gets target date from task line as os.time
---@param line string target line
---@return integer|nil
M.getTargetDate = function(line)
	local targetDatePat = string.format(
		"[%s,%s,%s]%%s*%s",
		cfg.taskIcon.scheduled,
		cfg.taskIcon.due,
		cfg.taskIcon.start,
		cfg.dateOpts.pat
	)
	local y, m, d = identifyDateParts({ line:match(targetDatePat) })
	if y == nil then
		return nil
	end

	if checkDate(y, m, d) then
		return os.time({ year = y, month = m, day = d })
	end
	return nil
end

--- formats given task line to be ended with given mark and icon
---@param line string
---@param opts table {mark = string, icon = string}
---@return string|nil
M.endTaskLineWith = function(line, opts)
	if type(line) ~= "string" then
		return nil
	end
	if not (opts["mark"] and opts["icon"]) then
		return
	end

	if not isTaskLine(line) then
		vim.notify("Not a task line", "WARNING")
		return nil
	end

	local newMark = opts.mark
	local newIcon = opts.icon
	local newLine = strRemoveCharAfter(line, newIcon)
	newLine = strRemoveCharAfter(newLine, cfg.taskIcon.complited)
	newLine = strRemoveCharAfter(newLine, cfg.taskIcon.canceled)

	newLine = taskLineSetStatus(newLine, newMark)
	newLine = table.concat({ newLine, newIcon, os.date(cfg.dateFormat) }, " ")
	return newLine
end

--- completes task in current buffer line using given mark and icon
---@param opts table {mark = string, icon = string}
M.endTaskWith = function(opts)
	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
	local line = table.concat(vim.api.nvim_buf_get_lines(0, row - 1, row, false))

	local newLine = M.endTaskLineWith(line, opts)
	if newLine == nil then
		return
	end

	vim.api.nvim_buf_set_lines(0, row - 1, row, false, { newLine })
end

M.completeTask = function()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = table.concat(vim.api.nvim_buf_get_lines(0, row - 1, row, false))

	local newLine = M.endTaskLineWith(line, { mark = cfg.taskMark.done, icon = cfg.taskIcon.complited })
	if newLine == nil then
		return
	end

	if isRecurTask(line) then
		local ruleStr = M.getRecurString(line)

		if ruleStr == "" then
			vim.notify("Failed to get recur string", "WARNING")
			return
		end

		local curDate = os.time()
		if not isRecurWhenDone(line) then
			local targetDate = M.getTargetDate(line)
			if targetDate ~= nil then
				curDate = targetDate
			end
		end

		print("Cur Date: " .. os.date(cfg.dateFormat, curDate))

		local r = nlp.parseRecurString(ruleStr)
		if r == nil then
			vim.notify("Failed to parse recur string")
			return
		end
		print(r)
		local nextDate = os.date(cfg.dateFormat, r:next(curDate))
		print("Next Date: " .. nextDate)
		local nextTask = replaceTargetDate(line, nextDate)
		nextDate = taskLineSetStatus(nextDate, cfg.taskMark.todo)

		if cfg.recurOnComplite == config.recurOnCompliteOptions.replace then
			vim.api.nvim_buf_set_lines(0, row - 1, row, false, { nextTask })
		elseif cfg.recurOnComplite == config.recurOnCompliteOptions.addAfter then
			vim.api.nvim_buf_set_lines(0, row - 1, row, false, { newLine })
			vim.api.nvim_buf_set_lines(0, row, row, false, { nextTask })
		elseif cfg.recurOnComplite == config.recurOnCompliteOptions.addBefore then
			vim.api.nvim_buf_set_lines(0, row - 1, row, false, { newLine })
			vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { nextTask })
		else
			vim.api.nvim_buf_set_lines(0, row - 1, row, false, { newLine })
		end
		return
	end

	vim.api.nvim_buf_set_lines(0, row - 1, row, false, { newLine })
end

M.cancelTask = function()
	M.endTaskWith({ mark = cfg.taskMark.canceled, icon = cfg.taskIcon.canceled })
end

return M
