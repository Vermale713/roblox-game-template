--[=[
	NumberUtil.luau
	A module for number manipulation or formatting
]=]

-- SERVICES
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
-- local Immutable = require(ReplicatedStorage.utilities.TableUtil.Immutable)

local NumberUtil = {}

function NumberUtil.truncate(num: number, decimals: number?)
	local factor = 10 ^ (decimals or 0)
	return math.floor(num * factor) / factor
end

return NumberUtil
