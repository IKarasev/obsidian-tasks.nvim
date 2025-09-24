local tl = require("obsidian-tasks.taskline")
local config = require("obsidian-tasks.config").getConfig()
local taskMarks = config.taskMark
local cfgSearcher = config.searcher
local M = {}

local searchTypes = {
	all = "all",
	active = "active",
	todo = "todo",
	done = "done",
	canceled = "canceled",
	progress = "in_progress",
	missed = "missed",
}

local searchPeriods = {
	day = "day",
	week = "week",
	month = "month",
}

M.getSearchTypes = function()
	local result = {}
	for _, value in pairs(searchTypes) do
		table.insert(result, value)
	end
	return result
end

M.getSearchPeriods = function()
	local result = {}
	for _, value in pairs(searchPeriods) do
		table.insert(result, value)
	end
	return result
end

---@class obsidian-tasks.TaskSearchResultItem
---@field file string
---@field line integer
---@field text string
local TaskSearchResultItem = {}
TaskSearchResultItem.__index = TaskSearchResultItem

---@param opts table?
---@return obsidian-tasks.TaskSearchResultItem
function TaskSearchResultItem.new(opts)
	local item = setmetatable({}, TaskSearchResultItem)
	if type(opts) == "table" then
		if opts.file then
			item.file = opts.file
		end
		if opts.line then
			item.line = opts.line
		end
		if opts.text then
			item.text = opts.text
		end
	end
	return item
end

--- filters list of tasks based on target date been in given period
---@param tasks table[obsidian-tasks.TaskSearchResultItem]
---@param startDate integer timestamp
---@param endDate integer timestamp
---@return table[obsidian-tasks.TaskSearchResultItem]
M.resultsFilterPeriod = function(tasks, startDate, endDate)
	local result = {}
	for _, task in ipairs(tasks) do
		local taskTs = tl.getTargetDate(task.text)
		if taskTs ~= nil then
			if taskTs >= startDate and taskTs <= endDate then
				table.insert(result, task)
			end
		end
	end
	return result
end

--- filters tasks list based on target date that are later than given date inclusive
---@param tasks table[obsidian-tasks.TaskSearchResultItem]
---@param start integer timestamp
---@return table[obsidian-tasks.TaskSearchResultItem]
M.resultsFilterFromDate = function(tasks, start)
	local result = {}
	local fromDate = os.date("*t", start)
	start = os.time({ year = fromDate.year, month = fromDate.month, day = fromDate.day })
	for _, task in ipairs(tasks) do
		local taskTs = tl.getTargetDate(task.text)
		if taskTs ~= nil then
			if taskTs >= start then
				table.insert(result, task)
			end
		end
	end
	return result
end

M.resultsFilterPeriodDays = function(tasks, startDays, endDays)
	local today = os.date("*t")
	if startDays > endDays then
		startDays, endDays = endDays, startDays
	end
	local startTs = 0
	local endTs = 0

	if startDays >= 0 then
		startTs = os.time({ year = today.year, month = today.month, day = today.day + startDays })
	else
		startTs = os.time({
			year = today.year,
			month = today.month,
			day = today.day + startDays,
			hour = 23,
			min = 59,
			sec = 59,
		})
	end
	if endDays >= 0 then
		endTs = os.time({
			year = today.year,
			month = today.month,
			day = today.day + endDays,
			hour = 23,
			min = 59,
			sec = 59,
		})
	else
		endTs = os.time({ year = today.year, month = today.month, day = today.day + endDays })
	end
	return M.resultsFilterPeriod(tasks, startTs, endTs)
end

--- filters tasks list based on target date from today to given number of days inclusive
---@param tasks table[obsidian-tasks.TaskSearchResultItem]
---@param days integer
---@return table[obsidian-tasks.TaskSearchResultItem]
M.resultsFilterNextDays = function(tasks, days)
	local today = os.date("*t")
	local startTs = 0
	local endTs = 0

	if days >= 0 then
		startTs = os.time({ year = today.year, month = today.month, day = today.day })
		endTs =
			os.time({ year = today.year, month = today.month, day = today.day + days, hour = 23, min = 59, sec = 59 })
	else
		startTs = os.time({ year = today.year, month = today.month, day = today.day + days })
		endTs = os.time({ year = today.year, month = today.month, day = today.day, hour = 23, min = 59, sec = 59 })
	end

	return M.resultsFilterPeriod(tasks, startTs, endTs)
end

--- class to search in files, all search functions should return table
--- of obsidian-tasks.TaskSearchResultItem
---@class obsidian-tasks.BaseSearcher
---@field engine string engine name
---@field findAll function finds all tasks
---@field findToDo function finds marked todo
---@field findDone function findes marked done
---@field findCanceled function finds marked canceled
---@field findInProgress function finds marked in progress
---@field findActiveIn function (n) find active tasks in next n days
---@field findActive function find tasks marked todo and target date in future
---@field findActiveToday function find tasks marked todo today
---@field findActiveWeek function find tasks marked todo for next week
---@field findActiveMonth function find tasks marked todo for next month
local BaseSearcher = {}
BaseSearcher.__index = BaseSearcher

local RgSearcher = {}
RgSearcher.__index = BaseSearcher

---@param rg table
---@return table<obsidian-tasks.TaskSearchResultItem>
local parseRgResults = function(rg)
	local result = {}
	for _, line in ipairs(rg) do
		local f, l, t = line:match("(.*):(%d+):(.*)")
		if t ~= nil then
			table.insert(
				result,
				TaskSearchResultItem.new({
					file = f,
					line = l,
					text = t:gsub("\r$", ""),
				})
			)
		end
	end
	return result
end

---@param taskMark string
---@return function <table<obsidian-tasks.TaskSearchResultItem>>
local rgSimpleTaskSearch = function(taskMark)
	return function()
		local rg = vim.fn.systemlist('rg -n -g "*.md" -e "^\\s*- \\[' .. taskMark .. '\\] #task"')
		return parseRgResults(rg)
	end
end

--- creates new ripgrep searcher
---@return obsidian-tasks.BaseSearcher
function RgSearcher.new()
	local rgs = setmetatable({}, BaseSearcher)

	rgs.engine = "ripgrep"
	rgs.findAll = rgSimpleTaskSearch(".")
	rgs.findToDo = rgSimpleTaskSearch(taskMarks.todo)
	rgs.findDone = rgSimpleTaskSearch(taskMarks.done)
	rgs.findCanceled = rgSimpleTaskSearch(taskMarks.canceled)
	rgs.findInProgress = rgSimpleTaskSearch(taskMarks.inprogress)
	rgs.findActiveIn = function(n)
		local tasks = rgSimpleTaskSearch(taskMarks.todo)()
		tasks = M.resultsFilterNextDays(tasks, n)
		return tasks
	end
	rgs.findActive = function()
		local tasks = rgSimpleTaskSearch(taskMarks.taskMark.todo)()
		tasks = M.resultsFilterFromDate(tasks, os.time())
		return tasks
	end
	rgs.findActiveToday = function()
		local tasks = rgSimpleTaskSearch(taskMarks.taskMark.todo)()
		tasks = M.resultsFilterNextDays(tasks, 0)
		return tasks
	end
	rgs.findActiveWeek = function()
		rgs.findActiveIn(7)
	end
	rgs.findActiveMonth = function()
		rgs.findActiveIn(30)
	end
	return rgs
end

--- get searcher by name
---@param name string
---@return obsidian-tasks.BaseSearcher | nil
M.getSearcher = function(name)
	if name == "ripgrep" then
		return RgSearcher.new()
	end
	return nil
end

--- finds tasks based on user cmd opts.fargs
---@param fargs table opts.fargs
---@return table[obsidian-tasks.TaskSearchResultItem]
M.findCmdFargs = function(fargs)
	local tasks = {}
	local s = M.getSearcher(cfgSearcher)

	if s == nil then
		print("ERROR: obsidian-tasks.nvim: Searcher " .. cfgSearcher .. " not found")
		return {}
	end
	if #fargs == 0 then
		return s.findAll()
	end

	local periodBase = 0
	local sType = fargs[1] or searchTypes.all
	local sPeriod = fargs[2]
	local countStart = fargs[3]
	local countEnd = fargs[4]

	if sType == searchTypes.all then
		tasks = s.findAll()
	elseif sType == searchTypes.todo or sType == searchTypes.missed then
		tasks = s.findToDo()
	elseif sType == searchTypes.active then
		tasks = s.findActive()
	elseif sType == searchTypes.canceled then
		tasks = s.findCanceled()
	elseif sType == searchTypes.done then
		tasks = s.findDone()
	end

	if sPeriod == nil then
		return tasks
	end

	if sPeriod == searchPeriods.day then
		periodBase = 1
	elseif sPeriod == searchPeriods.week then
		periodBase = 7
	elseif sPeriod == searchPeriods.month then
		periodBase = 30
	end

	if sType == searchTypes.missed then
		periodBase = -periodBase
	end

	countStart = tonumber(countStart) or 0
	countEnd = tonumber(countEnd)

	if countEnd == nil then
		tasks = M.resultsFilterNextDays(tasks, periodBase * countStart)
	else
		tasks = M.resultsFilterPeriodDays(tasks, periodBase * countStart, periodBase * countEnd)
	end

	return tasks
end

return M
