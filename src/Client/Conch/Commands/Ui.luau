-- IMPORTED MODULES
const Conch = require "@game/ReplicatedStorage/Packages/Conch"
const UiStore = require "@game/ReplicatedStorage/Client/Store/Ui"

-- PUBLIC MODULE
-- registers `ui`; drives the local UI store for quick testing:
--   ui hud <on|off>    show/hide the HUD layer
--   ui menu <name>     set the active menu (see MENU_NAMES)
return function()
	Conch.register("ui", {
		permissions = {},
		description = "Controls the local UI: `ui hud <on|off>` or `ui menu <name>`.",
		arguments = function()
			return Conch.args.string("action", "hud or menu"),
				Conch.args.string("value", "on/off for hud, or a menu name")
		end,
		callback = function(action: string, value: string)
			if action == "hud" then
				if value == "on" then
					UiStore.SetHudVisible(true)
				elseif value == "off" then
					UiStore.SetHudVisible(false)
				else
					Conch.log("error", "Usage: ui hud <on|off>")
				end
			elseif action == "menu" then
				if not UiStore.TrySetActiveMenu(value) then
					Conch.log("error", `Unknown menu '{value}'. Options: {table.concat(UiStore.MenuNames, ", ")}`)
				end
			else
				Conch.log("error", "Usage: ui <hud|menu> ...")
			end
		end,
	})
end
