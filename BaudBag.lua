-- addon defaults
---@class AddonNamespace
local AddOnTable = select(2, ...)
local AddOnName = select(1, ...)
local Localized = AddOnTable.Localized
local _

-- necessary globals
_G[AddOnName] = AddOnTable
---@type BagSet[]
AddOnTable["Sets"] = {}
---@type SubContainer[]
AddOnTable["SubBags"] = {}
AddOnTable["Backgrounds"] = {}

-- this is supposed to be deprecated and should be removed in the future this does not have to be global
local Prefix = "BaudBag" -- this should be identical to "AddOnName"

--[[ NON XML EVENT HANDLERS ]]--
--[[ these are the custom defined BaudBagFrame event handlers attached to a single event type]]--

local EventFuncs = {
    ADDON_LOADED = function(self, event, ...)
        -- check if the event was loaded for this addon
        local arg1 = ...
        if (arg1 ~= "BaudBag") then return end

        AddOnTable.Functions.DebugMessage("Bags", "Event ADDON_LOADED fired")

        -- make sure the cache is initialized
        AddOnTable:InitCache()
        AddOnTable:RegisterDefaultBackgrounds()

        -- the rest of the bank slots are cleared in the next event
        -- TODO: recheck why this is necessary and if it can be avoided
        BaudBagBankSlotPurchaseButton:Disable()

        AddOnTable.ApplyOverrides()
    end,

    PLAYER_LOGIN = function(self, event, ...)
        if (not BaudBag_DebugLog) then
            BaudBag_Debug = {}
        end
        AddOnTable.Functions.DebugMessage("Bags", "Event PLAYER_LOGIN fired")

        BaudBagUpdateFromBBConfig()

        AddOnTable:UpdateBankParents()
        AddOnTable:UpdateBagParents()

        for _, bagSetType in pairs(BagSetType) do
            bagSetType.BagOverview_Initialize()
            local bagSet = AddOnTable.Sets[bagSetType.Id]
            -- TODO: get rid of "Frame"...
            if (bagSet.Containers[1].Frame.Initialize) then
                bagSet.Containers[1].Frame:Initialize()
            end
            -- first time rebuld necessary to support containers that support cache
            bagSet.Containers[1]:Rebuild()
        end
    end,

    ITEM_LOCK_CHANGED = function(self, event, ...)
        local Bag, Slot = ...

        -- do nothing if this was called for an equipment slot, rather than a bag slot
        local notASlot = Slot == nil
        local invalidBankSlot = (Bag == BANK_CONTAINER and Slot > NUM_BANKGENERIC_SLOTS)
        local bagNotVisible = not notASlot and (AddOnTable.SubBags[Bag] == nil or not AddOnTable.SubBags[Bag]:IsOpen())

        if (notASlot or invalidBankSlot or bagNotVisible) then
            return
        end

        AddOnTable.Functions.DebugMessage("ItemHandle", "Event ITEM_LOCK_CHANGED fired (bag, slot) ", Bag, Slot)
        if (Bag == BANK_CONTAINER) then
            if (Slot <= NUM_BANKGENERIC_SLOTS) then
                BankFrameItemButton_UpdateLocked(_G[Prefix.."SubBag-1Item"..Slot])
            else
                local bankBagButton = AddOnTable.Sets[BagSetType.Bank.Id].BagButtons[Slot-NUM_BANKGENERIC_SLOTS]
                BankFrameItemButton_UpdateLocked(bankBagButton)
            end
        elseif (Bag == REAGENTBANK_CONTAINER) then
            BankFrameItemButton_UpdateLocked(_G[Prefix.."SubBag-3Item"..Slot])
        end

        if (Slot ~= nil) then
            local containerItemInfo = AddOnTable.BlizzAPI.GetContainerItemInfo(Bag, Slot)
            local itemLock = AddOnTable.State.ItemLock
            if ((not containerItemInfo.isLocked) and itemLock.Move) then
                if (itemLock.IsReagent and (AddOnTable.Functions.IsBankContainer(Bag)) and (Bag ~= REAGENTBANK_CONTAINER)) then
                    BaudBag_FixContainerClickForReagent(Bag, Slot)
                end
                itemLock.Move      = false
                itemLock.IsReagent = false
            end
            AddOnTable.Functions.DebugMessage("ItemHandle", "Updating ItemLock Info", itemLock.ItemLock)
        end
    end,

    ITEM_PUSH = function(self, event, ...)
        local BagID, Icon = ...
        AddOnTable.Functions.DebugMessage("ItemHandle", "Received new item", BagID)
        if (not BBConfig.ShowNewItems) then
            C_NewItems.ClearAll()
        end
    end,

    BAG_UPDATE_COOLDOWN = function(self, event, ...)
        local BagID = ...
        AddOnTable.Functions.DebugMessage("ItemHandle", "Item is on Cooldown after usage", BagID)
        BaudBagUpdateOpenBags()
    end,

    QUEST_ACCEPTED = function(self, event, ...)
        BaudBagUpdateOpenBags()
    end,
    QUEST_REMOVED = function(self, event, ...)
        BaudBagUpdateOpenBags()
    end
}

--[[ here come functions that will be hooked up to multiple events ]]--
local collectedBagEvents = {}
local Func = function(self, event, ...)
    AddOnTable.Functions.DebugMessage("Bags", "Event fired (event, source)", event, self:GetName())

    -- this is the ID of the affected container as known to WoW
    local bagId = ...
    if AddOnTable.Functions.IsBankContainer(bagId) or AddOnTable.Functions.IsInventory(bagId) then
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
    local bankAffected = false
    local bagsAffected = false
    for bagId, _ in pairs(collectedBagEvents) do
        affectedContainerCount = affectedContainerCount + 1
        if AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER <= bagId and bagId <= AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER then
            bagsAffected = true
        elseif bagId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER or bagId == AddOnTable.BlizzConstants.BANK_CONTAINER or AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER <= bagId then
            bankAffected = true
        end
    end

    -- full rebuild if it seems the bags could have been swapped (something like this will probably be necessary for classic, so it stays for the moment)
    if affectedContainerCount > 1 then
        if bagsAffected then
            local backpackSet = AddOnTable.Sets[BagSetType.Backpack.Id]
            backpackSet:RebuildContainers()
            for _, button in ipairs(backpackSet.BagButtons) do
                button:Hide()
                button:Show()
            end
            for _, button in ipairs(backpackSet.ReagentBagButtons) do
                button:Hide()
                button:Show()
            end
            backpackSet:UpdateBagHighlight()
        end
        if bankAffected then
            local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]
            bankSet:RebuildContainers()
            bankSet:UpdateBagHighlight()
        end
    else
        -- single bag update otherwise
        for bagId, _ in pairs(collectedBagEvents) do
            --AddOnTable["SubBags"][bagId]:Rebuild()
            AddOnTable["SubBags"][bagId]:UpdateSlotContents()
        end
    end

    -- reset collected data for next action
    collectedBagEvents = {}
end
EventFuncs.BAG_UPDATE_DELAYED = Func

EventFuncs.BAG_CONTAINER_UPDATE = function(self, event, ...)
    -- not sure how to identify what set is affected, so for now rebuild everything
    for _, bagSet in pairs(AddOnTable.Sets) do
        bagSet:RebuildContainers()
    end
    if (BaudBagOptions:IsShown()) then
        BaudBagOptions:Update()
    end
end

--[[ END OF NON XML EVENT HANDLERS ]]--


--[[ xml defined (called) BaudBagFrame event handlers ]]--
function BaudBag_OnLoad(self, event, ...)
    BINDING_HEADER_BaudBag					= "Baud Bag"
    BINDING_NAME_BaudBagToggleBank			= "Toggle Bank"
    BINDING_NAME_BaudBagToggleAccountBank	= "Toggle Warband Bank"
    BINDING_NAME_BaudBagToggleVoidStorage	= "Show Void Storage"

    AddOnTable.Functions.DebugMessage("Bags", "OnLoad was called")

    AddOnTable.Functions.InitFunctions()

    AddOnTable:ExtendBaseTypes()
    
    AddOnTable.Functions.DebugMessage("Bags", "Create BagSets")
    local Container
    for _, bagSetType in pairs(BagSetType) do
        bagSetType:Init()
        local bagSet = AddOnTable:CreateBagSet(bagSetType)
        bagSet:PerformInitialBuild()

        -- the first container for each set is different and is created in XML
        Container = _G[Prefix.."Container"..bagSetType.Id.."_1"]
        -- FreeSlots is only available in containers that inherit from BaudBagFirstContainerTemplate
        -- in special case Keyring this is not given
        if (Container.FreeSlots) then
            Container.FreeSlots:SetPoint("RIGHT",Container:GetName().."MoneyFrame","LEFT")
        end
        Container.BagSet = bagSetType.Id
        Container:SetID(1)
    end
    
    -- we think anything essential now should be available... let the system react to that
    AddOnTable:EssentialsLoaded()

    -- register for global events (actually handled in OnEvent function)
    for Key, Value in pairs(EventFuncs)do
        self:RegisterEvent(Key)
    end
    BaudBag_RegisterBankEvents(self)
    BaudBag_RegisterBackpackEvents(self)
    AddOnTable.Functions.RegisterEvents(self)
end


--[[ this will call the correct event handler ]]--
function BaudBag_OnEvent(self, event, ...)
    BaudBag_OnBankEvent(self, event, ...)
    BaudBag_OnBackpackEvent(self, event, ...)
    if EventFuncs[event] then
        EventFuncs[event](self, event, ...)
    end
    AddOnTable.Functions.OnEvent(self, event, ...)
end

--[[ This function updates the parent containers for each bag, according to the options setup ]]--
function BaudUpdateJoinedBags()
    AddOnTable.Functions.DebugMessage("Bags", "Updating joined bags...")
    
    for _, bagSet in pairs(BagSetType) do
        AddOnTable.Sets[bagSet.Id]:RebuildContainers()
    end

    AddOnTable.BagsReady = true
end

function BaudBagUpdateOpenBags()
    for _, subContainer in pairs(AddOnTable["SubBags"]) do
        subContainer:UpdateItemOverlays()
    end
end

--[[ custom defined BaudBagSubBag event handlers ]]--
local SubBagEvents = {}

local Func = function(self, event, ...)
    -- only update if the lock is for this bag!
    local Bag = ...
    if (self:GetID() ~= Bag) then
        return
    end
    AddOnTable.Functions.DebugMessage("ItemHandle", "Event ITEM_LOCK_CHANGED fired for subBag (ID)", self:GetID())
    AddOnTable["SubBags"][self:GetID()]:UpdateSlotContents()
end
SubBagEvents.ITEM_LOCK_CHANGED = Func
SubBagEvents.BAG_UPDATE_COOLDOWN = Func
SubBagEvents.UPDATE_INVENTORY_ALERTS = Func

--[[ xml defined (called) BaudBagSubBag event handlers ]]--
function BaudBagSubBag_OnLoad(self, event, ...)
    if AddOnTable.Functions.IsDefaultContainer(self:GetID()) then
        return
    end

    for Key, Value in pairs(SubBagEvents) do
        self:RegisterEvent(Key)
    end
end


function BaudBagSubBag_OnEvent(self, event, ...)
    if not self:GetParent():IsShown() or AddOnTable.Functions.IsDefaultContainer(self:GetID()) or (self:GetID() >= 5) and not AddOnTable.State.BankOpen then
        return
    end
    SubBagEvents[event](self, event, ...)
end

-- TODO: after changes there is some weird behavior after applying changes (like changing the name)
-- Seems to be in Background drawing for Slot Count
--[[ this can probably be removed as this is only called on classic and a new way to bubble updates needs to be found ]]
function BaudBagUpdateFromBBConfig()
    BaudUpdateJoinedBags()
    for _, bagSet in pairs(BagSetType) do
    
        if (BBConfig[bagSet.Id].Enabled ~= true) then
            AddOnTable.Sets[bagSet.Id]:Close()
        end
    end
    AddOnTable:UpdateBagParents()
    AddOnTable:UpdateBankParents()
end

--[[ if the mouse hovers over the bag slot item the slots belonging to this bag should be shown after a certain time (atm 350ms or 0.35s) ]]
function BaudBag_BagSlot_OnEnter(self, event, ...)
    AddOnTable.Functions.DebugMessage("BagHover", "Mouse is hovering above item")
    self.HighlightBag		= true
    self.HighlightBagOn		= false
    self.HighlightBagCount	= GetTime() + 0.35
end

--[[ determine if and how long the mouse was hovering and change bag according ]]
function BaudBag_BagSlot_OnUpdate(self, event, ...)
    if (self.HighlightBag and (not self.HighlightBagOn) and GetTime() >= self.HighlightBagCount) then
        AddOnTable.Functions.DebugMessage("BagHover", "showing item (itemName)", self:GetName())
        self.HighlightBagOn	= true
        AddOnTable["SubBags"][self.Bag]:SetSlotHighlighting(true)
    end
end

--[[ if the mouse was removed cancel all actions ]]
function BaudBag_BagSlot_OnLeave(self, event, ...)
    AddOnTable.Functions.DebugMessage("BagHover", "Mouse not hovering above item anymore")
    self.HighlightBag		= false
	
    if (self.HighlightBagOn) then
        self.HighlightBagOn	= false
        AddOnTable["SubBags"][self.Bag]:SetSlotHighlighting(false)
    end
	
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