-- PRIVATE STATE
const _activeDebounces: { [any]: number | boolean } = {}

-- PUBLIC MODULE
const Debounce = {}

function Debounce.Attempt(key: any, cooldown: number?): boolean
	if _activeDebounces[key] then
		return false
	end

	if not cooldown then
		_activeDebounces[key] = true
		return true
	end

	const expiry = os.clock() + cooldown
	_activeDebounces[key] = expiry

	task.delay(cooldown, function()
		if _activeDebounces[key] == expiry then
			_activeDebounces[key] = nil
		end
	end)

	return true
end

function Debounce.IsOnCooldown(key: any): boolean
	return _activeDebounces[key] ~= nil
end

function Debounce.GetRemaining(key: any): number
	const expiry = _activeDebounces[key]
	if typeof(expiry) ~= "number" then
		return 0
	end
	return math.max(0, expiry - os.clock())
end

function Debounce.Clear(key: any): ()
	_activeDebounces[key] = nil
end

return Debounce
