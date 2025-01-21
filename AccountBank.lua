---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local Funcs = AddOnTable.Functions
local Events = AddOnTable.Events
local Localized = AddOnTable.Localized

local function extendBaseType()
    Funcs.DebugMessage("AccountBank", "AccountBank#extendBaseType()")
    BagSetType["AccountBank"] = {
        Id = 6,
        Name = Localized.AccountBank,
        TypeName = "AccountBank",
        IsSupported = function() return true end,
        IsSubContainerOf = function(containerId)
            local isAccountBankContainer = (containerId == AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER)
            local isAccountBankSubContainer = (AddOnTable.BlizzConstants.ACCOUNT_BANK_FIRST_SUB_CONTAINER <= containerId) and (containerId <= AddOnTable.BlizzConstants.ACCOUNT_BANK_LAST_SUB_CONTAINER)
            return isAccountBankContainer or isAccountBankSubContainer
        end,
        ContainerIterationOrder = {},
        Init = function()
            -- AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER seems to only hold a list of purchased bank tabs along with an rather undefined icon
            -- not really sure what this thing is supposed to be for
            -- table.insert(BagSetType.AccountBank.ContainerIterationOrder, AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER)
            for bag = AddOnTable.BlizzConstants.ACCOUNT_BANK_FIRST_SUB_CONTAINER, AddOnTable.BlizzConstants.ACCOUNT_BANK_LAST_SUB_CONTAINER do
                table.insert(BagSetType.AccountBank.ContainerIterationOrder, bag)
            end

            for index, bagId in ipairs(BagSetType.AccountBank.ContainerIterationOrder) do
                AddOnTable.ContainerIdOptionsIndexMap[bagId] = index
            end
        end,
        NumberOfContainers = math.max(1, AddOnTable.BlizzAPI.FetchNumPurchasedBankTabs(Enum.BankType.Account)),
        DefaultConfig = {
            Columns = 14,
            Scale = 100,
            GetNameAddition = function(bagId) return Localized.AccountBank end,
            RequiresFreshConfig = function(bagId) return false end,
            Background = 2
        },
        GetContainerTemplate = function(containerId) return "BaudBagAccountBankContainerTemplate" end,
        GetItemButtonTemplate = function(containerId) return "AccountBankItemButtonTemplate" end,
        GetSize = function(containerId)
            if (BagSetType["AccountBank"].ShouldUseCache()) then
                local bagCache = AddOnTable.Cache:GetBagCache(containerId)
                if bagCache then
                    return bagCache.Size
                end
            end
            local purchasedBankTabIds  = AddOnTable.BlizzAPI.FetchPurchasedBankTabIDs(Enum.BankType.Account)

            -- necessary to get a visible first container even when not bought yet (so that we CAN buy)
            if table.getn(purchasedBankTabIds) == 0 and containerId == AddOnTable.BlizzConstants.ACCOUNT_BANK_FIRST_SUB_CONTAINER then
                return 98
            end

            for _, tabId in ipairs (purchasedBankTabIds) do
                if tabId == containerId then
                    return 98
                end
            end
            return 0
        end,
        SupportsCache = true,
        ShouldUseCache = function() return not AddOnTable.State.AccountBankOpen end,
        BagOverview_Initialize = function() _G["BaudBagContainer6_1"].BagsFrame:Initialize() end,
    }
    tinsert(BagSetTypeArray, BagSetType.AccountBank)

    AddOnTable.State.AccountBankOpen = false
end
hooksecurefunc(AddOnTable, "ExtendBaseTypes", extendBaseType)

EventRegistry:RegisterFrameEventAndCallback("BANKFRAME_OPENED", function(ownerID, ...)
    Funcs.DebugMessage("AccountBank", "AccountBank#bankframeOpened()")
    AddOnTable.State.AccountBankOpen = true
    ---@type BagSet
    local bagSet = AddOnTable.Sets[BagSetType.AccountBank.Id]
    bagSet:RebuildContainers()
    bagSet.Containers[1].Frame.BagsFrame:Update()
    bagSet:Open()
end, nil)

EventRegistry:RegisterFrameEventAndCallback("BANKFRAME_CLOSED", function(ownerID, ...)
    Funcs.DebugMessage("AccountBank", "AccountBank#bankframeClosed()")
    AddOnTable.State.AccountBankOpen = false
	AddOnTable.Sets[BagSetType.AccountBank.Id]:Close()
end, nil)

BaudBagFirstAccountBankMixin = {}

local function switchToUnlockMode(self)
    -- ensure unlock frame exists
    self.UnlockInfo = CreateFrame("Frame", "BaudBagAccountBankPurchase", _G["BaudBagContainer6_1"], "BaudBagContainerUnlockTemplate")
    Mixin(self.UnlockInfo, BaudBagAccountBankUnlockMixin)
    self.UnlockInfo:OnLoad()

    -- ensure that everything intefering with the unlock frame is being hidden
    self.showInfoBar = false
    self.MoneyFrame:Hide()
    self.BagsFrame:Hide()
    self.BagsButton:Hide()
    self.SearchButton:Hide()
    self.MenuButton:Hide()
end

local function endUnlockMode(self)
    -- unlock frame needs to vanish
    self.UnlockInfo:Hide()

    -- we need to re-enable everything that we've hidden earlier
    self.showInfoBar = true
    self.MoneyFrame:Show()
    self.BagsFrame:Show()
    self.BagsButton:Show()
    self.SearchButton:Show()
    self.MenuButton:Show()
end

function BaudBagFirstAccountBankMixin:Initialize()
    local purchasedBankTabsIds = AddOnTable.BlizzAPI.FetchPurchasedBankTabIDs(Enum.BankType.Account)
    if table.getn(purchasedBankTabsIds) == 0 then
        switchToUnlockMode(self)
    end
    MoneyFrame_SetType(self.MoneyFrame.SmallMoneyFrame, "ACCOUNT")
    self.MoneyFrame.SmallMoneyFrame:SetPoint("RIGHT", self.MoneyFrame.DepositFrame, "LEFT", -4, 0)
    self.MoneyFrame.DepositFrame:Show()
    self.MoneyFrame.DepositFrame.DepositButton:SetScript("OnClick", self.OnDeposit)
    self.MoneyFrame.DepositFrame.WithdrawButton:SetScript("OnClick", self.OnWithdrawal)
end

function BaudBagFirstAccountBankMixin:OnAccountBankShow()

    --[[if self:ShouldShowLockPrompt() then
		self:ShowLockPrompt();
		return;
	end]]

    self:RegisterEvent("ACCOUNT_MONEY")
    MoneyFrame_UpdateMoney(self.MoneyFrame.SmallMoneyFrame)
    self:RefreshDepositButtons()
    self:OnShow()
end

function BaudBagFirstAccountBankMixin:OnAccountBankEvent(event, ...)
    if (event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED") then
        Funcs.DebugMessage("AccountBank", "AccountBankFirstContainer#PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", ...)
        if self.UnlockInfo ~= nil then
            endUnlockMode(self)
            AddOnTable.Sets[BagSetType.AccountBank.Id].Containers[1]:Rebuild()
            AddOnTable.Sets[BagSetType.AccountBank.Id].Containers[1].BagsFrame:Update()
        end
    elseif (event == "ACCOUNT_MONEY") then
        MoneyFrame_UpdateMoney(self.MoneyFrame.SmallMoneyFrame)
        self:RefreshDepositButtons()
    end

    self:OnContainerEvent(event, ...)

    -- fallback for inherited OnEvents
    if (self.OnEvent) then
        self:OnEvent(event, ...)
    end
end

function BaudBagFirstAccountBankMixin:OnAccountBankHide()
    self:UnregisterEvent("ACCOUNT_MONEY")
    self:OnHide()
end

function BaudBagFirstAccountBankMixin:RefreshDepositButtons()
    local isAccountBankLocked = not C_PlayerInfo.HasAccountInventoryLock()
    local disabledTooltip = isAccountBankLocked and ACCOUNT_BANK_ERROR_NO_LOCK or nil;

    local canWithdrawMoney = C_Bank.CanWithdrawMoney(Enum.BankType.Account);
    local canDepositMoney = C_Bank.CanDepositMoney(Enum.BankType.Account);

    self.MoneyFrame.DepositFrame.WithdrawButton:SetEnabled(canWithdrawMoney);
    self.MoneyFrame.DepositFrame.DepositButton:SetEnabled(canDepositMoney);

    self.MoneyFrame.DepositFrame.WithdrawButton.disabledTooltip = disabledTooltip
    self.MoneyFrame.DepositFrame.DepositButton.disabledTooltip = disabledTooltip
end

function BaudBagFirstAccountBankMixin:OnWithdrawal()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);

	StaticPopup_Hide("BANK_MONEY_DEPOSIT");

	local alreadyShown = StaticPopup_Visible("BANK_MONEY_WITHDRAW");
	if alreadyShown then
		StaticPopup_Hide("BANK_MONEY_WITHDRAW");
		return;
	end

	StaticPopup_Show("BANK_MONEY_WITHDRAW", nil, nil, { bankType = Enum.BankType.Account });
end

function BaudBagFirstAccountBankMixin:OnDeposit()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);

	StaticPopup_Hide("BANK_MONEY_WITHDRAW");

	local alreadyShown = StaticPopup_Visible("BANK_MONEY_DEPOSIT");
	if alreadyShown then
		StaticPopup_Hide("BANK_MONEY_DEPOSIT");
		return;
	end

	StaticPopup_Show("BANK_MONEY_DEPOSIT", nil, nil, { bankType = Enum.BankType.Account });
end

--[[ ####################################### UnlockInfo frame ####################################### ]]
BaudBagAccountBankUnlockMixin = {}

function BaudBagAccountBankUnlockMixin:OnLoad()
    BaudBagContainerUnlockMixin.OnLoad(self)
    self.Title:SetText(AddOnTable.BlizzConstants.ACCOUNT_BANK_PANEL_TITLE)
    self.Text:SetText(AddOnTable.BlizzConstants.ACCOUNT_BANK_TAB_PURCHASE_PROMPT)
    self.PurchaseButton:SetAttribute("clickbutton", AccountBankPanel.PurchasePrompt.TabCostFrame.PurchaseButton)
end

function BaudBagAccountBankUnlockMixin:OnShow()
    self:Refresh()
    self:RegisterEvent("PLAYER_MONEY")
end

function BaudBagAccountBankUnlockMixin:OnEvent(event, ...)
	if event == "PLAYER_MONEY" then
		self:Refresh()
	end
end

function BaudBagAccountBankUnlockMixin:OnHide()
    self:UnregisterEvent("PLAYER_MONEY")
end

function BaudBagAccountBankUnlockMixin:Refresh()
	local tabCost = AddOnTable.BlizzAPI.FetchNextPurchasableBankTabCost(Enum.BankType.Account)
	if tabCost then 
        -- TODO: check if it is reasonable to wrap that or not
		MoneyFrame_Update(self.CostMoneyFrame, tabCost);
		local canAfford = GetMoney() >= tabCost;
		SetMoneyFrameColorByFrame(self.CostMoneyFrame, canAfford and "white" or "red");
	end
end

--[[ ########################################## Bags frame ########################################## ]]

local function UpdateContent(self)
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

local function OnShowOverride(self)
    self:UpdateContent()
end

local function UpdateTooltip(self)
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

local function OnClick(self, button)
    if button == "RightButton" and self.TabData then
        Funcs.DebugMessage("AccountBank", "BagButton#OnClick: recognized right click on already bought bank tab", self.TabData, self.SubContainerId)
        self:GetParent().TabSettingsMenu.selectedTabData = self.TabData
        self:GetParent().TabSettingsMenu:TriggerEvent(BankPanelTabSettingsMenuMixin.Event.OpenTabSettingsRequested, self.SubContainerId)
    end
end

local function OnCustomLeave(self)
    local tooltip = GameTooltip --BaudBagBagsFrameTooltip
    tooltip:Hide()

    self:OnLeave()
end

BaudBagAccountBagsFrameMixin = {}

function BaudBagAccountBagsFrameMixin:Initialize()
    --[[if (#AddOnTable.BlizzAPI.FetchPurchasedBankTabIDs(Enum.BankType.Account) == 0) then
        return
    end]]

    local accountBankSet = AddOnTable.Sets[BagSetType.AccountBank.Id]

    for bag = 1, AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER_NUM do
        local subContainerId = AddOnTable.BlizzConstants.BANK_LAST_CONTAINER + bag
        local bagButton = AddOnTable:CreateBagButton(BagSetType.AccountBank, subContainerId, bag, self)
        -- bagButton:SetPoint("TOPLEFT", 8, -8 - (bag-1) * bagButton:GetHeight())
        bagButton:SetPoint("TOPLEFT", 8 + mod(bag - 1, 2) * 39, -8 - floor((bag - 1) / 2) * 39)
        bagButton.UpdateContent = UpdateContent
        bagButton.UpdateTooltip = UpdateTooltip
        bagButton.OnShowOverride = OnShowOverride
        bagButton:SetScript("OnClick", OnClick)
        bagButton:SetScript("OnLeave", OnCustomLeave)
        accountBankSet.BagButtons[bag] = bagButton
    end

    self.PurchaseFrame.PurchaseButton:SetAttribute("clickbutton", AccountBankPanel.PurchasePrompt.TabCostFrame.PurchaseButton)
    local firstBagButton = accountBankSet.BagButtons[1]
    self:SetWidth(15 + (firstBagButton:GetWidth() * 2))
    self:Update()
end

function BaudBagAccountBagsFrameMixin:Update()
    local accountBankSet = AddOnTable.Sets[BagSetType.AccountBank.Id]
    local purchasedBankTabData = AddOnTable.BlizzAPI.FetchPurchasedBankTabData(Enum.BankType.Account)
    local numberOfBoughtContainers = #purchasedBankTabData
    AddOnTable.Functions.DebugMessage("AccountBank", "BagOverview: updating content", purchasedBankTabData, numberOfBoughtContainers)

    local bagSlot
    for bag = 1, AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER_NUM do
        bagSlot = accountBankSet.BagButtons[bag]
        if bag <= numberOfBoughtContainers then
            local tabData = purchasedBankTabData[bag]
            bagSlot.TabData = tabData
            local bagCache = AddOnTable.Cache:GetBagCache(bagSlot.SubContainerId)
            bagCache.TabData = tabData
        end
        bagSlot:UpdateContent()
    end

    if (numberOfBoughtContainers == AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER_NUM) then
        AddOnTable.Functions.DebugMessage("AccountBank", "BagOverview: all containers bought hiding purchase button")
        self.PurchaseFrame:Hide()
        self:UpdateHeight(accountBankSet.BagButtons[1]:GetHeight(), false)
        return
    end

    local cost = AddOnTable.BlizzAPI.FetchNextPurchasableBankTabCost(Enum.BankType.Account)
    if (AddOnTable.BlizzAPI.GetMoney() >= cost) then
        SetMoneyFrameColorByFrame(self.PurchaseFrame.MoneyFrame)
    else
        SetMoneyFrameColorByFrame(self.PurchaseFrame.MoneyFrame, "red")
    end
    MoneyFrame_Update(self.PurchaseFrame.MoneyFrame, cost)
    self.PurchaseFrame:Show()
    self:UpdateHeight(accountBankSet.BagButtons[1]:GetHeight(), true)
end

---@param withPurchaseFrame boolean
function BaudBagAccountBagsFrameMixin:UpdateHeight(firstButtonHeight, withPurchaseFrame)
    local purchaseHeight = 0
    if (withPurchaseFrame) then
        purchaseHeight = 40
    end
    --self:SetHeight(15 + AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER_NUM * firstBagButton:GetHeight() + 30)
    self:SetHeight(15 + ceil(AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER_NUM / 2) * firstButtonHeight + purchaseHeight)
end

function BaudBagAccountBagsFrameMixin:OnShow()
    if self.PurchaseFrame then
        if AddOnTable.State.AccountBankOpen then
            self.PurchaseFrame.PurchaseButton:Enable()
        else
            self.PurchaseFrame.PurchaseButton:Disable()
        end
    end
end

--[[ ###################################### Bags Settings frame ##################################### ]]

BaudBagAccountBankTabSettingsMixin = {}

function BaudBagAccountBankTabSettingsMixin:SetSelectedTab(selectedTabId)
    -- intentionally empty, please set the selectedTabData before requesting to show tab settings!
end

--[[ ###################################### Container Template ###################################### ]]

BaudBagAccountBankContainerMixin = {}

function BaudBagAccountBankContainerMixin:OnContainerLoad()
    self:OnLoad()

    -- on unload because it should be ensured that hiding also happens when the frame is not currently visible (otherwise the frame might only vanish)
    self:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
end

function BaudBagAccountBankContainerMixin:OnContainerEvent(event, ...)
    if (event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED" or event == "BAG_UPDATE") then
        local containerIndex = ...
        if (containerIndex == self:GetID()) then
            Funcs.DebugMessage("AccountBank", "AccountBankContainer#"..event, ...)
            self.QueueForUpdate = true
        end
    end

    if (event == "BAG_UPDATE_DELAYED" and self.QueueForUpdate) then
        AddOnTable.Sets[BagSetType.AccountBank.Id].Containers[self:GetID()]:Update()
    end

    -- fallback for inherited OnEvents
    if (self.OnEvent) then
        self:OnEvent(event, ...)
    end
end

function BaudBagAccountBankContainerMixin:UpdateBagHighlight()
    Funcs.DebugMessage("AccountBank", "AccountBankContainer#UpdateBagHighlight")
    local bagSet = AddOnTable.Sets[BagSetType.AccountBank.Id]
    for _, subContainer in pairs(bagSet.Containers[self:GetID()].SubContainers) do
        local button = bagSet.BagButtons[subContainer.ContainerId - AddOnTable.BlizzConstants.ACCOUNT_BANK_FIRST_SUB_CONTAINER + 1]
        if (subContainer:IsOpen()) then
            button.SlotHighlightTexture:Show()
        else
            button.SlotHighlightTexture:Hide()
        end
    end
end

--[[ ######################################### Item Buttons ######################################### ]]

---@param self BBItemButton
local function ItemButton_OnCustomEnter(self)
    local bagId = self:GetParent():GetID()
    local slotId = self:GetID()
    self:UpdateTooltipFromCache(bagId, slotId)
end

hooksecurefunc(AddOnTable, "ItemSlot_Created", function(self, bagSet, containerId, subcontainerId, slot, button)
    if (bagSet == BagSetType.AccountBank) then
        button:Init(subcontainerId, slot)
        button:SetScript("OnEnter", ItemButton_OnCustomEnter)
    end
end)


function BaudBagToggleWarbandBank()
    local warbandBankSet = AddOnTable.Sets[BagSetType.AccountBank.Id]
    local firstContainer = warbandBankSet.Containers[1]
    if (firstContainer.Frame:IsShown()) then
        firstContainer.Frame:Hide()
        warbandBankSet:AutoClose()
    else
        firstContainer.Frame:Show()
        warbandBankSet:AutoOpen()
    end
end