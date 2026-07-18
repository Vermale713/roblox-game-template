-- CONSTANTS
const SECONDS_PER_MINUTE = 60
const SECONDS_PER_HOUR = 3600
const SECONDS_PER_DAY = 86400

-- PUBLIC MODULE
const TimeUtil = {}

TimeUtil.SecondsPerMinute = SECONDS_PER_MINUTE
TimeUtil.SecondsPerHour = SECONDS_PER_HOUR
TimeUtil.SecondsPerDay = SECONDS_PER_DAY

function TimeUtil.MinutesToSeconds(minutes: number)
	return minutes * SECONDS_PER_MINUTE
end

function TimeUtil.HoursToSeconds(hours: number)
	return hours * SECONDS_PER_HOUR
end

function TimeUtil.DaysToSeconds(days: number)
	return days * SECONDS_PER_DAY
end

return TimeUtil
