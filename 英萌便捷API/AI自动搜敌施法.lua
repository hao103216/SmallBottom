local function cast_ai(self)
	if not self then
		return false
	end
	local hero = self.owner
	local target_type = self.target_type
	local range
	--如果是无目标技能 就认为选取范围是area或者单位的攻击距离
	if target_type == self.TARGET_TYPE_NONE then
		range = self.area or hero:get_attack_range()
		--其他类型就认为是技能的施法距离
	else
		range = self:get_range()
	end
	local u = ac.selector()
	: in_range(hero, range)
	--单位必须可见 防止隐身单位被ai透视
	: of_visible(hero)
	--对非无目标技能的处理
	if target_type == self.TARGET_TYPE_UNIT
	or target_type == self.TARGET_TYPE_UNIT_OR_POINT
	then
		--获得技能目标筛选器
		local func = base.target_filter(hero, self.target_data, self.exempt_type)
		--技能筛选成功的单位表
		local flag = {}
		u = u:add_filter(function(u)
			--筛选成功加入单位表
			if func(u) then
				flag[#flag + 1] = u
			end
			--一定要返回true 所有单位通过判定
			return true
		end):get()
		--如果有筛选成功的单位 就在筛选成功单位表里找
		if #flag > 0 then
			u = flag[math_random(#flag)]
		--没有在所有单位里找到一个随机单位点来释放
		elseif #u > 0 and target_type == self.TARGET_TYPE_UNIT_OR_POINT then
			u = u[math_random(#u)]:get_point()
		--否则没有目标可以释放
		else
			u = nil
		end
	else
		--无目标技能的话默认找周围的敌人释放
		u = u:is_enemy(hero):random()
	end
	--如果有目标 则技能默认为无视距离的施法
	if u then
		if target_type == self.TARGET_TYPE_NONE then
			return self:cast()
		end
		if target_type == self.TARGET_TYPE_POINT then
			return self:cast(u:get_point(), {ignore_range = true})
		end
		return self:cast(u, {ignore_range = true})
	end
	return false
end