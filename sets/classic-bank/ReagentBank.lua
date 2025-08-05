---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local Funcs = AddOnTable.Functions
local Events = AddOnTable.Events

local interfaceVersion = select(4, GetBuildInfo())

if (interfaceVersion >= 110200) then
    return
end

AddOnTable.State.ReagentBankSupported = true

--[[ This updates the visual of the given reagent bank item ]]
local Func = function(self, event, ...)
    local slot = ...
    Funcs.DebugMessage("BankReagent", "Updating Slot", slot)

    if not AddOnTable.State.BankOpen then return end

    local showColor = BBConfig.RarityColor
    local rarityIntensity = BBConfig.RarityIntensity

    local bagCache = AddOnTable.Cache:GetBagCache(AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER)
    local subBagObject = AddOnTable["SubBags"][AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER]
    --local rarityColor = BBConfig[2].RarityColor
    local finishItemButtonUpdateCallback = function(itemButton, link, newCacheEntry)
        bagCache[slot] = newCacheEntry
    end

    subBagObject.Items[slot]:SetRarityOptions(showColor, rarityIntensity)
    subBagObject.Items[slot]:UpdateContentFromLiveData(finishItemButtonUpdateCallback)
end
Events.PLAYERREAGENTBANKSLOTS_CHANGED = Func

Func = function(self, event, ...)
    _G["BaudBagSubBag-3"]:GetParent().UnlockInfo:Hide()
	_G["BaudBagSubBag-3"]:GetParent().DepositButton:Enable()
end
Events.REAGENTBANK_PURCHASED = Func

local function ReagentBankBagInitialize(self, BagContainer)
    -- create BagSlot for reagent bank!
    local BagSlot = CreateFrame("ItemButton", "BBReagentsBag", BagContainer, "ReagentBankSlotTemplate")
    BagSlot:SetID(AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER)
    BagSlot.Bag = AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER
    BagSlot:SetPoint("TOPLEFT", 8 + mod(NUM_BANKBAGSLOTS, 2) * 39, -8 - floor(NUM_BANKBAGSLOTS / 2) * 39)
    BagSlot:HookScript("OnEnter",	BaudBag_BagSlot_OnEnter)
    BagSlot:HookScript("OnUpdate",	BaudBag_BagSlot_OnUpdate)
    BagSlot:HookScript("OnLeave",	BaudBag_BagSlot_OnLeave)
    AddOnTable.Sets[BagSetType.Bank.Id].BagButtons[AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER] = BagSlot
end
hooksecurefunc(AddOnTable, "BankBags_Inititalize", ReagentBankBagInitialize)

local function ReagentBankBagUpdate(self)
    local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]

    local reagentBank = bankSet.SubContainers[AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER]
    local reagentBankContainer = reagentBank.Frame:GetParent()

    local unlockInfo = reagentBankContainer.UnlockInfo
    local depositButton = reagentBankContainer.DepositButton

    if (not AddOnTable.BlizzAPI.IsReagentBankUnlocked()) then
        local bagSlot = bankSet.BagButtons[AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER]
        bagSlot.IconBorder:SetVertexColor(1.0, 0.1, 0.1)
        unlockInfo:Show()
        depositButton:Disable()
        MoneyFrame_Update( unlockInfo.CostMoneyFrame, AddOnTable.BlizzAPI.GetReagentBankCost() )
    else
        unlockInfo:Hide()
        depositButton:Enable()
    end
end
hooksecurefunc(AddOnTable, "BankBags_Update", ReagentBankBagUpdate)

local function ReagentBankBagUpdateContent(self, bankVisible)
    AddOnTable.SubBags[REAGENTBANK_CONTAINER]:UpdateSlotContents()
end
hooksecurefunc(AddOnTable, "BankBags_UpdateContent", ReagentBankBagUpdateContent)

--[[ this prepares the visual style of the reagent bag slot ]]
function ReagentBankSlotButton_OnLoad(self, event, ...)
    -- for the time beeing we use the texture of manastorms duplicator for the reagent bank button
    local texture = C_Item.GetItemIconByID(118938)
    Funcs.DebugMessage("BankReagent", "[SlotButton_OnLoad] Updating texture of reagent bank slot")
    SetItemButtonTexture(self, texture)
end

function ReagentBankSlotButton_OnEvent(self, event, ...)
    Funcs.DebugMessage("BankReagent", "[SlotButton_OnEvent] called event "..event)
end

function ReagentBankSlotButton_OnEnter(self, event, ...)
    Funcs.DebugMessage("BankReagent", "[SlotButton_OnEnter] Hovering over bank slot, showing tooltip")
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(REAGENT_BANK)
end

function ReagentBankSlotButton_OnClick(self, event, ...)
    Funcs.DebugMessage("BankReagent", "[SlotButton_OnClick] trying to show reagent bank")
    -- trying to determine container for reagent bank
    local RBankContainer = _G["BaudBagSubBag-3"]:GetParent()
    if (RBankContainer:IsShown()) then
        RBankContainer:Hide()
    else
        RBankContainer:Show()
    end
end

BaudBagReagentBankUnlockMixin = {}

function BaudBagReagentBankUnlockMixin:OnLoad()
    BaudBagContainerUnlockMixin.OnLoad(self)
    self.Title:SetText(REAGENT_BANK)
    self.Text:SetText(REAGENTBANK_PURCHASE_TEXT)
    self.PurchaseButton:SetAttribute("clickbutton", ReagentBankFrameUnlockInfoPurchaseButton)
end

function BaudBagReagentBankUnlockMixin:Refresh()
    -- TODO: global api access
    MoneyFrame_Update( self.CostMoneyFrame, GetReagentBankCost())
end

function BaudBag_ContainerFrameItemButton_OnClick(self, button)
    AddOnTable.Functions.DebugMessage("ItemHandle", "OnClick called (button, bag)", button, self:GetParent():GetID())
    if (button ~= "LeftButton" and AddOnTable.State.BankOpen) then
        local itemId = AddOnTable.BlizzAPI.GetContainerItemID(self:GetParent():GetID(), self:GetID())
        local isReagent = (itemId and AddOnTable.Functions.IsCraftingReagent(itemId))
        local sourceIsBank = AddOnTable.Functions.IsBankContainer(self:GetParent():GetID())
        local targetReagentBank = AddOnTable.BlizzAPI.IsReagentBankUnlocked() and isReagent
        
        AddOnTable.Functions.DebugMessage("ItemHandle", "handling item (itemId, isReagent, targetReagentBank)", itemId, isReagent, targetReagentBank)

        -- remember to start a move operation when item was placed in bank by wow!
        if (targetReagentBank) then
            AddOnTable.State.ItemLock.Move      = true
            AddOnTable.State.ItemLock.IsReagent = true
        end
    end
end
hooksecurefunc("ContainerFrameItemButton_OnClick", BaudBag_ContainerFrameItemButton_OnClick)

function BaudBag_FixContainerClickForReagent(Bag, Slot)
    -- determine if there is another item with the same item in the reagent bank
    AddOnTable.Functions.DebugMessage("ItemHandle", "Trying to fix a reagent right click to move it to the reagent bank")
    local containerItemInfoBag = AddOnTable.BlizzAPI.GetContainerItemInfo(Bag, Slot)
    local maxSize = select(8, AddOnTable.BlizzAPI.GetItemInfo(containerItemInfoBag.hyperlink))
    local targetSlots = {}
    local emptySlots = AddOnTable.BlizzAPI.GetContainerFreeSlots(REAGENTBANK_CONTAINER)
    for i = 1, AddOnTable.BlizzAPI.GetContainerNumSlots(REAGENTBANK_CONTAINER) do
        local containerItemInfoReagentBank = AddOnTable.BlizzAPI.GetContainerItemInfo(REAGENTBANK_CONTAINER, i)
        if (containerItemInfoReagentBank ~= nil and containerItemInfoBag.hyperlink == containerItemInfoReagentBank.hyperlink) then
            local target    = {
                count    = containerItemInfoReagentBank.stackCount,
                slot     = i
            }
            table.insert(targetSlots, target)
        end
    end

    AddOnTable.Functions.DebugMessage("ItemHandle", "fixing reagent bank entry (Bag, Slot, targetSlots, emptySlots)", Bag, Slot, targetSlots, emptySlots)

    -- if there already is a stack of the same item try to join the stacks
    local count = containerItemInfoBag.stackCount
    for Key, Value in pairs(targetSlots) do
        AddOnTable.Functions.DebugMessage("ItemHandle", "there already seem to be items of the same type in the reagent bank", Value)
        
        -- only do something if there are still items to put somewhere (split)
        if (count > 0) then
            -- determine if there is enough space to put everything inside
            local space = maxSize - Value.count
            AddOnTable.Functions.DebugMessage("ItemHandle", "The current stack has this amount of (space)", space)
            if (space > 0) then
                if (space < count) then
                    -- doesn't seem so, split and go on
                    AddOnTable.BlizzAPI.SplitContainerItem(Bag, Slot, space)
                    AddOnTable.BlizzAPI.PickupContainerItem(REAGENTBANK_CONTAINER, Value.slot)
                    count = count - space
                else
                    -- seems so: put everything there
                    AddOnTable.BlizzAPI.PickupContainerItem(Bag, Slot)
                    AddOnTable.BlizzAPI.PickupContainerItem(REAGENTBANK_CONTAINER, Value.slot)
                    count = 0
                end
            end
        end
    end

    AddOnTable.Functions.DebugMessage("ItemHandle", "joining complete (leftItemCount)", count)
    
    -- either join didn't work or there's just something left over, we now put the rest in the first empty slot
    if (count > 0) then
        for Key, Value in pairs(emptySlots) do
            AddOnTable.Functions.DebugMessage("ItemHandle", "putting rest stack into reagent bank slot (restStack)", Value)
            AddOnTable.BlizzAPI.PickupContainerItem(Bag, Slot)
            AddOnTable.BlizzAPI.PickupContainerItem(REAGENTBANK_CONTAINER, Value)
            return
        end
    end
end