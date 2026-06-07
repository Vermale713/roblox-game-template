--[=[
	Chance.luau
	Handles all rng related subjects
]=]

-- PRIVATE STATE
const _rng = Random.new()

-- PUBLIC MODULE
const Rng = {}

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

function Rng.shuffle<T>(list: T & {}): T
	assert(#list > 0, "list cannot be empty")
	const copy = table.clone(list)
	for i = #copy, 2, -1 do
		const j = _rng:NextInteger(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

function Rng.pick<T>(list: { T }): T
	assert(#list > 0, "list cannot be empty")
	return list[_rng:NextInteger(1, #list)]
end

function Rng.sample<T>(list: { T }, elements: number): { T }
	assert(#list > 0, "list cannot be empty")
	assert(elements > 0, "elements must be greater than 0")
	assert(elements <= #list, "elements cannot exceed list size")
	const shuffled = Rng.shuffle(list)
	const result = {}
	for i = 1, elements do
		result[i] = shuffled[i]
	end
	return result
end

function Rng.weighted(options: { { [string]: any } }, itemKey: string, weightKey: string)
	assert(#options > 0, "options cannot be empty")

	local total = 0
	for _, option in options do
		total += option.weight
	end

	const roll = _rng:NextNumber(0, total)
	local cumulative = 0
	for _, option in options do
		cumulative += option[weightKey]
		if roll <= cumulative then
			return option[itemKey]
		end
	end

	-- edge case should never happen
	warn("edge case in weighted()")
	return options[#options].item
end

return Rng
