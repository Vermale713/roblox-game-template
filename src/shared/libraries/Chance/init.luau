--[=[
	Chance.luau
	Handles all rng related subjects
]=]

-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const Rng = require(ReplicatedStorage.libraries.Chance.Rng)

-- PUBLIC MODULE
const Chance = {}

Chance.Rng = Rng

return Chance
