local AddOnName, AddOnTable = ...
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
            local purchasedBankTabIds = AddOnTable.BlizzAPI.FetchPurchasedBankTabIDs(Enum.BankType.Account)

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

    --AddOnTable.ContainerIdOptionsIndexMap[AddOnTable.BlizzConstants.KEYRING_CONTAINER] = 1
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
end

function BaudBagFirstAccountBankMixin:OnAccountBankShow()

    --[[if self:ShouldShowLockPrompt() then
		self:ShowLockPrompt();
		return;
	end]]

    self:OnShow()
end

function BaudBagFirstAccountBankMixin:OnAccountBankEvent(event, ...)
    if (event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED") then
        Funcs.DebugMessage("AccountBank", "AccountBankFirstContainer#PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", ...)
        if self.UnlockInfo ~= nil then
            endUnlockMode(self)
            AddOnTable.Sets[BagSetType.AccountBank.Id].Containers[1]:Rebuild()
        end
    end

    self:OnContainerEvent(event, ...)

    -- fallback for inherited OnEvents
    if (self.OnEvent) then
        self:OnEvent(event, ...)
    end
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
    if (self.TabData) then
        self.ContainerNotPurchasedYet = false
        self.Icon:SetTexture(self.TabData.IconID)
        self:SetQuality()
    else
        self.ContainerNotPurchasedYet = true
        self:SetItem()
    end
end

local function OnShowOverride(self)
    self:UpdateContent()
end

BaudBagAccountBagsFrameMixin = {}

function BaudBagAccountBagsFrameMixin:Initialize()
    --[[if (#AddOnTable.BlizzAPI.FetchPurchasedBankTabIDs(Enum.BankType.Account) == 0) then
        return
    end]]

    local accountBankSet = AddOnTable.Sets[BagSetType.AccountBank.Id]

    for bag = 1, AddOnTable.BlizzConstants.ACCOUNT_BANK_CONTAINER_NUM do
        local subContainerId = AddOnTable.BlizzConstants.BANK_LAST_CONTAINER + bag
        ---@type Button
        local bagButton = AddOnTable:CreateBagButton(BagSetType.AccountBank, subContainerId, bag, self)
        -- bagButton:SetPoint("TOPLEFT", 8, -8 - (bag-1) * bagButton:GetHeight())
        bagButton:SetPoint("TOPLEFT", 8 + mod(bag - 1, 2) * 39, -8 - floor((bag - 1) / 2) * 39)
        bagButton.UpdateContent = UpdateContent
        bagButton.OnShowOverride = OnShowOverride
        accountBankSet.BagButtons[bag] = bagButton
    end

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
            ---@class TabData
            bagSlot.TabData = {
                Name = tabData.name,
                IconID = tabData.icon,
                Flags = tabData.depositFlags
            }
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

--[[ ###################################### Container Template ###################################### ]]

BaudBagAccountBankContainerMixin = {}

function BaudBagAccountBankContainerMixin:OnContainerLoad()
    self:OnLoad()

    -- on unload because it should be ensured that hiding also happens when the frame is not currently visible (otherwise the frame might only vanish)
    self:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
end

function BaudBagAccountBankContainerMixin:OnContainerEvent(event, ...)
    Funcs.DebugMessage("AccountBank", "AccountBankContainer#"..event, ...)
    if (event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED") then
        local containerIndex = ...
        if (containerIndex == self:GetID()) then
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
