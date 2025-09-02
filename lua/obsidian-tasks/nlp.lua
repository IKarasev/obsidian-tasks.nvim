local M = {}

local period = {
	DAY = "day",
	WEEK = "week",
	MONTH = "month",
	YEAR = "year",
}

local weekdays = {
	monday = 1,
	tuesday = 2,
	wednesday = 3,
	thursday = 4,
	friday = 5,
	saturday = 6,
	sunday = 7,
}

local months = {
	january = 1,
	february = 2,
	march = 3,
	april = 4,
	may = 5,
	june = 6,
	july = 7,
	august = 8,
	september = 9,
	october = 10,
	november = 11,
	december = 12,
}

local periodWords = {
	daily = period.DAY,
	day = period.DAY,
	days = period.DAY,
	weekly = period.WEEK,
	week = period.WEEK,
	weeks = period.WEEK,
	monthly = period.MONTH,
	month = period.MONTH,
	months = period.MONTH,
	yearly = period.YEAR,
	year = period.YEAR,
	years = period.YEAR,
}

--- removes hour, minutes and seconds from date
---@param time integer
---@return integer
local normalizeDate = function(time)
	local t = os.date("*t", time)
	t.hour = 0
	t.min = 0
	t.sec = 0
	return os.time(t)
end

--- adds n days to given date
---@param date integer date in seconds (as from os.time)
---@param n integer
---@return integer
local addDays = function(date, n)
	return date + (n * 86400)
end

---@class obsidian-tasks.Words
---@field len integer
---@field pos integer
---@field w table[string]
local Words = {}
Words.__index = Words

---@param opts table {text string, lower bool}
---@return obsidian-tasks.Words
function Words.new(opts)
	local text = opts.text or ""

	if opts.lower then
		text = string.lower(text)
	end

	local words = setmetatable({}, Words)
	words.w = {}
	words.pos = 0
	for w in string.gmatch(text, "%S+") do
		table.insert(words.w, w)
	end
	words.len = #words.w
	return words
end

--- sentence of words
---@return string
function Words:sentence()
	return table.concat(self.w, " ")
end

--- moves positoin N to left (start)
---@param N integer
function Words:left(N)
	local pos = self.pos - N
	if pos < 1 then
		pos = 1
	elseif pos > self.len then
		pos = self.len
	end
	self.pos = pos
end

--- moves postion N to right (end)
---@param N integer
function Words:right(N)
	local pos = self.pos + N
	if pos < 1 then
		pos = 1
	elseif pos > self.len then
		pos = self.len
	end
	self.pos = pos
end

--- current word
---@return string
function Words:cur()
	if self.pos > self.len then
		return ""
	end
	return self.w[self.pos]
end

--- next word or "" if end (moves position)
---@return string
function Words:next()
	if self.pos >= self.len then
		return ""
	end
	self.pos = self.pos + 1
	return self.w[self.pos]
end

--- previous word (moves position)
---@return string
function Words:prev()
	if self.pos <= 1 then
		return ""
	end
	self.pos = self.pos - 1
	return self.w[self.pos]
end

--- returns slice of next N words (does not move position)
---@param N integer
---@return table[strings]
function Words:getNextN(N)
	local slice = {}
	local last = self.pos + N
	for i = self.pos, (last > self.len) and self.len or last do
		table.insert(slice, self.w[i])
	end
	return slice
end

--- returns slice of last N words
---@param N integer
---@return table[strings]
function Words:lastN(N)
	local from = self.len - N
	from = (from > 0) and from or 1
	local slice = {}
	for i = from, self.len, 1 do
		table.insert(slice, self.w[i])
	end
	return slice
end

--- returns rest of words (does not move position)
---@return table[strings]
function Words:rest()
	local slice = self:getNextN(self.len)
	return slice
end

--- Tries to get number from next word, if not, doen't moves position
---@return integer|nil
function Words:expectNumber()
	local next = self:next()
	if next == "" then
		return nil
	end
	next = next:match("^(%d+)")
	local num = tonumber(next)
	if num == nil then
		self.pos = self.pos - 1
		return nil
	end
	return num
end

---@class obsidian-tasks.Recur
---@field period string base frequency definition (like daily, weekly etc)
---@field count integer how many times to repeat period (like 5 weeks)
---@field weekday integer recur on weekdays
---@field onmonth integer recur on month
---@field wdcount integer count for day/weekday/month for onmonth, weekday or day of month
---@field onlast boolean recur on last day of period
local Recur = {}
Recur.__index = Recur
Recur.__tostring = function(self)
	return self:toString()
end

---@return obsidian-tasks.Recur
function Recur.new()
	local recur = setmetatable({}, Recur)
	recur.period = ""
	recur.count = 1
	recur.weekday = 0
	recur.onmonth = 0
	recur.onlast = false
	recur.wdcount = 0
	return recur
end

---@return string
function Recur:toString()
	local str = {
		"PERIOD: " .. self.period,
		"COUNT: " .. tostring(self.count),
		"WEEKDAY: " .. tostring(self.weekday),
		"ONMONTH: " .. tostring(self.onmonth),
		"ON_LAST: " .. tostring(self.onlast),
		"WD_COUNT: " .. tostring(self.wdcount),
	}
	return table.concat(str, ", ")
end

--- sets Recur onmoth or weekday based on give key
---@param key string
function Recur:setWeekMonth(key)
	if months[key] then
		self.onmonth = months[key]
	elseif weekdays[key] then
		self.weekday = weekdays[key]
	end
end

--- sets weeday based on key
---@param key string
---@return boolean
function Recur:setWeekday(key)
	if weekdays[key] then
		self.weekdays = weekdays[key]
		return true
	end
	return false
end

--- sets onmonth based on key
---@param key string
---@return boolean
function Recur:setOnMonth(key)
	if months[key] then
		self.onmonth = months[key]
		return true
	end
	return false
end

---@param date integer time in seconds (like os.time)
---@return integer [next date in secodns]
function Recur:next(date)
	local curDate = os.date("*t", date)
	local nextDate = os.date("*t", date)
	nextDate.hour = 0
	nextDate.min = 0
	nextDate.sec = 0

	-- add period counts to date
	if self.period == period.DAY then
		nextDate.day = nextDate.day + self.count
	elseif self.period == period.WEEK then
		nextDate.day = nextDate.day + (self.count * 7)
	elseif self.period == period.MONTH then
		nextDate.month = nextDate.month + self.count
	elseif self.period == period.YEAR then
		nextDate.year = nextDate.year + self.count
	end

	-- if next date on specific month
	if self.onmonth > 0 then
		if curDate.year == nextDate.year and curDate.month >= self.onmonth then
			nextDate.year = nextDate.year + 1
		end
		nextDate.month = self.onmonth
	end

	-- if on last key set
	if self.onlast then
		-- if onlast day of month
		local t = os.time({
			year = nextDate.year,
			month = nextDate.month + 1,
			day = 1,
		})
		t = t - 86400
		nextDate = os.date("*t", t)

		-- if on last [day of the week]
		if self.weekday > 0 then
			local wd = nextDate.wday == 1 and 7 or (nextDate.wday - 1)
			local offset = self.weekday - wd
			if offset > 0 then
				offset = offset - 7
			end
			nextDate.day = nextDate.day + offset
		end
		return os.time(nextDate)
	end

	-- if on specified weekday (no last key)
	if self.weekday > 0 then
		local t = os.time({
			year = nextDate.year,
			month = nextDate.month,
			day = self.wdcount > 0 and 1 or nextDate.day,
		})
		local target = os.date("*t", t)
		local wd = target.wday == 1 and 7 or (target.wday - 1)
		local offset = self.weekday - wd
		if offset < 0 then
			offset = offset + 7
		end

		if self.wdcount < 1 then
			target.day = target.day + offset
		else
			target.day = 1 + offset + 7 * (self.wdcount - 1)
		end

		nextDate = target
		return os.time(nextDate)
	end

	-- no weekday specified, then wdcount - for day of the month
	if self.wdcount > 0 then
		nextDate.day = self.wdcount
	end

	return os.time(nextDate)
end

--- creates Words table from text
---@param opts table {text string, lower boolean}
---@return obsidian-tasks.Words
M.getWords = function(opts)
	local w = Words.new(opts)
	return w
end

---@return obsidian-tasks.Recur
M.newRecur = function()
	return Recur.new()
end

--- parses given recurence string
---@param text string
---@return obsidian-tasks.Recur|nil Recur
M.parseRecurString = function(text)
	local r = Recur.new()
	local words = Words.new({ text = text, lower = true })
	if words:next() ~= "every" then
		return nil
	end

	local next = nil

	-- case number of periods given
	next = words:expectNumber()
	if next ~= nil then
		r.count = next
	end

	next = words:next()

	if periodWords[next] then
		-- case every period (week|month etc)
		r.period = periodWords[next]
	else
		-- case every [weekday] or [month]
		r:setWeekMonth(next)
	end

	next = words:next()
	if next ~= "on" then
		return r
	end

	next = words:expectNumber()
	if next ~= nil then
		r.wdcount = next
	end
	next = words:next()
	if next == "" then
		return r
	end
	if next ~= "the" then
		r:setWeekMonth(next)
	end

	next = words:expectNumber()
	if next ~= nil then
		r.wdcount = next
	end

	next = words:next()
	if next == "" then
		return r
	end
	if next == "last" then
		r.onlast = true
	else
		r:setWeekMonth(next)
	end

	next = words:next()
	if next == "" then
		return r
	end

	r:setWeekMonth(next)

	return r
end

return M
