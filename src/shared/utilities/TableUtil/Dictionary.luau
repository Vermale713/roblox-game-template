-- PUBLIC MODULE
local Dictionary = {}

function Dictionary.set<T>(object: T & {}, key: string, value: any): T
	if object[key] ~= value then
		object = table.clone(object)
		object[key] = value
	end
	return object
end

function Dictionary.delete<T>(object: T & {}, key: string): T
	if object[key] ~= nil then
		object = table.clone(object)
		object[key] = nil
	end
	return object
end

function Dictionary.merge<T>(object: T & {}, source: any): T
	local result = object
	for key, value in source :: { [string]: any } do
		if result[key] ~= value then
			if result == object then
				result = table.clone(object) :: never
			end
			result[key] = value
		end
	end
	return result
end

return Dictionary
