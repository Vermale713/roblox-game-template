-- SERVICES
const LogService = game:GetService "LogService"
const Players = game:GetService "Players"

-- IMPORTED MODULES
const TypeForge = require "@game/ReplicatedStorage/Packages/TypeForge"
const TableUtil = require "@game/ReplicatedStorage/Utilities/TableUtil"
const PlayerService = require "@game/ServerScriptService/Shared/Services/PlayerService"
const Example = require "@game/ServerScriptService/Shared/StatusEffects/Example"
const PlayerDataStore = require "@game/ServerScriptService/Store/PlayerDataStore"

-- TYPES
type Required<T> = TypeForge.Required<T>
type StatusEffects = { [string]: ActiveStatusEffect }

export type StatusEffectData = {
	Id: string,
	OverrideRule: "Ignore" | "Override",
	ApplyType: "PersistOnDeath" | "ClearOnDeath",
	Duration: number, -- seconds
}

export type StatusEffectInterface = {
	Data: StatusEffectData,
	ModifyDamage: (number) -> number,
	ModifyHeal: (number) -> number,
}

export type ActiveStatusEffect = {
	StartTime: number,
	EndTime: number,
}

export type DefaultCharacterProps = {
	MaxHealth: number?,
	WalkSpeed: number?,
	StatusEffects: StatusEffects?,
}

export type CharacterState = Required<DefaultCharacterProps> & {
	Health: number,
	StatusEffects: StatusEffects,
	Humanoid: Humanoid, -- Purely for syncing
}

-- CONSTANTS
const STATUS_EFFECTS = {
	Example = Example,
}

-- PRIVATE STATE
const _characterStates: { [Model]: CharacterState } = {}
const _effectThreads: { [Player | Model]: { [string]: thread } } = {}

-- PRIVATE FUNCTIONS
const function onPlayerAdded(player: Player)
	-- TODO
	_effectThreads[player] = {}
end

const function onPlayerRemoving(player: Player)
	const playerEffectThreads = _effectThreads[player]

	for _, thread in playerEffectThreads do
		task.cancel(thread)
	end
end

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

	const health = defaultProps.MaxHealth or 100
	const walkSpeed = defaultProps.WalkSpeed or 16
	const statusEffects = defaultProps.StatusEffects or {}

	-- modify with state

	const state = {
		MaxHealth = health,
		Health = health,
		WalkSpeed = walkSpeed,
		StatusEffects = statusEffects,
		Humanoid = humanoid,
	}

	syncHumanoidWithState(state)

	_characterStates[rig] = state
	_effectThreads[rig] = {}
end

const function unregisterCharacterState(rig: Model)
	_characterStates[rig] = nil

	for _, thread in _effectThreads[rig] do
		task.cancel(thread)
	end

	_effectThreads[rig] = nil
end

-- PUBLIC MODULE
const CombatService = {}

CombatService.Dependencies = { "PlayerService" }

CombatService.StatusEffects = STATUS_EFFECTS

-- Export so other services can register their own characters
-- like npcs/monsters
CombatService.Register = registerCharacterState
CombatService.Unregister = unregisterCharacterState

function CombatService.OnInit()
	PlayerService.PlayerAdded:Connect(onPlayerAdded)
	PlayerService.PlayerRemoving:Connect(onPlayerRemoving)
end

function CombatService.ApplyStatus(rig: Model, status: StatusEffectInterface)
	const effectData = status.Data

	const state = _characterStates[rig]
	if not state then
		LogService:Warn(
			"[CombatService] Attempted to apply status effect to a non existing character: {name}",
			{ name = rig.Name }
		)
		return
	end

	const hasExistingStatus = CombatService.HasStatusEffect(rig, status)

	-- Overrides
	-- TODO implement more than just Ignore
	if effectData.OverrideRule == "Ignore" and hasExistingStatus then
		return
	end

	const isIndefinite = effectData.Duration <= -1

	const startTime = os.time()
	const endTime = if isIndefinite then math.huge else startTime + effectData.Duration

	if effectData.ApplyType == "PersistOnDeath" then
		-- save to player data
		const player = Players:GetPlayerFromCharacter(rig)
		if not player then
			LogService:Warn(
				"[CombatService] Attempted to apply a PersistOnDeath status effect to a non player: {name}",
				{ name = rig.Name }
			)
			return
		end

		PlayerDataStore.Update(player.UserId, function(data)
			const effects = data.StatusEffects :: { [string]: ActiveStatusEffect }

			return TableUtil.Set(
				data,
				"StatusEffects",
				TableUtil.Set(
					effects,
					effectData.Id,
					{
						StartTime = startTime,
						EndTime = endTime,
					} :: ActiveStatusEffect
				)
			)
		end)

		if not isIndefinite then
			const effectThread = task.delay(effectData.Duration, function()
				PlayerDataStore.Update(player.UserId, function(data)
					const effects = data.StatusEffects

					return TableUtil.Set(data, "StatusEffects", TableUtil.Remove(effects, effectData.Id))
				end)
				state.StatusEffects[effectData.Id] = nil
				_effectThreads[player][effectData.Id] = nil
			end)

			_effectThreads[player][effectData.Id] = effectThread
		end
	else
		if not isIndefinite then
			const effectThread = task.delay(effectData.Duration, function()
				state.StatusEffects[effectData.Id] = nil
				_effectThreads[rig][effectData.Id] = nil
			end)

			_effectThreads[rig][effectData.Id] = effectThread
		end
	end

	TableUtil.Set(
		state.StatusEffects,
		effectData.Id,
		{
			StartTime = startTime,
			EndTime = endTime,
		} :: ActiveStatusEffect
	)

	-- Sync humanoid state
	syncHumanoidWithState(state)
end

function CombatService.RemoveStatusEffect(rig: Model, status: StatusEffectInterface)
	const effectData = status.Data

	const state = _characterStates[rig]
	if not state then
		LogService:Warn(
			"[CombatService] Attempted to remove a status effect on a non existing character: {name}",
			{ name = rig.Name }
		)
		return
	end

	state.StatusEffects[effectData.Id] = nil
	const rigThread = _effectThreads[rig][effectData.Id]
	if rigThread then
		task.cancel(rigThread)
	end

	if effectData.ApplyType == "PersistOnDeath" then
		const player = Players:GetPlayerFromCharacter(rig)
		if not player then
			LogService:Warn(
				"[CombatService] Attempted to remove a PersistOnDeath status effect from a non player: {name}",
				{ name = rig.Name }
			)
			return
		end

		PlayerDataStore.Update(player.UserId, function(data)
			const effects = data.StatusEffects :: { [string]: ActiveStatusEffect }

			return TableUtil.Set(data, "StatusEffects", TableUtil.Remove(effects, effectData.Id))
		end)

		const playerThread = _effectThreads[player][effectData.Id]
		if playerThread then
			task.cancel(playerThread)
		end
	end

	syncHumanoidWithState(state)
end

function CombatService.HasStatusEffect(rig: Model, status: StatusEffectInterface)
	const effectData = status.Data

	const state = _characterStates[rig]
	if not state then
		LogService:Warn(
			"[CombatService] Attempted to check the existence of a status effect on a non existing character: {name}",
			{ name = rig.Name }
		)
		return false
	end

	return state.StatusEffects[effectData.Id] ~= nil
end

function CombatService.Damage(rig: Model, info: { Amount: number }): ()
	-- TODO
	-- expand upon this
	const state = _characterStates[rig]
	if not state then
		return
	end

	-- TODO
	local damage = info.Amount
	for statusId, _ in state.StatusEffects do
		const statusInterface = STATUS_EFFECTS[statusId :: keyof<typeof(STATUS_EFFECTS)>] :: StatusEffectInterface
		if statusInterface.ModifyDamage then
			damage = statusInterface.ModifyDamage(damage)
		end
	end

	state.Health = math.clamp(state.Health - damage, 0, state.MaxHealth)
	syncHumanoidWithState(state)
end

function CombatService.Heal(rig: Model, info: { Amount: number }): ()
	-- TODO
	-- expand upon this
	const state = _characterStates[rig]
	if not state then
		return
	end

	-- TODO
	local heal = info.Amount
	for statusId, _ in state.StatusEffects do
		const statusInterface = STATUS_EFFECTS[statusId :: keyof<typeof(STATUS_EFFECTS)>] :: StatusEffectInterface
		if statusInterface.ModifyDamage then
			heal = statusInterface.ModifyHeal(heal)
		end
	end

	state.Health = math.clamp(state.Health + heal, 0, state.MaxHealth)
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
