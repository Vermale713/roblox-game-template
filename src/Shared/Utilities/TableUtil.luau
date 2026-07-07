-- IMPORTED MODULES
const Types = require "@game/ReplicatedStorage/Types"

-- TYPES
type NonNilable<T> = Types.NonNilable<T>
type Partial<T> = Types.Partial<T>

-- PUBLIC MODULE
const TableUtil = {}

-- returns a shallow copy of `source` with `key` set to `value`
function TableUtil.Set<T>(source: T & {}, key: string, value: any): T
	if source[key] ~= value then
		source = table.clone(source)
		source[key] = value
	end
	return source
end

function TableUtil.Update<T, K>(source: T & {}, key: K & keyof<T>, fn: (NonNilable<index<T, K>>) -> index<T, K>?): T
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

-- returns a shallow copy of `source` with `key` removed
function TableUtil.Remove<T>(source: T & {}, key: string): T
	if source[key] then
		source = table.clone(source)
		source[key] = nil
	end
	return source
end

return TableUtil
