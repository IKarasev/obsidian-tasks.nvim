local config = require("obsidian-tasks.config")
local cfg = config.getConfig()
local tl = require("obsidian-tasks.taskline")

local M = {}

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

--- filters list of tasks based on target date
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

--- filters tasks list based on target date from today to given number of days inclusive
---@param tasks table[obsidian-tasks.TaskSearchResultItem]
---@param days integer
---@return table[obsidian-tasks.TaskSearchResultItem]
M.resultsFilterNextDays = function(tasks, days)
	local today = os.date("*t")
	local todayTs = os.time({ year = today.year, month = today.month, day = today.day })
	local endTs =
		os.time({ year = today.year, month = today.month, day = today.day + days, hour = 23, min = 59, sec = 59 })

	local result = {}

	for _, task in ipairs(tasks) do
		local taskTs = tl.getTargetDate(task.text)
		if taskTs ~= nil then
			if taskTs >= todayTs and taskTs <= endTs then
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
	rgs.findToDo = rgSimpleTaskSearch(cfg.taskMark.todo)
	rgs.findDone = rgSimpleTaskSearch(cfg.taskMark.done)
	rgs.findCanceled = rgSimpleTaskSearch(cfg.taskMark.canceled)
	rgs.findInProgress = rgSimpleTaskSearch(cfg.taskMark.inprogress)
	rgs.findActiveIn = function(n)
		local tasks = rgSimpleTaskSearch(cfg.taskMark.todo)()
		tasks = M.resultsFilterNextDays(tasks, n)
		return tasks
	end
	rgs.findActive = function()
		local tasks = rgSimpleTaskSearch(cfg.taskMark.todo)()
		tasks = M.resultsFilterFromDate(tasks, os.time())
		return tasks
	end
	rgs.findActiveToday = rgs.findActiveIn(0)
	rgs.findActiveWeek = rgs.findActiveIn(7)
	rgs.findActiveMonth = rgs.findActiveIn(30)
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

return M
