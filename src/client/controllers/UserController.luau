--[=[
	UserController.luau
	Handles creating the user and related data
]=]

-- SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const Client = require(ReplicatedStorage.client.network.Client)
const CharmSync = require(ReplicatedStorage.packages.CharmSync)
const SaveStore = require(ReplicatedStorage.client.store.SaveStore)
const Loader = require(ReplicatedStorage.utilities.Loader)

-- CONSTANTS

-- TYPES
type SyncPayload = CharmSync.SyncPayload

-- PRIVATE STATE

-- PRIVATE FUNCTIONS
local function onSync(patches: { SyncPayload })
	CharmSync.client.patch(patches)
end

-- PUBLIC MODULE
local UserController = {}
Loader.register("UserController", {
	Module = UserController,
	Dependencies = {},
})

function UserController.onInit()
	CharmSync.client.addSignals({
		[`User-{Players.LocalPlayer.Name}`] = SaveStore.SetSave,
	})
	Client.User.Sync.on(onSync)
end

return UserController
