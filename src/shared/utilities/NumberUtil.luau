--[=[
	NumberUtil.luau
	A module for number manipulation or formatting
]=]

-- PUBLIC MODULE
const NumberUtil = {}

function NumberUtil.truncate(num: number, decimals: number?)
	const factor = 10 ^ (decimals or 0)
	return math.floor(num * factor) / factor
end

return NumberUtil
