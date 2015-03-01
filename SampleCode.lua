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
