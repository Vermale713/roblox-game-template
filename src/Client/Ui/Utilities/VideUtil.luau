-- IMPORTED MODULES
const PlayerDataStore = require "@game/ReplicatedStorage/Client/Shared/Stores/PlayerDataStore"
const DataTemplate = require "@game/ReplicatedStorage/Data/Templates/DataTemplate"
const Charm = require "@game/ReplicatedStorage/Packages/Charm"
const Vide = require "@game/ReplicatedStorage/Packages/Vide"

-- TYPES
type PlayerData = DataTemplate.PlayerData

-- ALIASES
const action = Vide.action
const computed = Charm.computed

-- PUBLIC MODULE
const VideUtil = {}

function VideUtil.Tag(tag: string)
	return action(function(instance: Instance)
		instance:AddTag(tag)
	end)
end

function VideUtil.GetPlayerDataComputed(userId: number)
	const data = computed(function()
		return PlayerDataStore.GetAll()[tostring(userId)] or DataTemplate
	end)

	return data
end

function VideUtil.GetLocalPlayerDataComputed()
	const data = computed(function()
		return PlayerDataStore.GetLocal() or DataTemplate
	end)

	return data
end

return VideUtil
