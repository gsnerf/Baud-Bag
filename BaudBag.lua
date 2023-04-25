-- addon defaults
local AddOnName, AddOnTable = ...
local Localized = AddOnTable.Localized
local _

-- necessary globals
_G[AddOnName] = AddOnTable
AddOnTable["Sets"] = {}
AddOnTable["SubBags"] = {}
AddOnTable["Backgrounds"] = {}

-- -> possibly move this to default config?
local FadeTime = 0.2

-- this is supposed to be deprecated and should be removed in the future this does not have to be global
local Prefix = "BaudBag" -- this should be identical to "AddOnName"
local NumCont = {}

--[[ Local helper methods used in event handling ]]
local function BackpackBagOverview_Initialize()
    -- create BagSlots for the bag overview in the inventory (frame that pops out and only shows the available bags)
    AddOnTable.Functions.DebugMessage("Bags", "Creating bag slot buttons.")
    local backpackSet = AddOnTable["Sets"][1]
    local BBContainer1 = _G[Prefix.."Container1_1BagsFrame"]

    -- this is one container less, as the backpack itself doesn't get a button
    for backpackBagButton = 0, AddOnTable.BlizzConstants.BACKPACK_CONTAINER_NUM - 1 do
        local bagButton = AddOnTable:CreateBackpackBagButton(backpackBagButton, BBContainer1)
        bagButton:SetPoint("TOPLEFT", 8, -8 - backpackBagButton * bagButton:GetHeight())
        backpackSet.BagButtons[backpackBagButton] = bagButton
	end

    if (GetExpansionLevel() >= 9) then
        for reagentBagButton = 0, AddOnTable.BlizzConstants.BACKPACK_REAGENT_BAG_NUM - 1 do
            local bagButton = AddOnTable:CreateReagentBagButton(reagentBagButton, BBContainer1)
            bagButton:SetPoint("TOPLEFT", 8, -8 - (#backpackSet.BagButtons + 1 + reagentBagButton) * bagButton:GetHeight())
            backpackSet.ReagentBagButtons[reagentBagButton] = bagButton
        end
    end

    local firstBackpackBagButton = backpackSet.BagButtons[0]
    BBContainer1:SetWidth(15 + firstBackpackBagButton:GetWidth())
    BBContainer1:SetHeight(15 + AddOnTable.BlizzConstants.BACKPACK_TOTAL_BAGS_NUM * firstBackpackBagButton:GetHeight())
end

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
    end,

    PLAYER_LOGIN = function(self, event, ...)
        if (not BaudBag_DebugLog) then
            BaudBag_Debug = {}
        end
        AddOnTable.Functions.DebugMessage("Bags", "Event PLAYER_LOGIN fired")

        BackpackBagOverview_Initialize()
        BaudBagUpdateFromBBConfig()
        BaudBagBankBags_Initialize()
        if BBConfig and (BBConfig[2].Enabled == true) then 
            AddOnTable.Functions.DebugMessage("Bank", "BaudBag enabled for Bank, disable default bank event")
            BankFrame:UnregisterEvent("BANKFRAME_OPENED")
        end

        AddOnTable:UpdateBankParents()
        AddOnTable:UpdateBagParents()
    end,

    PLAYER_MONEY = function(self, event, ...)
        AddOnTable.Functions.DebugMessage("Bags", "Event PLAYER_MONEY fired")
        BaudBagBankBags_Update()
    end,

    ITEM_LOCK_CHANGED = function(self, event, ...)
        local Bag, Slot = ...

        -- do nothing if this was called for an equipment slot, rather than a bag slot
        local notASlot = Slot == nil
        local invalidBankSlot = (Bag == BANK_CONTAINER and Slot > NUM_BANKGENERIC_SLOTS)
        local bagNotVisible = not notASlot and not AddOnTable.SubBags[Bag]:IsOpen()

        if (notASlot or invalidBankSlot or bagNotVisible) then
            return
        end

        AddOnTable.Functions.DebugMessage("ItemHandle", "Event ITEM_LOCK_CHANGED fired (bag, slot) ", Bag, Slot)
        if (Bag == BANK_CONTAINER) then
            if (Slot <= NUM_BANKGENERIC_SLOTS) then
                BankFrameItemButton_UpdateLocked(_G[Prefix.."SubBag-1Item"..Slot])
            else
                local bankBagButton = AddOnTable["Sets"][2].BagButtons[Slot-NUM_BANKGENERIC_SLOTS]
                BankFrameItemButton_UpdateLocked(bankBagButton)
            end
        elseif (Bag == REAGENTBANK_CONTAINER) then
            BankFrameItemButton_UpdateLocked(_G[Prefix.."SubBag-3Item"..Slot])
        end

        if (Slot ~= nil) then
            local containerItemInfo = AddOnTable.BlizzAPI.GetContainerItemInfo(Bag, Slot)
            local itemLock = AddOnTable.State.ItemLock
            if ((not containerItemInfo.isLocked) and itemLock.Move) then
                if (itemLock.IsReagent and (BaudBag_IsBankContainer(Bag)) and (Bag ~= REAGENTBANK_CONTAINER)) then
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
Func = function(self, event, ...)
    AddOnTable.Functions.DebugMessage("Bags", "Event fired (event)", event)
    BaudBagAutoOpenSet(1, false)
end
EventFuncs.MAIL_SHOW = Func
EventFuncs.AUCTION_HOUSE_SHOW = Func

Func = function(self, event, ...)
    AddOnTable.Functions.DebugMessage("Bags", "Event fired", event)
    BaudBagAutoOpenSet(1, true)
end
EventFuncs.MERCHANT_CLOSED = Func
EventFuncs.MAIL_CLOSED = Func
EventFuncs.AUCTION_HOUSE_CLOSED = Func

local collectedBagEvents = {}
Func = function(self, event, ...)
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
            local bankBagButton = AddOnTable["Sets"][2].BagButtons[bankBagId]
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
            AddOnTable.Sets[1]:RebuildContainers()
            for _, button in ipairs(AddOnTable.Sets[1].BagButtons) do
                button:Hide()
                button:Show()
            end
            for _, button in ipairs(AddOnTable.Sets[1].ReagentBagButtons) do
                button:Hide()
                button:Show()
            end
        end
        if bankAffected then
            AddOnTable.Sets[2]:RebuildContainers()
        end
        BaudBagUpdateOpenBagHighlight()
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
    AddOnTable.Sets[1]:RebuildContainers()
    AddOnTable.Sets[2]:RebuildContainers()
    if (BaudBagOptions:IsShown()) then
        BaudBagOptions:Update()
    end
end

local function HandleMerchantShow()
    AddOnTable.Functions.DebugMessage("Bags", "MerchandFrame was shown, opening bags")
    BaudBagAutoOpenSet(1, false)

    AddOnTable.Functions.DebugMessage("Junk", "MerchandFrame was shown checking if we need to sell junk")
    if (BBConfig.SellJunk and MerchantFrame:IsShown()) then
        AddOnTable.Functions.DebugMessage("Junk", "junk selling active and merchant frame is shown, identifiyng junk now")
        BaudBagForEachBag(1,
            function(Bag, Index)
                for Slot = 1, AddOnTable.BlizzAPI.GetContainerNumSlots(Bag) do
                    local containerItemInfo = AddOnTable.BlizzAPI.GetContainerItemInfo(Bag, Slot)
                    if (containerItemInfo and containerItemInfo.quality and containerItemInfo.quality == 0) then
                        AddOnTable.Functions.DebugMessage("Junk", "Found junk (Container, Slot)", Bag, Slot)
                        AddOnTable.BlizzAPI.UseContainerItem(Bag, Slot)
                    end
                end
            end
        )
    end
end

if PlayerInteractionFrameManager ~= nil then
    Func = function(self, event, ...)
        -- todo: also call original manager when bank is deactivated in the settings!
        local type = ...
        if type ~= Enum.PlayerInteractionType.Banker or not BBConfig[2].Enabled then
            PlayerInteractionFrameManager:OnEvent(event, ...)
        end

        if type == Enum.PlayerInteractionType.Merchant then
            if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
                HandleMerchantShow()
            end

            --[[if event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
                -- for the moment still handled via MERCHANT_CLOSED
            end]]
        end
    end
    EventFuncs.PLAYER_INTERACTION_MANAGER_FRAME_SHOW = Func
    EventFuncs.PLAYER_INTERACTION_MANAGER_FRAME_HIDE = Func
end
--[[ END OF NON XML EVENT HANDLERS ]]--


--[[ xml defined (called) BaudBagFrame event handlers ]]--
function BaudBag_OnLoad(self, event, ...)
    BINDING_HEADER_BaudBag					= "Baud Bag"
    BINDING_NAME_BaudBagToggleBank			= "Toggle Bank"
    BINDING_NAME_BaudBagToggleVoidStorage	= "Show Void Storage"

    AddOnTable.Functions.DebugMessage("Bags", "OnLoad was called")

    AddOnTable.Functions.InitFunctions()

    -- register for global events (actually handled in OnEvent function)
    for Key, Value in pairs(EventFuncs)do
        self:RegisterEvent(Key)
    end
    BaudBag_RegisterBankEvents(self)
    AddOnTable.Functions.RegisterEvents(self)

    -- ensure to de-register the default player interaction frame, just so that we can take over the bank opening...
    if PlayerInteractionFrameManager ~= nil then
        PlayerInteractionFrameManager:UnregisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
        PlayerInteractionFrameManager:UnregisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
    end

    -- the first container from each set (inventory/bank) is different and is created in the XML
    local Container
    for BagSet = 1, 2 do
        Container = _G[Prefix.."Container"..BagSet.."_1"]
        Container.FreeSlots:SetPoint("RIGHT",Container:GetName().."MoneyFrame","LEFT")
        Container.BagSet = BagSet
        Container:SetID(1)
    end

    AddOnTable.Functions.DebugMessage("Bags", "Create BagSets")
    BackpackSet = AddOnTable:CreateBagSet(BagSetType.Backpack)
    BankSet = AddOnTable:CreateBagSet(BagSetType.Bank)

    -- create all necessary SubBags now with basic initialization, correct referencing later when config is available
    AddOnTable.Functions.DebugMessage("Bags", "Creating sub bags")
    BackpackSet:PerformInitialBuild()
    BankSet:PerformInitialBuild()
end


--[[ this will call the correct event handler]]--
function BaudBag_OnEvent(self, event, ...)
    BaudBag_OnBankEvent(self, event, ...)
    if EventFuncs[event] then
        EventFuncs[event](self, event, ...)
    end
    AddOnTable.Functions.OnEvent(self, event, ...)
end

-- this just makes sure the bags will be visible at the correct layer position when opened
function BaudBagBagsFrame_OnShow(self, event, ...)
    local isBags = self:GetName() == "BaudBagContainer1_1BagsFrame"
    local Level = self:GetFrameLevel() + 1
    AddOnTable.Functions.DebugMessage("Bank", "BaudBagBagsFrame is shown, correcting frame layer lvls of childs (frame, targetLevel)", self:GetName(), Level)
    -- Adjust frame level because of Blizzard's screw up
    if (isBags) then
        local backpackSet = AddOnTable["Sets"][1]
        for Bag = 0, 3 do
            backpackSet.BagButtons[Bag]:SetFrameLevel(Level)
        end
        if (backpackSet.ReagentBagButtons[0]) then
            backpackSet.ReagentBagButtons[0]:SetFrameLevel(Level)
        end
    else
        local bagSet = AddOnTable["Sets"][2]
        for Bag = 1, NUM_BANKBAGSLOTS do
            bagSet.BagButtons[Bag]:SetFrameLevel(Level)
        end
        if (AddOnTable.State.ReagentBankSupported) then
            _G["BBReagentsBag"]:SetFrameLevel(Level)
        end
    end
end

--[[ Container events ]]--
function BaudBagContainer_OnLoad(self, event, ...)
    tinsert(UISpecialFrames, self:GetName()) -- <- needed?
    self:RegisterForDrag("LeftButton")
end

function BaudBagContainer_OnUpdate(self, event, ...)

    local containerObject = AddOnTable["Sets"][self.BagSet].Containers[self:GetID()]

    if (self.Refresh) then
        containerObject:Update()
        BaudBagUpdateOpenBagHighlight()
    end

    if (self.UpdateSlots) then
        AddOnTable["Sets"][self.BagSet]:UpdateSlotInfo()
    end

    if (self.FadeStart) then
        local Alpha = (GetTime() - self.FadeStart) / FadeTime
        if not BBConfig.EnableFadeAnimation then
            -- immediate show/hide without animation
            Alpha = 1.1
        end
        if self.Closing then
            Alpha = 1 - Alpha
            if (Alpha < 0) then
                self.FadeStart = nil
                self:Hide()
                self.Closing = nil
                return
            end
        elseif (Alpha > 1) then
            self:SetAlpha(1)
            self.FadeStart = nil
            return
        end
        self:SetAlpha(Alpha)
    end
end


function BaudBagContainer_OnShow(self, event, ...)
    AddOnTable.Functions.DebugMessage("Bags", "BaudBagContainer_OnShow was called", self:GetName())
	
    -- check if the container was open before and closing now
    if self.FadeStart then
        return
    end
	
    -- container seems to not be visible, open and update
    self.FadeStart = GetTime()
    PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
    local bagSet = AddOnTable["Sets"][self.BagSet]
    local containerObject = bagSet.Containers[self:GetID()]
    containerObject:Update()
    if (containerObject.Frame.Slots > 0) then
        containerObject:UpdateBagHighlight()
    end

    if (self:GetID() == 1) then
        AddOnTable["Sets"][self.BagSet]:UpdateSlotInfo()
    end
end


function BaudBagContainer_OnHide(self, event, ...)
    -- correctly handle if this is called while the container is still fading out
    if self.Closing then
        if self.FadeStart then
            self:Show()
        end
        return
    end

    -- set vars for fading out ans start process
    self.FadeStart = GetTime()
    self.Closing = true
    PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
    self.AutoOpened = false
    BaudBagUpdateOpenBagHighlight()

    --[[TODO: look into merging the set specific close handling!!!]]--
    --[[
    if the option entry requires it close all remaining containers of the bag set
    (first the bag set so the "offline" title doesn't show up before closing and then the bank to disconnect)
    ]]--
    if (self:GetID() == 1) and (BBConfig[self.BagSet].Enabled) and (BBConfig[self.BagSet].CloseAll) then
        if (self.BagSet == 2) and AddOnTable.State.BankOpen then
            -- [TAINT] can be problematic, but doesn't have to be
            CloseBankFrame()
        end
        BaudBagCloseBagSet(self.BagSet)
    end

    self:Show()
end


function BaudBagContainer_OnDragStart(self, event, ...)
    if not BBConfig[self.BagSet][self:GetID()].Locked then
        self:StartMoving()
    end
end


function BaudBagContainer_OnDragStop(self, event, ...)
    self:StopMovingOrSizing()
    AddOnTable["Sets"][self.BagSet].Containers[self:GetID()]:SaveCoordsToConfig()
end


--[[ This function updates the parent containers for each bag, according to the options setup ]]--
function BaudUpdateJoinedBags()
    AddOnTable.Functions.DebugMessage("Bags", "Updating joined bags...")
    
    for bagSet = 1, 2 do
        NumCont[bagSet] = AddOnTable["Sets"][bagSet]:RebuildContainers()
    end

    AddOnTable.BagsReady = true
end

function BaudBagUpdateOpenBags()
    local Open, Frame, Slot, ItemButton, QuestTexture
    for _, subContainer in pairs(AddOnTable["SubBags"]) do
        subContainer:UpdateItemOverlays()
    end
end

--[[ Sets the highlight texture of bag slots indicating wether the contained bag is opened or not ]]--
function BaudBagUpdateOpenBagHighlight()
    AddOnTable.Functions.DebugMessage("Bags", "[BaudBagUpdateOpenBagHighlight]")
    for _, SubContainer in pairs(AddOnTable["SubBags"]) do
        SubContainer:UpdateOpenBagHighlight()
    end
end

--[[
    this function opens or closes a bag set (main bag with sub bags)
    BagSet (int): BagSet to open or close (1 - default bags, 2 - bank bags)
    Close (bool): should the set be closed instead of opened?
]]--
function BaudBagAutoOpenSet(BagSet, Close)
    -- debug messages:
    local closeState = Close and "true" or "false"
    AddOnTable.Functions.DebugMessage("BagOpening", "[AutoOpenSet Entry] (BagSet, Close)", BagSet, closeState)
    
    -- Set 2 doesn't need container 1 to be shown because that's a given
    local Container
    for ContNum = BagSet, NumCont[BagSet] do

        --[[ DEBUG ]]--
        local autoOpen = BBConfig[BagSet][ContNum].AutoOpen
        AddOnTable.Functions.DebugMessage("BagOpening", "[AutoOpenSet FOR] (ContNum, AutoOpen)", ContNum, autoOpen)

        if autoOpen then
            Container = _G[Prefix.."Container"..BagSet.."_"..ContNum]
            if not Close then
                if not Container:IsShown() then
                    AddOnTable.Functions.DebugMessage("BagOpening", "[AutoOpenSet FOR (IsShown)] FALSE")
                    Container.AutoOpened = true
                    Container:Show()
                else
                    AddOnTable.Functions.DebugMessage("BagOpening", "[AutoOpenSet FOR (IsShown)] TRUE")
                end
                BaudBagUpdateContainer(Container)
            elseif Container.AutoOpened then
                AddOnTable.Functions.DebugMessage("BagOpening", "[AutoOpenSet FOR (AutoOpened)] TRUE")
                Container.AutoOpened = false
                if BBConfig[BagSet][ContNum].AutoClose then
                    AddOnTable.Functions.DebugMessage("BagOpening", "[AutoOpenSet FOR (AutoOpened)] AutoClose set, hiding!")
                    Container:Hide()
                else
                    AddOnTable.Functions.DebugMessage("BagOpening", "[AutoOpenSet FOR (AutoOpened)] AutoClose not set, ignoring hide!")
                end
            else
                AddOnTable.Functions.DebugMessage("BagOpening", "[AutoOpenSet FOR (AutoOpened)] FALSE")
                BaudBagUpdateContainer(Container)
            end
        end
    end
end

function BaudBagCloseBagSet(BagSet)
    AddOnTable.Sets[BagSet]:Close()
end

local function IsBagShown(BagId)
    local SubContainer = AddOnTable["SubBags"][BagId]
    AddOnTable.Functions.DebugMessage("BagOpening", "Got SubContainer", SubContainer)
    return SubContainer:IsOpen()
end

local function UpdateThisHighlight(self)
    if BBConfig and (BBConfig[1].Enabled == false) then
        return
    end
    if IsBagShown(self:GetID() - CharacterBag0Slot:GetID() + 1) then
        self.SlotHighlightTexture:Show()
    else
        self.SlotHighlightTexture:Hide()
    end
end

--These function hooks override the bag button highlight changes that Blizzard does
--hooksecurefunc("BagSlotButton_OnClick", UpdateThisHighlight)
--hooksecurefunc("BagSlotButton_OnDrag", UpdateThisHighlight)
--hooksecurefunc("BagSlotButton_OnModifiedClick", UpdateThisHighlight)
--[[hooksecurefunc("BackpackButton_OnClick", function(self)
    if BBConfig and(BBConfig[1].Enabled == false)then
        return
    end
    if (IsBagShown(0)) then
        self.SlotHighlightTexture:Show()
    else
        self.SlotHighlightTexture:Hide()
    end
end)]]

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
    if BaudBag_IsBankDefaultContainer(self:GetID()) then
        return
    end

    for Key, Value in pairs(SubBagEvents) do
        self:RegisterEvent(Key)
    end
end


function BaudBagSubBag_OnEvent(self, event, ...)
    if not self:GetParent():IsShown() or BaudBag_IsBankDefaultContainer(Bag) or (self:GetID() >= 5) and not AddOnTable.State.BankOpen then
        return
    end
    SubBagEvents[event](self, event, ...)
end

--This is for the button that toggles the bank bag display
function BaudBagBagsButton_OnClick(self, event, ...)
    local Set = self:GetParent().BagSet
    --Bank set is automaticaly shown, and main bags are not
    BBConfig[Set].ShowBags = (BBConfig[Set].ShowBags==false)
    BaudBagUpdateBagFrames()
end


function BaudBagUpdateBagFrames()
    AddOnTable.Functions.DebugMessage("Bags", "Called BaudBagUpdateBagFrames()")
    local Shown, BagFrame, FrameName
    for BagSet = 1, 2 do
        Shown = (BBConfig[BagSet].ShowBags ~= false)
        _G[Prefix.."Container"..BagSet.."_1BagsButton"]:SetChecked(Shown)
        BagFrame = _G[Prefix.."Container"..BagSet.."_1BagsFrame"]
        AddOnTable.Functions.DebugMessage("Bags", "Updating (bagName, shown)", BagFrame:GetName(), Shown)
        if Shown then
            BagFrame:Show()
        else
            BagFrame:Hide()
        end
    end
end

--[[ DEPRECATED this WILL be moved to Container:Update()]]
function BaudBagUpdateContainer(Container)
    AddOnTable.Functions.DebugMessage("Bags", "Updating Container (name)", Container:GetName())
    local ContainerObject = AddOnTable["Sets"][Container.BagSet].Containers[Container:GetID()]
    ContainerObject:Update()
end

function BaudBag_OnModifiedClick(self, button)
    if (not AddOnTable.Cache:UsesCache(self:GetParent():GetID())) then
        return
    end

    if IsModifiedClick("SPLITSTACK")then
        StackSplitFrame:Hide()
    end

    local slotCache = AddOnTable.Cache:GetBagCache(self:GetParent():GetID())[self:GetID()]
    if slotCache then
        HandleModifiedItemClick(slotCache.Link)
    end
end


--hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", BaudBag_OnModifiedClick)
--hooksecurefunc("BankFrameItemButtonGeneric_OnModifiedClick", BaudBag_OnModifiedClick)

-- TODO: after changes there is some weird behavior after applying changes (like changing the name)
-- Seems to be in Background drawing for Slot Count
function BaudBagUpdateFromBBConfig()
    BaudUpdateJoinedBags()
    BaudBagUpdateBagFrames()
	
    for BagSet = 1, 2 do
        -- make sure the enabled states are current
        if (BBConfig[BagSet].Enabled ~= true) then
            BaudBagCloseBagSet(BagSet)
            if (BagSet == 2) then BankFrame:RegisterEvent("BANKFRAME_OPENED") end
        elseif (BagSet == 2) then
            BankFrame:UnregisterEvent("BANKFRAME_OPENED")
        end
    end
end

function BaudBagSearchButton_Click(self, event, ...)
    -- get references to all needed frames and data
    local Container		= self:GetParent()
    local Scale			= BBConfig[Container.BagSet][Container:GetID()].Scale / 100
    local Background	= BBConfig[Container.BagSet][Container:GetID()].Background
    
    BaudBagSearchFrame_ShowFrame(Container, Scale, Background)
end

function BaudBagSearchButton_Enter(self, event, ...)
    GameTooltip:SetOwner(self)
    GameTooltip:SetText(Localized.SearchBagTooltip)
    GameTooltip:Show()
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
        local sourceIsBank = BaudBag_IsBankContainer(self:GetParent():GetID())
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

--[[ this method ensures that the bank bags are either placed as childs under UIParent or BaudBag ]]
function AddOnTable:UpdateBagParents()
    local newParent = UIParent
    if AddOnTable.Functions.BagHandledByBaudBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER) then
        newParent = BaudBag_OriginalBagsHideFrame
    end

    if (ContainerFrameCombinedBags) then
        ContainerFrameCombinedBags:SetParent(newParent)
    end
    for i, frame in ContainerFrameUtil_EnumerateContainerFrames() do
        frame:SetParent(newParent)
    end
end