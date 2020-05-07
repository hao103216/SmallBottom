local table = table
local list = {}
setmetatable(list, list)
local api = {}

--list占用内存比table高 只能顺序遍历 在遍历中移除元素后不会影响后续遍历效果 可以套娃遍历移除元素

-- 有序遍历list
-- [[需要使用指定赋值方法]]
function list:__call()
	print('创建了一个list_ex')
    return setmetatable({_dataList = {}, _array = {}, _regress = 0}, list)
end

function list:__len(key)
	return #self._array
end

function api:len()
	return #self._array
end

--获取key的对应索引
function api:index(key)
	for i, k in ipairs(self._array) do
		if k == key then
			return i
		end
	end
	return nil
end

--获取索引对应的key
function api:key(index)
	return self._array[index]
end

--获取索引对应的value
function api:value(index)
	return self[self._array[index]]
end

function api:pairs()
	local array = self._array --查找序列存的key
	local data = self._dataList
	local n, r = 0, nil
	return function ()
		if not r then
			r = self._regress
		end
		local a = self._regress - r
		n = n + 1 - a
		r = r + a

		return array[n], data[array[n]], n
	end, self
end

function list:__index(key)
	if self._dataList.__index then
		return self._dataList:__index(key) or api[key]
	end
	return self._dataList[key] or api[key]
end
	
function list:__newindex(key, val)
	if key == nil then
		print('没有传入key')
		return
	end
	local array = self._array --查找数组
	if self._dataList[key] ~= nil then
		if val == nil then
			for i = 1, #array do
				if array[i] == key then
					table.remove(array, i)
					if #array == 0 then
						self._array = {}
						self._dataList = {}
					end
					break
				end
			end
			self._regress = self._regress + 1
		end
	else
		array[#array + 1] = key
	end

	self._dataList[key] = val
end