--!strict
-- SERVICES
const Players = game:GetService "Players"

-- IMPORTED MODULES
const Scythe = require "@pkg/Scythe"
const Signal = require "@pkg/Signal"
const PlayerService = require "@server/Player/PlayerService"

-- TYPES
type Signal<T...> = Signal.Signal<T...>
type ScytheScope = Scythe.Scope

-- PRIVATE STATE
const _playerCleaners: { [Player]: ScytheScope } = {}
const _characterAdded: Signal<Player, Model> = Signal.new()
const _characterRemoving: Signal<Player, Model> = Signal.new()

-- PRIVATE FUNCTIONS
const function onCharacterAdded(player: Player, rig: Model)
    const humanoid = rig:FindFirstChildOfClass "Humanoid"
    if not humanoid then return end

    humanoid.Died:Once(function()
        _characterRemoving:Fire(player, rig)
        task.wait(Players.RespawnTime)

        if not player:IsDescendantOf(Players) then return end

        player:LoadCharacterAsync()
    end)

    _characterAdded:Fire(player, rig)
end

const function setupCharacterConnections(player: Player)
    -- we have already setup connections for the player
    if _playerCleaners[player] then return end

    const scope = Scythe.scope()
    _playerCleaners[player] = scope

    Scythe.add(scope, player.CharacterAdded:Connect(function(rig) onCharacterAdded(player, rig) end))

    player:LoadCharacterAsync()
end

const function removeCharacterConnections(player: Player)
    const scope = _playerCleaners[player]
    if not scope then return end

    Scythe.destroy(scope)
    _playerCleaners[player] = nil
end

-- PUBLIC MODULE
const CharacterService = {}

CharacterService.CharacterAdded = _characterAdded
CharacterService.CharacterRemoving = _characterRemoving

CharacterService.Dependencies = { "PlayerService" }

function CharacterService.OnInit()
    PlayerService.PlayerJoined:Connect(setupCharacterConnections)
    PlayerService.PlayerRemoving:Connect(removeCharacterConnections)
end

return CharacterService
