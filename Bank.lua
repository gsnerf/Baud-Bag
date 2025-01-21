---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local Prefix = "BaudBag"
local Localized = AddOnTable.Localized

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

function BaudBag_RegisterBankEvents(self)
    for Key, Value in pairs(EventFuncs)do
        self:RegisterEvent(Key)
    end
end

function BaudBag_OnBankEvent(self, event, ...)
    if EventFuncs[event] then
        EventFuncs[event](self, event, ...)
    end
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
BagSetType.Bank.BagOverview_Initialize = BankBags_Initialize

function AddOnTable:BankBags_Inititalize(BagContainer)
    -- just an empty hook for other addons
end


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
function AddOnTable:UpdateBankParents()
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