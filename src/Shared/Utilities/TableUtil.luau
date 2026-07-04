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

-- returns a shallow copy of `source` with `key` removed
function TableUtil.Remove<T>(source: T & {}, key: string): T
	if source[key] then
		source = table.clone(source)
		source[key] = nil
	end
	return source
end

return TableUtil
