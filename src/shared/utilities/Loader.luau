--[=[
	Loader.luau
	Handles registering and loading services/controllers
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Promise = require(ReplicatedStorage.packages.Promise)

-- CONSTANTS
local SINGLETON_LIFECYCLES = {
	OnInit = "onInit",
	OnStart = "onStart",
}

-- TYPES
type Config<T> = {
	Module: T,
	Dependencies: { string },
}

type Singleton = {
	[string]: any,
	onInit: () -> (),
	onStart: () -> (),
}

-- PRIVATE STATE
local _singletons: { [string]: Config<unknown> } = {}
local _sortedSingletons: {}

-- PRIVATE FUNCTIONS
local function sort<T>(registry: { [string]: Config<T> }): {}
	local graph: { [string]: { string } } = {}
	local inDegree: { [string]: number } = {}

	for name in registry do
		graph[name] = {}
		inDegree[name] = inDegree[name] or 0
	end

	for name, config in registry do
		for _, dependency in config.Dependencies do
			if not graph[dependency] then
				error(`[Loader] Unknown dependency '{dependency}' required by '{name}'`)
			end

			table.insert(graph[dependency], name)
			inDegree[name] += 1
		end
	end

	local queue: { string } = {}
	for name, degree in inDegree do
		if degree == 0 then
			table.insert(queue, name)
		end
	end

	local sorted = {}
	while #queue > 0 do
		local current = table.remove(queue, 1) :: string
		table.insert(sorted, registry[current].Module)

		for _, dependent in graph[current] do
			inDegree[dependent] -= 1
			if inDegree[dependent] == 0 then
				table.insert(queue, dependent)
			end
		end
	end

	local registrySize = 0
	for _ in registry do
		registrySize += 1
	end

	if #sorted ~= registrySize then
		local loaded = {}
		for _, module in sorted do
			loaded[module] = true
		end

		local culprits: { string } = {}
		for name, config in registry do
			if not loaded[config.Module] then
				table.insert(culprits, name)
			end
		end
		error("[Loader] Circular dependency among: " .. table.concat(culprits, ", "))
	end

	return sorted
end

-- PUBLIC MODULE
local Loader = {}

function Loader.register<T>(name: string, config: Config<T>): ()
	_singletons[name] = config
end

function Loader.loadDirectory(dir: Instance, descendants: boolean?): Promise.TypedPromise<()>
	return Promise.new(function(resolve)
		descendants = descendants or false

		local dirDescendants = if descendants then dir:GetDescendants() else dir:GetChildren()

		for _, descendant: Instance in dirDescendants do
			if descendant:IsA("ModuleScript") then
				-- (require) is needed since it will give a type error if not present
				(require)(descendant)
			end
		end

		resolve()
	end)
end

function Loader.start(): Promise.TypedPromise<()>
	return Promise.new(function(resolve)
		_sortedSingletons = sort(_singletons)

		-- Initialize modules
		for _, module: Singleton in _sortedSingletons :: { Singleton } do
			local method: () -> () = module[SINGLETON_LIFECYCLES.OnInit]
			if method then
				method()
			end
		end

		-- Start modules
		for _, module: Singleton in _sortedSingletons :: { Singleton } do
			local method: () -> () = module[SINGLETON_LIFECYCLES.OnStart]
			if method then
				method()
			end
		end

		resolve()
	end)
end

return Loader
