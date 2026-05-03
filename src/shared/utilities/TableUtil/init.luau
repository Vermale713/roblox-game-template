--[=[
	TableUtil.luau
	A module for table manipulation
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Immutable = require(ReplicatedStorage.utilities.TableUtil.Immutable)

local TableUtil = {}

TableUtil.Immutable = Immutable

return TableUtil
