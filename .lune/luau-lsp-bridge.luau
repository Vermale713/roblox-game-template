--!strict
local fs = require "@lune/fs"
local net = require "@lune/net"
local process = require "@lune/process"
local serde = require "@lune/serde"
local stdio = require "@lune/stdio"
local task = require "@lune/task"

local WS_PORT = tonumber(process.env.LUAU_LSP_BRIDGE_PORT) or 3668
local LSP_URL = `http://127.0.0.1:{tonumber(process.env.LUAU_LSP_PORT) or 3667}`
local CACHE_FILE = "out/luau-lsp-datamodel.json"
local PROBE_INTERVAL = 0.25

local function note(text: string)
	stdio.write(`{stdio.color "purple"}[luau-lsp-bridge] {text}{stdio.color "reset"}\n`)
end

local lspUp = false
local sockets: { [net.WebSocket]: boolean } = {}
local cachedBody: string? = nil

if fs.isFile(CACHE_FILE) then
	cachedBody = fs.readFile(CACHE_FILE)
	note(`loaded cached DataModel from {CACHE_FILE}`)
end

local function postFull(body: string): boolean
	local ok, result = pcall(process.exec, "curl", {
		"-sf",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"-H",
		"Content-Encoding: gzip",
		"--data-binary",
		"@-",
		"--max-time",
		"10",
		`{LSP_URL}/full`,
	}, { stdio = { stdin = serde.compress("gzip", body) } :: any } :: any)
	return ok and result.ok
end

local function probe(): boolean
	local ok, result = (pcall :: any)(process.exec, "curl", {
		"-s",
		"-o",
		"/dev/null",
		"-w",
		"%{http_code}",
		"--max-time",
		"2",
		`{LSP_URL}/`,
	})
	return ok and result.ok and (result.stdout == "200" or result.stdout == "404")
end

local function requestResync()
	for socket in sockets do
		pcall(function()
			socket:send(serde.encode("json", { t = "resync" }))
		end)
	end
end

local function saveCache(body: string)
	cachedBody = body
	if not fs.isDir "out" then
		fs.writeDir "out"
	end
	fs.writeFile(CACHE_FILE, body)
end

task.spawn(function()
	while true do
		local up = probe()
		if up and not lspUp then
			lspUp = true
			if cachedBody then
				if postFull(cachedBody :: any) then
					note "luau-lsp is up — pushed cached DataModel"
				else
					note "luau-lsp is up — failed to push cached DataModel"
				end
			else
				note "luau-lsp is up — no cached DataModel yet"
			end
			requestResync()
		elseif not up and lspUp then
			lspUp = false
			note "luau-lsp went down"
		end
		task.wait(PROBE_INTERVAL)
	end
end)

local serveOk, serveErr = pcall(
	net.serve,
	WS_PORT,
	{
		handleRequest = function()
			return { status = 200, body = "luau-lsp bridge" }
		end,
		handleWebSocket = function(socket)
			sockets[socket] = true
			note "studio connected"
			while true do
				local raw = socket:next()
				if raw == nil then
					break
				end
				local ok, msg = pcall(function()
					return serde.decode("json", raw)
				end)
				if ok and type(msg) == "table" then
					if msg.t == "hello" then
						note(`studio synced place: {msg.place or "unknown"}`)
					elseif msg.t == "tree" and msg.tree then
						saveCache(raw)
						if lspUp then
							if postFull(raw) then
								note "DataModel forwarded to luau-lsp"
							else
								note "failed to forward DataModel to luau-lsp"
							end
						else
							note "DataModel cached (luau-lsp down)"
						end
					end
				end
			end
			sockets[socket] = nil
			note "studio disconnected"
		end,
	} :: any
)

if not serveOk then
	note(`port {WS_PORT} is busy ({tostring(serveErr):match "[^\n]*"}) — bridge already running? exiting`)
	process.exit(0)
end

note(`listening on ws://localhost:{WS_PORT} — waiting for Studio`)
