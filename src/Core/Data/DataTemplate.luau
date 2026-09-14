--!strict
-- IMPORTED MODULES
const TableTypes = require "@base/TableTypes"
const Scribe = require "@pkg/Scribe"

-- TYPES
type PlayerData<T> = Scribe.PlayerData<T>
type Dictionary<T, K> = TableTypes.Dictionary<T, K>

-- PRIVATE STATE
const _joined: Dictionary<Player, number> = {}

-- PUBLIC MODULE
const DataTemplate = {
    -- Currencies
    Coins = Scribe.Int(0, { Min = 0 }),
    -- Stats
    Stats = {
        CreatedUnix = Scribe.Dynamic(os.time),
        Playtime = Scribe.Int(0, { Min = 0 }),
    },
}

return Scribe {
    Template = DataTemplate,
    ProfileStoreIndex = "DataTemplate",
    ProfileKeyPrefix = "Player_",
    -- Lifecycles
    OnPlayerInit = function(player: Player, _, isNewProfile: boolean)
        const joinTime = os.time()
        _joined[player] = joinTime
    end,
    OnPlayerLeaving = function(player: Player, data: PlayerData<typeof(DataTemplate)>, reason)
        const joinDate = _joined[player]
        if joinDate then data.Stats.Playtime.Increment(os.time() - joinDate) end
    end,
}
