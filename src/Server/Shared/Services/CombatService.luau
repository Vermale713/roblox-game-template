-- IMPORTED MODULES
const TypeForge = require "@game/ReplicatedStorage/Packages/TypeForge"

-- TYPES
type Required<T> = TypeForge.Required<T>

export type DefaultCharacterProps = {
	MaxHealth: number?,
	WalkSpeed: number?,
}

export type CharacterState = Required<DefaultCharacterProps> & {
	Health: number,
	StatusEffects: {},
	Humanoid: Humanoid, -- Purely for syncing
}

-- PRIVATE STATE
const _characterStates: { [Model]: CharacterState } = {}

-- PRIVATE FUNCTIONS
const function syncHumanoidWithState(state: CharacterState)
	state.Humanoid.MaxHealth = state.MaxHealth
	state.Humanoid.Health = state.Health
	state.Humanoid.WalkSpeed = state.WalkSpeed
end

const function registerCharacterState(rig: Model, defaultProps: DefaultCharacterProps)
	const humanoid = rig:FindFirstChild "Humanoid" :: Humanoid?
	const humanoidRootPart = rig:FindFirstChild "HumanoidRootPart" :: Part?

	if not humanoid or not humanoidRootPart or not rig:IsDescendantOf(workspace) then
		return
	end

	const state = {
		MaxHealth = defaultProps.MaxHealth or 100,
		Health = defaultProps.MaxHealth or 100,
		WalkSpeed = defaultProps.WalkSpeed or 16,
		StatusEffects = {},
		Humanoid = humanoid,
	}

	syncHumanoidWithState(state)

	_characterStates[rig] = state
end

const function unregisterCharacterState(rig: Model)
	_characterStates[rig] = nil
end

-- PUBLIC MODULE
const CombatService = {}

-- Export so other services can register their own characters
-- like npcs/monsters
CombatService.Register = registerCharacterState
CombatService.Unregister = unregisterCharacterState

function CombatService.ApplyStatus()
	-- LATER
end

function CombatService.Damage(rig: Model, info: { Amount: number }): ()
	-- TODO
	-- expand upon this
	const state = _characterStates[rig]
	if not state then
		return
	end

	state.Health = math.clamp(state.Health - info.Amount, 0, state.MaxHealth)
	syncHumanoidWithState(state)
end

function CombatService.Heal(rig: Model, info: { Amount: number }): ()
	-- TODO
	-- expand upon this
	const state = _characterStates[rig]
	if not state then
		return
	end

	state.Health = math.clamp(state.Health + info.Amount, 0, state.MaxHealth)
	syncHumanoidWithState(state)
end

function CombatService.IsAlive(rig: Model): boolean
	const state = _characterStates[rig]
	if not state then
		return false
	end

	return state.Health > 0
end

return CombatService
