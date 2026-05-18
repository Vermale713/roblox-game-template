--[=[

	InputController.luau
	Handles the input from the client
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Loader = require(ReplicatedStorage.utilities.Loader)

-- TYPES
type ContextOptions = {
	priority: number?,
	sink: boolean?,
	enabled: boolean?,
}

type ActionOptions = {
	type: Enum.InputActionType?,
	enabled: boolean?,
	onPressed: () -> ()?,
	onReleased: () -> ()?,
	onChanged: (value: any) -> ()?,
}

type BindingOptions = {
	keycode: Enum.KeyCode,
}

-- PRIVATE STATE
local _contextFolder: Folder
local _contexts: { [string]: InputContext } = {}

local InputController = {}
Loader.register("InputController", {
	Module = InputController,
	Dependencies = {},
})

function InputController.onInit()
	local folder = Instance.new("Folder")
	folder.Name = "inputs"
	folder.Parent = ReplicatedStorage

	_contextFolder = folder
end

--[=[
	Returns an existing InputContext by name.

	Errors if no context with the given name has been created.

	@param name - The name passed to InputController.createContext.
	@return InputContext
	@error "InputContext not found" -- Thrown when no context with 'name' exists.
]=]
function InputController.getContext(name: string): InputContext
	local context = _contexts[name]
	assert(context and context:IsA("InputContext"), "InputContext not found")

	return context
end

--[=[
	Creates a new InputContext. and registers it internally under 'name'.

	Each controller should create exactly one context and use it for all of its actions.

	@param name - A unique identifier for the context.
	@param options -- ContextOptions
	@return InputContext
]=]
function InputController.createContext(name: string, options: ContextOptions): InputContext
	options = options or {} :: ContextOptions

	local context = Instance.new("InputContext")
	context.Priority = options.priority or 0
	context.Sink = options.sink or false
	context.Enabled = if options.enabled ~= nil then options.enabled else true
	context.Name = name

	context.Parent = _contextFolder

	_contexts[name] = context

	return context
end

function InputController.createAction(context: InputContext, name: string, options: ActionOptions): InputAction
	options = options or {} :: ActionOptions

	local action = Instance.new("InputAction")
	action.Name = name
	action.Type = options.type or Enum.InputActionType.Bool
	action.Enabled = if options.enabled ~= nil then options.enabled else true
	action.Parent = context

	if options.onPressed then
		action.Pressed:Connect(options.onPressed)
	end
	if options.onReleased then
		action.Released:Connect(options.onReleased)
	end
	if options.onChanged then
		action.Changed:Connect(options.onChanged)
	end

	return action
end

function InputController.addBinding(
	action: InputAction,
	name: "Keyboard" | "Gamepad",
	options: BindingOptions
): InputBinding
	local binding = Instance.new("InputBinding")
	binding.Name = name
	binding.KeyCode = options.keycode
	binding.Parent = action

	return binding
end

function InputController.addUIBinding(action: InputAction, guiButton: GuiButton): InputBinding
	local binding = Instance.new("InputBinding")
	binding.Name = "Touch"
	binding.UIButton = guiButton
	binding.Parent = action

	return binding
end

function InputController.isPressed(action: InputAction): boolean
	if action.Type ~= Enum.InputActionType.Bool then
		warn("isPressed() can only be called on actions with Bool type Actions")
		return false
	end

	return action:GetState() == true
end

function InputController.destroyContext(name: string): ()
	local context = _contexts[name]
	context:Destroy()
	_contexts[name] = nil
end

return InputController
