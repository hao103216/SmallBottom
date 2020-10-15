--需要多次table.remove时使用该函数
-- 被操作表
-- 对比函数(满足条件被删除)
function table.removes(obj, rm_func)
	if type(obj) ~= "table" or type(rm_func) ~= "function" then
        return
    end
 
	local index, r_index, length = 1, 1, #obj
	for _ in _loop_() do
		if index > length then
			return
		end
		local v = obj[index]
		obj[index] = nil
        if not rm_func(index, v) then
        	obj[r_index] = v
            r_index = r_index + 1
		end
        index = index + 1
	end
end