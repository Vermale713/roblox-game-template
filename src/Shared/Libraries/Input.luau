-- SERVICES
const LogService = game:GetService "LogService"
const ReplicatedStorage = game:GetService "ReplicatedStorage"

-- TYPES
type InputImpl = {
	__index: InputImpl,
	new: (string) -> Input,
	SetPriority: (Input, number) -> Input,
	SetSink: (Input, boolean) -> Input,
	SetEnabled: (Input, boolean) -> Input,
	Action: (Input, string) -> Action,
}
type InputData = {
	_context: InputContext,
	_actions: { [string]: Action },
}
type ActionImpl = {
	__index: ActionImpl,
	new: (Input, string) -> Action,
	OnPressed: (Action, () -> ()) -> Action,
	OnReleased: (Action, () -> ()) -> Action,
	OnStateChanged: (Action, (any) -> ()) -> Action,
	Bind: (Action, Enum.KeyCode) -> Bind,
}
type ActionData = {
	_input: Input,
	_action: InputAction,
}
type BindImpl = {
	__index: BindImpl,
	new: (Action, Enum.KeyCode) -> Bind,
	SetType: (Bind, Enum.InputBindingType) -> Bind,
	SetModifier: (Bind, Enum.KeyCode, Enum.KeyCode?) -> Bind,
}
type BindData = {
	_action: Action,
	_bind: InputBinding,
}

export type Input = setmetatable<InputData, InputImpl>
export type Action = setmetatable<ActionData, ActionImpl>
export type Bind = setmetatable<BindData, BindImpl>

-- CONSTANTS
const INPUTS_FOLDER_NAME = "Inputs"

-- PRIVATE FUNCTIONS
const function getInputsFolder()
	local folder = ReplicatedStorage:FindFirstChild(INPUTS_FOLDER_NAME)
	if not folder then
		folder = Instance.new "Folder"
		folder.Name = INPUTS_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	return folder
end

-- PRIVATE MODULE
const Bind = {} :: BindImpl
Bind.__index = Bind

function Bind.new(action: Action, keycode: Enum.KeyCode)
	const bind = Instance.new "InputBinding"
	bind.KeyCode = keycode
	bind.Parent = action._action

	return setmetatable(
		{
			_action = action,
			_bind = bind,
		} :: BindData,
		Bind
	)
end

function Bind.SetType(self: Bind, bindType: Enum.InputBindingType)
	self._bind.Type = bindType

	return self
end

function Bind.SetModifier(self: Bind, primaryModifier: Enum.KeyCode, secondaryModifier: Enum.KeyCode?)
	self._bind.PrimaryModifier = primaryModifier

	if secondaryModifier then
		self._bind.SecondaryModifier = secondaryModifier
	end

	return self
end

const Action = {} :: ActionImpl
Action.__index = Action

function Action.new(input: Input, name)
	const action = Instance.new "InputAction"
	action.Name = name
	action.Parent = input._context

	return setmetatable(
		{
			_input = input,
			_action = action,
		} :: ActionData,
		Action
	)
end

function Action.OnPressed(self: Action, callback: () -> ())
	self._action.Pressed:Connect(callback)

	return self
end

function Action.OnReleased(self: Action, callback: () -> ())
	self._action.Released:Connect(callback)

	return self
end

function Action.OnStateChanged(self: Action, callback: (any) -> ())
	self._action.StateChanged:Connect(callback)

	return self
end

function Action.Bind(self: Action, keycode: Enum.KeyCode)
	const bind = Bind.new(self, keycode)

	return bind
end

-- PUBLIC MODULE
const Input = {} :: InputImpl
Input.__index = Input

function Input.new(name: string)
	const folder = getInputsFolder()

	const context = Instance.new "InputContext"
	context.Name = name
	context.Enabled = false
	context.Parent = folder

	return setmetatable(
		{
			_context = context,
			_actions = {},
		} :: InputData,
		Input
	)
end

function Input.SetPriority(self: Input, priority: number)
	self._context.Priority = priority

	return self
end

function Input.SetSink(self: Input, state: boolean)
	self._context.Sink = state
	return self
end

function Input.SetEnabled(self: Input, state: boolean)
	self._context.Enabled = state
	return self
end

function Input.Action(self: Input, name: string)
	if self._actions[name] then
		LogService:Warn("[Input] {name} is a duplicate entry", { name = name })
		return self._actions[name]
	end

	const action = Action.new(self, name)

	self._actions[name] = action

	return action
end

return Input
