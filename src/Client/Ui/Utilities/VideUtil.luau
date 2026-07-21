-- IMPORTED MODULES
const Vide = require "@game/ReplicatedStorage/Packages/Vide"

-- ALIASES
const action = Vide.action

-- PUBLIC MODULE
const VideUtil = {}

function VideUtil.Tag(tag: string)
	return action(function(instance: Instance)
		instance:AddTag(tag)
	end)
end

return VideUtil
