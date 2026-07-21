-- SERVICES
const Players = game:GetService "Players"
const ReplicatedStorage = game:GetService "ReplicatedStorage"

-- IMPORTED MODULES
const Scaler = require "@game/ReplicatedStorage/Client/Ui/Components/Scaler"
const Vide = require "@game/ReplicatedStorage/Packages/Vide"

-- TYPES
type Source<T> = Vide.Source<T>
type LayerChildren = Source<{ () -> Instance }>

-- ALIASES
const create = Vide.create
const mount = Vide.mount
const source = Vide.source
const values = Vide.values

-- CONSTANTS
const HUD_DISPLAY_ORDER = 1000
const MENU_DISPLAY_ORDER = 2000
const MODAL_DISPLAY_ORDER = 3000

-- PRIVATE STATE
local _styleSheet: StyleSheet
const _huds: LayerChildren = source {}
const _menus: LayerChildren = source {}
const _modals: LayerChildren = source {}

-- PRIVATE FUNCTIONS
const function mountUiToLayer(layer: LayerChildren, fn: () -> Instance)
	const currentLayer = layer()
	table.insert(currentLayer, fn)
	layer(currentLayer)
end

const function layer(name: string, zindex: number, children: LayerChildren)
	return create "Frame" {
		Name = name,
		ZIndex = zindex,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),

		values(children, function(component, _index)
			return component()
		end),
	}
end

const function app()
	return create "ScreenGui" {
		Name = "MainUi",

		layer("Hud", HUD_DISPLAY_ORDER, _huds),
		layer("Menu", MENU_DISPLAY_ORDER, _menus),
		layer("Modal", MODAL_DISPLAY_ORDER, _modals),

		create "StyleLink" {
			StyleSheet = _styleSheet,
		},

		Scaler(),
	}
end

-- PUBLIC MODULE
const UiController = {}

UiController.StyleSheet = _styleSheet

function UiController.OnInit()
	const designFolder = ReplicatedStorage:FindFirstChild "Design" :: Folder
	_styleSheet = designFolder:FindFirstChild "Main" :: StyleSheet

	Vide.defaults = false

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
