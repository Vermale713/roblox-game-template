--!strict

-- IMPORTED MODULES
const Test = require("@game/ReplicatedStorage/Tests/Test")

return function()
	Test.Describe("hello", function()
		Test.Describe("defaults", function()
			Test.It("greets the world when no name is given", function()
				Test.Expect("Hello, world, from package!").ToBe "Hello, world, from package!"
			end)
		end)
	end)
end
