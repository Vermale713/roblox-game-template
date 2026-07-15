--!strict

const Cooldown = require "@game/ReplicatedStorage/Libraries/Cooldown"
const Test = require "@game/ReplicatedStorage/Tests/Test"

local Describe = Test.Describe
local It = Test.It
local Expect = Test.Expect

-- Short cooldown used for tests that need to observe real expiry.
-- Kept small so the suite runs quickly; WAIT_BUFFER absorbs scheduler jitter.
local SHORT_COOLDOWN = 0.05
local WAIT_BUFFER = 0.05

return function()
	Describe("Cooldown", function()
		Describe("Attempt", function()
			It("returns true the first time a key is attempted", function()
				local key = "attempt-first-call"
				Cooldown.Clear(key)

				local ok = Cooldown.Attempt(key, 5)

				Expect(ok).ToBe(true)

				Cooldown.Clear(key)
			end)

			It("returns false when the same key is attempted again before the cooldown elapses", function()
				local key = "attempt-repeat-call"
				Cooldown.Clear(key)

				local first = Cooldown.Attempt(key, 5)
				local second = Cooldown.Attempt(key, 5)

				Expect(first).ToBe(true)
				Expect(second).ToBe(false)

				Cooldown.Clear(key)
			end)

			It("tracks different keys independently", function()
				local keyA = "attempt-independent-a"
				local keyB = "attempt-independent-b"
				Cooldown.Clear(keyA)
				Cooldown.Clear(keyB)

				local first = Cooldown.Attempt(keyA, 5)
				local second = Cooldown.Attempt(keyB, 5)

				Expect(first).ToBe(true)
				Expect(second).ToBe(true)

				Cooldown.Clear(keyA)
				Cooldown.Clear(keyB)
			end)

			It("supports non-string keys", function()
				local key = {}
				Cooldown.Clear(key)

				local first = Cooldown.Attempt(key, 5)
				local second = Cooldown.Attempt(key, 5)

				Expect(first).ToBe(true)
				Expect(second).ToBe(false)

				Cooldown.Clear(key)
			end)

			It("allows a new attempt again automatically once the cooldown has elapsed", function()
				local key = "attempt-auto-expiry"
				Cooldown.Clear(key)

				local first = Cooldown.Attempt(key, SHORT_COOLDOWN)
				task.wait(SHORT_COOLDOWN + WAIT_BUFFER)
				local second = Cooldown.Attempt(key, SHORT_COOLDOWN)

				Expect(first).ToBe(true)
				Expect(second).ToBe(true)

				Cooldown.Clear(key)
			end)
		end)

		Describe("IsOnCooldown", function()
			It("returns false for a key that has never been attempted", function()
				local key = "cooldown-never-attempted"

				Expect(Cooldown.IsOnCooldown(key)).ToBe(false)
			end)

			It("returns true immediately after a successful attempt", function()
				local key = "cooldown-active"
				Cooldown.Clear(key)
				Cooldown.Attempt(key, 5)

				Expect(Cooldown.IsOnCooldown(key)).ToBe(true)

				Cooldown.Clear(key)
			end)

			It("returns false again once the cooldown has elapsed", function()
				local key = "cooldown-expires"
				Cooldown.Clear(key)
				Cooldown.Attempt(key, SHORT_COOLDOWN)

				task.wait(SHORT_COOLDOWN + WAIT_BUFFER)

				Expect(Cooldown.IsOnCooldown(key)).ToBe(false)
			end)
		end)

		Describe("GetRemaining", function()
			It("returns 0 for a key that is not on cooldown", function()
				local key = "remaining-not-on-cooldown"

				Expect(Cooldown.GetRemaining(key)).ToBe(0)
			end)

			It("returns a value close to the cooldown right after an attempt", function()
				local key = "remaining-fresh"
				local cooldown = 5
				Cooldown.Clear(key)
				Cooldown.Attempt(key, cooldown)

				local remaining = Cooldown.GetRemaining(key)

				Expect(remaining).ToBeGreaterThan(0)
				Expect(remaining).ToBeCloseTo(cooldown, 0.05)

				Cooldown.Clear(key)
			end)

			It("counts down over time and reaches 0 once expired", function()
				local key = "remaining-counts-down"
				Cooldown.Clear(key)
				Cooldown.Attempt(key, SHORT_COOLDOWN)

				local remainingBefore = Cooldown.GetRemaining(key)

				task.wait(SHORT_COOLDOWN + WAIT_BUFFER)

				local remainingAfter = Cooldown.GetRemaining(key)

				Expect(remainingBefore).ToBeGreaterThan(remainingAfter)
				Expect(remainingAfter).ToBe(0)
			end)
		end)

		Describe("Clear", function()
			It("lets a key be attempted again immediately", function()
				local key = "clear-resets-immediately"
				Cooldown.Clear(key)
				Cooldown.Attempt(key, 5)

				Cooldown.Clear(key)

				Expect(Cooldown.IsOnCooldown(key)).ToBe(false)
				Expect(Cooldown.Attempt(key, 5)).ToBe(true)

				Cooldown.Clear(key)
			end)

			It("is safe to call on a key that was never attempted", function()
				local key = "clear-noop"

				Expect(function()
					Cooldown.Clear(key)
				end).Never.ToThrow()
			end)
		end)
	end)
end
