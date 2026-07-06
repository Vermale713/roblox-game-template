--[=[
	Cloud test runner — `lune run test`

	Builds the test place with Argon, uploads it as a new (saved, unpublished)
	place version, runs the registered specs inside a real Roblox server via
	the Open Cloud Luau execution API, then renders the results locally.

	Configuration (environment variables, or a .env file in the project root):
		ROBLOX_API_KEY      Open Cloud key with universe-places:write and
		                    luau-execution-sessions:read + write scopes
		ROBLOX_UNIVERSE_ID  the experience that owns the test place
		ROBLOX_PLACE_ID     a place dedicated to test runs
]=]

-- IMPORTED MODULES
local fs = require "@lune/fs"
local net = require "@lune/net"
local process = require "@lune/process"
local serde = require "@lune/serde"
local stdio = require "@lune/stdio"
local task = require "@lune/task"

-- CONSTANTS
local API_BASE = "https://apis.roblox.com"
local PLACE_FILE = "test-place.rbxl"
local POLL_INTERVAL_SECONDS = 3
local POLL_TIMEOUT_SECONDS = 600

-- Runs inside Roblox: requires every *.spec module (each returns a registrar
-- function), then returns the framework's plain-data results, which Open
-- Cloud serializes into the task output.
local TASK_SCRIPT = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local testsFolder = ReplicatedStorage:WaitForChild("Tests")
local Test = require(testsFolder:WaitForChild("Test"))

for _, descendant in testsFolder:GetDescendants() do
	if descendant:IsA("ModuleScript") and string.sub(descendant.Name, -5) == ".spec" then
		require(descendant)()
	end
end

return Test.Run()
]==]

-- PRIVATE FUNCTIONS

local function color(name, text: string): string
	return `{stdio.color(name)}{text}{stdio.color "reset"}`
end

local function dim(text: string): string
	return `{stdio.style "dim"}{text}{stdio.style "reset"}`
end

local function bold(text: string): string
	return `{stdio.style "bold"}{text}{stdio.style "reset"}`
end

local function step(message: string)
	stdio.write(dim(`▸ {message}\n`))
end

local function fail(message: string): never
	stdio.ewrite(color("red", `✗ {message}\n`))
	return process.exit(1)
end

local function loadDotEnv(): { [string]: string }
	local variables: { [string]: string } = {}
	if not fs.isFile ".env" then
		return variables
	end
	for line in string.gmatch(fs.readFile ".env", "[^\r\n]+") do
		if not string.match(line, "^%s*#") then
			local key, value = string.match(line, "^%s*([%w_]+)%s*=%s*(.-)%s*$")
			if key and value then
				value = string.match(value, '^"(.*)"$') or string.match(value, "^'(.*)'$") or value
				variables[key] = value
			end
		end
	end
	return variables
end

local dotEnv = loadDotEnv()

local function requireVariable(name: string): string
	local value = process.env[name] or dotEnv[name]
	if value == nil or value == "" then
		return fail(`missing {name} — set it in your environment or .env (see .env.example)`)
	end
	return value
end

-- MAIN

local startTime = os.clock()

local apiKey = requireVariable "ROBLOX_API_KEY"
local universeId = requireVariable "ROBLOX_UNIVERSE_ID"
local placeId = requireVariable "ROBLOX_PLACE_ID"

-- 1. Build the test place
step "building test place with argon"
if not fs.isDir "roblox_packages" then
	fs.writeDir "roblox_packages"
end
local build = process.exec("argon", { "build", "test.project.json", "--output", PLACE_FILE }, { shell = true })
if not build.ok then
	stdio.ewrite(build.stdout)
	stdio.ewrite(build.stderr)
	fail "argon build failed"
end

-- 2. Upload it as a saved (unpublished) place version
step(`uploading place version to place {placeId}`)
local upload = net.request {
	url = `{API_BASE}/universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved`,
	method = "POST",
	headers = {
		["x-api-key"] = apiKey,
		["Content-Type"] = "application/octet-stream",
	},
	body = fs.readFile(PLACE_FILE),
}
if not upload.ok then
	fail(
		`place upload failed ({upload.statusCode}): {upload.body}\n`
			.. "  check that the API key has universe-places:write for this experience"
	)
end
local versionNumber = serde.decode("json", upload.body).versionNumber

-- 3. Start a Luau execution task against that version
step(`starting cloud execution task (place version {versionNumber})`)
local createResponse = net.request {
	url = `{API_BASE}/cloud/v2/universes/{universeId}/places/{placeId}/versions/{versionNumber}/luau-execution-session-tasks`,
	method = "POST",
	headers = {
		["x-api-key"] = apiKey,
		["Content-Type"] = "application/json",
	},
	body = serde.encode("json", { script = TASK_SCRIPT }),
}
if not createResponse.ok then
	fail(
		`task creation failed ({createResponse.statusCode}): {createResponse.body}\n`
			.. "  check that the API key has luau-execution-sessions:write"
	)
end
local taskInfo = serde.decode("json", createResponse.body)

-- 4. Poll until the task settles
step "waiting for results"
local waited = 0
while taskInfo.state == "QUEUED" or taskInfo.state == "PROCESSING" do
	if waited >= POLL_TIMEOUT_SECONDS then
		fail(`timed out after {POLL_TIMEOUT_SECONDS}s waiting for the execution task`)
	end
	task.wait(POLL_INTERVAL_SECONDS)
	waited += POLL_INTERVAL_SECONDS

	local poll = net.request {
		url = `{API_BASE}/cloud/v2/{taskInfo.path}`,
		headers = { ["x-api-key"] = apiKey },
	}
	if not poll.ok then
		fail(`task polling failed ({poll.statusCode}): {poll.body}`)
	end
	taskInfo = serde.decode("json", poll.body)
end

local function fetchLogMessages(): { string }
	local logsResponse = net.request {
		url = `{API_BASE}/cloud/v2/{taskInfo.path}/logs`,
		headers = { ["x-api-key"] = apiKey },
	}
	if not logsResponse.ok then
		return {}
	end
	local messages = {}
	local decoded = serde.decode("json", logsResponse.body)
	for _, page in (decoded.luauExecutionSessionTaskLogs or {}) do
		for _, message in (page.messages or {}) do
			table.insert(messages, tostring(message))
		end
		for _, structured in (page.structuredMessages or {}) do
			table.insert(messages, tostring(structured.message))
		end
	end
	return messages
end

-- 5. Render
if taskInfo.state ~= "COMPLETE" then
	for _, message in fetchLogMessages() do
		stdio.ewrite(dim(`  {message}\n`))
	end
	local errorMessage = if taskInfo.error ~= nil then tostring(taskInfo.error.message) else taskInfo.state
	fail(`cloud execution did not complete: {errorMessage}`)
end

local results = taskInfo.output.results[1]
if results == nil then
	fail "task completed but returned no results — did the task script return Test.Run()?"
end

local lastSuite: string? = nil
for _, testResult in results.Tests do
	if testResult.Suite ~= lastSuite then
		lastSuite = testResult.Suite
		local header = if testResult.Suite == "" then "(top level)" else testResult.Suite
		stdio.write(`\n{bold(header)}\n`)
	end
	if testResult.Status == "passed" then
		local duration = dim(string.format("(%.1f ms)", testResult.DurationMilliseconds))
		stdio.write(`  {color("green", "✓")} {testResult.Title} {duration}\n`)
	elseif testResult.Status == "skipped" then
		stdio.write(`  {color("yellow", "○")} {testResult.Title} {dim "(skipped)"}\n`)
	else
		stdio.write(`  {color("red", "✗")} {bold(testResult.Title)}\n`)
		for line in string.gmatch(tostring(testResult.Error), "[^\r\n]+") do
			stdio.write(color("red", `      {line}\n`))
		end
	end
end

local logMessages = fetchLogMessages()
if #logMessages > 0 then
	stdio.write(dim "\nconsole output:\n")
	for _, message in logMessages do
		stdio.write(dim(`  {message}\n`))
	end
end

local summaryParts = { `{results.Passed} passed` }
if results.Failed > 0 then
	table.insert(summaryParts, `{results.Failed} failed`)
end
if results.Skipped > 0 then
	table.insert(summaryParts, `{results.Skipped} skipped`)
end
table.insert(summaryParts, `{results.Total} total`)
local summary = table.concat(summaryParts, ", ")

local timing = string.format(
	"suites %d/%d passed · %.0f ms in Roblox · %.0f s total",
	results.SuitesTotal - results.SuitesFailed,
	results.SuitesTotal,
	results.DurationMilliseconds,
	os.clock() - startTime
)
stdio.write(`\n{color(if results.Failed > 0 then "red" else "green", summary)} {dim(timing)}\n`)

process.exit(if results.Failed > 0 then 1 else 0)
