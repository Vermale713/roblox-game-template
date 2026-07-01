-- IMPORTED MODULES
const Vide = require "@game/ReplicatedStorage/Packages/Vide"
const Theme = require "@game/ReplicatedStorage/Client/Ui/Theme"

-- ALIASES
const create = Vide.create

-- TYPES
type ContainerProps = {
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	[number]: any,
}

-- PUBLIC MODULE
const function Container(props: ContainerProps): Instance
	return create "Frame" {
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		BackgroundColor3 = Theme.Colors.Primary,

		table.unpack(props),
	}
end

return Container
