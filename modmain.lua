GLOBAL.TRAVEL_COST = GetModConfigData("Travel_Cost")

local function TravelableInit(inst)
	inst:AddComponent("signable")
	inst:AddComponent("travelable")
	inst:AddComponent("talker")
end
AddPrefabPostInit("homesign", TravelableInit)

-------------------- Actions --------------------
local Action = GLOBAL.Action
local ActionHandler = GLOBAL.ActionHandler
local SpawnPrefab = GLOBAL.SpawnPrefab

local EDIT = Action({}, 9, false, true)
EDIT.str = "Edit"
EDIT.id = "EDIT"
EDIT.fn = function(act)
	local tar = act.target
	local signer = act.doer
	if tar and tar.components.signable and signer then
		tar.components.signable:OnSign(signer)
		return true
	end
end
AddAction(EDIT)
AddStategraphActionHandler("wilson", ActionHandler(EDIT, "give"))

local SIGN_REPAIR = Action({}, 10, false)
SIGN_REPAIR.str = "Repair"
SIGN_REPAIR.id = "SIGN_REPAIR"
SIGN_REPAIR.fn = function(act)
	local tar = act.target
	if tar and tar:HasTag("fire") then
		tar.components.burnable:Extinguish()
		return true
	end
	if tar and tar:HasTag("burnt") then
		local prod = SpawnPrefab(tar.prefab)
		if prod then
			local pt = Point(tar.Transform:GetWorldPosition())
			local text = tar.components.signable and tar.components.signable:GetText()
			tar:Remove()

			prod.Transform:SetPosition(pt.x, pt.y, pt.z)
			if prod.components.signable then
				prod.components.signable:SetText(text)
			end

			return true
		end
	end
end
AddAction(SIGN_REPAIR)
AddStategraphActionHandler("wilson", ActionHandler(SIGN_REPAIR, "dolongaction"))

local DESTINATION = Action({}, 10, false, true)
DESTINATION.str = "Select Destination"
DESTINATION.id = "DESTINATION"
DESTINATION.fn = function(act)
	local tar = act.target
	local traveller = act.doer
	if tar and tar.components.travelable and traveller then
		tar:DoTaskInTime(
			.2,
			function()
				tar.components.travelable:OnSelect(traveller)
			end
		)
		return true
	end
end
AddAction(DESTINATION)
AddStategraphActionHandler("wilson", ActionHandler(DESTINATION, "give"))
