-- PUBLIC MODULE
const ConchRegistrar = {}

-- requires every command module directly under `container` and runs it; each
-- command module returns a function that registers its command via `Conch`
-- (see src/Server/Conch/Commands for examples)
function ConchRegistrar.RegisterFolder(container: Instance)
	for _, module in container:GetChildren() do
		if not module:IsA "ModuleScript" then
			continue
		end

		const register = require(module) :: () -> ()
		register()
	end
end

return ConchRegistrar
