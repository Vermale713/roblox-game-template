--[=[
	NumberUtil.luau
	A module for number manipulation or formatting
]=]

-- PUBLIC MODULE
local NumberUtil = {}

function NumberUtil.truncate(num: number, decimals: number?)
	local factor = 10 ^ (decimals or 0)
	return math.floor(num * factor) / factor
end

return NumberUtil
