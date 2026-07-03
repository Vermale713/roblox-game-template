-- SERVICES
const Players = game:GetService "Players"
const RunService = game:GetService "RunService"
const ServerScriptService = game:GetService "ServerScriptService"

-- IMPORTED MODULES
const Conch = require "@game/ReplicatedStorage/Packages/Conch"
const ConchRegistrar = require "@game/ReplicatedStorage/Utilities/ConchRegistrar"

-- CONSTANTS
-- "super-user" is Conch's built-in role: it bypasses every permission check, so
-- admins can run any command regardless of the `permissions` it declares
const SUPER_USER_ROLE = "super-user"
-- the role every non-admin player receives; it only holds the permissions listed
-- here, so add any guest-available permission to this list (commands gate access
-- by listing a permission in their `Conch.register` call)
const GUEST_ROLE = "guest"
const GUEST_PERMISSIONS: { string } = {}
-- UserIds that receive the super-user role in live games; everyone is super-user
-- in Studio for easy testing
const ADMIN_USER_IDS: { number } = {}

-- PRIVATE FUNCTIONS
const function grantRoles(player: Player)
	const isAdmin = RunService:IsStudio() or table.find(ADMIN_USER_IDS, player.UserId) ~= nil
	const role = if isAdmin then SUPER_USER_ROLE else GUEST_ROLE
	Conch.give_roles(Conch.get_user(player), role)
end

-- PUBLIC MODULE
const ConchService = {}

function ConchService.OnInit()
	Conch.initiate_default_lifecycle()
	Conch.set_role_permissions(GUEST_ROLE, table.unpack(GUEST_PERMISSIONS))

	ConchRegistrar.RegisterFolder(ServerScriptService.Conch.Commands)

	for _, player in Players:GetPlayers() do
		grantRoles(player)
	end
	Players.PlayerAdded:Connect(grantRoles)
end

return ConchService
