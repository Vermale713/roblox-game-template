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

-- lifecycle phase a service moves through, surfaced for debug tooling
export type ServicePhase = "Discovered" | "Initialized" | "Running" | "Completed" | "Failed"

export type ServiceStatus = {
	Name: string,
	HasInit: boolean,
	HasStart: boolean,
	Phase: ServicePhase,
	InitSeconds: number?,
}

-- PRIVATE STATE
-- lifecycle tracking, exposed via Loader.GetStatus for the debug overlay; keyed by
-- service name, with _statusOrder preserving dependency (load) order
const _status: { [string]: ServiceStatus } = {}
const _statusOrder: { string } = {}
const _nameByService: { [Service]: string } = {}

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
			_nameByService[result] = descendant.Name
		end

		const ok, order = pcall(getLoadOrder, registry)
		if not ok then
			reject(order)
			return
		end

		for _, service in order do
			const name = _nameByService[service]
			if name and not _status[name] then
				_status[name] = {
					Name = name,
					HasInit = service.OnInit ~= nil,
					HasStart = service.OnStart ~= nil,
					Phase = "Discovered",
				}
				table.insert(_statusOrder, name)
			end

			if service.OnInit then
				const startClock = os.clock()
				const initOk, err = pcall(service.OnInit, service)
				if name then
					_status[name].InitSeconds = os.clock() - startClock
					_status[name].Phase = if initOk then "Initialized" else "Failed"
				end
				if not initOk then
					reject(err)
					return
				end
			elseif name then
				_status[name].Phase = "Initialized"
			end
		end

		resolve(order)
	end)
end

function Loader.Start(services: Services): typeof(Promise.new(function() end))
	return Promise.new(function(resolve)
		for _, service in services do
			const name = _nameByService[service]
			if service.OnStart then
				if name then
					_status[name].Phase = "Running"
				end
				task.spawn(function()
					-- track completion vs. a still-yielding OnStart; re-raise so the
					-- error stays visible exactly as an unwrapped task.spawn would
					const ok, err = pcall(service.OnStart, service)
					if name then
						_status[name].Phase = if ok then "Completed" else "Failed"
					end
					if not ok then
						error(err)
					end
				end)
			elseif name then
				_status[name].Phase = "Completed"
			end
		end

		resolve()
	end)
end

function Loader.GetStatus(): { ServiceStatus }
	const ordered: { ServiceStatus } = {}
	for _, name in _statusOrder do
		table.insert(ordered, _status[name])
	end
	return ordered
end

return Loader
