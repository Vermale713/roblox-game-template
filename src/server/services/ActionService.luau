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
local _actions: { [string]: ActionDefinition } = {}
local _activePlayerActions: { [Player]: { [string]: ActionInstance } } = {}

-- PRIVATE FUNCTIONS
const function onUserAdded(user: User)
	local player = user.Player
	_activePlayerActions[player] = {}
end

const function onUserRemoving(user: User)
	local player = user.Player
	_activePlayerActions[player] = nil
end

const function onCharacterRemoving(character: Character)
	local model = character.Model
	local player = Players:GetPlayerFromCharacter(model)
	if not player then
		return
	end
	local activeActions = _activePlayerActions[player]

	for actionName, actionDefinition in activeActions do
		local action = _actions[actionName]
		action.stop(character)
	end

	table.clear(_activePlayerActions[player])
end

const function onActionEventRequest(player: Player, payload: ActionPayload)
	local actionName = payload.Action
	local actionType = payload.Type
	local playerActions = _activePlayerActions[player]
	local action = _actions[actionName]
	local character = CharacterService.Characters[player]

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
				local definition = _actions[actionInstance.Name]
				if not definition.CheckedByOthers then
					continue
				end

				return
			end
		end

		local function contextStopAction()
			local character = CharacterService.Characters[player]
			if not character then
				return
			end

			playerActions[actionName] = nil

			action.stop(character)
		end

		local context: ActionContext = {
			stop = contextStopAction,
		}

		local actionInstance: ActionInstance = {
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
local ActionService = {}
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
	local opts: ActionDefinition = options :: ActionDefinition
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
