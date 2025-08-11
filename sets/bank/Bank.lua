---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local Prefix = "BaudBag"
local Funcs = AddOnTable.Functions
local Localized = AddOnTable.Localized

local function extendBaseType()
    Funcs.DebugMessage("Bank", "Bank#extendBaseType()")
    BagSetType["Bank"] = {
        Id = 2,
        Name = Localized.BankBox,
        TypeName = "Bank",
        IsSupported = function() return true end,
        IsSubContainerOf = function(containerId)
            local isBankContainer = (containerId == AddOnTable.BlizzConstants.BANK_CONTAINER)
            local isBankSubContainer = (AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER <= containerId) and (containerId <= AddOnTable.BlizzConstants.BANK_LAST_CONTAINER)
            return isBankContainer or isBankSubContainer
        end,
        ContainerIterationOrder = {},
        Init = function()
            -- AddOnTable.BlizzConstants.BANK_CONTAINER seems to only hold a list of purchased bank tabs along with an rather undefined icon
            -- not really sure what this thing is supposed to be for
            for bag = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
                table.insert(BagSetType.Bank.ContainerIterationOrder, bag)
            end

            for index, bagId in ipairs(BagSetType.Bank.ContainerIterationOrder) do
                AddOnTable.ContainerIdOptionsIndexMap[bagId] = index
            end
        end,
        NumberOfContainers = math.max(1, AddOnTable.BlizzAPI.FetchNumPurchasedBankTabs(Enum.BankType.Character)),
        DefaultConfig = {
            Columns = 14,
            Scale = 100,
            GetNameAddition = function(bagId) return Localized.BankBox end,
            RequiresFreshConfig = function(bagId) return false end,
            Background = 2,
        },
        ApplyConfigRestorationSpecificalities = function(configObject) end,
        CanContainerBeJoined = function(subContainerId) return true end,
        LinkedSet = function() return BagSetType.AccountBank and BagSetType.AccountBank or nil end,
        GetContainerTemplate = function(containerId) return "BaudBagBankContainerTemplate" end,
        GetItemButtonTemplate = function(containerId) return "BankItemButtonTemplate" end,
        GetSize = function(containerId)
            if (BagSetType.Bank.ShouldUseCache()) then
                local bagCache = AddOnTable.Cache:GetBagCache(containerId)
                if bagCache then
                    return bagCache.Size
                end
            end

            -- we seem to be at the bank, let's get live data
            local purchasedBankTabIds  = AddOnTable.BlizzAPI.FetchPurchasedBankTabIDs(Enum.BankType.Character)

            -- necessary to get a visible first container even when not bought yet (so that we CAN buy)
            if table.getn(purchasedBankTabIds) == 0 and containerId == AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER then
                return 98
            end

            for _, tabId in pairs (purchasedBankTabIds) do
                if tabId == containerId then
                    return 98
                end
            end
            return 0
        end,
        SupportsCache = true,
        ShouldUseCache = function() return not AddOnTable.State.BankOpen end,
        BagOverview_Initialize = function() _G["BaudBagContainer2_1"].BagsFrame:Initialize() end,
        UpdateOpenBagHighlight = function(subContainer)
            local open = subContainer:IsOpen()
            local button = AddOnTable.Sets[BagSetType.Bank.Id].BagButtons[subContainer.ContainerId - AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER + 1]
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
        CanInteractWithBags = function() return AddOnTable.Sets[BagSetType.Bank.Id].Containers[1].Frame:IsShown() end,
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
    tinsert(BagSetTypeArray, BagSetType.Bank)

    AddOnTable.State.BankOpen = false
end
hooksecurefunc(AddOnTable, "ExtendBaseTypes", extendBaseType)

--[[ ######################################### basic events ######################################### ]]
local function canViewBank()
    local viewableBankTypes = AddOnTable.BlizzAPI.FetchViewableBankTypes()

    for _,viewableType in pairs(viewableBankTypes) do
        if (viewableType == AddOnTable.BlizzEnum.BankType.Character) then
            return true
        end
    end
    return false
end

local bankFrameOpenedOwner = nil
local function bankFrameOpened()
    Funcs.DebugMessage("Bank", "Bank#bankframeOpened()")

    if not canViewBank() then
        Funcs.DebugMessage("Bank", "It seems we have been opened with the warband bank distance inhibitor... skipping regular bank")
        return
    end
    
    AddOnTable.State.BankOpen = true

    ---@type BagSet
    local bankBagSet = AddOnTable.Sets[BagSetType.Bank.Id]
    bankBagSet:RebuildContainers()
    bankBagSet.Containers[1].Frame.BagsFrame:Update()
    bankBagSet:AutoOpen()
    AddOnTable.Sets[BagSetType.Backpack.Id]:AutoOpen()
end

local bankFrameClosedOwner = nil
local function bankFrameClosed()
    Funcs.DebugMessage("Bank", "Bank#bankframeClosed()")
    AddOnTable.State.BankOpen = false
	AddOnTable.Sets[BagSetType.Bank.Id]:AutoClose()
    AddOnTable.Sets[BagSetType.Backpack.Id]:AutoClose()
end

--[[ this method ensures that the bank bags are either placed as childs under UIParent or BaudBag ]]
local function updateBankParents()
    local newParent = UIParent
    if BBConfig[BagSetType.Bank.Id].Enabled and BBConfig[BagSetType.AccountBank.Id].Enabled then
        newParent = BaudBag_OriginalBagsHideFrame
    end

    BankFrame:SetParent(newParent)
end

hooksecurefunc(AddOnTable, "ConfigUpdated", function()
    if BBConfig[BagSetType.Bank.Id].Enabled then
        bankFrameOpenedOwner = EventRegistry:RegisterFrameEventAndCallback("BANKFRAME_OPENED", bankFrameOpened, nil)
        bankFrameClosedOwner = EventRegistry:RegisterFrameEventAndCallback("BANKFRAME_CLOSED", bankFrameClosed, nil)
    else
        if (bankFrameOpenedOwner ~= nil) then
            EventRegistry:UnregisterCallback("BANKFRAME_OPENED", bankFrameOpenedOwner)
        end
        if (bankFrameClosedOwner ~= nil) then
            EventRegistry:UnregisterCallback("BANKFRAME_CLOSED", bankFrameClosedOwner)
        end
    end

    updateBankParents()
end)

--[[ ####################################### container frames ####################################### ]]

BaudBagFirstBankMixin = {}

local function switchToUnlockMode(self)
    -- ensure unlock frame exists
    self.UnlockInfo = CreateFrame("Frame", "BaudBagBankPurchase", _G["BaudBagContainer2_1"], "BaudBagContainerUnlockTemplate")
    Mixin(self.UnlockInfo, BaudBagBankUnlockMixin)
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

function BaudBagFirstBankMixin:Initialize()
    local purchasedBankTabsIds = AddOnTable.BlizzAPI.FetchPurchasedBankTabIDs(Enum.BankType.Character)
    if table.getn(purchasedBankTabsIds) == 0 then
        switchToUnlockMode(self)
    end
    MoneyFrame_SetType(self.MoneyFrame.SmallMoneyFrame, "PLAYER")
end

function BaudBagFirstBankMixin:OnBankShow()
    self:RegisterEvent("PLAYER_MONEY")
    self:RegisterEvent("BANK_TAB_SETTINGS_UPDATED")
    MoneyFrame_UpdateMoney(self.MoneyFrame.SmallMoneyFrame)
    --self:RefreshDepositButtons()
    self:OnShow()
end


function BaudBagFirstBankMixin:OnBankEvent(event, ...)
    if not BBConfig[BagSetType.Bank.Id].Enabled then
        return
    end

    if (event == "PLAYERBANKSLOTS_CHANGED") then
        Funcs.DebugMessage("Bank", "BankFirstContainer#PLAYERBANKTAB_SLOTS_CHANGED", ...)
        if self.UnlockInfo ~= nil then
            endUnlockMode(self)
            AddOnTable.Sets[BagSetType.Bank.Id].Containers[1]:Rebuild()
            AddOnTable.Sets[BagSetType.Bank.Id].Containers[1].BagsFrame:Update()
        end
    elseif (event == "PLAYER_MONEY") then
        MoneyFrame_UpdateMoney(self.MoneyFrame.SmallMoneyFrame)
        --self:RefreshDepositButtons()
    elseif (event == "BANK_TAB_SETTINGS_UPDATED") then
        local bankType = ...
        if (bankType == AddOnTable.BlizzEnum.BankType.Character) then
            AddOnTable.Sets[BagSetType.Bank.Id].Containers[1].Frame.BagsFrame:Update()
            AddOnTable.Sets[BagSetType.Bank.Id]:RebuildContainers()
        end
    end

    self:OnContainerEvent(event, ...)

    -- fallback for inherited OnEvents
    if (self.OnEvent) then
        self:OnEvent(event, ...)
    end
end

function BaudBagFirstBankMixin:OnBankHide()
    self:UnregisterEvent("PLAYER_MONEY")
    self:UnregisterEvent("BANK_TAB_SETTINGS_UPDATED")
    self:OnHide()
end


--[[ ####################################### UnlockInfo frame ####################################### ]]
BaudBagBankUnlockMixin = {}

function BaudBagBankUnlockMixin:OnLoad()
    BaudBagContainerUnlockMixin.OnLoad(self)
    self.Title:SetText(AddOnTable.BlizzConstants.BANK_PANEL_TITLE)
    self.Text:SetText(AddOnTable.BlizzConstants.BANK_TAB_PURCHASE_PROMPT)
    self.PurchaseButton:SetAttribute("clickbutton", BankPanel.PurchasePrompt.TabCostFrame.PurchaseButton)
end

function BaudBagBankUnlockMixin:OnShow()
    self:Refresh()
    self:RegisterEvent("PLAYER_MONEY")
end

function BaudBagBankUnlockMixin:OnEvent(event, ...)
	if event == "PLAYER_MONEY" then
		self:Refresh()
	end
end

function BaudBagBankUnlockMixin:OnHide()
    self:UnregisterEvent("PLAYER_MONEY")
end

function BaudBagBankUnlockMixin:Refresh()
    local nextBankTabData = AddOnTable.BlizzAPI.FetchNextPurchasableBankTabData(Enum.BankType.Character)
	if nextBankTabData then 
		MoneyFrame_Update(self.CostMoneyFrame, nextBankTabData.tabCost);
		SetMoneyFrameColorByFrame(self.CostMoneyFrame, nextBankTabData.canAfford and "white" or "red");
	end
end

--[[ ########################################## Bags frame ########################################## ]]
BaudBagBankBagsFrameMixin = {}

function BaudBagBankBagsFrameMixin:Initialize()
    local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]

    for bag = 1, AddOnTable.BlizzConstants.BANK_CONTAINER_NUM do
        local subContainerId = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER - 1 + bag
        local bagButton = AddOnTable:CreateBagButton("BaudBag_Bank_BagButton", BagSetType.Bank, subContainerId, bag, self)
        bagButton:SetPoint("TOPLEFT", 8 + mod(bag - 1, 2) * 39, -8 - floor((bag - 1) / 2) * 39)
        bankSet.BagButtons[bag] = bagButton
    end

    self.PurchaseFrame.PurchaseButton:SetAttribute("overrideBankType", Enum.BankType.Character)
    local firstBagButton = bankSet.BagButtons[1]
    self:SetWidth(15 + (firstBagButton:GetWidth() * 2))
    self:Update()
end

local function canBankBeSeen()
    local watchableTables = AddOnTable.BlizzAPI.FetchViewableBankTypes()
    for _, watchableType in pairs(watchableTables) do
        if watchableType == AddOnTable.BlizzEnum.BankType.Character then
            return true
        end
    end

    return false
end

function BaudBagBagsFrameMixin:Update()
    if not canBankBeSeen() then return end
    -- TODO: make this work with cache for offline viewing
    local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]
    local purchasedBankTabData = AddOnTable.BlizzAPI.FetchPurchasedBankTabData(Enum.BankType.Character)
    local numberOfBoughtContainers = #purchasedBankTabData
    AddOnTable.Functions.DebugMessage("Bank", "BagOverview: updating content", purchasedBankTabData, numberOfBoughtContainers)

    local bagSlot
    for bag = 1, AddOnTable.BlizzConstants.BANK_CONTAINER_NUM do
        bagSlot = bankSet.BagButtons[bag]
        if bag <= numberOfBoughtContainers then
            local tabData = purchasedBankTabData[bag]
            bagSlot.TabData = tabData
            local bagCache = AddOnTable.Cache:GetBagCache(bagSlot.SubContainerId)
            bagCache.TabData = tabData
        end
        bagSlot:UpdateContent()
    end

    if (numberOfBoughtContainers == AddOnTable.BlizzConstants.BANK_CONTAINER_NUM) then
        AddOnTable.Functions.DebugMessage("Bank", "BagOverview: all containers bought hiding purchase button")
        self.PurchaseFrame:Hide()
        self:UpdateHeight(bankSet.BagButtons[1]:GetHeight(), false)
        return
    end

    local nextBankTabData = AddOnTable.BlizzAPI.FetchNextPurchasableBankTabData(Enum.BankType.Character)
    SetMoneyFrameColorByFrame(self.PurchaseFrame.MoneyFrame, nextBankTabData.canAfford and "white" or "red");
    MoneyFrame_Update(self.PurchaseFrame.MoneyFrame, nextBankTabData.tabCost)
    self.PurchaseFrame:Show()
    self:UpdateHeight(bankSet.BagButtons[1]:GetHeight(), true)
end

---@param withPurchaseFrame boolean
function BaudBagBagsFrameMixin:UpdateHeight(firstButtonHeight, withPurchaseFrame)
    local purchaseHeight = 0
    if (withPurchaseFrame) then
        purchaseHeight = 40
    end
    self:SetHeight(15 + ceil(AddOnTable.BlizzConstants.BANK_CONTAINER_NUM / 2) * firstButtonHeight + purchaseHeight)
end

function BaudBagBagsFrameMixin:OnShow()
    if self.PurchaseFrame then
        if AddOnTable.State.BankOpen then
            self.PurchaseFrame.PurchaseButton:Enable()
        else
            self.PurchaseFrame.PurchaseButton:Disable()
        end
    end
end

--[[ ###################################### Container Template ###################################### ]]

BaudBagBankContainerMixin = {}

function BaudBagBankContainerMixin:OnContainerLoad()
    self:OnLoad()

    -- on unload because it should be ensured that hiding also happens when the frame is not currently visible (otherwise the frame might only vanish)
    self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
end

function BaudBagBankContainerMixin:OnContainerEvent(event, ...)
    if (event == "PLAYERBANKSLOTS_CHANGED" or event == "BAG_UPDATE") then
        local containerIndex = ...
        if (containerIndex == self:GetID()) then
            Funcs.DebugMessage("Bank", "BankContainer#"..event, ...)
            self.QueueForUpdate = true
        end
    end

    if (event == "BAG_UPDATE_DELAYED" and self.QueueForUpdate) then
        AddOnTable.Sets[BagSetType.Bank.Id].Containers[self:GetID()]:Update()
    end

    -- fallback for inherited OnEvents
    if (self.OnEvent) then
        self:OnEvent(event, ...)
    end
end

function BaudBagBankContainerMixin:UpdateBagHighlight()
    Funcs.DebugMessage("Bank", "BankContainer#UpdateBagHighlight")
    local bagSet = AddOnTable.Sets[BagSetType.Bank.Id]
    for _, subContainer in pairs(bagSet.Containers[self:GetID()].SubContainers) do
        local button = bagSet.BagButtons[subContainer.ContainerId - AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER + 1]
        if (subContainer:IsOpen()) then
            button.SlotHighlightTexture:Show()
        else
            button.SlotHighlightTexture:Hide()
        end
    end
end

--[[ ###################################### Bags Settings frame ##################################### ]]

BaudBagBankTabSettingsMixin = {}

function BaudBagBankTabSettingsMixin:SetSelectedTab(selectedTabId)
    -- intentionally empty, please set the selectedTabData before requesting to show tab settings!
end


--[[ ######################################### Item Buttons ######################################### ]]

---@param self BBItemButton
local function ItemButton_OnCustomEnter(self)
    local bagId = self:GetParent():GetID()
    local slotId = self:GetID()
    self:UpdateTooltipFromCache(bagId, slotId)
end

hooksecurefunc(AddOnTable, "ItemSlot_Created", function(self, bagSet, containerId, subcontainerId, slot, button)
    if (bagSet == BagSetType.Bank) then
        button:Init(Enum.BankType.Character, subcontainerId, slot)
        button:SetScript("OnEnter", ItemButton_OnCustomEnter)
    end
end)

--[[ ####################################### Base for Bindings ###################################### ]]

function BaudBagToggleBank()
    local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]
    local firstContainer = bankSet.Containers[1]
    if (firstContainer.Frame:IsShown()) then
        --firstContainer.Frame:Hide()
        bankSet:Close()
    else
        --firstContainer.Frame:Show()
        bankSet:Open()
    end
end
