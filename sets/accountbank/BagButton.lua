---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

BaudBag_AccountBank_BagButtonMixin = {}


function BaudBag_AccountBank_BagButtonMixin:Initialize()
    BaudBag_BagButtonMixin.Initialize(self)
end

function BaudBag_AccountBank_BagButtonMixin:UpdateContent()
    -- ensure we load potentially cached data when opening the account bank in offline mode before visiting the bank npc
    if not self.TabData and not AddOnTable.State.AccountBankOpen then
        local bagCache = AddOnTable.Cache:GetBagCache(self.SubContainerId)
        self.TabData = bagCache.TabData
    end

    -- now that all data should be present update the button content
    if (self.TabData) then
        self.ContainerNotPurchasedYet = false
        self.Icon:SetTexture(self.TabData.icon)
        self:SetQuality()
    else
        self.ContainerNotPurchasedYet = true
        self:SetItem()
    end
end

function BaudBag_AccountBank_BagButtonMixin:OnShow()
    self:UpdateContent()
end

function BaudBag_AccountBank_BagButtonMixin:UpdateTooltip()
    if not self.TabData then
        return
    end

    ---@type GameTooltip
    local tooltip = GameTooltip -- BaudBagBagsFrameTooltip
    tooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(tooltip, self.TabData.name, NORMAL_FONT_COLOR)
    if self.TabData.depositFlags then
        local depositFlags = self.TabData.depositFlags
        if FlagsUtil.IsSet(depositFlags, Enum.BagSlotFlags.ExpansionCurrent) then
            GameTooltip_AddNormalLine(tooltip, BANK_TAB_EXPANSION_ASSIGNMENT:format(BANK_TAB_EXPANSION_FILTER_CURRENT))
        elseif FlagsUtil.IsSet(depositFlags, Enum.BagSlotFlags.ExpansionLegacy) then
            GameTooltip_AddNormalLine(tooltip, BANK_TAB_EXPANSION_ASSIGNMENT:format(BANK_TAB_EXPANSION_FILTER_LEGACY))
        end
        
        -- TODO: global method
        local filterList = ContainerFrameUtil_ConvertFilterFlagsToList(depositFlags)
        if filterList then
            local wrapText = true
            GameTooltip_AddNormalLine(tooltip, BANK_TAB_DEPOSIT_ASSIGNMENTS:format(filterList), wrapText)
        end
    end
    GameTooltip_AddInstructionLine(tooltip, BANK_TAB_TOOLTIP_CLICK_INSTRUCTION)
    tooltip:Show()
end

function BaudBag_AccountBank_BagButtonMixin:OnClick(button)
    if button == "RightButton" and self.TabData then
        AddOnTable.Functions.DebugMessage("AccountBank", "BagButton#OnClick: recognized right click on already bought bank tab", self.TabData, self.SubContainerId)
        self:GetParent().TabSettingsMenu.selectedTabData = self.TabData
        self:GetParent().TabSettingsMenu:TriggerEvent(BankPanelTabSettingsMenuMixin.Event.OpenTabSettingsRequested, self.SubContainerId)
    end
end

function BaudBag_AccountBank_BagButtonMixin:OnCustomLeave()
    local tooltip = GameTooltip --BaudBagBagsFrameTooltip
    tooltip:Hide()

    BaudBag_BagButtonMixin.OnLeave(self)
end