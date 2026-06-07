--[=[
	UserService.luau
	Handles creating the user and related data
]=]

-- SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- IMPORTED MODULES
const Server = require(ServerScriptService.network.Server)
const PlayerData = require(ReplicatedStorage.data.templates.PlayerData)
const Charm = require(ReplicatedStorage.packages.Charm)
const CharmSync = require(ReplicatedStorage.packages.CharmSync)
const ProfileStore = require(ServerScriptService.serverPackages.ProfileStore)
const SaveStore = require(ServerScriptService.store.SaveStore)
const AnalyticsUtil = require(ServerScriptService.utilities.AnalyticsUtil)
const DataMigrationUtil = require(ServerScriptService.utilities.DataMigrationUtil)
const Signal = require(ReplicatedStorage.packages.Signal)
const Loader = require(ReplicatedStorage.utilities.Loader)

-- CONSTANTS
const STORE_KEY = "PlayerStore"

-- TYPES
type SyncPayload = CharmSync.SyncPayload

export type User = {
	Player: Player,
	Permissions: "guest" | "super-user",
	Profile: ProfileStore.Profile<PlayerData.PlayerData>,
}

-- PRIVATE STATE
const _profileStore =
	ProfileStore.New(STORE_KEY, PlayerData :: never).Mock :: ProfileStore.ProfileStore<PlayerData.PlayerData>
const _users: { [Player]: User } = {}
const _userAdded = Signal.new() :: Signal.Signal<User>
const _userRemoving = Signal.new() :: Signal.Signal<User>

-- PRIVATE FUNCTIONS
const function onPlayerAdded(player: Player)
	if _users[player] then
		-- Player might have not been cleaned up properly
		player:Kick("Preexisting user - Please rejoin")
		return
	end

	const profile = _profileStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return not player:IsDescendantOf(Players)
		end,
	})

	if profile == nil then
		player:Kick("Profile load fail - Please rejoin")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	-- Migration
	if profile.Data.Metadata.Version < PlayerData.Metadata.Version then
		DataMigrationUtil.migrate(profile.Data)
	end

	const sessionStart = os.time()

	if profile.Data.Metadata.JoinDate == 0 then
		-- We can mutate like this because
		-- this is before initial replication
		profile.Data.Metadata.JoinDate = sessionStart
	end

	-- TODO: Test this further
	profile.OnSessionEnd:Connect(function()
		_users[player] = nil
		player:Kick()
	end)
	profile.OnLastSave:Connect(function()
		profile.Data.Metadata.LastSeen = os.time()
		profile.Data.Metadata.TotalPlaytime += os.time() - sessionStart
	end)

	const charmListener = Charm.computed(function()
		return SaveStore.GetSave(player.Name)
	end)

	SaveStore.SetSaveData(player.Name, profile.Data)

	Charm.subscribe(charmListener, function(state: PlayerData.PlayerData)
		-- ProfileStore has wacky types so we have to cast
		profile.Data = state :: any
	end)

	if player:IsDescendantOf(Players) then
		const role = if player.UserId == 2600715546 then "super-user" else "guest"

		_users[player] = {
			Player = player,
			Permissions = role,
			Profile = profile,
		}

		CharmSync.server.addSignalsToClient(player, {
			[`User-{player.Name}`] = charmListener,
		})
	else
		profile:EndSession()
	end

	AnalyticsUtil.LogOnboardingStep(player, "Joined the game")
	_userAdded:Fire(_users[player])
end

const function onPlayerRemoving(player: Player)
	const user = _users[player]
	if not user then
		-- Player left before user was created
		return
	end

	_userRemoving:Fire(user)
end

const function onSync(player: Player, patches: { SyncPayload })
	Server.User.Sync.fire(player, patches)
end

-- PUBLIC MODULE
const UserService = {}
Loader.register("UserService", {
	Module = UserService,
	Dependencies = {},
})

--[=[
	Guarantees User object exists
]=]
UserService.UserAdded = _userAdded
UserService.UserRemoving = _userRemoving
-- exported incase you need users and not Players:GetPlayers()
UserService.Users = _users

function UserService.onInit()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	CharmSync.server.connect(onSync)
end

function UserService.onStart()
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return UserService
