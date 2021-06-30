-- addon defaults
local AddOnName, AddOnTable = ...
local Localized = BaudBagLocalized
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
local ItemToolTip


local BBFrameFuncs = {
    IsCraftingReagent = function (itemId)
        ItemToolTip:SetItemByID(itemId)
        local isReagent = false
        for i = 1, ItemToolTip:NumLines() do
            local text = _G["BaudBagScanningTooltipTextLeft"..i]:GetText()
            if (string.find(text, Localized.TooltipScanReagent)) then
                isReagent = true
            end
        end
        return isReagent
    end
}

--[[ Local helper methods used in event handling ]]
local function BackpackBagOverview_Initialize()
    -- create BagSlots for the bag overview in the inventory (frame that pops out and only shows the available bags)
    BaudBag_DebugMsg("Bags", "Creating bag slot buttons.")
    local backpackSet = AddOnTable["Sets"][1]
    local BBContainer1 = _G[Prefix.."Container1_1BagsFrame"]
    BBContainer1:SetWidth(15 + 30)
    BBContainer1:SetHeight(15 + 4 * 30)
    
    for Bag = 1, 4 do
        local buttonIndex = Bag - 1
        local bagButton = AddOnTable:CreateBagButton(backpackSet.Type, buttonIndex, Bag, BBContainer1, "BagSlotButtonTemplate")
        bagButton.Frame:SetPoint("TOPLEFT", 8, -8 - buttonIndex * 30)
        bagButton.Frame:SetSize(30, 30)
        _G[bagButton.Frame:GetName().."NormalTexture"]:SetSize(48,48)
        backpackSet.BagButtons[buttonIndex] = bagButton
    end
end

--[[ NON XML EVENT HANDLERS ]]--
--[[ these are the custom defined BaudBagFrame event handlers attached to a single event type]]--

local EventFuncs = {
    ADDON_LOADED = function(self, event, ...)
        -- check if the event was loaded for this addon
        local arg1 = ...
        if (arg1 ~= "BaudBag") then return end

        BaudBag_DebugMsg("Bags", "Event ADDON_LOADED fired")

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
        BaudBag_DebugMsg("Bags", "Event PLAYER_LOGIN fired")
        

        BackpackBagOverview_Initialize()
        BaudBagUpdateFromBBConfig()
        BaudBagBankBags_Initialize()
        if BBConfig and (BBConfig[2].Enabled == true) then 
            BaudBag_DebugMsg("Bank", "BaudBag enabled for Bank, disable default bank event")
            BankFrame:UnregisterEvent("BANKFRAME_OPENED")
        end
    end,

    PLAYER_MONEY = function(self, event, ...)
        BaudBag_DebugMsg("Bags", "Event PLAYER_MONEY fired")
        BaudBagBankBags_Update()
    end,

    ITEM_LOCK_CHANGED = function(self, event, ...)
        local Bag, Slot = ...
        BaudBag_DebugMsg("ItemHandle", "Event ITEM_LOCK_CHANGED fired (bag, slot) ", Bag, Slot)
        if (Bag == BANK_CONTAINER) then
            if (Slot <= NUM_BANKGENERIC_SLOTS) then
                BankFrameItemButton_UpdateLocked(_G[Prefix.."SubBag-1Item"..Slot])
            else
                local bankBagButton = AddOnTable["Sets"][2].BagButtons[Slot-NUM_BANKGENERIC_SLOTS].Frame
                BankFrameItemButton_UpdateLocked(bankBagButton)
            end
        end

        if (Slot ~= nil) then
            local _, _, locked = GetContainerItemInfo(Bag, Slot)
            if ((not locked) and BaudBagFrame.ItemLock.Move) then
                BaudBagFrame.ItemLock.Move      = false
                BaudBagFrame.ItemLock.IsReagent = false
            end
            BaudBag_DebugMsg("ItemHandle", "Updating ItemLock Info", BaudBagFrame.ItemLock)
        end
    end,

    ITEM_PUSH = function(self, event, ...)
        local BagID, Icon = ...
        BaudBag_DebugMsg("ItemHandle", "Received new item", BagID)
        if (not BBConfig.ShowNewItems) then
            C_NewItems.ClearAll()
        end
    end,

    BAG_UPDATE_COOLDOWN = function(self, event, ...)
        local BagID = ...
        BaudBag_DebugMsg("ItemHandle", "Item is on Cooldown after usage", BagID)
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
    BaudBag_DebugMsg("Bags", "Event fired (event)", event)
    BaudBagAutoOpenSet(1, false)

    if (BBConfig.SellJunk and MerchantFrame:IsShown()) then
        BaudBagForEachBag(1,
            function(Bag, Index)
                for Slot = 1, GetContainerNumSlots(Bag) do
                    local quality = select(4, GetContainerItemInfo(Bag, Slot))
                    if (quality and quality == 0) then
                        BaudBag_DebugMsg("Junk", "Found junk (Container, Slot)", Bag, Slot)
                        UseContainerItem(Bag, Slot)
                    end
                end
            end
        )
    end
end
EventFuncs.MERCHANT_SHOW = Func

Func = function(self, event, ...)
    BaudBag_DebugMsg("Bags", "Event fired (event)", event)
    BaudBagAutoOpenSet(1, false)
end
EventFuncs.MAIL_SHOW = Func
EventFuncs.AUCTION_HOUSE_SHOW = Func

Func = function(self, event, ...)
    BaudBag_DebugMsg("Bags", "Event fired", event)
    BaudBagAutoOpenSet(1, true)
end
EventFuncs.MERCHANT_CLOSED = Func
EventFuncs.MAIL_CLOSED = Func
EventFuncs.AUCTION_HOUSE_CLOSED = Func

local collectedBagEvents = {}
Func = function(self, event, ...)
    BaudBag_DebugMsg("Bags", "Event fired (event, source)", event, self:GetName())

    -- this is the ID of the affected container as known to WoW
    local bagId = ...
    if bagId ~= -2 then
        if collectedBagEvents[bagId] == nil then
            collectedBagEvents[bagId] = {}
        end
        table.insert(collectedBagEvents[bagId], event)
    end

    -- old stuff, for compatibility until the stuff above works as expected
    -- if there are new bank slots the whole view has to be updated
    if (event == "PLAYERBANKSLOTS_CHANGED") then
        -- update bank bag slot
        if (bagId > NUM_BANKGENERIC_SLOTS) then
            local bankBagButton = AddOnTable["Sets"][2].BagButtons[bagId-NUM_BANKGENERIC_SLOTS].Frame
            BankFrameItemButton_Update(bankBagButton)
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
    BaudBag_DebugMsg("Bags", "BAG_UPDATE_DELAYED (collectedBagEvents)", collectedBagEvents)
    -- collect information on last action
    local affectedContainerCount = 0
    local bankAffected = false
    local bagsAffected = false
    for bagId, _ in pairs(collectedBagEvents) do
        affectedContainerCount = affectedContainerCount + 1
        if bagId >= 0 and bagId <= 4 then
            bagsAffected = true
        elseif bagId == -3 or bagId == -1 or bagId > 4 then
            bankAffected = true
        end
    end

    -- full rebuild if it seems the bags could have been swapped/added/removed
    if affectedContainerCount > 1 then
        if bagsAffected then
            AddOnTable.Sets[1]:RebuildContainers()
        end
        if bankAffected then
            AddOnTable.Sets[2]:RebuildContainers()
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
--[[ END OF NON XML EVENT HANDLERS ]]--


--[[ xml defined (called) BaudBagFrame event handlers ]]--
function BaudBag_OnLoad(self, event, ...)
    BINDING_HEADER_BaudBag					= "Baud Bag"
    BINDING_NAME_BaudBagToggleBank			= "Toggle Bank"

    BaudBag_DebugMsg("Bags", "OnLoad was called")

    -- init item lock info
    BaudBagFrame.ItemLock           = {}
    BaudBagFrame.ItemLock.Move      = false
    BaudBagFrame.ItemLock.IsReagent = false

    -- register for global events (actually handled in OnEvent function)
    for Key, Value in pairs(EventFuncs)do
        self:RegisterEvent(Key)
    end
    BaudBag_RegisterBankEvents(self)

    -- the first container from each set (inventory/bank) is different and is created in the XML
    local SubBag, Container
    for BagSet = 1, 2 do
        Container = _G[Prefix.."Container"..BagSet.."_1"]
        Container.FreeSlots:SetPoint("RIGHT",Container:GetName().."MoneyFrame","LEFT")
        Container.BagSet = BagSet
        Container:SetID(1)
    end

    BaudBag_DebugMsg("Bags", "Create BagSets")
    BackpackSet = AddOnTable:CreateBagSet(BagSetType.Backpack)
    BankSet = AddOnTable:CreateBagSet(BagSetType.Bank)

    -- create all necessary SubBags now with basic initialization, correct referencing later when config is available
    BaudBag_DebugMsg("Bags", "Creating sub bags")
    BackpackSet:PerformInitialBuild()
    BankSet:PerformInitialBuild()

    -- create tooltip for parsing exactly once!
    ItemToolTip = CreateFrame("GameTooltip", "BaudBagScanningTooltip", nil, "GameTooltipTemplate")
    ItemToolTip:SetOwner( WorldFrame, "ANCHOR_NONE" )

    -- now make sure all functions that are supposed to be part of the frame are hooked to the frame, now we know that it is there!
    for Key, Value in pairs(BBFrameFuncs) do
        BaudBagFrame[Key] = Value
    end
end


--[[ this will call the correct event handler]]--
function BaudBag_OnEvent(self, event, ...)
    BaudBag_OnBankEvent(self, event, ...)
    if EventFuncs[event] then
        EventFuncs[event](self, event, ...)
    end
end

-- this just makes sure the bags will be visible at the correct layer position when opened
function BaudBagBagsFrame_OnShow(self, event, ...)
    local isBags = self:GetName() == "BaudBagContainer1_1BagsFrame"
    local Level = self:GetFrameLevel() + 1
    BaudBag_DebugMsg("Bank", "BaudBagBagsFrame is shown, correcting frame layer lvls of childs (frame, targetLevel)", self:GetName(), Level)
    -- Adjust frame level because of Blizzard's screw up
    if (isBags) then
        local backpackSet = AddOnTable["Sets"][1]
        for Bag = 0, 3 do
            backpackSet.BagButtons[Bag].Frame:SetFrameLevel(Level)
        end
    else
        local bagSet = AddOnTable["Sets"][2]
        for Bag = 1, NUM_BANKBAGSLOTS do
            bagSet.BagButtons[Bag].Frame:SetFrameLevel(Level)
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
    BaudBag_DebugMsg("Bags", "BaudBagContainer_OnShow was called", self:GetName())
	
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
	
    -- If there are tokens watched then decide if we should show the bar
    -- [TAINT] can be problematic, but doesn't have to be
    if ( ManageBackpackTokenFrame ) then
        ManageBackpackTokenFrame()
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
        if (self.BagSet == 2) and BaudBagFrame.BankOpen then
            -- [TAINT] can be problematic, but doesn't have to be
            CloseBankFrame()
        end
        BaudBagCloseBagSet(self.BagSet)
    end

    self:Show()

    -- make sure the search field is closed (and therefor the items are update) before the bag is
    BaudBagSearchFrame_CheckClose(self)

    -- TODO: if the bag is closed and there is a search running clear the items inside the bag from the search marks!
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
    BaudBag_DebugMsg("Bags", "Updating joined bags...")
    
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
    BaudBag_DebugMsg("Bags", "[BaudBagUpdateOpenBagHighlight]")
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
    BaudBag_DebugMsg("BagOpening", "[AutoOpenSet Entry] (BagSet, Close)", BagSet, closeState)
    
    -- Set 2 doesn't need container 1 to be shown because that's a given
    local Container
    for ContNum = BagSet, NumCont[BagSet] do

        --[[ DEBUG ]]--
        local autoOpen = BBConfig[BagSet][ContNum].AutoOpen
        BaudBag_DebugMsg("BagOpening", "[AutoOpenSet FOR] (ContNum, AutoOpen)", ContNum, autoOpen)

        if autoOpen then
            Container = _G[Prefix.."Container"..BagSet.."_"..ContNum]
            if not Close then
                if not Container:IsShown() then
                    BaudBag_DebugMsg("BagOpening", "[AutoOpenSet FOR (IsShown)] FALSE")
                    Container.AutoOpened = true
                    Container:Show()
                else
                    BaudBag_DebugMsg("BagOpening", "[AutoOpenSet FOR (IsShown)] TRUE")
                end
                BaudBagUpdateContainer(Container)
            elseif Container.AutoOpened then
                BaudBag_DebugMsg("BagOpening", "[AutoOpenSet FOR (AutoOpened)] TRUE")
                Container.AutoOpened = false
                if BBConfig[BagSet][ContNum].AutoClose then
                    BaudBag_DebugMsg("BagOpening", "[AutoOpenSet FOR (AutoOpened)] AutoClose set, hiding!")
                    Container:Hide()
                else
                    BaudBag_DebugMsg("BagOpening", "[AutoOpenSet FOR (AutoOpened)] AutoClose not set, ignoring hide!")
                end
            else
                BaudBag_DebugMsg("BagOpening", "[AutoOpenSet FOR (AutoOpened)] FALSE")
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
    BaudBag_DebugMsg("BagOpening", "Got SubContainer", SubContainer)
    return SubContainer:IsOpen()
end

local function UpdateThisHighlight(self)
    if BBConfig and (BBConfig[1].Enabled == false) then
        return
    end
    self:SetChecked(IsBagShown(self:GetID() - CharacterBag0Slot:GetID() + 1))
end

--These function hooks override the bag button highlight changes that Blizzard does
hooksecurefunc("BagSlotButton_OnClick", UpdateThisHighlight)
hooksecurefunc("BagSlotButton_OnDrag", UpdateThisHighlight)
hooksecurefunc("BagSlotButton_OnModifiedClick", UpdateThisHighlight)
hooksecurefunc("BackpackButton_OnClick", function(self)
    if BBConfig and(BBConfig[1].Enabled == false)then
        return
    end
    self:SetChecked(IsBagShown(0))
end)

--[[ custom defined BaudBagSubBag event handlers ]]--
local SubBagEvents = {}

local Func = function(self, event, ...)
    -- only update if the lock is for this bag!
    local Bag = ...
    if (self:GetID() ~= Bag) then
        return
    end
    BaudBag_DebugMsg("ItemHandle", "Event ITEM_LOCK_CHANGED fired for subBag (ID)", self:GetID())
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
    if not self:GetParent():IsShown() or BaudBag_IsBankDefaultContainer(Bag) or (self:GetID() >= 5) and not BaudBagFrame.BankOpen then
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
    BaudBag_DebugMsg("Bags", "Called BaudBagUpdateBagFrames()")
    local Shown, BagFrame, FrameName
    for BagSet = 1, 2 do
        Shown = (BBConfig[BagSet].ShowBags ~= false)
        _G[Prefix.."Container"..BagSet.."_1BagsButton"]:SetChecked(Shown)
        BagFrame = _G[Prefix.."Container"..BagSet.."_1BagsFrame"]
        BaudBag_DebugMsg("Bags", "Updating (bagName, shown)", BagFrame:GetName(), Shown)
        if Shown then
            BagFrame:Show()
        else
            BagFrame:Hide()
        end
    end
end

--[[ DEPRECATED this WILL be moved to Container:Update()]]
function BaudBagUpdateContainer(Container)
    BaudBag_DebugMsg("Bags", "Updating Container (name)", Container:GetName())
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


hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", BaudBag_OnModifiedClick)
hooksecurefunc("BankFrameItemButtonGeneric_OnModifiedClick", BaudBag_OnModifiedClick)

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

--[[ if the mouse hovers over the bag slot item the slots belonging to this bag should be shown after a certain time (atm 350ms or 0.35s) ]]
function BaudBag_BagSlot_OnEnter(self, event, ...)
    BaudBag_DebugMsg("BagHover", "Mouse is hovering above item")
    self.HighlightBag		= true
    self.HighlightBagOn		= false
    self.HighlightBagCount	= GetTime() + 0.35
end

--[[ determine if and how long the mouse was hovering and change bag according ]]
function BaudBag_BagSlot_OnUpdate(self, event, ...)
    if (self.HighlightBag and (not self.HighlightBagOn) and GetTime() >= self.HighlightBagCount) then
        BaudBag_DebugMsg("BagHover", "showing item (itemName)", self:GetName())
        self.HighlightBagOn	= true
        AddOnTable["SubBags"][self.Bag]:SetSlotHighlighting(true)
    end
end

--[[ if the mouse was removed cancel all actions ]]
function BaudBag_BagSlot_OnLeave(self, event, ...)
    BaudBag_DebugMsg("BagHover", "Mouse not hovering above item anymore")
    self.HighlightBag		= false
	
    if (self.HighlightBagOn) then
        self.HighlightBagOn	= false
        AddOnTable["SubBags"][self.Bag]:SetSlotHighlighting(false)
    end
	
end

function BaudBag_ContainerFrameItemButton_OnClick(self, button)
    BaudBag_DebugMsg("ItemHandle", "OnClick called (button, bag)", button, self:GetParent():GetID())
    if (button ~= "LeftButton" and BaudBagFrame.BankOpen) then
        local itemId = GetContainerItemID(self:GetParent():GetID(), self:GetID())
        local isReagent = (itemId and BaudBagFrame.IsCraftingReagent(itemId))
        local sourceIsBank = BaudBag_IsBankContainer(self:GetParent():GetID())
        local targetReagentBank = IsReagentBankUnlocked() and isReagent
        
        BaudBag_DebugMsg("ItemHandle", "handling item (itemId, isReagent, targetReagentBank)", itemId, isReagent, targetReagentBank)

        -- remember to start a move operation when item was placed in bank by wow!
        if (targetReagentBank) then
            BaudBagFrame.ItemLock.Move      = true
            BaudBagFrame.ItemLock.IsReagent = true
        end
    end
end
