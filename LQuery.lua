local LQueryMethods = {
	__default = {},
	__table = {},
	__string = {},
	__boolean = {},
	__number = {},
	__userdata = {}
}

--> @table functions
function LQueryMethods.__table.push(L_State, ...)
	for i, v in ipairs {...} do
		table.insert(L_State.selector, v)
	end
	return L_State
end

function LQueryMethods.__table.pushKey(L_State, ...)
	local args = {...}
	for i = 1, #args, 2 do
		L_State.selector[i] = args[i + 1]
	end
	return L_State
end

function LQueryMethods.__table.pop(L_State)
	table.remove(L_State.selector, #L_State.selector)
	return L_State
end

--> note: cannot take varargs due to lua's table 'resizing' on remove
function LQueryMethods.__table.popIndex(L_State, index)
	if index > #L_State.selector then
		error "Attempt to pop a nil value"
	end
	table.remove(L_State.selector, index)
	return L_State
end

function LQueryMethods.__table.popKey(L_State, ...)
	for i, v in pairs {...} do
		L_State.selector[v] = nil
	end
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

--> @string functions
function LQueryMethods.__string.push(L_State, append)
	L_State.selector = L_State.selector .. tostring(append)
	return L_State
end

function LQueryMethods.__string.byte(L_State)
	L_State.selector = string.byte(L_State.selector)
	return L_State
end

function LQueryMethods.__string.dump(L_State, callback)
	L_State.selector = string.dump(L_State.selector, callback)
	return L_State
end

function LQueryMethods.__string.find(L_State, pattern, start, shouldUsePattern)
	return string.find(L_State.selector, pattern, start, shouldUsePattern)
end

function LQueryMethods.__string.format(L_State, pattern, ...)
	L_State.selector = string.format(L_State.selector, pattern, ...)	
	return L_State
end

function LQueryMethods.__string.gmatch(L_State, pattern)
	return string.gmatch(L_State.selector, pattern)
end

function LQueryMethods.__string.gsub(L_State, replace)
	L_State.selector = string.gsub(L_State.selector, replace)
	return L_State
end

function LQueryMethods.__string.len(L_State, replace)
	return string.len(L_State.selector)
end

function LQueryMethods.__string.lower(L_State)
	L_State.selector = string.lower(L_State.selector)
	return L_State
end

function LQueryMethods.__string.rep(L_State, iterations)
	L_State.selector = string.rep(L_State.selector, iterations)
	return L_State
end

function LQueryMethods.__string.reverse(L_State)
	L_State.selector = string.reverse(L_State.selector)
	return L_State
end

function LQueryMethods.__string.sub(L_State, start, finish)
	L_State.selector = string.sub(L_State.selector, start, finish)
	return L_State
end

function LQueryMethods.__string.upper(L_State)
	L_State.selector = string.upper(L_State.selector)
	return L_State
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
			end,
			__concat = function(_self)
				return tostring(_self.selector)
			end
		})
		
		return scope
	end,
	 __metatable = {}
})
