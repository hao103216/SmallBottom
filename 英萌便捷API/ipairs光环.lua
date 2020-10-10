local table_insert = table.insert
local function create_template(set_class)
	return setmetatable({}, {__index = function (self, name) 
		local obj = ac.buff[name]
		set_class(obj)
		local init = {'on_add', 'on_remove', 'on_finish', 'on_pulse', 'on_cover', 'on_cast'}
		local hook = {}
		for i, key in ipairs(init) do
			if obj[key] then
				hook[key] = true
			end
		end
		local tbl = setmetatable({}, {
			__newindex = function (self, key, val)
				if hook[key] then
					obj['__' .. key] = val
					return
				end
				obj[key] = val
			end,
			__index = function (self, key)
				if hook[key] then
					return obj['__' .. key]
				end
				return obj[key]
			end,
		})
		self[name] = tbl
		return tbl
	end})
end

ac.aura_buff = create_template(function(mt)
	function mt:on_add()
		--给个默认值 0.5秒
		if not self.aura_pulse then
			self.aura_pulse = 0.5
		end
		local aura_pulse = self.aura_pulse * 1000
		local hero = self.target

		--找到子buff名字
		self.child_buff = self.child_buff or self.name

		--找到子buff的模板
		--[[换成你自己的判断buff是否存在的方式
		比如
		local data = ac.buff[name]
		local child_pulse = data.pulse or self.pulse
		]]
		local data = ac.bff.has_data(self.child_buff)

		--子心跳间隔
		local child_pulse = data and data.pulse or self.pulse

		--不是子buff 进行周期性回调
		if not self.aura_child then
			if self.name == self.child_buff then
				self.selector:is_not(hero)
			end

			--创建结构表
			self.aura_node = {}
			self.aura_child = {}

			--光环心跳
			self.aura_timer = hero:loop(aura_pulse, function()
				local aura_child = self.aura_child

				if not hero:is_alive() then
					if #self.aura_node > 0 then
						for i, u in ipairs(self.aura_node) do
							if aura_child[u] then
								aura_child[u]:remove()
								aura_child[u] = nil
							end
							self.aura_node[i] = nil
						end
					end
					return
				end

				local aura_node = {}
				--更新的队列
				local update = {}
				--选取一次
				for _, u in self.selector:ipairs() do
					update[u] = true
					table_insert(aura_node, u)
				end
				--查找要失去光环的单位
				for i, u in ipairs(self.aura_node) do
					if not update[u] then
						if aura_child[u] then
							aura_child[u]:remove()
							aura_child[u] = nil
						end
					end
					self.aura_node[i] = nil
				end

				for i, u in ipairs(aura_node) do
					if not aura_child[u] or aura_child[u].removed then
						aura_child[u] = u:add_buff(self.child_buff)
						{
							source = self.source,
							skill = self.skill,
							data = self.data,
							aura_child = true,
							parent_buff = self,
							pulse = child_pulse,
						}
					end
				end

				self.aura_node = aura_node
			end)
			self.aura_timer:on_timer()
		end
		if self.__on_add then self:__on_add() end
	end
	function mt:on_remove()
		if self.aura_timer then self.aura_timer:remove() end
		if self.aura_node then
			local aura_child = self.aura_child
			for i, u in ipairs(self.aura_node) do
				if aura_child[u] then
					aura_child[u]:remove()
					aura_child[u] = nil
				end
			end
		end
		self.aura_node = nil
		if self.__on_remove then self:__on_remove() end
	end
	function mt:on_cover(new)
		if self.name == self.child_buff then
			if not new.aura_child then
				return true
			end
			self:set_remaining(new.time)
			return false
		else
			if self.__on_cover then
				return self:__on_cover(new)
			end
			return true
		end
	end
end)
