local AddOnName, AddOnTable = ...
local _
local Prefix = "BaudBag"
local Localized = AddOnTable.Localized

local EventFuncs = {
    BANKFRAME_CLOSED = function(self, event, ...)
        AddOnTable.Functions.DebugMessage("Bank", "Event BANKFRAME_CLOSED fired")
        AddOnTable.State.BankOpen = false
        BaudBagBankSlotPurchaseButton:Disable()
        if _G[Prefix.."Container2_1"].AutoOpened then
            _G[Prefix.."Container2_1"]:Hide()
        else
            --Add offline again to bag name
            local numberOfContainers = AddOnTable.Sets[2].ContainerNumber
            for ContNum = 1, numberOfContainers do
                AddOnTable.Sets[2].Containers[ContNum]:UpdateName()
            end
        end
        AddOnTable.Sets[1]:AutoClose()
    end,

    PLAYER_MONEY = function(self, event, ...)
        AddOnTable.Functions.DebugMessage("Bags", "Event PLAYER_MONEY fired")
        BaudBagBankBags_Update()
    end,
}

local Func = function(self, event, ...)
    AddOnTable.Functions.DebugMessage("Bank", "Event fired", event)
    
	-- set bank open marker if it was opend
    if (event == "BANKFRAME_OPENED") then
        AddOnTable.State.BankOpen = true
    end
    
    -- everything coming now is only needed if the bank is visible
    local bankVisible = BBConfig[2].Enabled and (event == "BANKFRAME_OPENED")
    AddOnTable:BankBags_UpdateContent(self, bankVisible)
    if not bankVisible then
        return
    end
    
    -- make sure current bag information are processed
    AddOnTable.Sets[2]:RebuildContainers()
    AddOnTable.Sets[1]:AutoOpen()
    AddOnTable.Sets[2]:AutoOpen()
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
function BaudBagBankBags_Initialize()
    local BagSlot, Texture
    local bankSet = AddOnTable["Sets"][2]
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


--[[
    This analyses the bought bags and updates the bag slot view
    (the little window that pops out the main bank container and shows the bought bags) 
    alongside the "bag slot buy" button 
  ]]
function BaudBagBankBags_Update()
    local Purchase = BaudBagBankSlotPurchaseFrame
    local Slots, Full = GetNumBankSlots()
    
    local BagSlot
    local bankSet = AddOnTable["Sets"][2]

    AddOnTable.Functions.DebugMessage("Bank", "BankBags: updating")
    
    for Bag = 1, NUM_BANKBAGSLOTS do
        BagSlot = bankSet.BagButtons[Bag]
        
        if (Bag <= Slots) then
            SetItemButtonTextureVertexColor(BagSlot, 1.0, 1.0, 1.0)
            BagSlot.tooltipText = BANK_BAG
        else
            SetItemButtonTextureVertexColor(BagSlot, 1.0, 0.1, 0.1)
            BagSlot.tooltipText = BANK_BAG_PURCHASE
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
    
    local Cost = GetBankSlotCost(Slots)
    AddOnTable.Functions.DebugMessage("Bank", "BankBags: buyable bag slots left, currentCost = "..Cost)
    
    -- This line allows the confirmation box to show the cost
    BankFrame.nextSlotCost = Cost
    
    if (GetMoney() >= Cost) then
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

    AddOnTable.SubBags[BANK_CONTAINER]:UpdateSlotContents()
    for Index = 1, NUM_BANKBAGSLOTS do
        local bankBagButton = AddOnTable["Sets"][2].BagButtons[Index]
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
        local inventoryId = BankButtonIDToInvSlotID(Bag, 1)
        bagCache.BagLink  = GetInventoryItemLink("player", inventoryId)
        bagCache.BagCount = GetInventoryItemCount("player", inventoryId)
    end
    
    local firstBankContainer = AddOnTable.Sets[2].Containers[1]
    if firstBankContainer.Frame:IsShown() then
        firstBankContainer:Update()
        AddOnTable["Sets"][2]:UpdateSlotInfo()
    else
        firstBankContainer.Frame.AutoOpened = true
        firstBankContainer.Frame:Show()
    end
end

function BaudBagToggleBank(self)
    local firstBankContainer = AddOnTable.Sets[2].Containers[1]
    if firstBankContainer.Frame:IsShown() then
        firstBankContainer.Frame:Hide()
        AddOnTable.Sets[2]:AutoClose()
    else
        firstBankContainer.Frame:Show()
        AddOnTable.Sets[2]:AutoOpen()
    end
end

--[[ this method ensures that the bank bags are either placed as childs under UIParent or BaudBag ]]
function AddOnTable:UpdateBankParents()
    local newParent = UIParent
    if AddOnTable.Functions.BagHandledByBaudBag(AddOnTable.BlizzConstants.BANK_CONTAINER) then
        newParent = BaudBag_OriginalBagsHideFrame
    end

    BankFrame:SetParent(newParent)
    for i = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
        _G["ContainerFrame"..(i+1)]:SetParent(newParent)
    end
end