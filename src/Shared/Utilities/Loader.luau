-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const LogService = game:GetService "LogService"

-- IMPORTED MODULES
const Promise = require(ReplicatedStorage.Packages.Promise)

-- TYPES
type Service = {
	Dependencies: { string }?,
	OnInit: ((self: any) -> ())?,
	OnStart: ((self: any) -> ())?,
	[string]: any,
}

export type Services = { Service }

-- PRIVATE FUNCTIONS
const function getLoadOrder(registry: { [string]: Service }): { Service }
	const visited: { [string]: boolean } = {}
	const inStack: { [string]: boolean } = {}
	const order: { Service } = {}

	const function visit(name: string)
		if inStack[name] then
			LogService:Error("[Loader] Circular dependency detected at {name}", { name = name })
		end
		if visited[name] then
			return
		end

		inStack[name] = true

		const service = registry[name]
		if service.Dependencies then
			for _, dep in service.Dependencies do
				if not registry[dep] then
					LogService:Error("[Loader] Service {name} depends on {dep}, which was not found", {
						name = name,
						dep = dep,
					})
				end
				visit(dep)
			end
		end

		inStack[name] = nil
		visited[name] = true
		table.insert(order, service)
	end

	for name in registry do
		visit(name)
	end

	return order
end

-- PUBLIC MODULE
const Loader = {}

function Loader.Load(container: Instance): typeof(Promise.new(function() end))
	return Promise.new(function(resolve, reject)
		const registry: { [string]: Service } = {}

		for _, descendant in container:GetDescendants() do
			if not descendant:IsA "ModuleScript" then
				continue
			end

			const ok, result = pcall(require, descendant)
			if not ok then
				LogService:Warn("[Loader] Failed to require {name}: {error}", {
					name = descendant.Name,
					error = result,
				})
				continue
			end

			const parentName = descendant.Parent.Name
			if (parentName ~= "Services" and parentName ~= "Controllers") or typeof(result) ~= "table" then
				continue
			end

			if registry[descendant.Name] then
				LogService:Warn("[Loader] Duplicate service name {name}, skipping", {
					name = descendant.Name,
				})
				continue
			end

			registry[descendant.Name] = result
		end

		const ok, order = pcall(getLoadOrder, registry)
		if not ok then
			reject(order)
			return
		end

		for _, service in order do
			if service.OnInit then
				const initOk, err = pcall(service.OnInit, service)
				if not initOk then
					reject(err)
					return
				end
			end
		end

		resolve(order)
	end)
end

function Loader.Start(services: Services): typeof(Promise.new(function() end))
	return Promise.new(function(resolve)
		for _, service in services do
			if service.OnStart then
				task.spawn(service.OnStart, service)
			end
		end

		resolve()
	end)
end

return Loader
