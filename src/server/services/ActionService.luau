--[=[
	ActionService.luau
	Handles all actions of users
]=]

-- SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- IMPORTED MODULES
const GlobalTypes = require(ReplicatedStorage.types.GlobalTypes)
const NetworkTypes = require(ReplicatedStorage.types.NetworkTypes)
const Server = require(ServerScriptService.network.Server)
const CharacterService = require(ServerScriptService.services.CharacterService)
const UserService = require(ServerScriptService.services.UserService)
const Loader = require(ReplicatedStorage.utilities.Loader)

-- TYPES
type User = UserService.User
type Character = CharacterService.Character
type Partial<T> = GlobalTypes.Partial<T>

export type ActionDefinition = {
	Name: string, -- Name of the action
	CheckForActives: boolean, -- Checks other actions for if its activated or not
	CheckedByOthers: boolean, -- Allows to be checked by other actions
	Interruptable: boolean,
	-- Methods
	start: (ctx: ActionContext, character: Character) -> (),
	stop: (character: Character) -> (),
}

export type ActionContext = {
	stop: () -> (),
}

type ActionInstance = {
	Name: string,
	StartedAt: number,
}

type ActionPayload = NetworkTypes.Action_ActionEvent

-- PRIVATE STATE
const _actions: { [string]: ActionDefinition } = {}
const _activePlayerActions: { [Player]: { [string]: ActionInstance } } = {}

-- PRIVATE FUNCTIONS
const function onUserAdded(user: User)
	const player = user.Player
	_activePlayerActions[player] = {}
end

const function onUserRemoving(user: User)
	const player = user.Player
	_activePlayerActions[player] = nil
end

const function onCharacterRemoving(character: Character)
	const model = character.Model
	const player = Players:GetPlayerFromCharacter(model)
	if not player then
		return
	end
	const activeActions = _activePlayerActions[player]

	for actionName, actionDefinition in activeActions do
		const action = _actions[actionName]
		action.stop(character)
	end

	table.clear(_activePlayerActions[player])
end

const function onActionEventRequest(player: Player, payload: ActionPayload)
	const actionName = payload.Action
	const actionType = payload.Type
	const playerActions = _activePlayerActions[player]
	const action = _actions[actionName]
	const character = CharacterService.Characters[player]

	if not character then
		-- Can't run action if no character exists
		return
	end

	if not action then
		warn(`[ActionService] Action not found: {actionName}`)
		return
	end

	if actionType == "Start" then
		if action.CheckForActives then
			for _, actionInstance in playerActions do
				const definition = _actions[actionInstance.Name]
				if not definition.CheckedByOthers then
					continue
				end

				return
			end
		end

		const function contextStopAction()
			const character = CharacterService.Characters[player]
			if not character then
				return
			end

			playerActions[actionName] = nil

			action.stop(character)
		end

		const context: ActionContext = {
			stop = contextStopAction,
		}

		const actionInstance: ActionInstance = {
			Name = actionName,
			StartedAt = os.time(),
		}
		playerActions[actionName] = actionInstance

		-- start action
		action.start(context, character)
	else
		playerActions[actionName] = nil

		-- stop action
		action.stop(character)
	end

	-- Notify other clients that this action had an event
	Server.Action.NotifyActionEvent.fireExcept(player, payload)
end

-- PUBLIC MODULE
const ActionService = {}
Loader.register("ActionService", {
	Module = ActionService,
	Dependencies = { "UserService", "CharacterService" },
})

function ActionService.onInit()
	UserService.UserAdded:Connect(onUserAdded)
	UserService.UserRemoving:Connect(onUserRemoving)
	CharacterService.CharacterRemoving:Connect(onCharacterRemoving)
	Server.Action.RequestActionEvent.on(onActionEventRequest)
end

function ActionService.defineAction(options: Partial<ActionDefinition>): ()
	const opts: ActionDefinition = options :: ActionDefinition
		or {
			Name = options.Name,
			CheckForActives = options.CheckForActives or true,
			CheckedByOthers = options.CheckedByOthers or true,
			Interruptable = options.Interruptable or false,

			start = options.start,
			stop = options.stop,
		} :: ActionDefinition

	if not opts.Name then
		warn(`[ActionService] Action needs to be defined with a name`)
		return
	end

	if _actions[opts.Name] then
		warn(`[ActionService] Action already exists with the name: {opts.Name}`)
		return
	end
	_actions[opts.Name] = opts
end

return ActionService
