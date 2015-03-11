--[[
	update=function(file)return(dofile("/Users/davidwilson/Documents/LuaFiles/"..((file)or"testing")..".lua"))end
]]

local references = {}

local LQueryMethods = {
	__without_selector = {},
	__global = {},
	__table = {},
	__number = {},
	__boolean = {},
	__string = {},
	__userdata = {}	
}

local function warn(message)
	print("WARNING FROM LQUERY: " .. message)
end

--!> FUNCTIONS THAT CAN BE CALLED DIRECTLY FROM LQ (no selector needed) <!--
function LQueryMethods.__without_selector.create_stack()
	local stack;
	local inheritance = {}
	inheritance.push_back = function(value)
		rawset(stack, #stack + 1, value)
	end
	inheritance.push_forward = function(value)
		for i = #stack, 1, -1 do
			rawset(stack, i + 1, rawget(stack, i))
		end
		rawset(stack, 1, value)
	end
	inheritance.pop = function()
		return table.remove(stack, #stack)
	end
	inheritance.pop_at = function(index)
		if index > 0 then
			return table.remove(stack, index)
		end
		return table.remove(stack, #stack + index + 1)
	end
	inheritance.get = function(index)
		if index > 0 then
			return rawget(stack, index)
		end
		return rawget(stack, #stack + index + 1)
	end
	stack = setmetatable({}, {__index = function(self, key)
		return inheritance[key] or error("invalid stack operation '" .. key .. "'")
	end})
	return stack
end

function LQueryMethods.__without_selector.execute_thread(func)
	coroutine.wrap(func)()
end

--!> GLOBAL FUNCTIONS (available to any selector type) <!--
function LQueryMethods.__global.getval(L_State)
	return L_State:__get()
end

function LQueryMethods.__global.kill(L_State)
	setmetatable(L_State, {
		__mode = "kv",
		__index = function() 
			error "this has been garbage collected!" 
		end
	})
	L_State = nil
	L_State:__set(nil)
	collectgarbage()
	return nil
end

--!> NUMBER FUNCTIONS <!--
function LQueryMethods.__number.apply_to_function(L_State, func)
	L_State:__set(loadstring("return " .. func:gsub("x", L_State:__get()))())
	return L_State
end

--!> TABLE FUNCTIONS <!--
function LQueryMethods.__table.insert(L_State, ...)
	for i, v in ipairs{...} do
		table.insert(L_State:__get(), v)
	end
	return L_State
end

function LQueryMethods.__table.remove(L_State, ...)
	local args = {...}
	table.sort(args, function(a, b)
		return a > b
	end)
	for i, v in ipairs(args) do
		table.remove(L_State:__get(), v)
	end
	return L_State
end

function LQueryMethods.__table.remove_by_value(L_State, values)
	for i, v in ipairs(L_State:__get()) do
		for q, k in ipairs(values) do
			if k == v then
				table.remove(L_State:__get(), i)
			end
		end
	end
	return L_State
end

function LQueryMethods.__table.concat(L_State, pattern)
	return table.concat(L_State:__get(), pattern)
end

function LQueryMethods.__table.cutoff(L_State, index)
	local to_kill = {}
	if index > 0 then
		for i = 1, index do
			table.insert(to_kill, i)
		end
	else
		for i = 1, #L_State + index + 1 do
			table.insert(to_kill, i)
		end
	end
	LQueryMethods.__table.remove(L_State, unpack(to_kill))
end

function LQueryMethods.__table.for_each(L_State, callback, should_pass_in_state)
	for i, v in pairs(L_State:__get()) do
		callback(should_pass_in_state and l(v) or v, i)
	end
	return L_State
end

function LQueryMethods.__table.bind(L_State, event, callback)
	if not getmetatable(L_State:__get()) then
		setmetatable(L_State:__get(), {})
	end
	getmetatable(L_State:__get())["__" .. event] = callback
	return L_State
end

function LQueryMethods.__table.get_all_children(L_State)
	local children = {}
	local scan;
	function scan(parent)
		for i, v in pairs(parent) do
			if type(v) == "table" then
				scan(v)
			else
				if not children[i] then
					children[i] = v
				else
					table.insert(children, v)
				end
			end
		end
		return children
	end
	return scan(L_State:__get())
end

--> ROBLOX only functions, won't cause any errors if using standard Lua
if Instance then
	local http = game:GetService("HttpService")
	
	local function roblox_to_rproxy(url)
		local old_url = url
		url, matches = url:gsub("roblox.com", "rproxy.tk")
		if matches > 0 then
			warn("You're not allowed to send get/post requests to roblox.com.  Your link '" .. old_url .. "' was changed to '" .. url .. "'")
		end
		return url
	end

	function LQueryMethods.__without_selector.get(url, callback)
		local source = http:GetAsync(roblox_to_rproxy(url), true)
		if source then
			callback(source)
		end
		return L_State
	end

	function LQueryMethods.__without_selector.post(url, data, content_type)
		if http_enabled then
			http:PostAsync(roblox_to_rproxy(url), data, content_type)
		end
		return L_State
	end

	function LQueryMethods.__without_selector.decode_json(json)
		return http:JSONDecode(json)
	end

	function LQueryMethods.__without_selector.encode_json(data)
		return http:JSONEncode(data)
	end
	
	function LQueryMethods.__userdata.bind(L_State, event, callback)
		L_State:__get()[event]:connect(function(...)
			callback(L_State:__get(), ...)
		end)
		return L_State
	end
	
	function LQueryMethods.__userdata.attr(L_State, attr_name, attr_value)
		if type(attr_name) == "string" then
			L_State:__get()[attr_name] = attr_value
		elseif type(attr_name) == "table" then
			for i, v in pairs(attr_name) do
				L_State:__get()[i] = v
			end
		end
		return L_State
	end
end

l = setmetatable({}, {
	__call = function(self, _selector)		
		local funccall, scope;		
		
		if type(_selector) == "table" or type(_selector) == "userdata" then
			if references[_selector] then
				scope = references[_selector]
			end
		end
		
		if not scope then
			scope = setmetatable({__selector = _selector}, {
				__index = function(_self, key)
					funccall = key
					return _self
				end,
				__call = function(_self, ...)
					if LQueryMethods.__global[funccall] then
						return LQueryMethods.__global[funccall](_self, ...)
					end
					return LQueryMethods["__" .. type(_self:__get())][funccall](_self, ...)
				end,
				__concat = function(_self)
					return tostring(_self:__get())
				end
			})
			function scope:__set(v)
				self.__selector = v
			end
			function scope:__get()
				return self.__selector
			end
		end
		
		if type(_selector) == "table" or type(_selector) == "userdata" then
			if not references[_selector] then
				references[_selector] = scope
			end
		end	
		
		return scope
	end,
	__index = function(self, key)
		return LQueryMethods.__without_selector[key] or error "Invalid LQuery global"
	end,
	 __metatable = {}
})

if Instance then
	return l
end
