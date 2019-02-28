local TravelScreen = require "screens/travelscreen"

local min_hunger_cost = 5
local max_hunger_cost = 75
local sanity_cost_ratio = 25 / 75

local Travelable =
	Class(
	function(self, inst)
		self.inst = inst
	end
)

function Travelable:CollectSceneActions(doer, actions, right)
	if right and not self.inst:HasTag("burnt") and not self.inst:HasTag("fire") then
		table.insert(actions, ACTIONS.DESTINATION)
	end
end

function Travelable:OnSelect(traveller)
	local comment = self.inst.components.talker
	if not traveller then
		if comment then
			comment:Say("Is there anyone touched me???")
		end
		return
	end
	local talk = traveller.components.talker

	if traveller.components.health and traveller.components.health:IsDead() then
		if comment then
			comment:Say("It's too late. We can't help you.")
		end
	elseif self:IsNearDanger(traveller) then
		if talk then
			talk:Say("It's not safe to travel.")
		elseif comment then
			comment:Say("It's not safe to travel.")
		end
		return
	else
		TheFrontEnd:PushScreen(TravelScreen(self.inst, traveller))
	end
end

function Travelable:MakeInfos()
	local dest_infos = {}
	local xi, yi, zi = self.inst.Transform:GetWorldPosition()
	for k, v in pairs(Signs) do
		local info = {}
		info.inst = v
		info.name = v.components.signable and v.components.signable:GetText()
		info.x, info.y, info.z = v.Transform:GetWorldPosition()
		local dist = math.sqrt((xi - info.x) ^ 2 + (zi - info.z) ^ 2)
		info.cost_hunger = math.ceil(math.min(min_hunger_cost + dist / TRAVEL_COST, max_hunger_cost))
		info.cost_sanity = math.ceil(info.cost_hunger * sanity_cost_ratio)
		if GetSeasonManager():GetSeasonString() == "winter" then
			info.cost_sanity = math.ceil(info.cost_sanity * 1.25)
		elseif GetSeasonManager():GetSeasonString() == "summer" then
			info.cost_sanity = math.ceil(info.cost_sanity * 0.75)
		end

		if v:HasTag("burnt") then
			info.status = "burnt"
		elseif v:HasTag("fire") then
			info.status = "fire"
		end
		if info.status then
			info.cost_hunger = math.ceil(info.cost_hunger * 1.5)
			info.cost_sanity = math.ceil(info.cost_sanity * 1.5)
		end

		if not v.ininterior then
			table.insert(dest_infos, info)
		end
	end

	table.sort(
		dest_infos,
		function(info1, info2)
			if info1.name == "" then
				return false
			end
			if info2.name == "" then
				return true
			end
			return string.lower(info1.name) < string.lower(info2.name)
		end
	)

	return dest_infos
end

function Travelable:DoTravel(traveller, info)
	local comment = self.inst.components.talker
	if not traveller then
		if comment then
			comment:Say("Is there anyone touched me???")
		end
		return
	end
	local talk = traveller.components.talker

	if self.inst.ininterior then
		if comment then
			comment:Say("NO TRAVELLING HERE.")
		elseif talk then
			talk:Say("It seems to be broken.")
		end
		return
	end

	if not info or not info.inst or not info.inst:IsValid() then
		if comment then
			comment:Say("The destination is no longer reachable.")
		elseif talk then
			talk:Say("The destination is no longer reachable.")
		end
		return
	end

	if traveller.components.hunger and traveller.components.hunger.current >= info.cost_hunger and traveller.components.sanity and traveller.components.sanity.current >= info.cost_sanity then
		traveller.components.hunger:DoDelta(-info.cost_hunger)
		traveller.components.sanity:DoDelta(-info.cost_sanity)

		if traveller.Physics then
			traveller.Physics:Teleport(info.x - 1, 0, info.z)
		else
			traveller.Transform:SetPosition(info.x - 1, 0, info.z)
		end

		-- follows
		if traveller.components.leader and traveller.components.leader.followers then
			for kf, vf in pairs(traveller.components.leader.followers) do
				if kf.Physics then
					kf.Physics:Teleport(info.x + 1, 0, info.z)
				else
					kf.Transform:SetPosition(info.x + 1, 0, info.z)
				end
			end
		end

		local inventory = traveller.components.inventory
		if inventory then
			for ki, vi in pairs(inventory.itemslots) do
				if vi.components.leader and vi.components.leader.followers then
					for kif, vif in pairs(vi.components.leader.followers) do
						if kif.Physics then
							kif.Physics:Teleport(info.x, 0, info.z + 1)
						else
							kif.Transform:SetPosition(info.x, 0, info.z + 1)
						end
					end
				end
			end
		end

		local container = inventory.overflow and inventory.overflow.components.container
		if container then
			for kb, vb in pairs(container.slots) do
				if vb.components.leader and vb.components.leader.followers then
					for kbf, vbf in pairs(vb.components.leader.followers) do
						if kbf.Physics then
							kbf.Physics:Teleport(info.x, 0, info.z - 1)
						else
							kbf.Transform:SetPosition(info.x, 0, info.z - 1)
						end
					end
				end
			end
		end

		local text = self.inst.components.signable and self.inst.components.signable:GetText()
		if not text or text == "" then
			self.inst:Remove()
			SpawnPrefab("boards").Transform:SetPosition(info.x, info.y, info.z)
		end
	else
		if talk then
			talk:Say("It's too far.")
		elseif comment then
			comment:Say("It's too far.")
		end
	end
end

function Travelable:IsNearDanger(traveller)
	if not traveller then
		print("traveller is nil\n", debug.traceback())
		return true
	end

	local hounded = GetWorld().components.hounded
	if hounded and (hounded.warning or hounded.timetoattack <= 0) then
		return true
	end
	local burnable = traveller.components.burnable
	if burnable and (burnable:IsBurning() or burnable:IsSmoldering()) then
		return true
	end
	if traveller:HasTag("spiderwhisperer") then
		return FindEntity(
			traveller,
			10,
			function(target)
				return (target.components.combat and target.components.combat.target == traveller) or (target:HasTag("monster") and not target:HasTag("spider")) or target:HasTag("pig")
			end,
			nil,
			nil,
			{"monster", "pig", "_combat"}
		)
	end
	return FindEntity(
		traveller,
		10,
		function(target)
			return (target.components.combat and target.components.combat.target == traveller) or target:HasTag("monster")
		end,
		nil,
		nil,
		{"monster", "_combat"}
	)
end

function Travelable:Reload()
	package.loaded["screens/travelscreen"] = nil
	TravelScreen = require "screens/travelscreen"
	print("TravelScreen Reloaded")
end

return Travelable
