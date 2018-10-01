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

		self.signedit = self.root:AddChild(TextEdit(BODYTEXTFONT, fontsize, self.text or ""))
		self.signedit:SetPosition(0, sign_offset, 0)
		self.signedit:SetRegionSize(edit_width, edit_height)
		self.signedit:SetHAlign(ANCHOR_LEFT)
		self.signedit:SetFocusedImage(self.sign_bg, UI_ATLAS, "textbox_long_over.tex", "textbox_long.tex")
		self.signedit:SetTextLengthLimit(30)
		self.signedit:SetCharacterFilter(VALID_CHARS)
		self.signedit:SetAllowClipboardPaste(true)
		self.signedit.OnTextInput = function(_, text)
			local origin = _:GetLineEditString()
			local re = TextEdit.OnTextInput(_, text)
			if origin ~= _:GetLineEditString() then
				self.hint:Hide()
			end
			return re
		end
		self.signedit.OnControl = function(_, control, down)
			-- print("ctl", control, down)
			return TextEdit.OnControl(_, control, down)
		end
		self.signedit.OnRawKey = function(_, key, down)
			-- print("key", key, down)
			if down then
				_.enter_focused = false
			else
				if key == KEY_BACKSPACE then
					self.hint:Hide()
				elseif key == KEY_ENTER and _.enter_focused then
					self:OnWrite()
				end
			end
			if key == KEY_W or key == KEY_S or key == KEY_A or key == KEY_D then
				_.dofocusmove = false
			else
				_.dofocusmove = true
			end
			return TextEdit.OnRawKey(_, key, down)
		end
		self.signedit.OnTextEntered = function(text)
			self.signedit.enter_focused = true
		end
		self.signedit.OnFocusMove = function(_, dir, down)
			-- print("fcs", dir, down)
			if not _.dofocusmove or dir == MOVE_LEFT or dir == MOVE_RIGHT then
				return true
			end
			return Widget.OnFocusMove(_, dir, down)
		end

		self.hint = self.root:AddChild(Text(BODYTEXTFONT, hintsize, "signedit already exists"))
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

		self.signedit:SetFocusChangeDir(MOVE_DOWN, self.writebutton)
		self.writebutton:SetFocusChangeDir(MOVE_UP, self.signedit)
		self.destroybutton:SetFocusChangeDir(MOVE_UP, self.signedit)
		self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.signedit)

		self.default_focus = self.signedit
		self:Show()
		self.signedit:SetEditing(true)
		self.isopen = true
	end
)

function EditScreen:OnWrite()
	if not self.isopen then
		return
	end

	local text = self.signedit:GetLineEditString()
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
	self:OnCancel()
	if self.attach.components.travelable then
		self.attach.components.travelable:OnSelect(self.signer)
	else
		print("is not travelable\n", debug.traceback())
	end
end

function EditScreen:OnRemove()
	if not self.isopen then
		return
	end

	if self.attach then
		self.attach.components.lootdropper:DropLoot()
		SpawnPrefab("collapse_big").Transform:SetPosition(self.attach.Transform:GetWorldPosition())
		self.attach.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
		self.attach:Remove()
	else
		print("self.attach is nil\n", debug.traceback())
	end
	self:OnCancel()
end

function EditScreen:OnCancel()
	if not self.isopen then
		return
	end

	TheFrontEnd:PopScreen(self)
	SetPause(false)
end

function EditScreen:OnRawKey(key, down)
	if self._base.OnRawKey(self, key, down) then
		return true
	end
	if down then
		self.keyin = true
	else
		if key == KEY_ENTER and self.keyin then
			self:OnWrite()
			return true
		end
		self.keyin = false
	end
end

function EditScreen:OnControl(control, down)
	if self._base.OnControl(self, control, down) then
		return true
	end
	if not down then
		if control == CONTROL_CANCEL then
			self:OnCancel()
			return true
		end
	end
end

return EditScreen
