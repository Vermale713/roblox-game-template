--!strict

const Test = require "@game/ReplicatedStorage/Tests/Test"
const TableUtil = require "@game/ReplicatedStorage/Utilities/TableUtil"

local Describe = Test.Describe
local It = Test.It
local Expect = Test.Expect

return function()
	Describe("TableUtil", function()
		Describe("Set", function()
			It("returns a new table when the value changes", function()
				local source = { Count = 1 }

				local result = TableUtil.Set(source, "Count", 2)

				Expect(result.Count).ToBe(2)
				Expect(result).Never.ToBe(source)
				Expect(source.Count).ToBe(1)
			end)

			It("returns the same reference when the value is unchanged", function()
				local source = { Count = 1 }

				local result = TableUtil.Set(source, "Count", 1)

				Expect(result).ToBe(source)
			end)

			It("can add a key that didn't previously exist", function()
				local source = {}

				local result = TableUtil.Set(source, "Count", 5)

				Expect(result.Count).ToBe(5)
				Expect(source.Count).ToBeNil()
			end)
		end)

		Describe("Update", function()
			It("returns a new table with the key transformed by fn", function()
				local source = { Count = 1 }

				local result = TableUtil.Update(source, "Count", function(count: number)
					return count + 1
				end)

				Expect(result.Count).ToBe(2)
				Expect(source.Count).ToBe(1)
			end)

			It("returns the same reference when fn returns an unchanged value", function()
				local source = { Count = 1 }

				local result = TableUtil.Update(source, "Count", function(count)
					return count
				end)

				Expect(result).ToBe(source)
			end)

			It("does nothing when the key is nil", function()
				local source = {}
				local called = false

				local result = TableUtil.Update(source, "Count", function(count)
					called = true
					return count
				end)

				Expect(called).ToBe(false)
				Expect(result).ToBe(source)
			end)
		end)

		Describe("Remove", function()
			It("returns a new table with the key removed", function()
				local source = { Count = 1 }

				local result = TableUtil.Remove(source, "Count")

				Expect(result.Count).ToBeNil()
				Expect(source.Count).ToBe(1)
			end)

			It("returns the same reference when the key is already absent", function()
				local source = {}

				local result = TableUtil.Remove(source, "Count")

				Expect(result).ToBe(source)
			end)

			It("does not remove a key whose current value is false", function()
				local source = { Flag = false }

				local result = TableUtil.Remove(source, "Flag")

				Expect(result.Flag).ToBe(false)
			end)
		end)
	end)
end
