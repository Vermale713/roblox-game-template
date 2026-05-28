--[=[
	Chance.luau
	Handles all rng related subjects
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Rng = require(ReplicatedStorage.libraries.Chance.Rng)

-- PUBLIC MODULE
local Chance = {}

Chance.Rng = Rng

return Chance
