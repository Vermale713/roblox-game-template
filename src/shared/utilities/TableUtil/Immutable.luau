--[=[
	Immutable.luau
	A module for immutable table updates
]=]

local Immutable = {}

function Immutable.set<T, K>(object: T & {}, key: K & keyof<T>, value: index<T, K>): T
	if object[key] ~= value then
		object = table.clone(object)
		object[key] = value
	end
	return object
end

function Immutable.delete<T>(object: T & {}, key: keyof<T>): T
	if object[key] ~= nil then
		object = table.clone(object)
		object[key] = nil
	end
	return object
end

return Immutable
