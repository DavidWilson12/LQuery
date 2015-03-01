local lq = require("LQuery")

--WITHOUT LQUERY:
local array = {}
local metatable = {}
metatable.__newindex = function(self, key, value)
	print("value '" .. tostring(value) .. "' now stored under key '" .. key .. "')
end
setmetatable(array, metatable)

--WITH LQUERY
local array = {}
lq(array).pushMetatable {
	__newindex = function(self, key, value)
		print("value '" .. tostring(value) .. "' now stored under key '" .. key .. "')
	end
}

--WITHOUT LQUERY:
local array = {20, 15, 500, "hello"}

function removeByElement(array, element)
	for i, v in ipairs(array) do
		if v == element then
			table.remove(array, i)
			return
		end
	end
end

removeByElement(array, 500)

--WITH LQUERY:
local array = {20, 15, 500, "hello"}
lq(array).popByValue(500)



--the following is an example of the "HTML" parsing that I'm working on.  It works well, however it doesn't yet support frames inside of frames.
--note that this is only compatible with the ROBLOX engine

local lq = require(script.Parent:WaitForChild("LQueryModule"))
local screen = script.Parent:WaitForChild("ScreenGui"):WaitForChild("Screen")

--> add 'screen' to the database of parents that the parser can access
lq.pushParent("screen", screen)

lq.parseHTML [[
	<Frame Size=Vector2.new(100, 100); Position=Vector2.new(100, 100); Rotation=45; Parent=screen;> </Frame>
]]
