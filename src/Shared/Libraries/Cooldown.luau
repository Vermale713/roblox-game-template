-- PRIVATE STATE
const _activeCooldowns: { [any]: number | boolean } = {}

-- PUBLIC MODULE
const Cooldown = {}

function Cooldown.Attempt(key: any, cooldown: number?): boolean
	if _activeCooldowns[key] then
		return false
	end

	if not cooldown then
		_activeCooldowns[key] = true
		return true
	end

	const expiry = os.clock() + cooldown
	_activeCooldowns[key] = expiry

	task.delay(cooldown, function()
		if _activeCooldowns[key] == expiry then
			_activeCooldowns[key] = nil
		end
	end)

	return true
end

function Cooldown.IsOnCooldown(key: any): boolean
	return _activeCooldowns[key] ~= nil
end

function Cooldown.GetRemaining(key: any): number
	const expiry = _activeCooldowns[key]
	if typeof(expiry) ~= "number" then
		return 0
	end
	return math.max(0, expiry - os.clock())
end

function Cooldown.Clear(key: any): ()
	_activeCooldowns[key] = nil
end

return Cooldown
