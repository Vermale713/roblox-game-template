--[=[
	Chance.luau
	Handles all rng related subjects
]=]

-- PRIVATE STATE
local _rng = Random.new()

-- PUBLIC MODULE
local Rng = {}

function Rng.roll(weight: number?): boolean
	return _rng:NextNumber() < (weight or 0.5)
end

function Rng.float(min: number, max: number): number
	assert(min < max, "min must be less than max")
	return _rng:NextNumber(min, max)
end

function Rng.int(min: number, max: number): number
	assert(min < max, "min must be less than max")
	return _rng:NextInteger(min, max)
end

function Rng.weighted(options: { { item: any, weight: any } })
	assert(#options > 0, "options cannot be empty")

	local total = 0
	for _, option in options do
		total += option.weight
	end

	local roll = _rng:NextNumber(0, total)
	local cumulative = 0
	for _, option in options do
		cumulative += option.weight
		if roll <= cumulative then
			return option.item
		end
	end

	-- edge case should never happen
	warn("edge case in weighted()")
	return options[#options].item
end

return Rng
