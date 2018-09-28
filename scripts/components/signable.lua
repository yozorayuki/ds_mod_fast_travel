local EditScreen = require "screens/editscreen"

Signs = {}

local Signable =
	Class(
	function(self, inst)
		self.inst = inst
		self.text = nil

		if self.inst and self.inst.components.inspectable then
			self.inst.components.inspectable:SetDescription(
				function(inst, viewr)
					if self.text and #self.text > 0 then
						return 'It writes "' .. self.text .. '".'
					else
						return "Nothing written on it."
					end
				end
			)
		end

		table.insert(Signs, self.inst)
	end
)

function Signable:CollectSceneActions(doer, actions, right)
	if self.inst:HasTag("burnt") or self.inst:HasTag("fire") then
		table.insert(actions, ACTIONS.SIGN_REPAIR)
	elseif not self.text or self.text == "" then
	-- table.insert(actions, ACTIONS.EDIT)
	end
end

function Signable:OnBuilt(builder)
	if self.inst.components.signable and builder then
		self.inst.components.signable:OnSign(builder)
	end
end

function Signable:OnRemoveEntity()
	for k, v in pairs(Signs) do
		if v == self.inst then
			table.remove(Signs, k)
			break
		end
	end
end

function Signable:OnSave()
	return {text = self.text}
end

function Signable:OnLoad(data)
	self:SetText(data.text)
end

function Signable:GetText()
	return self.text or ""
end

function Signable:SetText(text)
	self.text = text
end

function Signable:OnSign(signer)
	if signer then
		TheFrontEnd:PushScreen(EditScreen(self.inst, signer))
	end
end

return Signable
