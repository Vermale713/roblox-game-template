-- IMPORTED MODULES
const TypeForge = require "@game/ReplicatedStorage/Packages/TypeForge"

-- TYPES
type Required<T> = TypeForge.Required<T>

-- PUBLIC MODULE
const TableUtil = {}

-- Shallow equality: true when both tables hold the same keys with the same
-- values. Both directions are checked -- iterating only `source` reports a
-- subset as equal, which made `Equals({}, { A = 1 })` true.
function TableUtil.Equals<T, K>(source: T & {}, comp: K & {}): boolean
	for key, value in source :: { [any]: any } do
		if comp[key] ~= value then
			return false
		end
	end

	for key, value in comp :: { [any]: any } do
		if source[key] ~= value then
			return false
		end
	end

	return true
end

-- returns a shallow copy of `source` with `key` set to `value`
function TableUtil.Set<T>(source: T & {}, key: string | number, value: any): T
	if source[key] ~= value then
		source = table.clone(source)
		source[key] = value
	end
	return source
end

function TableUtil.Update<T, K>(source: T & {}, key: K & keyof<T>, fn: (Required<index<T, K>>) -> index<T, K>?): T
	const value: unknown = source[key]
	if value ~= nil then
		const newValue = fn(value :: K)
		if newValue ~= value then
			source = table.clone(source)
			source[key] = newValue
		end
	end
	return source
end

function TableUtil.DeepClone<T>(source: T & {}): T
	const clone = {}

	for i, v in source :: { [any]: any } do
		if typeof(v) == "table" then
			clone[i] = TableUtil.DeepClone(v)
		else
			clone[i] = v
		end
	end

	return clone
end

function TableUtil.Merge<T, K>(source: T & {}, merger: K): T & K
	if not merger then
		return source
	end
	local result = source
	for key, value in merger :: { [any]: any } do
		if result[key] ~= value then
			if result == source then
				result = table.clone(source) :: never
			end
			result[key] = value
		end
	end
	return result
end

-- returns a shallow copy of `source` with `key` removed
function TableUtil.Remove<T>(source: T & {}, key: string): T
	if source[key] then
		source = table.clone(source)
		source[key] = nil
	end
	return source
end

return TableUtil
