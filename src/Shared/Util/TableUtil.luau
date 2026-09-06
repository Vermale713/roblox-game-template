-- TYPES
type AnyTable = { [any]: any }

-- PUBLIC MODULE
const TableUtil = {}

function TableUtil.Equals<T, K>(source: T & {}, comp: K & {}): boolean
    const left = source :: AnyTable
    const right = comp :: AnyTable

    for key, value in left do
        if right[key] ~= value then return false end
    end

    for key, value in right do
        if left[key] ~= value then return false end
    end

    return true
end

function TableUtil.Set<T>(source: T & {}, key: string | number, value: any): T
    const view = source :: AnyTable

    if view[key] == value then return source end

    const result = table.clone(view)
    result[key] = value

    return result :: any
end

function TableUtil.Update<T>(source: T & {}, key: string | number, fn: (any) -> any): T
    const view = source :: AnyTable
    const current = view[key]

    if current == nil then return source end

    const updated = fn(current)
    if updated == current then return source end

    const result = table.clone(view)
    result[key] = updated

    return result :: any
end

function TableUtil.DeepClone<T>(source: T & {}): T
    const clone: AnyTable = {}

    for key, value in source :: AnyTable do
        if typeof(value) == "table" then
            clone[key] = TableUtil.DeepClone(value)
        else
            clone[key] = value
        end
    end

    return clone :: any
end

function TableUtil.Merge<T, K>(source: T & {}, merger: K & {}): T & K
    if not merger then return source :: any end

    const view = source :: AnyTable
    local result = view

    for key, value in merger :: AnyTable do
        if result[key] ~= value then
            if result == view then result = table.clone(view) end

            result[key] = value
        end
    end

    return result :: any
end

function TableUtil.Remove<T>(source: T & {}, key: string): T
    const view = source :: AnyTable

    if view[key] == nil then return source end

    const result = table.clone(view)
    result[key] = nil

    return result :: any
end

return TableUtil
