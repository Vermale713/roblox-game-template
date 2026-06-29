-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"

-- IMPORTED MODULES
const Conch = require(ReplicatedStorage.Packages.Conch)
const PlayerDataStore = require(ReplicatedStorage.Client.Store.PlayerData)

-- PUBLIC MODULE
-- registers `coins`; reads the local player's replicated coin count
return function()
	Conch.register("coins", {
		permissions = {},
		description = "Shows your current coin count.",
		arguments = function() end,
		callback = function()
			const data = PlayerDataStore.GetLocal()
			const coins = if data then data.Coins else 0
			Conch.log("info", `You have {coins} coins.`)
		end,
	})
end
