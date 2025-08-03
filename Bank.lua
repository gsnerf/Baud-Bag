---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local Prefix = "BaudBag"
local Localized = AddOnTable.Localized

local interfaceVersion = select(4, GetBuildInfo())

if (interfaceVersion >= 110200) then
    return
end

--[[
    This method creates the buttons in the banks BagsFrame (frame that pops out and shows the available bags).
  ]]
local function BankBags_Initialize()
    local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]
    local BBContainer2 = _G[Prefix.."Container2_1BagsFrame"]

    -- create BagSlots for regular bags
    for Bag = 1, NUM_BANKBAGSLOTS do
        local buttonIndex = Bag
        local bagButton = AddOnTable:CreateBankBagButton(buttonIndex, BBContainer2)
        bagButton:SetID(buttonIndex)
        bagButton:SetPoint("TOPLEFT", 8 + mod(Bag - 1, 2) * 39, -8 - floor((Bag - 1) / 2) * 39)
        bankSet.BagButtons[Bag] = bagButton
    end

    AddOnTable:BankBags_Inititalize(BBContainer2)

    BBContainer2:SetWidth(91)
    --Height changes depending if there is a purchase button
    BBContainer2.Height = 13 + ceil(NUM_BANKBAGSLOTS / 2) * 39
    BaudBagBankBags_Update()
end

function AddOnTable:BankBags_Inititalize(BagContainer)
    -- just an empty hook for other addons
end

local function extendBaseType()
    AddOnTable.Functions.DebugMessage("Bank", "Bank#extendBaseType()")
    BagSetType["Bank"] = {
        Id = 2,
        Name = Localized.BankBox,
        TypeName = "Bank",
        IsSupported = function() return true end,
        IsSubContainerOf = function(containerId)
            local isBankDefaultContainer = (containerId == AddOnTable.BlizzConstants.BANK_CONTAINER) or (containerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER)
            local isBankSubContainer = (AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER <= containerId) and (containerId <= AddOnTable.BlizzConstants.BANK_LAST_CONTAINER)
            return isBankDefaultContainer or isBankSubContainer
        end,
        ContainerIterationOrder = {},
        Init = function()
            table.insert(BagSetType.Bank.ContainerIterationOrder, AddOnTable.BlizzConstants.BANK_CONTAINER)
            for bag = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
                table.insert(BagSetType.Bank.ContainerIterationOrder, bag)
            end
            -- explicitly using the numerical value of the expansion instead of the enum, as classic variants seemingly do not contain those enums
            if (GetExpansionLevel() >= 5) then
                table.insert(BagSetType.Bank.ContainerIterationOrder, AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER)
            end

            AddOnTable.ContainerIdOptionsIndexMap[AddOnTable.BlizzConstants.BANK_CONTAINER] = 1
            AddOnTable.ContainerIdOptionsIndexMap[AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER] = AddOnTable.BlizzConstants.BANK_CONTAINER_NUM + 2
            for id = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
                AddOnTable.ContainerIdOptionsIndexMap[id] = id - AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER + 1
            end
        end,
        -- bank container + number of additional bags in bank + optionally reagent bank
        NumberOfContainers = 1 + AddOnTable.BlizzConstants.BANK_CONTAINER_NUM + (GetExpansionLevel() >= 5 and 1 or 0),
        DefaultConfig = {
            Columns = 14,
            Scale = 100,
            GetNameAddition = function(bagId)
                local isReagentBank = bagId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER
                if (isReagentBank) then
                    return Localized.ReagentBankBox
                else
                    return Localized.BankBox
                end
            end,
            RequiresFreshConfig = function(bagId)
                local isReagentBank = bagId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER
                return isReagentBank
            end,
            Background = 2
        },
        ApplyConfigRestorationSpecificalities = function(configObject)
            -- make sure the reagent bank is NOT joined by default!
            if (configObject[BagSetType.Bank.Id].Joined[9] == nil) then
                AddOnTable.Functions.DebugMessage("Config", "- reagent bank join for BagSet "..BagSetType.Bank.Id.." damaged or missing, creating now")
                configObject[BagSetType.Bank.Id].Joined[9] = false
            end
        end,
        GetContainerTemplate = function(containerId)
            if (containerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
                return "BaudBagReagentBankTemplate"
            else
                return "BaudBagContainerTemplate"
            end
        end,
        GetItemButtonTemplate = function(containerId)
            if (containerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
                return "ReagentBankItemButtonGenericTemplate"
            else
                return "BankItemButtonGenericTemplate"
            end
        end,
        GetSize = function(containerId)
            local useCache = not AddOnTable.State.BankOpen
            if useCache and (containerId ~= AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
                local bagCache = AddOnTable.Cache:GetBagCache(containerId)
                return bagCache.Size
            else
                return AddOnTable.BlizzAPI.GetContainerNumSlots(containerId)
            end
        end,
        SupportsCache = true,
        ShouldUseCache = function() return not AddOnTable.State.BankOpen end,
        BagOverview_Initialize = BankBags_Initialize,
        BagFilterGetFunction = AddOnTable.BlizzAPI.GetBankBagSlotFlag,
        BagFilterSetFunction = AddOnTable.BlizzAPI.SetBankBagSlotFlag,
        CanInteractWithBags = function() return AddOnTable.Sets[BagSetType.Bank.Id].Containers[1].Frame:IsShown() end,
        OnItemButtonCustomEnter = function(self)
            local bagId = self:GetParent():GetID()
            local slotId = self:GetID()
            AddOnTable.Functions.DebugMessage("Tooltip", "[ItemButton:UpdateTooltip] This button is part of the bank bags... reading from cache")
            self:UpdateTooltipFromCache(bagId, slotId)
        end,
        FilterData = {
            GetFilterType = function(container)
                local containerId = container.ContainerId
                if (containerId ~= AddOnTable.BlizzConstants.BANK_CONTAINER) and (containerId ~= AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
                    container:GetFilterType()
                end
                return nil
            end,
            SetFilterType = function(container, type, value)
                local containerId = container.ContainerId
                if (containerId ~= AddOnTable.BlizzConstants.BANK_CONTAINER) and (containerId ~= AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
                    container:SetFilterType(type, value)
                end
            end,
            GetCleanupIgnore = function(container)
                local containerId = container.ContainerId
                if (containerId == AddOnTable.BlizzConstants.BANK_CONTAINER or containerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
                    return AddOnTable.BlizzAPI.GetBankAutosortDisabled()
                end
                -- TODO: check if the ID is really correct for the newer versions of the API, maybe we need that in the API wrapper instead!
                return AddOnTable.BlizzAPI.GetBankBagSlotFlag(containerId - AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER, AddOnTable.BlizzAPI.GetIgnoreCleanupFlag())
            end,
            SetCleanupIgnore = function(container, value)
                local containerId = container.ContainerId
                if (containerId == AddOnTable.BlizzConstants.BANK_CONTAINER) then
                    AddOnTable.BlizzAPI.SetBankAutosortDisabled(value)
                else
                    -- TODO: check if the ID is really correct for the newer versions of the API, maybe we need that in the API wrapper instead!
                    AddOnTable.BlizzAPI.SetBankBagSlotFlag(containerId - AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER, AddOnTable.BlizzAPI.GetIgnoreCleanupFlag(), value)
                end
            end,
        },
        CustomCloseAllFunction = function()
            if (AddOnTable.State.BankOpen) then
                AddOnTable.BlizzAPI.CloseBankFrame()
            end
        end,
    }
    tinsert(BagSetTypeArray, BagSetType.Bank)

    AddOnTable.State.BankOpen = false
end
hooksecurefunc(AddOnTable, "ExtendBaseTypes", extendBaseType)

local EventFuncs = {
    BANKFRAME_CLOSED = function(self, event, ...)
        AddOnTable.Functions.DebugMessage("Bank", "Event BANKFRAME_CLOSED fired")
        AddOnTable.State.BankOpen = false

        local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]

        BaudBagBankSlotPurchaseButton:Disable()
        if _G[Prefix.."Container2_1"].AutoOpened then
            _G[Prefix.."Container2_1"]:Hide()
        else
            --Add offline again to bag name
            local numberOfContainers = bankSet.ContainerNumber
            for ContNum = 1, numberOfContainers do
                bankSet.Containers[ContNum]:UpdateName()
            end
        end
        AddOnTable.Sets[BagSetType.Backpack.Id]:AutoClose()
    end,

    PLAYER_MONEY = function(self, event, ...)
        AddOnTable.Functions.DebugMessage("Bags", "Event PLAYER_MONEY fired")
        BaudBagBankBags_Update()
    end,
}

local Func = function(self, event, ...)
    AddOnTable.Functions.DebugMessage("Bank", "Event fired", event)
    
	-- set bank open marker if it was opend
    if (event == "BANKFRAME_OPENED" and AddOnTable.BlizzAPI.CanUseBank(AddOnTable.BlizzEnum.BankType.Character)) then
        AddOnTable.State.BankOpen = true
    end
    
    -- everything coming now is only needed if the bank is visible
    local bankVisible = BBConfig[2].Enabled and (event == "BANKFRAME_OPENED")
    AddOnTable:BankBags_UpdateContent(self, bankVisible)
    if not bankVisible then
        return
    end
    
    -- make sure current bag information are processed
    AddOnTable.Sets[BagSetType.Bank.Id]:RebuildContainers()
    AddOnTable.Sets[BagSetType.Backpack.Id]:AutoOpen()
    AddOnTable.Sets[BagSetType.Bank.Id]:AutoOpen()
end
EventFuncs.BANKFRAME_OPENED = Func
EventFuncs.PLAYERBANKBAGSLOTS_CHANGED = Func

local collectedBagEvents = {}
Func = function(self, event, ...)
    AddOnTable.Functions.DebugMessage("Bags", "Event fired for bank (event, source)", event, self:GetName())

    -- this is the ID of the affected container as known to WoW
    local bagId = ...
    if BagSetType.Bank.IsSubContainerOf(bagId) then
        if collectedBagEvents[bagId] == nil then
            collectedBagEvents[bagId] = {}
        end
        table.insert(collectedBagEvents[bagId], event)

        -- temporary until BAG_UPDATE_DELAYED is fixed again
        AddOnTable["SubBags"][bagId]:UpdateSlotContents()
    end

    -- old stuff, for compatibility until the stuff above works as expected
    -- if there are new bank slots the whole view has to be updated
    if (event == "PLAYERBANKSLOTS_CHANGED") then
        -- bank bag slot
        if (bagId > AddOnTable.BlizzConstants.BANK_SLOTS_NUM) then
            local bankBagId = bagId-AddOnTable.BlizzConstants.BANK_SLOTS_NUM
            local bankBagButton = AddOnTable.Sets[BagSetType.Bank.Id].BagButtons[bankBagId]
            bankBagButton:UpdateContent()
            return
        end

        -- if the main bank bag is visible make sure the content of the sub-bags is also shown
        local BankBag = _G[Prefix.."SubBag-1"]
        if BankBag:GetParent():IsShown() then
            AddOnTable["SubBags"][-1]:UpdateSlotContents()
        end
        local Container = _G[Prefix.."Container2_1"]
        if not Container:IsShown() then
            return
        end
        Container.UpdateSlots = true
    end
end
EventFuncs.BAG_OPEN = Func
EventFuncs.BAG_UPDATE = Func
EventFuncs.BAG_CLOSED = Func
EventFuncs.PLAYERBANKSLOTS_CHANGED = Func

Func = function(self, event, ...)
    AddOnTable.Functions.DebugMessage("Bags", "BAG_UPDATE_DELAYED (collectedBagEvents)", collectedBagEvents)
    -- collect information on last action
    local affectedContainerCount = 0
    for bagId, _ in pairs(collectedBagEvents) do
        affectedContainerCount = affectedContainerCount + 1
    end

    -- full rebuild if it seems the bags could have been swapped (something like this will probably be necessary for classic, so it stays for the moment)
    if affectedContainerCount > 1 then
        local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]
        bankSet:RebuildContainers()
        bankSet:UpdateBagHighlight()
    else
        -- single bag update otherwise
        for bagId, _ in pairs(collectedBagEvents) do
            AddOnTable["SubBags"][bagId]:UpdateSlotContents()
        end
    end

    -- reset collected data for next action
    collectedBagEvents = {}
end
EventFuncs.BAG_UPDATE_DELAYED = Func


local function registerBankEvents(self)
    for Key, Value in pairs(EventFuncs)do
        EventRegistry:RegisterFrameEvent(Key, Value)
    end
end
hooksecurefunc(AddOnTable, "RegisterEvents", registerBankEvents)


--[[
    This analyses the bought bags and updates the bag slot view
    (the little window that pops out the main bank container and shows the bought bags) 
    alongside the "bag slot buy" button 
  ]]
function BaudBagBankBags_Update()
    local Purchase = BaudBagBankSlotPurchaseFrame
    local Slots, Full = AddOnTable.BlizzAPI.GetNumBankSlots()
    
    local BagSlot
    local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]

    AddOnTable.Functions.DebugMessage("Bank", "BankBags: updating")
    
    for Bag = 1, NUM_BANKBAGSLOTS do
        BagSlot = bankSet.BagButtons[Bag]
        
        if (Bag <= Slots) then
            BagSlot.tooltipText = BANK_BAG
        else
            BagSlot.ContainerNotPurchasedYet = true
            BagSlot.tooltipText = BANK_BAG_PURCHASE
            BagSlot:UpdateContent()
        end
    end
    AddOnTable:BankBags_Update()
    
    local BBContainer2 = _G[Prefix.."Container2_1BagsFrame"]
    
    if Full then
        AddOnTable.Functions.DebugMessage("Bank", "BankBags: all bags bought hiding purchase button")
        Purchase:Hide()
        BBContainer2:SetHeight(BBContainer2.Height)
        return
    end
    
    -- TODO migrate to FetchNextPurchasableBankTabCost with fallback for classic?
    local Cost = AddOnTable.BlizzAPI.GetBankSlotCost(Slots)
    AddOnTable.Functions.DebugMessage("Bank", "BankBags: buyable bag slots left, currentCost = "..Cost)
    
    -- This line allows the confirmation box to show the cost
    BankFrame.nextSlotCost = Cost
    
    if (AddOnTable.BlizzAPI.GetMoney() >= Cost) then
        -- SetMoneyFrameColor(Purchase:GetName().."MoneyFrame", 1.0, 1.0, 1.0)
        SetMoneyFrameColor(Purchase:GetName().."MoneyFrame")
    else
        SetMoneyFrameColor(Purchase:GetName().."MoneyFrame", "red")
    end
    MoneyFrame_Update(Purchase:GetName().."MoneyFrame", Cost)
    
    Purchase:Show()
    BBContainer2:SetHeight(BBContainer2.Height + 40)
end

function AddOnTable:BankBags_Update()
    -- just an empty hook for other addons
end

function AddOnTable:BankBags_UpdateContent(self, bankVisible)
    -- make sure the player can buy new bankslots
    BaudBagBankSlotPurchaseButton:Enable()

    local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]

    AddOnTable.SubBags[BANK_CONTAINER]:UpdateSlotContents()
    for Index = 1, NUM_BANKBAGSLOTS do
        local bankBagButton = bankSet.BagButtons[Index]
        bankBagButton:UpdateContent()
    end
    
    BaudBagBankBags_Update()
    
    if not bankVisible then
        AddOnTable.Functions.DebugMessage("Bank", "Bankframe does not really seem to be open or event was not BANKFRAME_OPENED. Stepping over actually opening the Bankframes")
        return
    end

    AddOnTable.Functions.DebugMessage("Bank", "Recording bank bag info.")
    for Bag = 1, NUM_BANKBAGSLOTS do
        local bagCache = AddOnTable.Cache:GetBagCache(Bag + AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER)
        local inventoryId = AddOnTable.BlizzAPI.BankButtonIDToInvSlotID(Bag, 1)
        bagCache.BagLink  = AddOnTable.BlizzAPI.GetInventoryItemLink("player", inventoryId)
        bagCache.BagCount = AddOnTable.BlizzAPI.GetInventoryItemCount("player", inventoryId)
    end
    
    local firstBankContainer = bankSet.Containers[1]
    if firstBankContainer.Frame:IsShown() then
        firstBankContainer:Update()
        bankSet:UpdateSlotInfo()
    else
        firstBankContainer.Frame.AutoOpened = true
        firstBankContainer.Frame:Show()
    end
end

function BaudBagToggleBank(self)
    local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]
    local firstBankContainer = bankSet.Containers[1]
    if firstBankContainer.Frame:IsShown() then
        firstBankContainer.Frame:Hide()
        bankSet:AutoClose()
    else
        firstBankContainer.Frame:Show()
        bankSet:AutoOpen()
    end
end

--[[ this method ensures that the bank bags are either placed as childs under UIParent or BaudBag ]]
local function updateBankParents()
    local newParent = ContainerFrameContainer
    if AddOnTable.Functions.BagHandledByBaudBag(AddOnTable.BlizzConstants.BANK_CONTAINER) then
        newParent = BaudBag_OriginalBagsHideFrame
    end

    BankFrame:SetParent(newParent)
    for i = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
        _G["ContainerFrame"..(i+1)]:SetParent(newParent)
    end

    if not AddOnTable.Functions.BagHandledByBaudBag(AddOnTable.BlizzConstants.BANK_CONTAINER) and AddOnTable.Functions.BagHandledByBaudBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER) then
        ---@type Frame
        local firstContainer = _G["ContainerFrame1"]
        local _, _, _, offX, offY = firstContainer:GetPointByName("BOTTOMRIGHT")
        ---@type Frame
        local firstBankContainer = _G["ContainerFrame"..(AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER+1)]
        firstBankContainer:SetAllPoints()
        firstBankContainer:SetPoint("BOTTOMRIGHT", ContainerFrameContainer, "BOTTOMRIGHT",  offX, offY)
        DevTools_Dump(firstBankContainer:GetNumPoints())
        DevTools_Dump(firstBankContainer:GetPointByName("BOTTOMRIGHT"))
    end
end
hooksecurefunc(AddOnTable, "ConfigUpdated", updateBankParents)

--[[ #################################### Container Menu Entries #################################### ]]
local function toggleBankMenuEntry(self)
    local firstBankContainer = AddOnTable.Sets[BagSetType.Bank.Id].Containers[1]
    if firstBankContainer.Frame:IsShown() then
        firstBankContainer.Frame:Hide()
        AddOnTable.Sets[BagSetType.Bank.Id]:AutoClose()
    else
        firstBankContainer.Frame:Show()
        AddOnTable.Sets[BagSetType.Bank.Id]:AutoOpen()
    end
    self:GetParent():GetParent():Hide()
end

hooksecurefunc(AddOnTable, "ExtendContainerMenuWithGeneralEntriesForBackpack", function(addOnTable, menuGroup, addedButtons)
    local showBankButton = CreateFrame("CheckButton", nil, menuGroup, "BaudBagContainerMenuCheckButtonTemplate")
    showBankButton:SetText(Localized.ShowBank)
    showBankButton:SetScript("OnClick", toggleBankMenuEntry)
    menuGroup.ShowBankButton = showBankButton

    table.insert(addedButtons, showBankButton)
end)

