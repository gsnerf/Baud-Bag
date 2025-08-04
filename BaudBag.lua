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
        AddOnTable.ApplyOverrides()
    end,

    PLAYER_LOGIN = function(self, event, ...)
        if (not BaudBag_DebugLog) then
            BaudBag_Debug = {}
        end
        AddOnTable.Functions.DebugMessage("Bags", "Event PLAYER_LOGIN fired")

        BaudBagUpdateFromBBConfig()
        AddOnTable:ConfigUpdated()

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
    if AddOnTable.Functions.IsInventory(bagId) then
        if collectedBagEvents[bagId] == nil then
            collectedBagEvents[bagId] = {}
        end
        table.insert(collectedBagEvents[bagId], event)

        -- temporary until BAG_UPDATE_DELAYED is fixed again
        AddOnTable["SubBags"][bagId]:UpdateSlotContents()
    end
end
EventFuncs.BAG_OPEN = Func
EventFuncs.BAG_UPDATE = Func
EventFuncs.BAG_CLOSED = Func

Func = function(self, event, ...)
    AddOnTable.Functions.DebugMessage("Bags", "BAG_UPDATE_DELAYED (collectedBagEvents)", collectedBagEvents)
    -- collect information on last action
    local affectedContainerCount = 0
    for bagId, _ in pairs(collectedBagEvents) do
        affectedContainerCount = affectedContainerCount + 1
    end

    -- full rebuild if it seems the bags could have been swapped (something like this will probably be necessary for classic, so it stays for the moment)
    if affectedContainerCount > 1 then
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
    BaudBag_RegisterBackpackEvents(self)
    AddOnTable.Functions.RegisterEvents(self)
    AddOnTable:RegisterEvents(self)
end


--[[ this will call the correct event handler ]]--
function BaudBag_OnEvent(self, event, ...)
    BaudBag_OnBackpackEvent(self, event, ...)
    if EventFuncs[event] then
        EventFuncs[event](self, event, ...)
    end
    AddOnTable.Functions.OnEvent(self, event, ...)
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
    local Bag, Slot = ...
    if (Slot == nil or self:GetID() ~= Bag) then
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
    for _, bagSet in pairs(BagSetType) do
        AddOnTable.Sets[bagSet.Id]:RebuildContainers()
        if (BBConfig[bagSet.Id].Enabled ~= true) then
            AddOnTable.Sets[bagSet.Id]:Close()
        end
    end
    AddOnTable.BagsReady = true
    AddOnTable:UpdateBagParents()
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