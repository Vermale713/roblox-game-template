--!strict

--[=[
	Minimal test framework that runs anywhere Luau runs (Roblox, Lune).

	Specs register suites with `Describe`/`It` and assert with `Expect`.
	`Run` executes everything registered and returns a plain-data summary,
	which the cloud test runner serializes back to the command line.
]=]

-- TYPES

export type TestStatus = "passed" | "failed" | "skipped"

export type TestResult = {
	Suite: string,
	Title: string,
	Name: string,
	Status: TestStatus,
	Error: string?,
	DurationMilliseconds: number,
}

export type RunResults = {
	Passed: number,
	Failed: number,
	Skipped: number,
	Total: number,
	SuitesFailed: number,
	SuitesTotal: number,
	DurationMilliseconds: number,
	Tests: { TestResult },
}

type Matchers = {
	ToBe: (expected: any) -> (),
	ToEqual: (expected: any) -> (),
	ToBeNil: () -> (),
	ToBeTruthy: () -> (),
	ToBeFalsy: () -> (),
	ToBeCloseTo: (expected: number, epsilon: number?) -> (),
	ToBeGreaterThan: (expected: number) -> (),
	ToBeLessThan: (expected: number) -> (),
	ToContain: (expected: any) -> (),
	ToHaveLength: (expected: number) -> (),
	ToThrow: (expectedMessage: string?) -> (),
}

export type Expectation = Matchers & { Never: Matchers }

type RegisteredTest = {
	SuitePath: { string },
	Title: string,
	Callback: (() -> ())?,
}

-- PRIVATE STATE

local suitePath: { string } = {}
local registeredTests: { RegisteredTest } = {}

-- PRIVATE FUNCTIONS

local function formatValue(value: any, depth: number?): string
	local currentDepth = depth or 0
	if type(value) == "string" then
		return string.format("%q", value)
	elseif type(value) == "table" then
		if currentDepth >= 2 then
			return tostring(value)
		end
		local parts: { string } = {}
		for key, entry in value :: { [any]: any } do
			if #parts >= 8 then
				table.insert(parts, "…")
				break
			end
			table.insert(
				parts,
				`[{formatValue(key, currentDepth + 1)}] = {formatValue(entry, currentDepth + 1)}`
			)
		end
		return `\{ {table.concat(parts, ", ")} }`
	end
	return tostring(value)
end

local function deepEqual(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for key, value in a :: { [any]: any } do
		if not deepEqual(value, (b :: { [any]: any })[key]) then
			return false
		end
	end
	for key in b :: { [any]: any } do
		if (a :: { [any]: any })[key] == nil then
			return false
		end
	end
	return true
end

local function buildMatchers(received: any, negated: boolean): Matchers
	local function check(pass: boolean, message: string, negatedMessage: string)
		if negated then
			if pass then
				error(negatedMessage, 0)
			end
		elseif not pass then
			error(message, 0)
		end
	end

	return {
		ToBe = function(expected: any)
			check(
				received == expected,
				`expected {formatValue(received)} to be {formatValue(expected)}`,
				`expected {formatValue(received)} to never be {formatValue(expected)}`
			)
		end,

		ToEqual = function(expected: any)
			check(
				deepEqual(received, expected),
				`expected {formatValue(received)} to deep-equal {formatValue(expected)}`,
				`expected {formatValue(received)} to never deep-equal {formatValue(expected)}`
			)
		end,

		ToBeNil = function()
			check(
				received == nil,
				`expected {formatValue(received)} to be nil`,
				"expected value to never be nil"
			)
		end,

		ToBeTruthy = function()
			check(
				received and true or false,
				`expected {formatValue(received)} to be truthy`,
				`expected {formatValue(received)} to never be truthy`
			)
		end,

		ToBeFalsy = function()
			check(
				not received,
				`expected {formatValue(received)} to be falsy`,
				`expected {formatValue(received)} to never be falsy`
			)
		end,

		ToBeCloseTo = function(expected: number, epsilon: number?)
			local tolerance = epsilon or 1e-7
			check(
				type(received) == "number" and math.abs(received - expected) <= tolerance,
				`expected {formatValue(received)} to be within {tolerance} of {expected}`,
				`expected {formatValue(received)} to never be within {tolerance} of {expected}`
			)
		end,

		ToBeGreaterThan = function(expected: number)
			check(
				type(received) == "number" and received > expected,
				`expected {formatValue(received)} to be greater than {expected}`,
				`expected {formatValue(received)} to never be greater than {expected}`
			)
		end,

		ToBeLessThan = function(expected: number)
			check(
				type(received) == "number" and received < expected,
				`expected {formatValue(received)} to be less than {expected}`,
				`expected {formatValue(received)} to never be less than {expected}`
			)
		end,

		ToContain = function(expected: any)
			local contains = false
			if type(received) == "string" then
				contains = string.find(received, tostring(expected), 1, true) ~= nil
			elseif type(received) == "table" then
				for _, entry in received :: { any } do
					if deepEqual(entry, expected) then
						contains = true
						break
					end
				end
			end
			check(
				contains,
				`expected {formatValue(received)} to contain {formatValue(expected)}`,
				`expected {formatValue(received)} to never contain {formatValue(expected)}`
			)
		end,

		ToHaveLength = function(expected: number)
			local length: number? = nil
			if type(received) == "string" then
				length = #(received :: string)
			elseif type(received) == "table" then
				length = #(received :: { any })
			end
			check(
				length == expected,
				`expected {formatValue(received)} to have length {expected}, got {tostring(length)}`,
				`expected {formatValue(received)} to never have length {expected}`
			)
		end,

		ToThrow = function(expectedMessage: string?)
			if type(received) ~= "function" then
				error(`ToThrow expects a function, received {formatValue(received)}`, 0)
			end
			local ok, thrown = pcall(received)
			local threwExpected = not ok
				and (
					expectedMessage == nil
					or string.find(tostring(thrown), expectedMessage, 1, true) ~= nil
				)
			check(
				threwExpected,
				if expectedMessage == nil
					then "expected function to throw"
					else `expected function to throw {formatValue(expectedMessage)}, got {if ok
						then "no error"
						else formatValue(tostring(thrown))}`,
				if expectedMessage == nil
					then "expected function to never throw"
					else `expected function to never throw {formatValue(expectedMessage)}`
			)
		end,
	}
end

-- PUBLIC MODULE

local Test = {}

--- Groups tests. Nestable; suite names are joined into the test's full name.
function Test.Describe(name: string, callback: () -> ())
	table.insert(suitePath, name)
	callback()
	table.remove(suitePath)
end

--- Registers a test. Runs later, when `Run` is called.
function Test.It(name: string, callback: () -> ())
	table.insert(registeredTests, {
		SuitePath = table.clone(suitePath),
		Title = name,
		Callback = callback,
	})
end

Test.Test = Test.It

--- Registers a test that is reported as skipped instead of run.
function Test.ItSkip(name: string, _callback: (() -> ())?)
	table.insert(registeredTests, {
		SuitePath = table.clone(suitePath),
		Title = name,
		Callback = nil,
	})
end

--- Begins an assertion. Chain a matcher, or negate through `.Never`.
function Test.Expect(received: any): Expectation
	local expectation = buildMatchers(received, false) :: any
	expectation.Never = buildMatchers(received, true)
	return expectation :: Expectation
end

--- Runs every registered test and returns a plain-data summary.
function Test.Run(): RunResults
	local results: RunResults = {
		Passed = 0,
		Failed = 0,
		Skipped = 0,
		Total = #registeredTests,
		SuitesFailed = 0,
		SuitesTotal = 0,
		DurationMilliseconds = 0,
		Tests = {},
	}
	local suiteHasNoFailures: { [string]: boolean } = {}

	local runStart = os.clock()
	for _, registeredTest in registeredTests do
		local suite = table.concat(registeredTest.SuitePath, " › ")
		local fullName = if suite == ""
			then registeredTest.Title
			else `{suite} › {registeredTest.Title}`

		local status: TestStatus
		local errorMessage: string? = nil
		local durationMilliseconds = 0

		if registeredTest.Callback == nil then
			status = "skipped"
			results.Skipped += 1
		else
			local testStart = os.clock()
			local ok, thrown = pcall(registeredTest.Callback :: () -> ())
			durationMilliseconds = (os.clock() - testStart) * 1000

			if ok then
				status = "passed"
				results.Passed += 1
			else
				status = "failed"
				errorMessage = tostring(thrown)
				results.Failed += 1
			end
		end

		if suiteHasNoFailures[suite] == nil then
			suiteHasNoFailures[suite] = true
			results.SuitesTotal += 1
		end
		if status == "failed" and suiteHasNoFailures[suite] then
			suiteHasNoFailures[suite] = false
			results.SuitesFailed += 1
		end

		table.insert(results.Tests, {
			Suite = suite,
			Title = registeredTest.Title,
			Name = fullName,
			Status = status,
			Error = errorMessage,
			DurationMilliseconds = durationMilliseconds,
		})
	end

	results.DurationMilliseconds = (os.clock() - runStart) * 1000
	table.clear(registeredTests)

	return results
end

return Test
