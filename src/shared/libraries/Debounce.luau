--[=[
	Debounce.luau
	Handles debounces
]=]

-- TYPES
type DebounceImpl = {
	__index: DebounceImpl,
	new: (duration: number) -> Debounce,
	check: (self: Debounce) -> boolean,
}

type DebounceProto = {
	_duration: number,
	_ready: boolean,
}

export type Debounce = setmetatable<DebounceProto, DebounceImpl>

-- PUBLIC MODULE
const Debounce = {} :: DebounceImpl
Debounce.__index = Debounce

function Debounce.new(duration: number): Debounce
	assert(typeof(duration) == "number" and duration >= 0, "Duration must be a non-negative number")

	return setmetatable({
		_duration = duration,
		_ready = true,
	}, Debounce)
end

function Debounce.check(self: Debounce): boolean
	if not self._ready then
		return false
	end

	self._ready = false
	task.delay(self._duration, function()
		self._ready = true
	end)

	return true
end

return Debounce
