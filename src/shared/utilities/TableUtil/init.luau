--[=[
    TableUtil.luau
    A utility for all table related manipulation
]=]

-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const Dictionary = require(ReplicatedStorage.utilities.TableUtil.Dictionary)

-- PUBLIC MODULE
const TableUtil = {}

TableUtil.Dictionary = Dictionary

return TableUtil
