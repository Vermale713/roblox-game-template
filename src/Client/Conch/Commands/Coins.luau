-- IMPORTED MODULES
const Conch = require "@game/ReplicatedStorage/Packages/Conch"
const PlayerDataStore = require "@game/ReplicatedStorage/Client/Store/PlayerDataStore"

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
