local lq = require("LQuery")

local array = {1, 5, 9, 20, 30}

--> returning true keeps 'this' in the array; vice-versa for false
lq(array).filter(function(this)
	return this > 5
end)

print(lq(array).concat(", ")) --> 9, 20, 30

lq(array).pushKey("exampleOne", 10, "exampleTwo", 20)

print(array.exampleOne, array.exampleTwo) --> 10 20

lq(array).pushMetatable {
	__newindex = function(self, key, value)
		print(tostring(self) .. " [" .. key .. "] = " .. value)
		rawset(self, key, value)
	end
}

lq(array).pushKey("exampleThree", 30) --> table: 0x20828f00 [exampleThree] = 30

print(array.exampleThree) --> 30

print(lq{}.push(100, 500, 1900).filter(function(this)
	return this > 100
end).pop().concat(", ")) --> 500
