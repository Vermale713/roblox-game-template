--[=[
	Immutable.luau
	A module for immutable table updates
]=]

local Immutable = {}

function Immutable.deepClone<T>(object: T): T
	local result = {}

	for i, v in object :: { [any]: any } do
		if typeof(v) == "table" then
			result[i] = Immutable.deepClone(v)
		else
			result[i] = v
		end
	end

	return result
end

function Immutable.filter<K, V>(object: { [K]: V }, predicate: (V, K) -> boolean): { [K]: V }
	local result: { [K]: V } = {}
	for key, value in object do
		if predicate(value, key) then
			result[key] = value
		end
	end
	return result
end

function Immutable.set<T, K>(object: T & {}, key: K & keyof<T>, value: index<T, K>): T
	if object[key] ~= value then
		object = table.clone(object)
		object[key] = value
	end
	return object
end

function Immutable.update<T, K>(object: T & {}, key: K & keyof<T>, fn: (index<T, K>) -> index<T, K>?): T
	local value: unknown = object[key]
	if value ~= nil then
		local newValue = fn(value :: K)
		if newValue ~= value then
			object = table.clone(object)
			object[key] = newValue
		end
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

function Immutable.join<T>(object: T & {}, source: T?): T
	if not source then
		return object
	end
	local result = object
	for key, value in source :: { [any]: any } do
		if result[key] ~= value then
			if result == object then
				result = table.clone(object) :: never
			end
			result[key] = value
		end
	end
	return result
end

return Immutable
