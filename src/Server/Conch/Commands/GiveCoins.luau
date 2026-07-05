-- IMPORTED MODULES
const Conch = require "@game/ReplicatedStorage/Packages/Conch"
const TableUtil = require "@game/ReplicatedStorage/Utilities/TableUtil"
const PlayerDataStore = require "@game/ServerScriptService/Store/PlayerDataStore"

-- PUBLIC MODULE
-- registers `givecoins <player> <amount>`; gated behind the "manage_coins"
-- permission and mutates the replicated PlayerData store
return function()
	Conch.register("givecoins", {
		permissions = { "manage_coins" },
		description = "Gives coins to a player.",
		arguments = function()
			return Conch.args.player("player", "Player to receive the coins"),
				Conch.args.number("amount", "Number of coins to give")
		end,
		callback = function(player: Player, amount: number)
			PlayerDataStore.Update(player.UserId, function(current)
				return TableUtil.Set(current, "Coins", current.Coins + amount)
			end)
			Conch.log("success", `Gave {amount} coins to {player.DisplayName}.`)
		end,
	})
end
