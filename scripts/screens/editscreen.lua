local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Menu = require "widgets/menu"
local TextEdit = require "widgets/textedit"
local Text = require "widgets/text"

local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"]]

local EditScreen =
	Class(
	Screen,
	function(self, attach, signer)
		Screen._ctor(self, "EditScreen")

		self:Hide()
		SetPause(true, "pause")

		self.attach = attach
		self.signer = signer
		self.text = self.attach.components.signable and self.attach.components.signable:GetText() or ""

		self.root = self:AddChild(Widget("ROOT"))
		self.root:SetVAnchor(ANCHOR_MIDDLE)
		self.root:SetHAnchor(ANCHOR_MIDDLE)
		self.root:SetPosition(0, 0, 0)
		self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

		self.bg = self.root:AddChild(Image("images/globalpanels.xml", "panel.tex"))
		self.bg:SetPosition(0, 0, 0)
		self.bg:SetSize(500, 300)

		local sign_offset = 30
		local edit_height = 50
		local edit_width = 350
		local edit_bg_padding = 60
		local fontsize = 30
		local hintsize = 25

		self.sign_bg = self.root:AddChild(Image())
		self.sign_bg:SetTexture("images/ui.xml", "textbox_long.tex")
		self.sign_bg:SetPosition(0, sign_offset, 0)
		self.sign_bg:ScaleToSize(edit_width + edit_bg_padding, edit_height)

		self.sign = self.root:AddChild(TextEdit(BODYTEXTFONT, fontsize, self.text or ""))
		self.sign:SetPosition(0, sign_offset, 0)
		self.sign:SetRegionSize(edit_width, edit_height)
		self.sign:SetHAlign(ANCHOR_LEFT)
		self.sign:SetFocusedImage(self.sign_bg, UI_ATLAS, "textbox_long_over.tex", "textbox_long.tex")
		self.sign:SetTextLengthLimit(30)
		self.sign:SetCharacterFilter(VALID_CHARS)
		self.sign:SetAllowClipboardPaste(true)
		self.sign.OnTextInput = function(_, text)
			local origin = _:GetLineEditString()
			local re = TextEdit.OnTextInput(_, text)
			if origin ~= _:GetLineEditString() then
				self.hint:Hide()
			end
			return re
		end
		self.sign.OnRawKey = function(_, key, down)
			if not down and key == KEY_ENTER then
				self:OnWrite()
				return true
			end
			if not down and key == KEY_BACKSPACE then
				self.hint:Hide()
			end
			return TextEdit.OnRawKey(_, key, down)
		end

		self.hint = self.root:AddChild(Text(BODYTEXTFONT, hintsize, "sign already exists"))
		self.hint:SetPosition(0, -5, 0)
		self.hint:SetRegionSize(edit_width, edit_height)
		self.hint:SetHAlign(ANCHOR_LEFT)
		self.hint:SetColour(1, 0, 0, 0.8)
		self.hint:Hide()

		self.menu = self.root:AddChild(Menu(nil, 200, true))
		self.menu:SetScale(0.6)
		self.menu:SetPosition(0, -50, 0)
		self.writebutton =
			self.menu:AddItem(
			"Write",
			function()
				self:OnWrite()
			end
		)
		self.destroybutton =
			self.menu:AddItem(
			"Destroy",
			function()
				self:OnRemove()
			end
		)
		self.cancelbutton =
			self.menu:AddItem(
			"Cancel",
			function()
				self:OnCancel()
			end
		)
		self.menu:SetHRegPoint(ANCHOR_MIDDLE)

		self.sign:SetFocusChangeDir(MOVE_DOWN, self.writebutton)
		self.writebutton:SetFocusChangeDir(MOVE_UP, self.sign)
		self.destroybutton:SetFocusChangeDir(MOVE_UP, self.sign)
		self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.sign)

		self.default_focus = self.cancelbutton
		self:Show()
	end
)

function EditScreen:OnWrite()
	local text = self.sign:GetLineEditString()
	if text ~= self.text then
		if text and text ~= "" then
			for k, v in pairs(Signs) do
				if v.components.signable and v.components.signable:GetText() == text and v ~= self.attach then
					self.hint:Show()
					return
				end
			end
		end
		if self.attach.components.signable then
			self.attach.components.signable:SetText(text)
		end
	end
	if self.attach.components.travelable then
		TheFrontEnd:PopScreen(self)
		self.attach.components.travelable:OnSelect(self.signer)
	else
		self:OnCancel()
	end
end

function EditScreen:OnRemove()
	if self.attach then
		self.attach.components.lootdropper:DropLoot()
		SpawnPrefab("collapse_big").Transform:SetPosition(self.attach.Transform:GetWorldPosition())
		self.attach.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
		self.attach:Remove()
	end
	self:OnCancel()
end

function EditScreen:OnCancel()
	TheFrontEnd:PopScreen(self)
	SetPause(false)
end

function EditScreen:OnControl(control, down)
	if self._base.OnControl(self, control, down) then
		return true
	end
	if not down and (control == CONTROL_PAUSE or control == CONTROL_CANCEL) then
		self:OnCancel()
		return true
	end
	if not down and control == CONTROL_ACCEPT then
		self:OnWrite()
		return true
	end
end

return EditScreen
