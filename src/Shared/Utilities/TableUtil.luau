-- PUBLIC MODULE
const TableUtil = {}

-- returns a shallow copy of `source` with `key` set to `value`
function TableUtil.Set<K, V>(source: { [K]: V }, key: K, value: V): { [K]: V }
	const result = table.clone(source)
	result[key] = value
	return result
end

-- returns a shallow copy of `source` with `key` removed
function TableUtil.Remove<K, V>(source: { [K]: V }, key: K): { [K]: V }
	const result: { [K]: V } = {}
	for existingKey, value in source do
		if existingKey ~= key then
			result[existingKey] = value
		end
	end
	return result
end

return TableUtil
