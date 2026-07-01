-- IMPORTED MODULES
const Charm = require "@game/ReplicatedStorage/Packages/Charm"
const TableUtil = require "@game/ReplicatedStorage/Utilities/TableUtil"
const PlayerDataTemplate = require "@game/ReplicatedStorage/Data/Templates/PlayerData"

-- TYPES
type PlayerData = PlayerDataTemplate.PlayerData
-- keyed by tostring(userId): a string-keyed dict survives the CharmSync/remote
-- boundary unambiguously (number keys can be coerced, breaking client lookups)
type PlayerDataMap = { [string]: PlayerData }

-- PRIVATE STATE
const _getData, _setData = Charm.signal({} :: PlayerDataMap)

-- PUBLIC MODULE
const PlayerDataStore = {}

-- the getter is exposed so the replication service can register it with CharmSync
PlayerDataStore.Getter = _getData

function PlayerDataStore.Load(userId: number, data: PlayerData)
	const key = tostring(userId)
	_setData(function(state)
		return TableUtil.Set(state, key, data)
	end)
end

function PlayerDataStore.Unload(userId: number)
	const key = tostring(userId)
	_setData(function(state)
		return TableUtil.Remove(state, key)
	end)
end

function PlayerDataStore.Get(userId: number): PlayerData?
	return _getData()[tostring(userId)]
end

-- mutator should return a NEW PlayerData; mutating in place risks aliasing the
-- profile data PlayerService still holds a reference to
function PlayerDataStore.Update(userId: number, mutator: (PlayerData) -> PlayerData)
	const key = tostring(userId)
	_setData(function(state)
		const current = state[key]
		if not current then
			return state
		end

		return TableUtil.Set(state, key, mutator(current))
	end)
end

return PlayerDataStore
