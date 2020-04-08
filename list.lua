local table = table
local list = {}
setmetatable(list, list)
local mt = {}
list.__index = mt

--list占用内存比table高 只能顺序遍历 在遍历中移除元素后不会影响后续遍历效果 可以套娃遍历移除元素

function list:__call()
	print('创建了一个list')
    return setmetatable({_array = {}, _regress = 0}, list)
end

-- 有序遍历list
-- [[需要使用指定赋值方法]]
function mt:pairs()
	local array = self._array --查找序列存的key
	local n, r = 0, nil
	return function ()
		if not r then
			r = self._regress
		end
		local a = self._regress - r
		n = n + 1 - a
		r = r + a
		return array[n], self[array[n]], n
	end, self
end

--获取key的对应索引
function mt:index(key)
	for i, k in ipairs(self._array) do
		if k == key then
			return i
		end
	end
	return nil
end

--获取索引对应的key
function mt:key(index)
	return self._array[index]
end

--获取索引对应的value
function mt:value(index)
	return self[self._array[index]]
end

function mt:len()
	return #self._array
end

function mt:set(key, val)
	if not key then
		print('没有传入key')
		return
	end
	local array = self._array --查找数组
	if self[key] ~= nil then
		if val == nil then
			for i = 1, #array do
				if array[i] == key then
					table.remove(array, i)
					break
				end
			end
			self._regress = self._regress + 1
		end
	else
		array[#array + 1] = key
	end

	self[key] = val
end

--根据索引移除元素
function mt:remove(index)
	if not index or index <= 0 then
		return
	end
	self:set(self._array[index])
end

