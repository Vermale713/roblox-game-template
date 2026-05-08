--[=[
	UserService.luau
	Handles creating the user and related data
]=]

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- IMPORTED MODULES
local Server = require(ServerScriptService.network.Server)
local PlayerData = require(ReplicatedStorage.data.templates.PlayerData)
local Charm = require(ReplicatedStorage.packages.Charm)
local CharmSync = require(ReplicatedStorage.packages.CharmSync)
local ProfileStore = require(ServerScriptService.serverPackages.ProfileStore)
local SaveStore = require(ServerScriptService.store.SaveStore)
local Signal = require(ReplicatedStorage.packages.Signal)
local Loader = require(ReplicatedStorage.utilities.Loader)

-- CONSTANTS
local STORE_KEY = "PlayerStore"

-- TYPES
export type User = {
	Player: Player,
	Permissions: "guest" | "super-user",
	Profile: ProfileStore.Profile<PlayerData.PlayerData>,
}

-- PRIVATE STATE
local _profileStore =
	ProfileStore.New(STORE_KEY, PlayerData :: never).Mock :: ProfileStore.ProfileStore<PlayerData.PlayerData>
local _users: { [Player]: User } = {}
local _userAdded = Signal.new() :: Signal.Signal<User>
local _userRemoving = Signal.new() :: Signal.Signal<User>

-- PRIVATE FUNCTIONS
local function onPlayerAdded(player: Player)
	if _users[player] then
		-- Player might have not been cleaned up properly
		player:Kick("Preexisting user - Please rejoin")
		return
	end

	local profile = _profileStore:StartSessionAsync(`{player.UserId}`, {
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

	local charmListener = Charm.computed(function()
		return SaveStore.GetSave(player.Name)
	end)

	SaveStore.SetSaveData(player.Name, profile.Data)

	Charm.subscribe(charmListener, function(state: PlayerData.PlayerData)
		-- ProfileStore has wacky types so we have to cast
		profile.Data = state :: any
	end)

	local sessionStart = os.time()

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

	if player:IsDescendantOf(Players) then
		local role = if player.UserId == 2600715546 then "super-user" else "guest"

		_users[player] = {
			Player = player,
			Permissions = role,
			Profile = profile,
		}

		CharmSync.server.addSignalsToClient(player, {
			[`UserData-{player.Name}`] = charmListener,
		})
	else
		profile:EndSession()
	end

	_userAdded:Fire(_users[player])
end

local function onPlayerRemoving(player: Player)
	local user = _users[player]
	if not user then
		-- Player left before user was created
		return
	end

	_userRemoving:Fire(user)
end

-- PUBLIC MODULE
local UserService = {}
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
	CharmSync.server.connect(function(player, patches)
		Server.User.Sync.fire(player, patches)
	end)
end

function UserService.onStart()
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return UserService
