--快速施法（建议在施法结束时使用）
-- 施法次数
-- [施法间隔]
-- [自定义来源和目标]
-- [首次施法是否无视间隔]
function mt:fast_cast(count, time, data, bol)
	if not count then
		return
	end
	-- 技能不可多重施法
	-- 技能是指令
	-- 技能是开关技能
    if self.never_fast_cast
    or self:is_order()
    or self:is_switch()
    then
        return
    end
    
	local owner = data and data.owner or self.owner
	local target = data and data.target or self.target

	local function on()
		-- 没有次数 或者 施法者死亡 就结束
		if count <= 0 or not owner:is_alive() then
			return false
		end

		local target = target
		local target_type = self.target_type
		count = count - 1

		-- 技能是单位目标
		-- 技能是单位或点目标
		if target_type == self.TARGET_TYPE_UNIT
		or target_type == self.TARGET_TYPE_UNIT_OR_POINT
		then
			local range = self:get_range()
			local u = ac.selector()
				-- 在英雄的施法距离内寻找合适的单位
				: in_range(owner, range)
				-- 进行目标类型筛选
				: add_filter(base.target_filter(owner, self.target_data, self.exempt_type))
				-- 单位必须可见
				: of_visible(owner)
				-- 随机选一个
				: random()
			if not u then
				-- 如果周围没有单位了 并且技能是单位目标类型 就结束
				if target_type == self.TARGET_TYPE_UNIT then
					return false
				end
				-- 说明本次施法 是凭空多重施法 结束
				if not target then
					return false
				end
				-- 否则沿用上次施法目标点
				local point = owner:get_point()
				target = target:get_point()
				-- 超出最大距离 重设点
				if target * point > range then
					target = point - {point / target, range}
				end
			else
				-- 有就替换成u
				target = u
			end
		elseif target_type == self.TARGET_TYPE_POINT then
			-- 技能是点目标 就核实一下距离 超出就重设点
			local range = self:get_range()
			local point = owner:get_point()
			if target * point > range then
				target = point - {point / target, range}
			end
		end

		-- 创建一个施法表 临时的
		local self = self:create_cast{
            owner = owner,
            target = target,
            force_cast = 1,
            break_move = 0,
            ignore_cool = true,
            ignore_cost = true,
            _is_casting = true,
            -- 给施法表打上技能无法多重施法的标签
            never_fast_cast = true,
            -- 给施法表打上多重施法的指令标签
            isOrder = self.ORDER_TYPE_FAST_CAST,
        }
		-- 进行强制施法 跳过判定流程
		self:_change_step 'start'

		return true
	end

	if not time then
		for _ in _loop_() do
			if not on() then
				return
			end
		end
		return
	end

	local timer = owner:loop(time * 1000, function(timer)
		if not on() then
			timer:remove()
		end
	end)

	if bol then
		timer:on_timer()
	end
end