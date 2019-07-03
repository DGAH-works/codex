--[[
	太阳神三国杀武将扩展包·代码先锋
	适用版本：V2 - 愚人版（版本号：20150401）清明补丁（版本号：20150405）
	武将总数：8
	武将一览：
		1、天枢（狼断、天临）
		2、天璇（伏门、地动）
		3、天玑（聚禄、人灵）
		4、天权（文对、时分）
		5、玉衡（贞辩、音准）
		6、开阳（武功、律明）
		7、摇光（力破、星辉）
		8、北极（示向、先锋）
	所需标记：
		1、@cdxShiXiangMark（“星”标记，来自技能“示向”）
		2、@cdxXianFengMark（“先锋”标记，来自技能“先锋”）
]]--
module("extensions.codex", package.seeall)
extension = sgs.Package("codex", sgs.Package_GeneralPack)
json = require("json")
--代码先锋开关
OPEN_CODEX = false
--翻译信息
sgs.LoadTranslationTable{
	["codex"] = "代码先锋",
}
--[[****************************************************************
	编号：CDX - 001
	武将：天枢
	称号：贪狼星
	势力：神
	性别：男
	体力上限：3勾玉
]]--****************************************************************
TianShu = sgs.General(extension, "cdxTianShu", "god", 3)
--翻译信息
sgs.LoadTranslationTable{
	["cdxTianShu"] = "天枢",
	["&cdxTianShu"] = "天枢",
	["#cdxTianShu"] = "贪狼星",
	["designer:cdxTianShu"] = "DGAH",
	["cv:cdxTianShu"] = "无",
	["illustrator:cdxTianShu"] = "汇图网",
	["~cdxTianShu"] = "代号“天枢”的阵亡台词",
}
--[[
	技能：狼断
	描述：一名角色使用技能卡时，你可以弃一张牌，令此技能卡无效。
]]--
LangDuan = sgs.CreateTriggerSkill{
	name = "cdxLangDuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local skillcard = use.card
		if skillcard and skillcard:isKindOf("SkillCard") then
			local room = player:getRoom()
			local alives = room:getAlivePlayers()
			for _,source in sgs.qlist(alives) do
				if source:hasSkill("cdxLangDuan") and not source:isNude() then
					local prompt = string.format("@cdxLangDuan:::%s:", skillcard:getSkillName())
					local card = room:askForCard(source, "..", prompt, data, "cdxLangDuan")
					if card then
						room:broadcastSkillInvoke("cdxLangDuan") --播放配音
						room:notifySkillInvoked(source, "cdxLangDuan") --显示技能发动
						local msg = sgs.LogMessage()
						msg.type = "#cdxLangDuan"
						msg.from = source
						msg.arg = skillcard:getSkillName()
						room:sendLog(msg) --发送提示信息
						local user = use.from
						if user then
							user:addHistory(skillcard:objectName(), 1)
						end
						return true
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--添加技能
TianShu:addSkill(LangDuan)
--翻译信息
sgs.LoadTranslationTable{
	["cdxLangDuan"] = "狼断",
	[":cdxLangDuan"] = "一名角色使用技能卡时，你可以弃一张牌，令此技能卡无效。",
	["@cdxLangDuan"] = "您可以发动“狼断”弃置一张牌，令此【%arg技能卡】无效",
	["#cdxLangDuan"] = "%from 发动了“狼断”，取消了此【%arg技能卡】的后续效果",
}
--[[
	技能：天临
	描述：一名角色的回合结束时，若你于此回合内受到过伤害或除弃牌阶段外弃置过牌，你可以摸两张牌。
]]--
TianLin = sgs.CreateTriggerSkill{
	name = "cdxTianLin",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.Damaged, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			if player:getPhase() == sgs.Player_Discard then
				return false
			end
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				if player:hasSkill("cdxTianLin") and player:getMark("cdxTianLinAttention") == 0 then
					local basic = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if basic == sgs.CardMoveReason_S_REASON_DISCARD then
						for index, id in sgs.qlist(move.card_ids) do
							local place = move.from_places:at(index)
							if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
								room:setPlayerMark(player, "cdxTianLinAttention", 1)
								break
							end
						end
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			local victim = damage.to
			if victim and victim:objectName() == player:objectName() then
				if player:hasSkill("cdxTianLin") and player:getMark("cdxTianLinAttention") == 0 then
					room:setPlayerMark(player, "cdxTianLinAttention", 1)
				end
			end
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				local alives = room:getAlivePlayers()
				for _,source in sgs.qlist(alives) do
					if source:hasSkill("cdxTianLin") then
						room:setPlayerMark(source, "cdxTianLinAttention", 0)
					end
				end
			elseif phase == sgs.Player_Finish then
				local alives = room:getAlivePlayers()
				for _,source in sgs.qlist(alives) do
					if source:hasSkill("cdxTianLin") and source:getMark("cdxTianLinAttention") > 0 then
						if source:askForSkillInvoke("cdxTianLin", data) then
							room:broadcastSkillInvoke("cdxTianLin") --播放配音
							room:notifySkillInvoked(source, "cdxTianLin") --显示技能发动
							room:setPlayerMark(source, "cdxTianLinAttention", 0)
							room:drawCards(source, 2, "cdxTianLin")
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target 
	end,
}
--添加技能
TianShu:addSkill(TianLin)
--翻译信息
sgs.LoadTranslationTable{
	["cdxTianLin"] = "天临",
	[":cdxTianLin"] = "一名角色的回合结束时，若你于此回合内受到过伤害或除弃牌阶段外弃置过牌，你可以摸两张牌。",
}
--[[****************************************************************
	编号：CDX - 002
	武将：天璇
	称号：巨门星
	势力：神
	性别：男
	体力上限：3勾玉
]]--****************************************************************
TianXuan = sgs.General(extension, "cdxTianXuan", "god", 3)
--翻译信息
sgs.LoadTranslationTable{
	["cdxTianXuan"] = "天璇",
	["&cdxTianXuan"] = "天璇",
	["#cdxTianXuan"] = "巨门星",
	["designer:cdxTianXuan"] = "DGAH",
	["cv:cdxTianXuan"] = "无",
	["illustrator:cdxTianXuan"] = "汇图网",
	["~cdxTianXuan"] = "代号“天璇”的阵亡台词",
}
--[[
	技能：伏门
	描述：若一名其他角色在询问技能发动时点击了“确定”，你可以弃一张牌令该技能无效直至其下个回合开始，然后对其造成1点伤害。
]]--
function doFuMenInvalidity(room, source, target, skill)
	if target:hasSkill(skill:objectName()) then
		local msg = sgs.LogMessage()
		msg.type = "#cdxFuMenInvalidity"
		msg.from = source
		msg.to:append(target)
		msg.arg = skill:objectName()
		room:sendLog(msg) --发送提示信息
		local mark = string.format("cdxFuMenTarget_%s", skill:objectName())
		room:setPlayerMark(target, mark, 1)
		local alives = room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			room:filterCards(p, p:getCards("he"), true)
		end
		--QSanProtocol::S_GAME_EVENT_UPDATE_SKILL = 9
		--QSanProtocol::S_COMMAND_LOG_EVENT = 40
		room:doBroadcastNotify(40, json.encode({9}))
	end
end
FuMen = sgs.CreateTriggerSkill{
	name = "cdxFuMen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.ChoiceMade},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use and use.card then
			return false
		end
		local message = data:toString()
		if message and message ~= "" then
			message = message:split(":")
			local _type = message[1]
			local _skillname = message[2]
			local _choice = message[3]
			if _type and _type == "skillInvoke" then
				if _choice and _choice == "yes" then
					local skill = sgs.Sanguosha:getSkill(_skillname)
					if skill and not skill:inherits("SPConvertSkill") then
						local room = player:getRoom()
						local others = room:getOtherPlayers(player)
						local prompt = string.format("@cdxFuMen:%s::%s:", player:objectName(), _skillname)
						for _,source in sgs.qlist(others) do
							if source:hasSkill("cdxFuMen") and not source:isNude() then
								local discard = room:askForCard(source, "..", prompt)
								if discard then
									doFuMenInvalidity(room, source, player, skill)
									local damage = sgs.DamageStruct()
									damage.from = source
									damage.to = player
									damage.damage = 1
									room:damage(damage)
									if player:isDead() then
										--room:throwEvent(sgs.TurnBroken) --为了防止游戏崩溃
										break
									end
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
FuMenEffect = sgs.CreateInvaliditySkill{
	name = "#cdxFuMenEffect",
	skill_valid = function(self, player, skill)
		local mark = string.format("cdxFuMenTarget_%s", skill:objectName())
		if player:getMark(mark) > 0 then
			return false
		end
		return true
	end,
}
FuMenClear = sgs.CreateTriggerSkill{
	name = "#cdxFuMenClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local flag = false
			local skills = player:getVisibleSkillList()
			for _,skill in sgs.qlist(skills) do
				local mark = string.format("cdxFuMenTarget_%s", skill:objectName())
				if player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
					local msg = sgs.LogMessage()
					msg.type = "#cdxFuMenClearInvalidity"
					msg.from = player
					msg.arg = skill:objectName()
					room:sendLog(msg) --发送提示信息
					flag = true
				end
			end
			if flag then
				local alives = room:getAlivePlayers()
				for _,p in sgs.qlist(alives) do
					room:filterCards(p, p:getCards("he"), false)
				end
				--QSanProtocol::S_GAME_EVENT_UPDATE_SKILL = 9
				--QSanProtocol::S_COMMAND_LOG_EVENT = 40
				room:doBroadcastNotify(40, json.encode({9}))
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
extension:insertRelatedSkills("cdxFuMen", "#cdxFuMenEffect")
extension:insertRelatedSkills("cdxFuMen", "#cdxFuMenClear")
--添加技能
TianXuan:addSkill(FuMen)
TianXuan:addSkill(FuMenEffect)
TianXuan:addSkill(FuMenClear)
--翻译信息
sgs.LoadTranslationTable{
	["cdxFuMen"] = "伏门",
	[":cdxFuMen"] = "若一名其他角色在询问技能发动时点击了“确定”，你可以弃一张牌令该技能无效直至其下个回合开始，然后对其造成1点伤害。",
	["@cdxFuMen"] = "%src 发动了技能“%arg”，您可以发动“伏门”对其造成1点伤害",
	["#cdxFuMenInvalidity"] = "%from 发动了技能“伏门”，令 %to 的技能“%arg”无效直到其下个回合开始",
	["#cdxFuMenClearInvalidity"] = "%from 的回合开始，“伏门”的影响消失，技能“%arg”恢复有效",
}
--[[
	技能：地动
	描述：你即将造成或受到一次伤害时，你可以弃两张牌，令此伤害+1或-1。
]]--
DiDongCard = sgs.CreateSkillCard{
	name = "cdxDiDongCard",
	skill_name = "cdxDiDong",
	target_fixed = true,
	will_throw = true,
	mute = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("cdxDiDong") --播放配音
		room:notifySkillInvoked(source, "cdxDiDong") --显示技能发动
	end,
}
DiDongVS = sgs.CreateViewAsSkill{
	name = "cdxDiDong",
	n = 2,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = DiDongCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@cdxDiDong"
	end,
}
DiDong = sgs.CreateTriggerSkill{
	name = "cdxDiDong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused, sgs.DamageInflicted},
	view_as_skill = DiDongVS,
	on_trigger = function(self, event, player, data)
		if player:getCardCount(true) < 2 then
			return false
		end
		local room = player:getRoom()
		local damage = data:toDamage()
		local count = damage.damage
		local source = damage.from
		local victim = damage.to
		local invoke = false
		if event == sgs.DamageCaused then
			if source and source:objectName() == player:objectName() then
				invoke = true
			end
		elseif event == sgs.DamageInflicted then
			if victim and victim:objectName() == player:objectName() then
				invoke = true
			end
		end
		if invoke then
			local prompt = string.format("@cdxDiDong::%s:%d:", victim:objectName(), count)
			if room:askForCard(player, "@@cdxDiDong", prompt) then
				local msg = sgs.LogMessage()
				msg.from = player
				msg.arg = count
				local choice = room:askForChoice(player, "cdxDiDong", "up+down", data)
				if choice == "up" then
					msg.type = "#cdxDiDongUp"
					count = count + 1
				elseif choice == "down" then
					if count > 1 then
						msg.type = "#cdxDiDongDown"
					else
						msg.type = "#cdxDiDongAvoid"
					end
					count = count - 1
				end
				msg.arg2 = count
				room:sendLog(msg) --发送提示信息
				damage.damage = count
				data:setValue(damage)
				return ( count == 0 )
			end
		end
		return false
	end,
}
--添加技能
TianXuan:addSkill(DiDong)
--翻译信息
sgs.LoadTranslationTable{
	["cdxDiDong"] = "地动",
	[":cdxDiDong"] = "你即将造成或受到一次伤害时，你可以弃两张牌，令此伤害+1或-1。",
	["@cdxDiDong"] = "您可以发动“地动”弃置两张牌，令 %dest 受到的此伤害+1或-1",
	["~cdxDiDong"] = "选择两张牌（包括装备）->点击“确定”",
	["cdxDiDong:up"] = "伤害+1",
	["cdxDiDong:down"] = "伤害-1",
	["#cdxDiDongUp"] = "%from 发动了“地动”令本次伤害+1，由 %arg 点上升至 %arg2 点",
	["#cdxDiDongDown"] = "%from 发动了“地动”令本次伤害-1，由 %arg 点下降至 %arg2 点",
	["#cdxDiDongAvoid"] = "%from 发动了“地动”令本次伤害-1，防止了 %arg 点伤害",
}
--[[****************************************************************
	编号：CDX - 003
	武将：天玑
	称号：禄存星
	势力：神
	性别：男
	体力上限：3勾玉
]]--****************************************************************
TianJi = sgs.General(extension, "cdxTianJi", "god", 3)
--翻译信息
sgs.LoadTranslationTable{
	["cdxTianJi"] = "天玑",
	["&cdxTianJi"] = "天玑",
	["#cdxTianJi"] = "禄存星",
	["designer:cdxTianJi"] = "DGAH",
	["cv:cdxTianJi"] = "无",
	["illustrator:cdxTianJi"] = "汇图网",
	["~cdxTianJi"] = "代号“天玑”的阵亡台词",
}
--[[
	技能：聚禄（阶段技）
	描述：你可以弃一张草花手牌，并执行一项：
		1、选择一名角色武将牌上的一个牌堆，获得该牌堆中的所有牌。
		2、获得一名角色装备区或判定区中的一张牌。
]]--
JuLuCard = sgs.CreateSkillCard{
	name = "cdxJuLuCard",
	skill_name = "cdxJuLu",
	target_fixed = false,
	will_throw = true,
	mute = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:hasEquip() then
				return true
			elseif not to_select:getJudgingArea():isEmpty() then
				return true
			end
			local piles = to_select:getPileNames()
			for _,pile in ipairs(piles) do
				if not to_select:getPile(pile):isEmpty() then
					return true
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local choices = {}
		local piles = target:getPileNames()
		for _,pile in ipairs(piles) do
			if not target:getPile(pile):isEmpty() then
				table.insert(choices, pile)
			end
		end
		if target:hasEquip() then
			table.insert(choices, "equip")
		end
		if not target:getJudgingArea():isEmpty() then
			table.insert(choices, "judge")
		end
		choices = table.concat(choices, "+")
		local card_ids = sgs.IntList()
		local ai_data = sgs.QVariant()
		ai_data:setValue(target)
		local area = room:askForChoice(source, "cdxJuLu", choices, ai_data)
		if area == "equip" then
			local id = room:askForCardChosen(source, target, "e", "cdxJuLu")
			if id > 0 then
				card_ids:append(id)
			end
		elseif area == "judge" then
			local id = room:askForCardChosen(source, target, "j", "cdxJuLu")
			if id > 0 then
				card_ids:append(id)
			end
		else
			card_ids = target:getPile(area)
		end
		if card_ids:isEmpty() then
			return 
		end
		local move = sgs.CardsMoveStruct()
		move.from = target
		move.from_place = sgs.Player_PlaceSpecial
		move.to = source
		move.to_place = sgs.Player_PlaceHand
		move.card_ids = card_ids
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
		room:moveCardsAtomic(move, false)
	end,
}
JuLu = sgs.CreateViewAsSkill{
	name = "cdxJuLu",
	n = 1,
	view_filter = function(self, selected, to_select)
		if to_select:getSuit() == sgs.Card_Club then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = JuLuCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:isKongcheng() then
			return false
		elseif player:hasUsed("#cdxJuLuCard") then
			return false
		end
		return true
	end,
}
--添加技能
TianJi:addSkill(JuLu)
--翻译信息
sgs.LoadTranslationTable{
	["cdxJuLu"] = "聚禄",
	[":cdxJuLu"] = "<font color=\"green\"><b>阶段技</b></font>，你可以弃一张草花手牌，并执行一项：\
1、选择一名角色武将牌上的一个牌堆，获得该牌堆中的所有牌。\
2、获得一名角色装备区或判定区中的一张牌。",
	["cdxJuLu:equip"] = "装备区",
	["cdxJuLu:judge"] = "判定区",
}
--[[
	技能：人灵
	描述：准备阶段开始时，你可以观看牌堆顶的五张牌，展示并获得其中任意数目的草花牌，然后将其余的牌以任意顺序置于牌堆顶或牌堆底。
]]--
RenLing = sgs.CreateTriggerSkill{
	name = "cdxRenLing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase() 
			if phase == sgs.Player_Start then
				if player:askForSkillInvoke("cdxRenLing", data) then
					local card_ids = room:getNCards(5)
					local clubs, disabled_ids = sgs.IntList(), sgs.IntList()
					for _,id in sgs.qlist(card_ids) do
						local card = sgs.Sanguosha:getCard(id)
						if card:getSuit() == sgs.Card_Club then
							clubs:append(id)
						else
							disabled_ids:append(id)
						end
					end
					local to_get = sgs.IntList()
					while not clubs:isEmpty() do
						room:fillAG(card_ids, player, disabled_ids)
						local id = room:askForAG(player, clubs, true, "cdxRenLing")
						room:clearAG(player)
						if id == -1 then
							break
						end
						clubs:removeOne(id)
						card_ids:removeOne(id)
						to_get:append(id)
						room:showCard(player, id)
					end
					if not to_get:isEmpty() then
						local move = sgs.CardsMoveStruct()
						move.to = player
						move.to_place = sgs.Player_PlaceHand
						move.card_ids = to_get
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName())
						room:moveCardsAtomic(move, true)
					end
					if not card_ids:isEmpty() then
						room:askForGuanxing(player, card_ids, sgs.Room_GuanxingBothSides)
					end
				end
			end
		end
		return false
	end,
}
--添加技能
TianJi:addSkill(RenLing)
--翻译信息
sgs.LoadTranslationTable{
	["cdxRenLing"] = "人灵",
	[":cdxRenLing"] = "准备阶段开始时，你可以观看牌堆顶的五张牌，展示并获得其中所有的草花牌，然后将其余的牌以任意顺序置于牌堆顶或牌堆底。",
}
--[[****************************************************************
	编号：CDX - 00
	武将：天权
	称号：文曲星
	势力：神
	性别：男
	体力上限：3勾玉
]]--****************************************************************
TianQuan = sgs.General(extension, "cdxTianQuan", "god", 3)
--翻译信息
sgs.LoadTranslationTable{
	["cdxTianQuan"] = "天权",
	["&cdxTianQuan"] = "天权",
	["#cdxTianQuan"] = "文曲星",
	["designer:cdxTianQuan"] = "DGAH",
	["cv:cdxTianQuan"] = "无",
	["illustrator:cdxTianQuan"] = "汇图网",
	["~cdxTianQuan"] = "代号“天权”的阵亡台词",
}
--[[
	技能：文对
	描述：你于回合外即将受到一张卡牌造成的伤害时，若伤害来源存在且不为你，你可以弃置一张相同点数的手牌，防止此伤害，令伤害来源立即死亡。
]]--
WenDui = sgs.CreateTriggerSkill{
	name = "cdxWenDui",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			if player:isKongcheng() then
				return false
			end
			local damage = data:toDamage()
			local card = damage.card
			if card then
				local point = card:getNumber()
				if point >= 1 and point <= 13 then
					local source = damage.from
					if source and source:isAlive() then
						if source:objectName() ~= player:objectName() then
							local pattern = string.format(".|.|%d|hand", point)
							local prompt = string.format("@cdxWenDui:%s::%d:", source:objectName(), point)
							local room = player:getRoom()
							if room:askForCard(player, pattern, prompt, data, "cdxWenDui") then
								room:broadcastSkillInvoke("cdxWenDui") --播放配音
								room:notifySkillInvoked(player, "cdxWenDui") --显示技能发动
								room:doLightbox("$cdxWenDuiKillPlayer")
								local reason = sgs.DamageStruct()
								reason.from = player
								reason.to = source
								room:killPlayer(source, reason)
								return true
							end
						end
					end
				end
			end
		end
		return false
	end,
}
--添加技能
TianQuan:addSkill(WenDui)
--翻译信息
sgs.LoadTranslationTable{
	["cdxWenDui"] = "文对",
	[":cdxWenDui"] = "你于回合外即将受到一张卡牌造成的伤害时，若伤害来源存在且不为你，你可以弃置一张相同点数的手牌，防止此伤害，令伤害来源立即死亡。",
	["@cdxWenDui"] = "文对：您可以弃一张点数为 %arg 的手牌防止此伤害，令 %src 立即死亡",
	["$cdxWenDuiKillPlayer"] = "死！",
}
--[[
	技能：时分
	描述：一名其他角色的回合开始时，若其手牌数为全场最多，你可以获得其一张牌；一名其他角色的回合结束时，若其手牌数为全场最少，你可以交给其一张牌。
]]--
ShiFen = sgs.CreateTriggerSkill{
	name = "cdxShiFen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Start then
			local others = room:getOtherPlayers(player)
			for _,source in sgs.qlist(others) do
				if source:hasSkill("cdxShiFen") then
					if player:isNude() then
						return false
					end
					for _,p in sgs.qlist(others) do
						if p:getHandcardNum() > player:getHandcardNum() then
							return false
						end
					end
					local prompt = string.format("invoke:%s:", player:objectName())
					if source:askForSkillInvoke("cdxShiFen", sgs.QVariant(prompt)) then
						local id = room:askForCardChosen(source, player, "he", "cdxShiFen")
						if id > 0 then
							room:obtainCard(source, id)
						end
					end
				end
			end
		elseif phase == sgs.Player_Finish then
			local others = room:getOtherPlayers(player)
			for _,source in sgs.qlist(others) do
				if source:hasSkill("cdxShiFen") and not source:isNude() then
					for _,p in sgs.qlist(others) do
						if p:getHandcardNum() < player:getHandcardNum() then
							return false
						end
					end
					local prompt = string.format("@cdxShiFen:%s:", player:objectName())
					local ai_data = sgs.QVariant()
					ai_data:setValue(player)
					local card = room:askForCard(
						source, "..", prompt, ai_data, sgs.Card_MethodNone, player, false, "cdxShiFen", false
					)
					if card then
						room:obtainCard(player, card)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
--添加技能
TianQuan:addSkill(ShiFen)
--翻译信息
sgs.LoadTranslationTable{
	["cdxShiFen"] = "时分",
	[":cdxShiFen"] = "一名其他角色的回合开始时，若其手牌数为全场最多，你可以获得其一张牌；一名其他角色的回合结束时，若其手牌数为全场最少，你可以交给其一张牌。",
	["cdxShiFen:invoke"] = "%src 的手牌为全场最多，您可以发动“时分”获得其一张牌",
	["@cdxShiFen"] = "%src 的手牌为全场最少，您可以发动“时分”交给其一张牌",
}
--[[****************************************************************
	编号：CDX - 005
	武将：玉衡
	称号：廉贞星
	势力：神
	性别：男
	体力上限：3勾玉
]]--****************************************************************
YuHeng = sgs.General(extension, "cdxYuHeng", "god", 3)
--翻译信息
sgs.LoadTranslationTable{
	["cdxYuHeng"] = "玉衡",
	["&cdxYuHeng"] = "玉衡",
	["#cdxYuHeng"] = "廉贞星",
	["designer:cdxYuHeng"] = "DGAH",
	["cv:cdxYuHeng"] = "无",
	["illustrator:cdxYuHeng"] = "汇图网",
	["~cdxYuHeng"] = "代号“玉衡”的阵亡台词",
}
--[[
	技能：贞辩
	描述：一名角色开始判定时，你可以打出一张牌，令本次判定按相反的规则生效。若你打出的牌为红色，本次判定结束后，你可以回复一点体力。
]]--
ZhenBian = sgs.CreateTriggerSkill{
	name = "cdxZhenBian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.StartJudge, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		if event == sgs.StartJudge then
			local alives = room:getAlivePlayers()
			for _,source in sgs.qlist(alives) do
				if source:hasSkill("cdxZhenBian") and not source:isNude() then
					local prompt = string.format("@cdxZhenBian:%s::%s:", player:objectName(), judge.reason)
					local card = room:askForCard(
						source, "..", prompt, data, sgs.Card_MethodResponse, nil, false, "cdxZhenBian", false
					)
					if card then
						local msg = sgs.LogMessage()
						msg.type = "#cdxZhenBian"
						msg.from = source
						msg.to:append(player)
						msg.arg = "cdxZhenBian"
						msg.arg2 = judge.reason
						room:sendLog(msg) --发送提示信息
						judge.good = not judge.good
						data:setValue(judge)
						if card:isRed() then
							room:setPlayerMark(source, "cdxZhenBian_Recover", 1)
						end
						return false
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local alives = room:getAlivePlayers()
			for _,source in sgs.qlist(alives) do
				if source:getMark("cdxZhenBian_Recover") > 0 then
					room:setPlayerMark(source, "cdxZhenBian_Recover", 0)
					if source:getLostHp() > 0 then
						local msg = sgs.LogMessage()
						msg.type = "#cdxZhenBianRecover"
						msg.from = source
						msg.arg = "cdxZhenBian"
						room:sendLog(msg) --发送提示信息
						if source:askForSkillInvoke("cdxZhenBianRecover", data) then
							local recover = sgs.RecoverStruct()
							recover.who = source
							recover.recover = 1
							room:recover(source, recover)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
--添加技能
YuHeng:addSkill(ZhenBian)
--翻译信息
sgs.LoadTranslationTable{
	["cdxZhenBian"] = "贞辩",
	[":cdxZhenBian"] = "一名角色开始判定时，你可以打出一张牌，令本次判定按相反的规则生效。若你打出的牌为红色，本次判定结束后，你可以回复一点体力。",
	["@cdxZhenBian"] = "您可以发动“贞辩”打出一张牌（包括装备），令 %src 本次的 %arg 判定按相反的规则生效",
	["#cdxZhenBian"] = "%from 发动了“%arg”，令 %to 本次的 %arg 判定按相反的规则生效",
	["cdxZhenBianRecover"] = "贞辩·体力回复",
	["#cdxZhenBianRecover"] = "%from 发动“%arg”打出了一张红色牌，可以回复一点体力",
}
--[[
	技能：音准
	描述：你于回合外使用或打出一张牌后，你可以选择一种花色。若如此做，到你的下个出牌阶段结束前，每当你使用该花色卡牌时，或你被指定为该花色卡牌的目标时，你摸一张牌。
]]--
function doYinZhun(room, player, data)
	if room:askForSkillInvoke(player, "cdxYinZhun", data) then
		local suit = room:askForSuit(player, "cdxYinZhun")
		room:broadcastSkillInvoke("cdxYinZhun", 1) --播放配音
		if suit == sgs.Card_Spade then
			player:gainMark("@cdxYinZhunSpade", 1)
		elseif suit == sgs.Card_Heart then
			player:gainMark("@cdxYinZhunHeart", 1)
		elseif suit == sgs.Card_Club then
			player:gainMark("@cdxYinZhunClub", 1) 
		elseif suit == sgs.Card_Diamond then
			player:gainMark("@cdxYinZhunDiamond", 1)
		end
		room:setPlayerMark(player, "cdxYinZhunInvoked", 1)
	end
end
function doYinZhunDraw(room, player, card)
	local suit = card:getSuit()
	local mark = 0
	if suit == sgs.Card_Spade then
		mark = player:getMark("@cdxYinZhunSpade")
	elseif suit == sgs.Card_Heart then
		mark = player:getMark("@cdxYinZhunHeart")
	elseif suit == sgs.Card_Club then
		mark = player:getMark("@cdxYinZhunClub")
	elseif suit == sgs.Card_Diamond then
		mark = player:getMark("@cdxYinZhunDiamond")
	end
	if mark > 0 then
		room:broadcastSkillInvoke("cdxYinZhun", 2) --播放配音
		room:notifySkillInvoked(player, "cdxYinZhun") --显示技能发动
		room:drawCards(player, mark, "cdxYinZhun")
	end
end
YinZhun = sgs.CreateTriggerSkill{
	name = "cdxYinZhun",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseEnd, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			doYinZhunDraw(room, player, card)
			if player:getPhase() == sgs.Player_NotActive then
				if card:isKindOf("SkillCard") then
					return false
				end
				doYinZhun(room, player, data)
			end
		elseif event == sgs.CardResponded then
			if player:getPhase() == sgs.Player_NotActive then
				local response = data:toCardResponse()
				local card = response.m_card
				if card:isKindOf("SkillCard") then
					return false
				end
				doYinZhun(room, player, data)
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				if player:getMark("cdxYinZhunInvoked") > 0 then
					room:setPlayerMark(player, "cdxYinZhunInvoked", 0)
					player:loseAllMarks("@cdxYinZhunSpade")
					player:loseAllMarks("@cdxYinZhunHeart")
					player:loseAllMarks("@cdxYinZhunClub")
					player:loseAllMarks("@cdxYinZhunDiamond")
				end
			end
		elseif event == sgs.TargetConfirmed then
			if player:getMark("cdxYinZhunInvoked") == 0 then
				return false
			end
			local use = data:toCardUse()
			local card = use.card
			local suit = card:getSuit()
			for _,p in sgs.qlist(use.to) do
				if p:objectName() == player:objectName() then
					doYinZhunDraw(room, player, card)
				end
			end
		end
		return false
	end,
}
--添加技能
YuHeng:addSkill(YinZhun)
--翻译信息
sgs.LoadTranslationTable{
	["cdxYinZhun"] = "音准",
	[":cdxYinZhun"] = "你于回合外使用或打出一张牌后，你可以选择一种花色。若如此做，到你的下个出牌阶段结束前，每当你使用该花色卡牌时，或你被指定为该花色卡牌的目标时，你摸一张牌。",
	["$cdxYinZhun1"] = "技能 音准 选择花色时 的台词",
	["$cdxYinZhun2"] = "技能 音准 摸牌时 的台词",
	["@cdxYinZhunSpade"] = "黑桃",
	["@cdxYinZhunHeart"] = "红心",
	["@cdxYinZhunClub"] = "草花",
	["@cdxYinZhunDiamond"] = "方块",
}
--[[****************************************************************
	编号：CDX - 006
	武将：开阳
	称号：武曲星
	势力：神
	性别：男
	体力上限：3勾玉
]]--****************************************************************
KaiYang = sgs.General(extension, "cdxKaiYang", "god", 3)
--翻译信息
sgs.LoadTranslationTable{
	["cdxKaiYang"] = "开阳",
	["&cdxKaiYang"] = "开阳",
	["#cdxKaiYang"] = "武曲星",
	["designer:cdxKaiYang"] = "DGAH",
	["cv:cdxKaiYang"] = "无",
	["illustrator:cdxKaiYang"] = "汇图网",
	["~cdxKaiYang"] = "代号“开阳”的阵亡台词",
}
--[[
	技能：武功
	描述：以你为伤害来源的伤害结算开始时，你可以弃置一张黑桃牌，令伤害目标的所有技能无效直到本阶段结束。
]]--
WuGong = sgs.CreateTriggerSkill{
	name = "cdxWuGong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Predamage, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Predamage then
			local damage = data:toDamage()
			local source = damage.from
			if source and source:objectName() == player:objectName() then
				if source:hasSkill("cdxWuGong") and not source:isKongcheng() then
					local target = damage.to
					if target and target:getMark("cdxWuGongEffect") == 0 then
						local prompt = string.format("@cdxWuGong:%s:", target:objectName())
						local card = room:askForCard(source, ".|spade", prompt, data, "cdxWuGong")
						if card then
							room:setPlayerMark(target, "cdxWuGongEffect", 1)
							local msg = sgs.LogMessage()
							msg.type = "#cdxWuGong"
							msg.from = source
							msg.to:append(target)
							msg.arg = "cdxWuGong"
							room:sendLog(msg) --发送提示信息
							local alives = room:getAlivePlayers()
							for _,p in sgs.qlist(alives) do
								local cards = p:getCards("he")
								room:filterCards(p, cards, true)
							end
							room:doBroadcastNotify(40, json.encode({9}))
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			local alives = room:getAlivePlayers()
			local flag = false
			for _,p in sgs.qlist(alives) do
				if p:getMark("cdxWuGongEffect") > 0 then
					room:setPlayerMark(p, "cdxWuGongEffect", 0)
					local msg = sgs.LogMessage()
					msg.type = "#cdxWuGongClear"
					msg.from = p
					msg.arg = "cdxWuGong"
					room:sendLog(msg) --发送提示信息
					flag = true
				end
			end
			if flag then
				for _,p in sgs.qlist(alives) do
					local cards = p:getCards("he")
					room:filterCards(p, cards, false)
				end
				room:doBroadcastNotify(40, json.encode({9}))
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	priority = 20,
}
WuGongEffect = sgs.CreateInvaliditySkill{
	name = "#cdxWuGongEffect",
	skill_valid = function(self, player, skill)
		if player:getMark("cdxWuGongEffect") > 0 then
			return false
		end
		return true
	end
}
extension:insertRelatedSkills("cdxWuGong", "#cdxWuGongEffect")
--添加技能
KaiYang:addSkill(WuGong)
KaiYang:addSkill(WuGongEffect)
--翻译信息
sgs.LoadTranslationTable{
	["cdxWuGong"] = "武功",
	[":cdxWuGong"] = "以你为伤害来源的伤害结算开始时，你可以弃置一张黑桃牌，令伤害目标的所有技能无效直到本阶段结束。",
	["@cdxWuGong"] = "您可以发动“武功”弃置一张黑桃牌（包括装备），令 %src 的所有技能无效直至本阶段结束",
	["#cdxWuGong"] = "%from 发动了“%arg”，令 %to 的所有技能无效直到本阶段结束",
	["#cdxWuGongClear"] = "当前阶段结束，%from 受“%arg”的影响消失，所有技能恢复有效",
}
--[[
	技能：律明
	描述：你于弃牌阶段外弃置牌时，你可以令一名角色摸等量的牌并展示所有手牌。若展示的牌均为同一颜色，你可以令其回复1点体力，否则你可以获得其区域中的一张牌。
]]--
LvMing = sgs.CreateTriggerSkill{
	name = "cdxLvMing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Discard then
			return false
		end
		local move = data:toMoveOneTime()
		local source = move.from
		if source and source:objectName() == player:objectName() then
			local basic = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			if basic == sgs.CardMoveReason_S_REASON_DISCARD then
				local count = 0
				for index, place in sgs.qlist(move.from_places) do
					if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
						count = count + 1
					end
				end
				if count == 0 then
					return false
				end
				local room = player:getRoom()
				local others = room:getAlivePlayers()
				local prompt = string.format("@cdxLvMing:::%d:", count)
				local target = room:askForPlayerChosen(player, others, "cdxLvMing", prompt, true)
				if target then
					room:drawCards(target, count, "cdxLvMing")
					if target:isKongcheng() then
						return false
					end
					room:showAllCards(target)
					local handcards = target:getHandcards()
					local black, red = false, false
					local same = true
					for _,c in sgs.qlist(handcards) do
						if c:isRed() then
							red = true
						elseif c:isBlack() then
							black = true
						end
						if red and black then
							same = false
							break
						end
					end
					if same then
						if target:getLostHp() > 0 then
							prompt = string.format("recover:%s:", target:objectName())
							if player:askForSkillInvoke("cdxLvMing", sgs.QVariant(prompt)) then
								local recover = sgs.RecoverStruct()
								recover.who = player
								recover.recover = 1
								room:recover(target, recover)
							end
						end
					else
						prompt = string.format("obtain:%s:", target:objectName())
						if player:askForSkillInvoke("cdxLvMing", sgs.QVariant(prompt)) then
							local id = room:askForCardChosen(player, target, "hej", "cdxLvMing")
							if id > 0 then
								room:obtainCard(player, id)
							end
						end
					end
				end
			end
		end
		return false
	end,
}
--添加技能
KaiYang:addSkill(LvMing)
--翻译信息
sgs.LoadTranslationTable{
	["cdxLvMing"] = "律明",
	[":cdxLvMing"] = "你于弃牌阶段外弃置牌时，你可以令一名角色摸等量的牌并展示所有手牌。若展示的牌均为同一颜色，你可以令其回复1点体力，否则你可以获得其区域中的一张牌。",
	["@cdxLvMing"] = "您可以发动“律明”选择一名其他角色，令其摸 %arg 张牌并展示所有手牌",
	["cdxLvMing:recover"] = "%src 展示的牌均为同一颜色，您可以发动“律明”令其回复1点体力",
	["cdxLvMing:obtain"] = "%src 展示的牌不为同一颜色，您可以发动“律明”获得其区域中的一张牌",
}
--[[****************************************************************
	编号：CDX - 007
	武将：摇光
	称号：破军星
	势力：神
	性别：男
	体力上限：3勾玉
]]--****************************************************************
YaoGuang = sgs.General(extension, "cdxYaoGuang", "god", 3)
--翻译信息
sgs.LoadTranslationTable{
	["cdxYaoGuang"] = "摇光",
	["&cdxYaoGuang"] = "摇光",
	["#cdxYaoGuang"] = "破军星",
	["designer:cdxYaoGuang"] = "DGAH",
	["cv:cdxYaoGuang"] = "无",
	["illustrator:cdxYaoGuang"] = "汇图网",
	["~cdxYaoGuang"] = "代号“摇光”的阵亡台词",
}
--[[
	技能：力破（阶段技）
	描述：若你的手牌数大于体力值，你可以将一张牌当做【杀】对一名角色使用。你以此法使用的【杀】无视距离、防具、禁止技和额定使用次数限制。
]]--
LiPoCard = sgs.CreateSkillCard{
	name = "cdxLiPoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_validate = function(self, use)
		local subcards = self:getSubcards()
		local id = subcards:first()
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuit()
		local point = card:getNumber()
		local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
		slash:setSkillName("cdxLiPo")
		slash:addSubcard(id)
		for _,target in sgs.qlist(use.to) do
			target:addQinggangTag(slash)
		end
		return slash
	end,
}
LiPoVS = sgs.CreateViewAsSkill{
	name = "cdxLiPo",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LiPoCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:hasUsed("#cdxLiPoCard") then
			return false
		elseif player:isNude() then
			return false
		elseif player:getHandcardNum() > player:getHp() then
			return true
		end
		return false
	end,
}
LiPo = sgs.CreateTriggerSkill{
	name = "cdxLiPo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished},
	view_as_skill = LiPoVS,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local card = use.card
		if card:getSkillName() == "cdxLiPo" then
			local room = player:getRoom()
			room:addPlayerHistory(player, card:getClassName(), -1)
		end
		return false
	end,
	priority = -10,
}
--添加技能
YaoGuang:addSkill(LiPo)
--翻译信息
sgs.LoadTranslationTable{
	["cdxLiPo"] = "力破",
	[":cdxLiPo"] = "<font color=\"green\"><b>阶段技</b></font>，若你的手牌数大于体力值，你可以将一张牌当做【杀】对一名角色使用。你以此法使用的【杀】无视距离、防具、禁止技和额定使用次数限制。",
	["cdxlipo"] = "力破",
}
--[[
	技能：星辉
	描述：准备阶段开始时，若有手牌数多于你的角色，你可以摸X+1张牌，然后弃置X张牌（X为你已损失的体力值）；否则你可以弃置场上的一张牌。
]]--
XingHui = sgs.CreateTriggerSkill{
	name = "cdxXingHui",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local case = 2
			local alives = room:getAlivePlayers()
			for _,p in sgs.qlist(alives) do
				if p:getHandcardNum() > player:getHandcardNum() then
					case = 1 
					break
				end
			end
			if case == 1 then
				if player:askForSkillInvoke("cdxXingHui", data) then
					local x = player:getLostHp()
					room:drawCards(player, x+1, "cdxXingHui")
					if x > 0 then
						room:askForDiscard(player, "cdxXingHui", x, x, false, true)
					end
				end
			elseif case == 2 then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(alives) do
					if p:hasEquip() and player:canDiscard(p, "e") then
						targets:append(p)
					elseif p:getJudgingArea():isEmpty() then
					elseif player:canDiscard(p, "j") then
						targets:append(p)
					end
				end
				if targets:isEmpty() then
					return false
				end
				local target = room:askForPlayerChosen(player, targets, "cdxXingHui", "@cdxXingHui", true)
				if target then
					local id = room:askForCardChosen(player, target, "ej", "cdxXingHui")
					if id > 0 then
						if player:canDiscard(target, id) then
							room:throwCard(id, target, player)
						end
					end
				end
			end
		end
		return false
	end,
}
--添加技能
YaoGuang:addSkill(XingHui)
--翻译信息
sgs.LoadTranslationTable{
	["cdxXingHui"] = "星辉",
	[":cdxXingHui"] = "准备阶段开始时，若有手牌数多于你的角色，你可以摸X+1张牌，然后弃置X张牌（X为你已损失的体力值）；否则你可以弃置场上的一张牌。",
	["@cdxXingHui"] = "您的手牌数为全场最多，可以发动“星辉”弃置场上的一张牌",
}
--[[****************************************************************
	编号：CDX - 008
	武将：北极
	称号：代码先锋
	势力：神
	性别：男
	体力上限：3勾玉
]]--****************************************************************
BeiJi = sgs.General(extension, "cdxBeiJi", "god", 3, true, true)
--翻译信息
sgs.LoadTranslationTable{
	["cdxBeiJi"] = "北极",
	["&cdxBeiJi"] = "北极",
	["#cdxBeiJi"] = "代码先锋",
	["designer:cdxBeiJi"] = "DGAH",
	["cv:cdxBeiJi"] = "无",
	["illustrator:cdxBeiJi"] = "汇图网",
	["~cdxBeiJi"] = "代号“北极”的阵亡台词",
}
--[[
	技能：示向
	描述：锁定技，你每令一名角色回复一次体力，该角色获得一枚“星”标记；
		阶段技，你可以弃置一名角色的一枚“星”标记，令其摸两张牌。
]]--
ShiXiangCard = sgs.CreateSkillCard{
	name = "cdxShiXiangCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:getMark("@cdxShiXiangMark") > 0 
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		target:loseMark("@cdxShiXiangMark", 1)
		room:drawCards(target, 2, "cdxShiXiang")
	end,
}
ShiXiangVS = sgs.CreateViewAsSkill{
	name = "cdxShiXiang",
	n = 0,
	view_as = function(self, cards)
		return ShiXiangCard:clone()
	end,
	enabled_at_play = function(self, player)
		if player:hasUsed("#cdxShiXiangCard") then
			return false
		elseif player:getMark("@cdxShiXiangMark") > 0 then
			return true
		end
		local others = player:getSiblings()
		for _,p in sgs.qlist(others) do
			if p:getMark("@cdxShiXiangMark") > 0 then
				return true
			end
		end
		return false
	end,
}
ShiXiang = sgs.CreateTriggerSkill{
	name = "cdxShiXiang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.HpRecover},
	view_as_skill = ShiXiangVS,
	on_trigger = function(self, event, player, data)
		local recover = data:toRecover()
		local source = recover.who
		if source and source:hasSkill("cdxShiXiang") then
			player:gainMark("@cdxShiXiangMark", 1)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	priority = 2,
}
--添加技能
BeiJi:addSkill(ShiXiang)
--翻译信息
sgs.LoadTranslationTable{
	["cdxShiXiang"] = "示向",
	[":cdxShiXiang"] = "<font color=\"blue\"><b>锁定技</b></font>，你每令一名角色回复一次体力，该角色获得一枚“星”标记；<font color=\"green\"><b>阶段技</b></font>，你可以弃置一名角色的一枚“星”标记，令其摸两张牌。",
	["@cdxShiXiangMark"] = "星",
	["cdxshixiang"] = "示向",
}
--[[
	技能：先锋（限定技）
	描述：你死亡前，若场上“星”标记数不少于7，你可以指定至少一名其他角色并结束游戏，你与这些角色成为胜利者；否则你可以弃置所有的“星”标记并摸等量的牌，跳过死亡结算。
]]--
XianFengCard = sgs.CreateSkillCard{
	name = "cdxXianFengCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local message = {}
		table.insert(message, source:objectName())
		for _,p in ipairs(targets) do
			table.insert(message, p:objectName())
		end
		message = table.concat(message, "+")
		room:gameOver(message)
	end,
}
XianFengVS = sgs.CreateViewAsSkill{
	name = "cdxXianFeng",
	n = 0,
	view_as = function(self, cards)
		return XianFengCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@cdxXianFeng"
	end,
}
XianFeng = sgs.CreateTriggerSkill{
	name = "cdxXianFeng",
	frequency = sgs.Skill_Limited,
	events = {sgs.GameOverJudge},
	view_as_skill = XianFengVS,
	limit_mark = "@cdxXianFengMark",
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local victim = death.who
		if victim and victim:objectName() == player:objectName() then
			local count = 0
			local room = player:getRoom()
			local allplayers = room:getPlayers()
			for _,p in sgs.qlist(allplayers) do
				count = count + p:getMark("@cdxShiXiangMark")
			end
			if count >= 7 then
				room:askForUseCard(player, "@@cdxXianFeng", "@cdxXianFeng")
			elseif player:getMark("@cdxXianFengMark") > 0 then
				if player:askForSkillInvoke("cdxXianFeng", data) then
					player:loseMark("@cdxXianFengMark", 1)
					for _,p in sgs.qlist(allplayers) do
						if p:getMark("@cdxShiXiangMark") > 0 then
							p:loseAllMarks("@cdxShiXiangMark")
						end
					end
					if OPEN_CODEX then
						room:setPlayerProperty(player, "maxhp", sgs.QVariant(0))
					end
					room:revivePlayer(player)
					if OPEN_CODEX then
						room:setPlayerMark(player, "cdxXianFengState", 1)
					end
					room:drawCards(player, count, "cdxXianFeng")
					room:setTag("SkipGameRule", sgs.QVariant(true))
					return true
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill("cdxXianFeng")
	end,
	priority = 100,
}
if OPEN_CODEX then
function pass(room, player)
	room:addPlayerMark(player, "cdxXianFengProtect", 1)
	if player:getMark("cdxXianFengProtect") >= 49 then
		room:setPlayerMark(player, "cdxXianFengProtect", 0)
		if math.random(1, 100) <= 70 then
			room:killPlayer(player)
			return false
		end
		local maxhp = player:getMaxHp() + 1
		room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
	end
	return true
end
XianFengState = sgs.CreateTriggerSkill{
	name = "#cdxXianFeng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreHpLost, sgs.DamageForseen, sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreHpLost then
			if not pass(room, player) then
				return false
			end
			local msg = sgs.LogMessage()
			msg.type = "#cdxXianFengState_AntiHpLost"
			msg.from = player
			room:sendLog(msg) --发送提示信息
			return true
		elseif event == sgs.DamageForseen then
			local damage = data:toDamage()
			local victim = damage.to
			if victim and victim:objectName() == player:objectName() then
				if not pass(room, player) then
					return false
				end
				local msg = sgs.LogMessage()
				msg.type = "#cdxXianFengState_AntiDamage"
				msg.from = player
				room:sendLog(msg) --发送提示信息
				return true
			end
		elseif event == sgs.DrawNCards then
			local count = data:toInt()
			count = count + room:alivePlayerCount() 
			count = math.min(7, count)
			data:setValue(count)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getMark("cdxXianFengState") > 0 
	end,
	priority = 10,
}
XianFengKeep = sgs.CreateMaxCardsSkill{
	name = "#cdxXianFengKeep",
	extra_func = function(self, player)
		if player:getMark("cdxXianFengState") > 0 then
			return 7
		end
		return 0
	end,
}
end
--添加技能
BeiJi:addSkill(XianFeng)
if OPEN_CODEX then
BeiJi:addSkill(XianFengState)
BeiJi:addSkill(XianFengKeep)
end
--翻译信息
sgs.LoadTranslationTable{
	["cdxXianFeng"] = "先锋",
	[":cdxXianFeng"] = "<font color=\"red\"><b>限定技</b></font>，你死亡前，若场上“星”标记数不少于7，你可以指定至少一名其他角色并结束游戏，你与这些角色成为胜利者；否则你可以弃置所有的“星”标记并摸等量的牌，跳过死亡结算。",
	["@cdxXianFengMark"] = "先锋",
	["@cdxXianFeng"] = "您可以发动“先锋”选择至少一名其他角色，令你与这些角色成为游戏的胜利者",
	["~cdxXianFeng"] = "选择一些角色->点击“确定”",
	["#cdxXianFengState_AntiHpLost"] = "警告：你不能令 %from 失去体力",
	["#cdxXianFengState_AntiDamage"] = "警告：你不能令 %from 受到伤害",
	["cdxxianfeng"] = "先锋",
}