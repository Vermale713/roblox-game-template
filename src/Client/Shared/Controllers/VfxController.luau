-- SERVICES
const LogService = game:GetService "LogService"

-- IMPORTED MODULES
const Client = require "@game/ReplicatedStorage/Client/Network/Client"
const NetworkTypes = require "@game/ReplicatedStorage/Network/NetworkTypes"
const Signal = require "@game/ReplicatedStorage/Packages/Signal"

-- TYPES
type VfxPayload = NetworkTypes.VFX_VFXPayload
type VfxState = "Start" | "Stop"

-- ALIASES

-- CONSTANTS

-- PRIVATE STATE
const _registeredVfx: { [string]: Signal.Signal<VfxPayload, VfxState?> } = {}
const _activeVfx = {} -- for the non one shot

-- PRIVATE FUNCTIONS

-- PRIVATE MODULE

-- PUBLIC MODULE
const VfxController = {}

function VfxController.OnInit()
	Client.VFX.ReplicateVfx.On(function(payload)
		const vfxType = payload.Type
		const vfxData = payload.Data
		const name = vfxData.Name
		const vfx = _registeredVfx[name]

		if not vfx then
			LogService:Warn(
				"[VfxController] Attempted to play vfx that does not exist: {Name}",
				vfxData :: { [string]: any }
			)
		end

		if vfxType == "Sustained" then
			local state: VfxState = "Start"

			if _activeVfx[name] then
				state = "Stop"
			end

			vfx:Fire(vfxData, state)
		else
			vfx:Fire(vfxData)
		end
	end)
end

function VfxController.Register(name: string)
	if _registeredVfx[name] then
		LogService:Warn("[VfxController] Already registered {name}", { name = name })
		return
	end

	_registeredVfx[name] = Signal.new()
end

function VfxController.Connect(name: string, fn: (VfxPayload, VfxState?) -> ()): Signal.Connection
	const vfxSignal = _registeredVfx[name]
	if not vfxSignal then
		LogService:Error("[VfxController] Cannot connect to nonexistent signal: {name}", { name = name })
	end

	return vfxSignal:Connect(fn)
end

return VfxController
