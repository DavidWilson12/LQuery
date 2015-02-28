local LQueryMethods = {
	__default = {},
	__table = {},
	__string = {},
	__boolean = {},
	__number = {},
	__userdata = {}
} 

--> @table functions
function LQueryMethods.__table.push(L_State, value)
	table.insert(L_State.selector, value)
	return L_State
end

function LQueryMethods.__table.pushKey(L_State, key, value)
	L_State.selector[key] = value
	return L_State
end

function LQueryMethods.__table.pop(L_State)
	table.remove(L_State.selector, #L_State.selector)
	return L_State
end

function LQueryMethods.__table.popIndex(L_State, index)
	if index > #L_State.selector then
		error "Attempt to pop a nil value"
	end
	table.remove(L_State.selector, index)
	return L_State
end

function LQueryMethods.__table.popKey(L_State, key)
	L_State.selector[key] = nil
	return L_State
end

function LQueryMethods.__table.each(L_State, callback)
	for i, v in pairs(L_State.selector) do
		callback(v)
	end
	return L_State
end

function LQueryMethods.__table.pushMetatable(L_State, metatable)
	setmetatable(L_State.selector, metatable)
	return L_State
end

function LQueryMethods.__table.popMetatable(L_State)
	return LQueryMethods.__table.pushMetatable(L_State.selector, nil)
end

function LQueryMethods.__table.getMetatable(L_State)
	return getmetatable(L_State.selector)
end

function LQueryMethods.__table.concat(L_State, pattern)
	return table.concat(L_State.selector, pattern)
end

--> @boolean functions
function LQueryMethods.__boolean.invert(L_State)
	return not L_State.selector
end

--> @LQuery metamethods: creates a new scope when called
return setmetatable({}, {
	__call = function(self, _selector)		
		local funccall;				
		
		local scope = setmetatable({selector = _selector}, {
			__index = function(_self, key)
				funccall = key
				return _self
			end,
			__call = function(_self, ...)
				if LQueryMethods.__default[funccall] then
					return LQueryMethods.__default[funccall](_self, ...)
				end
				return LQueryMethods["__" .. type(_self.selector)][funccall](_self, ...)
			end,
			__tostring = function(_self)
				return tostring(_self.selector)
			end
		})
		
		return scope
	end,
	 __metatable = {}
})
