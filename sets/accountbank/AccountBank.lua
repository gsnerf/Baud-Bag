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
        NumberOfContainers = math.max(1, AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER_NUM),
        DefaultConfig = {
            Columns = 14,
            Scale = 100,
            GetNameAddition = function(bagId) return Localized.AccountBank end,
            RequiresFreshConfig = function(bagId) return false end,
            Theme = "BlizzBankDragonflight"
        },
        ApplyConfigRestorationSpecificalities = function(configObject) end,
        CanContainerBeJoined = function(subContainerId) return true end,
        LinkedSet = function() return BagSetType.Bank and BagSetType.Bank or nil end,
        GetContainerTemplate = function(containerId) return "BaudBagAccountBankContainerTemplate" end,
        GetItemButtonTemplate = function(containerId) return "BankItemButtonTemplate" end,
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
        UpdateOpenBagHighlight = function(subContainer)
            local open = subContainer:IsOpen()
            local button = AddOnTable.Sets[BagSetType.AccountBank.Id].BagButtons[subContainer.ContainerId - AddOnTable.BlizzConstants.ACCOUNT_BANK_FIRST_SUB_CONTAINER + 1]
            if (button) then
                if (open) then
                    button.SlotHighlightTexture:Show()
                else
                    button.SlotHighlightTexture:Hide()
                end
            end
        end,
        BagFilterGetFunction = nil,
        BagFilterSetFunction = function() end,
        CanInteractWithBags = function() return AddOnTable.Sets[BagSetType.AccountBank.Id].Containers[1].Frame:IsShown() end,
        OnItemButtonCustomEnter = function(self) end,
        FilterData = {
            GetFilterType = function(container) return false end,
            SetFilterType = function(container, type, value) end,
            GetCleanupIgnore = function(container) return false end,
            SetCleanupIgnore = function(container, value) end,
        },
        CustomCloseAllFunction = function() end,
        GetSpecialBagTexture = function(subContainerId) return nil end,
    }
    tinsert(BagSetTypeArray, BagSetType.AccountBank)

    AddOnTable.State.AccountBankOpen = false
end
-- for actual hooking see bottom of file

--[[ ######################################### basic events ######################################### ]]

local function canViewAccountBank()
    local viewableBankTypes = AddOnTable.BlizzAPI.FetchViewableBankTypes()

    for _,viewableType in pairs(viewableBankTypes) do
        if (viewableType == AddOnTable.BlizzEnum.BankType.Account) then
            return true
        end
    end
    return false
end

local accountBankFrameOpenedOwner = nil
local function accountBankFrameOpened()
    Funcs.DebugMessage("AccountBank", "AccountBank#bankframeOpened()")

    if not canViewAccountBank() then
        Funcs.DebugMessage("AccountBank", "It seems the accountbank is not supported here... skipping")
        return
    end

    AddOnTable.State.AccountBankOpen = true
    ---@type BagSet
    local bagSet = AddOnTable.Sets[BagSetType.AccountBank.Id]
    bagSet:RebuildContainers()
    bagSet.Containers[1].Frame.BagsFrame:Update()
    bagSet:AutoOpen()
    AddOnTable.Sets[BagSetType.Backpack.Id]:AutoOpen()

    -- if auto open is NOT enabled for the first container, ensure that it is being shown anyways!
     if not BBConfig[BagSetType.AccountBank.Id][1].AutoOpen then
        bagSet.Containers[1].Frame:Show()
     end
end

local accountBankFrameClosedOwner = nil
local function accountBankFrameClosed()
    Funcs.DebugMessage("AccountBank", "AccountBank#bankframeClosed()")
    AddOnTable.State.AccountBankOpen = false
	AddOnTable.Sets[BagSetType.AccountBank.Id]:AutoClose()
    AddOnTable.Sets[BagSetType.Backpack.Id]:AutoClose()

    -- if auto open is NOT enabled for the first container, ensure that it is still being closed.
     if not BBConfig[BagSetType.AccountBank.Id][1].AutoOpen then
        AddOnTable.Sets[BagSetType.AccountBank.Id].Containers[1].Frame:Hide()
     end
end

local function configUpdateHook()
    if BBConfig[BagSetType.AccountBank.Id].Enabled then
        accountBankFrameOpenedOwner = EventRegistry:RegisterFrameEventAndCallback("BANKFRAME_OPENED", accountBankFrameOpened, nil)
        accountBankFrameClosedOwner = EventRegistry:RegisterFrameEventAndCallback("BANKFRAME_CLOSED", accountBankFrameClosed, nil)
    else
        if (accountBankFrameOpenedOwner ~= nil) then
            EventRegistry:UnregisterCallback("BANKFRAME_OPENED", accountBankFrameOpenedOwner)
        end
        if (accountBankFrameClosedOwner ~= nil) then
            EventRegistry:UnregisterCallback("BANKFRAME_CLOSED", accountBankFrameClosedOwner)
        end
    end
end
-- for actual hooking see bottom of file

--[[ ####################################### container frames ####################################### ]]

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
    self:RegisterEvent("BANK_TAB_SETTINGS_UPDATED")
    MoneyFrame_UpdateMoney(self.MoneyFrame.SmallMoneyFrame)
    self:RefreshDepositButtons()
    self:OnShow()
end

function BaudBagFirstAccountBankMixin:OnAccountBankEvent(event, ...)
    if not BBConfig[BagSetType.AccountBank.Id].Enabled then
        return
    end

    if (event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED") then
        Funcs.DebugMessage("AccountBank", "AccountBankFirstContainer#PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", ...)
        if self.UnlockInfo ~= nil then
            endUnlockMode(self)
            AddOnTable.Sets[BagSetType.AccountBank.Id].Containers[1]:Rebuild()
            AddOnTable.Sets[BagSetType.AccountBank.Id].Containers[1].Frame.BagsFrame:Update()
        end
    elseif (event == "ACCOUNT_MONEY") then
        MoneyFrame_UpdateMoney(self.MoneyFrame.SmallMoneyFrame)
        self:RefreshDepositButtons()
    elseif (event == "BANK_TAB_SETTINGS_UPDATED") then
        local bankType = ...
        if (bankType == AddOnTable.BlizzEnum.BankType.Account) then
            AddOnTable.Sets[BagSetType.AccountBank.Id].Containers[1].Frame.BagsFrame:Update()
            AddOnTable.Sets[BagSetType.AccountBank.Id]:RebuildContainers()
        end
    end

    self:OnContainerEvent(event, ...)

    -- fallback for inherited OnEvents
    if (self.OnEvent) then
        self:OnEvent(event, ...)
    end
end

function BaudBagFirstAccountBankMixin:OnAccountBankHide()
    self:UnregisterEvent("ACCOUNT_MONEY")
    self:UnregisterEvent("BANK_TAB_SETTINGS_UPDATED")
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

    self.ItemDepositButton:Update()
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
    if (PlayerGetTimerunningSeasonID ~= nil) then return end

    BaudBagContainerUnlockMixin.OnLoad(self)
    self.Title:SetText(AddOnTable.BlizzConstants.ACCOUNT_BANK_PANEL_TITLE)
    self.Text:SetText(AddOnTable.BlizzConstants.ACCOUNT_BANK_TAB_PURCHASE_PROMPT)
    self.PurchaseButton:SetAttribute("overrideBankType", Enum.BankType.Account)
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
    local nextBankTabData = AddOnTable.BlizzAPI.FetchNextPurchasableBankTabData(Enum.BankType.Account)
	if nextBankTabData then 
		MoneyFrame_Update(self.CostMoneyFrame, nextBankTabData.tabCost);
		SetMoneyFrameColorByFrame(self.CostMoneyFrame, nextBankTabData.canAfford and "white" or "red");
	end
end

--[[ ########################################## Bags frame ########################################## ]]

BaudBagAccountBagsFrameMixin = {}

function BaudBagAccountBagsFrameMixin:Initialize()
    --[[if (#AddOnTable.BlizzAPI.FetchPurchasedBankTabIDs(Enum.BankType.Account) == 0) then
        return
    end]]

    local accountBankSet = AddOnTable.Sets[BagSetType.AccountBank.Id]

    for bag = 1, AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER_NUM do
        local subContainerId = AddOnTable.BlizzConstants.BANK_LAST_CONTAINER + bag
        local bagButton = AddOnTable:CreateBagButton("BaudBag_AccountBank_BagButton", BagSetType.AccountBank, subContainerId, bag, self)
        bagButton:SetPoint("TOPLEFT", 8 + mod(bag - 1, 2) * 39, -8 - floor((bag - 1) / 2) * 39)
        accountBankSet.BagButtons[bag] = bagButton
    end

    self.PurchaseFrame.PurchaseButton:SetAttribute("overrideBankType", Enum.BankType.Account)
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

    local nextBankTabData = AddOnTable.BlizzAPI.FetchNextPurchasableBankTabData(Enum.BankType.Account)
    SetMoneyFrameColorByFrame(self.PurchaseFrame.MoneyFrame, nextBankTabData.canAfford and "white" or "red");
    MoneyFrame_Update(self.PurchaseFrame.MoneyFrame, nextBankTabData.tabCost)
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
    if (PlayerGetTimerunningSeasonID ~= nil) then return end
    self:OnLoad()

    -- on unload because it should be ensured that hiding also happens when the frame is not currently visible (otherwise the frame might only vanish)
    self:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
end

function BaudBagAccountBankContainerMixin:OnContainerShow()
    self.ItemDepositButton:Update()
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

--[[ ##################################### Ragent Deposit Button #################################### ]]
BaudBagAccountBankDepositButtonMixin = {}

function BaudBagAccountBankDepositButtonMixin:Update()
    local autoDepositSupported = AddOnTable.BlizzAPI.DoesBankTypeSupportAutoDeposit(AddOnTable.BlizzEnum.BankType.Account)
    if (AddOnTable.State.AccountBankOpen and autoDepositSupported) then
        self:Show()
    else
        self:Hide()
    end
end

function BaudBagAccountBankDepositButtonMixin:OnClick()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
    BankPanel:SetBankType(AddOnTable.BlizzEnum.BankType.Account)
    BankPanel.AutoDepositFrame.DepositButton:AutoDepositItems()
end

function BaudBagAccountBankDepositButtonMixin:OnEnter()
    GameTooltip:SetOwner(self)
    GameTooltip:SetText(AddOnTable.BlizzConstants.ACCOUNT_BANK_DEPOSIT_BUTTON_LABEL)
    GameTooltip:Show()
end

--[[ ######################################### Item Buttons ######################################### ]]

---@param self BBItemButton
local function ItemButton_OnCustomEnter(self)
    local bagId = self:GetParent():GetID()
    local slotId = self:GetID()
    self:UpdateTooltipFromCache(bagId, slotId)
end

local function itemSlotCreatedHook(self, bagSet, containerId, subcontainerId, slot, button)
    if (bagSet == BagSetType.AccountBank) then
        button:Init(Enum.BankType.Account, subcontainerId, slot)
        button:SetScript("OnEnter", ItemButton_OnCustomEnter)
    end
end
-- for actual hooking see bottom of file

--[[ ####################################### Base for Bindings ###################################### ]]

function BaudBagToggleWarbandBank()
    if (PlayerGetTimerunningSeasonID() ~= nil) then return end
    
    local warbandBankSet = AddOnTable.Sets[BagSetType.AccountBank.Id]
    local firstContainer = warbandBankSet.Containers[1]
    if (firstContainer.Frame:IsShown()) then
        --firstContainer.Frame:Hide()
        warbandBankSet:Close()
    else
        --firstContainer.Frame:Show()
        warbandBankSet:Open()
    end
end

--[[ #################################### Container Menu Entries #################################### ]]
local function toggleAccountBankMenuEntry(self)
    BaudBagToggleWarbandBank()
    self:GetParent():GetParent():Hide()
end

local function extendContainerMenuHook(addOnTable, menuGroup, addedButtons)
    local showAccountBankButton = CreateFrame("CheckButton", nil, menuGroup, "BaudBagContainerMenuCheckButtonTemplate")
    showAccountBankButton:SetText(Localized.ShowAccountBank)
    showAccountBankButton:SetScript("OnClick", toggleAccountBankMenuEntry)
    menuGroup.ShowAccountBankButton = showAccountBankButton

    table.insert(addedButtons, showAccountBankButton)
end
-- for actual hooking see bottom of file


--[[ ################################################################################################ ]]
--[[ ############ actual hooking should happen here for easy disabling in certain cases ############# ]]
--[[ ################################################################################################ ]]

if (PlayerGetTimerunningSeasonID() == nil) then
    hooksecurefunc(AddOnTable, "ExtendBaseTypes", extendBaseType)
    hooksecurefunc(AddOnTable, "ConfigUpdated", configUpdateHook)
    hooksecurefunc(AddOnTable, "ItemSlot_Created", itemSlotCreatedHook)
    hooksecurefunc(AddOnTable, "ExtendContainerMenuWithGeneralEntriesForBackpack", extendContainerMenuHook)
end