local LQueryMethods = {
	__default = {},
	__table = {},
	__string = {},
	__boolean = {},
	__number = {},
	__userdata = {}
}

--> simulate switch/case because Lua doesn't have it :(
function switch(variable, callbacks)
	for i, v in ipairs(callbacks) do
		if variable == v[1] then
			v[2]()
			break
		end
	end
	--> we're still here, resort to default if it exists
	for i, v in ipairs(callbacks) do
		if v[1] == "default" then
			v[2]()
		end
	end
end

--> store locations of tables: if already exists, don't create a new scope!
local references = {}

--> dictionary that contains parents for HTML parsing
local parents = {}

--> @default functions (global functions that can be accessed without a selector!)
function LQueryMethods.__default.pushParent(key, instance)
	parents[key] = instance
end

function LQueryMethods.__default.popParent(key)
	parents[key] = nil
end

function LQueryMethods.__default.getParent(key)
	return parents[key] or error "That is not a valid HTML parent!"
end

--> note this is NOT done yet: the basics work, but frames inside of frames do not work yet
function LQueryMethods.__default.parseHTML(html)
	local index = 0
	local inc, dec, space, getchar, parseBeginTag, rollback, peek, createTagTree, createInstaceFromTags;
	function inc()
		index = index + 1
	end
	function dec()
		index = index - 1
	end
	function space()
		return index < html:len()
	end
	function peek()
		return html:sub(index + 1, index + 1)
	end
	function getchar()
		return html:sub(index, index)
	end
	function rollback(_index)
		index = _index
	end
	function parseBeginTag(_datatree)
		inc()
		local block = ""
		while space() and getchar() ~= ">" do
			block = block .. getchar()
			inc()
		end
		return block
	end
	function createTagTree(tags)
		local tree = {}
		for varname, varval in tags:gmatch("%s+(.-)=(.-);") do
			tree[varname] = varval
		end
		tree.UI_TYPE = tags:sub(1, tags:find("%s")):gsub("%s+", "")
		return tree
	end
	function createInstanceFromTags(tags)
		local data = {}
		for i, v in pairs(tags) do
			if i == "Parent" then
				data[i] = parents[v]
			else
				data[i] = loadstring("return " .. v)()
			end
		end
		if data.Size then
			data.Size = UDim2.new(0, data.Size.X, 0, data.Size.Y)
		end
		if data.Position then
			data.Position = UDim2.new(0, data.Position.X, 0, data.Position.Y)
		end
		local frame = Instance.new(tags.UI_TYPE, data.Parent)
		for i, v in pairs(data) do
			if i ~= "UI_TYPE" then
				frame[i] = v
			end
		end
	end
	while space() do
		inc()
		switch(getchar(), {
			{"<", function()
				if peek() ~= "/" then
					local tags = createTagTree(parseBeginTag())
					createInstanceFromTags(tags)
					--> now we're at the end of the tag definition, scan the insides
					if getchar() == ">" then
						print "success"
					end
				end
			end}
		})
	end
end

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
		L_State.selector[args[i]] = args[i + 1]
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

function LQueryMethods.__table.filter(L_State, callback)
	local index = {} --> make sure to safely remove the correct indexes by iterating backwards
	for i, v in ipairs(L_State.selector) do
		if not callback(v) then
			table.insert(index, i)
		end
	end
	for i = #index, 1, -1 do
		table.remove(L_State.selector, i)
	end
	return L_State
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
		local funccall, scope;
		
		if type(_selector) == "table" then
			if references[tostring(_selector)] then
				scope = references[tostring(_selector)]
			end
		end		
		
		if not scope then
			scope = setmetatable({selector = _selector}, {
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
				end,
				__mode = "kv"
			})
		end
		
		if type(_selector) == "table" then
			if not references[tostring(_selector)] then
				references[tostring(_selector)] = scope
			end
		end	
		
		return scope
	end,
	__index = function(self, key)
		return LQueryMethods.__default[key] or error "Invalid LQuery global"
	end,
	 __metatable = {}
})
