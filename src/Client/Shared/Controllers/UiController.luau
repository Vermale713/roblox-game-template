-- SERVICES
const Players = game:GetService "Players"

-- IMPORTED MODULES
const Scaler = require "@game/ReplicatedStorage/Client/Ui/Components/Scaler"
const Theme = require "@game/ReplicatedStorage/Client/Ui/Theme"
const Vide = require "@game/ReplicatedStorage/Packages/Vide"

-- TYPES
type Source<T> = Vide.Source<T>
type LayerChildren = Source<{ Instance }>

-- ALIASES
const create = Vide.create
const mount = Vide.mount
const source = Vide.source
const indexes = Vide.indexes

-- PRIVATE STATE
const _huds: LayerChildren = source {}
const _menus: LayerChildren = source {}
const _modals: LayerChildren = source {}

-- PRIVATE FUNCTIONS
const function mountUiToLayer(layer: LayerChildren, fn: () -> Instance)
	const result = fn()

	const currentLayer = layer()
	table.insert(currentLayer, result)
	layer(currentLayer)
end

const function layer(name: string, zindex: number, children: LayerChildren)
	return create "Frame" {
		Name = name,
		ZIndex = zindex,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromScale(1, 1),

		indexes(children, function(component, _index)
			return component()
		end),
	}
end

const function app()
	return create "ScreenGui" {
		Name = "MainUi",

		layer("Hud", Theme.DisplayOrder.Hud, _huds),
		layer("Menu", Theme.DisplayOrder.Menu, _menus),
		layer("Modal", Theme.DisplayOrder.Modal, _modals),

		Scaler(),
	}
end

-- PUBLIC MODULE
const UiController = {}

function UiController.OnInit()
	const playerGui = Players.LocalPlayer:FindFirstChild "PlayerGui" :: Instance

	mount(app, playerGui)
end

function UiController.MountHud(fn: () -> Instance)
	mountUiToLayer(_huds, fn)
end

function UiController.MountMenu(fn: () -> Instance)
	mountUiToLayer(_menus, fn)
end

function UiController.MountModal(fn: () -> Instance)
	mountUiToLayer(_modals, fn)
end

return UiController
