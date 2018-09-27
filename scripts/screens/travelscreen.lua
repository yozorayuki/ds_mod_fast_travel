local Screen = require "widgets/screen"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local Menu = require "widgets/menu"

local display_rows = 5

local TravelScreen =
    Class(
    Screen,
    function(self, attach, traveller)
        Screen._ctor(self, "TravelScreen")

        self:Hide()
        SetPause(true, "pause")

        self.attach = attach
        self.traveller = traveller
        self.text = self.attach.components.signable and self.attach.components.signable:GetText() or ""

        self.root = self:AddChild(Widget("ROOT"))
        self.root:SetVAnchor(ANCHOR_MIDDLE)
        self.root:SetHAnchor(ANCHOR_MIDDLE)
        self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

        self.bg = self.root:AddChild(Image("images/globalpanels.xml", "panel.tex"))
        self.bg:SetSize(500, 650)
        self.bg:SetPosition(0, 25)

        self.current = self.root:AddChild(Text(BODYTEXTFONT, 35))
        self.current:SetPosition(0, 225, 0)
        self.current:SetRegionSize(350, 50)
        self.current:SetHAlign(ANCHOR_MIDDLE)
        if self.text ~= "" then
            self.current:SetString(self.text)
        else
            self.current:SetString("Unknow")
            self.current:SetColour(1, 0, 0, 0.4)
        end

        self.dest_offset = 0
        self.destspanel = self.root:AddChild(Menu(nil, -80, false))

        self.leftbutton = self.destspanel:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
        self.leftbutton:SetPosition(-250, 0, 0)
        self.leftbutton:SetRotation(180)
        self.leftbutton:SetOnClick(
            function()
                self:Scroll(-display_rows)
            end
        )

        self.rightbutton = self.destspanel:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
        self.rightbutton:SetPosition(250, 0, 0)
        self.rightbutton:SetOnClick(
            function()
                self:Scroll(display_rows)
            end
        )

        self.menu = self.root:AddChild(Menu(nil, 200, true))
        self.menu:SetScale(0.6)
        self.menu:SetPosition(0, -225, 0)
        self.editbutton =
            self.menu:AddItem(
            "Edit",
            function()
                self:OnEdit()
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

        self.destwidgets = {}
        self:ReloadDists()

        self.default_focus = self.cancelbutton
        self:Show()
    end
)

function TravelScreen:ReloadDists()
    self.dest_infos = self.attach.components.travelable and self.attach.components.travelable:MakeInfos()
    if not self.dest_infos then
        return
    end

    self.dest_offset = 0
    self:Scroll(0)
end

function TravelScreen:Scroll(dir)
    if (dir > 0 and (self.dest_offset + display_rows) < #self.dest_infos) or (dir < 0 and self.dest_offset + dir >= 0) then
        self.dest_offset = self.dest_offset + dir
    end

    self:RefreshDests()

    if self.dest_offset > 0 then
        self.leftbutton:Show()
    else
        self.leftbutton:Hide()
    end

    if self.dest_offset + display_rows < #self.dest_infos then
        self.rightbutton:Show()
    else
        self.rightbutton:Hide()
    end
end

function TravelScreen:RefreshDests()
    for k, v in pairs(self.destwidgets) do
        v:Kill()
    end
    self.destwidgets = {}
    self.destspanel:Clear()

    local page_total = math.min(#self.dest_infos - self.dest_offset, display_rows)
    for k = 1, page_total do
        local idx = self.dest_offset + k

        local info = self.dest_infos[idx]

        local dest = self.destspanel:AddCustomItem(Widget("destination"))

        dest.idx = idx

        dest.bg = dest:AddChild(UIAnim())
        dest.bg:GetAnimState():SetBuild("savetile")
        dest.bg:GetAnimState():SetBank("savetile")
        dest.bg:GetAnimState():PlayAnimation("anim")
        dest.bg:SetScale(1, 0.8, 1)

        dest.name = dest:AddChild(Text(BODYTEXTFONT, 35))
        dest.name:SetVAlign(ANCHOR_MIDDLE)
        dest.name:SetHAlign(ANCHOR_LEFT)
        dest.name:SetPosition(0, 10, 0)
        dest.name:SetRegionSize(300, 40)
        if info.name == "" then
            dest.name:SetString("Unknow")
            dest.name:SetColour(1, 1, 0, 0.6)
        else
            dest.name:SetString(info.name)
        end

        local cost_py = -20
        local cost_font = UIFONT
        local cost_fontsize = 20

        dest.cost_hunger = dest:AddChild(Text(cost_font, cost_fontsize))
        dest.cost_hunger:SetVAlign(ANCHOR_MIDDLE)
        dest.cost_hunger:SetHAlign(ANCHOR_LEFT)
        dest.cost_hunger:SetPosition(-100, cost_py, 0)
        dest.cost_hunger:SetRegionSize(100, 30)
        dest.cost_hunger:SetColour(1, 1, 1, 0.8)
        if info.cost_hunger then
            dest.cost_hunger:SetString("hunger: " .. info.cost_hunger)
        end

        dest.cost_sanity = dest:AddChild(Text(cost_font, cost_fontsize))
        dest.cost_sanity:SetVAlign(ANCHOR_MIDDLE)
        dest.cost_sanity:SetHAlign(ANCHOR_LEFT)
        dest.cost_sanity:SetPosition(-30, cost_py, 0)
        dest.cost_sanity:SetRegionSize(100, 30)
        dest.cost_sanity:SetColour(1, 1, 1, 0.8)
        if info.cost_sanity then
            dest.cost_sanity:SetString("sanity: " .. info.cost_sanity)
        end

        dest.status = dest:AddChild(Text(cost_font, cost_fontsize))
        dest.status:SetVAlign(ANCHOR_MIDDLE)
        dest.status:SetHAlign(ANCHOR_LEFT)
        dest.status:SetPosition(150, cost_py, 0)
        dest.status:SetRegionSize(100, 30)

        if info.inst == self.attach then
            dest.name:SetColour(0, 1, 0, 0.4)
            dest.cost_hunger:SetString("current")
            dest.cost_hunger:SetColour(0, 1, 0, 0.4)
            dest.cost_sanity:Hide()
            dest.status:Hide()
            dest:Disable()
        else
            if info.status then
                dest.status:SetString(info.status)
                dest.status:SetColour(1, 1, 0, 0.6)
                dest.cost_hunger:SetColour(1, 1, 0, 0.6)
                dest.cost_sanity:SetColour(1, 1, 0, 0.6)
            end
            if self.traveller.components.hunger and self.traveller.components.hunger.current < info.cost_hunger then
                dest.cost_hunger:SetColour(1, 0, 0, 0.4)
                dest:Disable()
            end
            if self.traveller.components.sanity and self.traveller.components.sanity.current < info.cost_sanity then
                dest.cost_sanity:SetColour(1, 0, 0, 0.4)
                dest:Disable()
            end
        end

        local spacing = 80
        dest:SetPosition(0, (display_rows - 1) * spacing * .5 - (k - 1) * spacing - 00, 0)

        dest.OnGainFocus = function()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            dest:SetScale(1.1, 1.1, 1)
            dest.bg:GetAnimState():PlayAnimation("over")
        end

        dest.OnLoseFocus = function()
            dest:SetScale(1, 1, 1)
            dest.bg:GetAnimState():PlayAnimation("anim")
        end

        if dest:IsEnabled() then
            dest.OnControl = function(_, control, down)
                if Widget.OnControl(dest, control, down) then
                    return true
                end
                if control == CONTROL_ACCEPT and not down then
                    self:DoTravel(dest.idx)
                    return true
                end
            end
        else
            dest:Enable()
        end

        table.insert(self.destwidgets, dest)
    end

    for k, v in ipairs(self.destspanel.items) do
        if k > 1 then
            self.destspanel.items[k]:SetFocusChangeDir(MOVE_UP, self.destspanel.items[k - 1])
        end

        if k < #self.destspanel.items then
            self.destspanel.items[k]:SetFocusChangeDir(MOVE_DOWN, self.destspanel.items[k + 1])
        end

        self.destspanel.items[k]:SetFocusChangeDir(
            MOVE_LEFT,
            function()
                if not self:OnFirstPage() then
                    self:Scroll(-display_rows)
                end
                return self.destspanel.items[k]
            end
        )

        self.destspanel.items[k]:SetFocusChangeDir(
            MOVE_RIGHT,
            function()
                if not self:OnLastPage() then
                    self:Scroll(display_rows)
                end
                if k > #self.destspanel.items then
                    return self.destspanel.items[#self.destspanel.items]
                else
                    return self.destspanel.items[k]
                end
            end
        )
    end

    if self.destspanel.items == nil or #self.destspanel.items == 0 then
        return
    end

    self.destspanel.items[#self.destspanel.items]:SetFocusChangeDir(MOVE_DOWN, self.editbutton)
    self.editbutton:SetFocusChangeDir(MOVE_UP, self.destspanel.items[#self.destspanel.items])
    self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.destspanel.items[#self.destspanel.items])
end

function TravelScreen:OnFirstPage()
    return self.dest_offset == 0
end

function TravelScreen:OnLastPage()
    return self.dest_offset + display_rows >= #self.dest_infos
end

function TravelScreen:DoTravel(idx)
    local info = self.dest_infos[idx]

    if self.attach.components.travelable then
        self.attach.components.travelable:DoTravel(self.traveller, info)
    end
    self:OnCancel()
end

function TravelScreen:OnCancel()
    TheFrontEnd:PopScreen(self)
    SetPause(false)
end

function TravelScreen:OnEdit()
    if self.attach.components.signable then
        TheFrontEnd:PopScreen(self)
        self.attach.components.signable:OnSign(self.traveller)
    end
end

function TravelScreen:OnControl(control, down)
    if self._base.OnControl(self, control, down) then
        return true
    end
    if not down and (control == CONTROL_PAUSE or control == CONTROL_CANCEL) then
        self:OnCancel()
        return true
    end
end

return TravelScreen
