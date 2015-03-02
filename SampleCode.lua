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

lq.pushParent("screen", screen)

lq.parseHTML [[
	<TextButton Size="Vector2.new(100, 100)" class="PRINT_CONTENTS_BUTTON" Parent="screen"> 
		<!-- note that you cannot currently embed elements inside of elements -->
	</TextButton>
	
	<TextButton Size="Vector2.new(200, 200)" Position="Vector2.new(300, 300)" BackgroundColor3="Color3.new(1, 0, 0)" class="PRINT_CONTENTS_BUTTON" Parent="screen">
		
	</TextButton>
]]

lq(".PRINT_CONTENTS_BUTTON").addEvent("MouseButton1Click", function(this)
	print(("BUTTON PROPERTIES:\n\tSize: %s\n\tPosition: %s\n\tParent: %s\n"):format(
		tostring(this.Size), 
		tostring(this.Position), 
		tostring(this.Parent)
	))
end)
