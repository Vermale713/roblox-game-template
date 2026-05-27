--[=[
    TableUtil.luau
    A utility for all table related manipulation
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Dictionary = require(ReplicatedStorage.utilities.TableUtil.Dictionary)

-- PUBLIC MODULE
local TableUtil = {}

TableUtil.Dictionary = Dictionary

return TableUtil
