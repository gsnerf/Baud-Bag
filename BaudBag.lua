--[[ defining variables for the events ]]--
local AddOnName, AddOnTable = ...
local Localized = BaudBagLocalized;

local Prefix = "BaudBag";
local NumCont = {};
local FadeTime = 0.2;
local BagsReady;
local _;
local ItemToolTip;

_G[AddOnName] = AddOnTable;
AddOnTable["Sets"] = {}
AddOnTable["SubBags"] = {}
AddOnTable["Backgrounds"] = {}

local BBFrameFuncs = {
    IsCraftingReagent = function (itemId)
        ItemToolTip:SetItemByID(itemId);
        local isReagent = false;
        for i = 1, ItemToolTip:NumLines() do
            local text = _G["BaudBagScanningTooltipTextLeft"..i]:GetText();
            if (string.find(text, Localized.TooltipScanReagent)) then
                isReagent = true;
            end
        end
        return isReagent;
    end
};

--[[ Local helper methods used in event handling ]]
local function BackpackBagOverview_Initialize()
    -- prepare BagSlot creation
    local BagSlot, Texture;
    local BBContainer1 = _G[Prefix.."Container1_1BagsFrame"];

    -- create BagSlots for the bag overview in the inventory (frame that pops out and only shows the available bags)
    BaudBag_DebugMsg("Bags", "Creating bag slot buttons.");
    for Bag = 1, 4 do
        -- the slot name before "BagXSlot" has to be 10 chars long or else this will HARDCRASH
        BagSlot	= CreateFrame("CheckButton", "BaudBInveBag"..(Bag - 1).."Slot", BBContainer1, "BagSlotButtonTemplate");
        -- BagSlot:SetPoint("TOPLEFT", 8, -8 - (Bag - 1) * 39);
        BagSlot:SetPoint("TOPLEFT", 8, -8 - (Bag - 1) * 30);
        BagSlot:SetFrameStrata("HIGH");
        BagSlot.HighlightBag = false;
        BagSlot.Bag = Bag;
        BagSlot:HookScript("OnEnter",	BaudBag_BagSlot_OnEnter);
        BagSlot:HookScript("OnUpdate",	BaudBag_BagSlot_OnUpdate);
        BagSlot:HookScript("OnLeave",	BaudBag_BagSlot_OnLeave);
    end
    
    BBContainer1:SetWidth(15 + 30);
    BBContainer1:SetHeight(15 + 4 * 30);
end

--[[ NON XML EVENT HANDLERS ]]--
--[[ these are the custom defined BaudBagFrame event handlers attached to a single event type]]--

local EventFuncs =
    {
        ADDON_LOADED = function(self, event, ...)
            -- check if the event was loaded for this addon
            local arg1 = ...;
            if (arg1 ~= "BaudBag") then return end;

            BaudBag_DebugMsg("Bags", "Event ADDON_LOADED fired");

            -- make sure the cache is initialized
            --BBCache:initialize();
            BaudBagInitCache();
            AddOnTable:RegisterDefaultBackgrounds()

            -- the rest of the bank slots are cleared in the next event
            -- TODO: recheck why this is necessary and if it can be avoided
            BaudBagBankSlotPurchaseButton:Disable();
        end,

        PLAYER_LOGIN = function(self, event, ...)
            if (not BaudBag_DebugLog) then
                BaudBag_Debug = {};
            end
            BaudBag_DebugMsg("Bags", "Event PLAYER_LOGIN fired");
            

            BackpackBagOverview_Initialize()
            BaudBagUpdateFromBBConfig();
            BaudBagBankBags_Initialize();
            if BBConfig and (BBConfig[2].Enabled == true) then 
                BaudBag_DebugMsg("Bank", "BaudBag enabled for Bank, disable default bank event");
                BankFrame:UnregisterEvent("BANKFRAME_OPENED");
            end
        end,

        BANKFRAME_CLOSED = function(self, event, ...)
            BaudBag_DebugMsg("Bank", "Event BANKFRAME_CLOSED fired");
            BaudBagFrame.BankOpen = false;
            BaudBagBankSlotPurchaseButton:Disable();
            if _G[Prefix.."Container2_1"].AutoOpened then
                _G[Prefix.."Container2_1"]:Hide();
            else
                --Add offline again to bag name
                for ContNum = 1, NumCont[2]do
                    AddOnTable.Sets[2].Containers[ContNum]:UpdateName()
                end
            end
            BaudBagAutoOpenSet(1, true);
        end,

        PLAYER_MONEY = function(self, event, ...)
            BaudBag_DebugMsg("Bags", "Event PLAYER_MONEY fired");
            BaudBagBankBags_Update();
        end,

        ITEM_LOCK_CHANGED = function(self, event, ...)
            local Bag, Slot = ...;
            BaudBag_DebugMsg("ItemHandle", "Event ITEM_LOCK_CHANGED fired (bag, slot) ", Bag, Slot);
            if (Bag == BANK_CONTAINER) then
                if (Slot <= NUM_BANKGENERIC_SLOTS) then
                    BankFrameItemButton_UpdateLocked(_G[Prefix.."SubBag-1Item"..Slot]);
                else
                    BankFrameItemButton_UpdateLocked(_G["BaudBBankBag"..(Slot-NUM_BANKGENERIC_SLOTS)]);
                end
            elseif (Bag == REAGENTBANK_CONTAINER) then
                BankFrameItemButton_UpdateLocked(_G[Prefix.."SubBag-3Item"..Slot]);
            end

            if (Slot ~= nil) then
                local _, _, locked = GetContainerItemInfo(Bag, Slot);
                if ((not locked) and BaudBagFrame.ItemLock.Move) then
                    if (BaudBagFrame.ItemLock.IsReagent and (BaudBag_IsBankContainer(Bag)) and (Bag ~= REAGENTBANK_CONTAINER)) then
                        BaudBag_FixContainerClickForReagent(Bag, Slot);
                    end
                    BaudBagFrame.ItemLock.Move      = false;
                    BaudBagFrame.ItemLock.IsReagent = false;
                end
                BaudBag_DebugMsg("ItemHandle", "Updating ItemLock Info", BaudBagFrame.ItemLock);
            end
        end,

        ITEM_PUSH = function(self, event, ...)
            local BagID, Icon = ...;
            BaudBag_DebugMsg("ItemHandle", "Received new item", BagID);
            if (not BBConfig.ShowNewItems) then
                C_NewItems.ClearAll();
            end
        end,

        BAG_UPDATE_COOLDOWN = function(self, event, ...)
            local BagID = ...;
            BaudBag_DebugMsg("ItemHandle", "Item is on Cooldown after usage", BagID);
            BaudBagUpdateOpenBags();
        end,

        QUEST_ACCEPTED = function(self, event, ...)
            BaudBagUpdateOpenBags();
        end,
        QUEST_REMOVED = function(self, event, ...)
            BaudBagUpdateOpenBags();
        end
    };

--[[ here come functions that will be hooked up to multiple events ]]--
local Func = function(self, event, ...)
    BaudBag_DebugMsg("Bank", "Event fired", event)
    
	-- set bank open marker if it was opend
    if (event == "BANKFRAME_OPENED") then
        BaudBagFrame.BankOpen = true
    end
    
    -- everything coming now is only needed if the bank is visible
    local bankVisible = BBConfig[2].Enabled and (event == "BANKFRAME_OPENED")
    BaudBagBankBags_UpdateContent(bankVisible)
    if not bankVisible then
        return
    end
    BaudBagAutoOpenSet(1)
    BaudBagAutoOpenSet(2)
end
EventFuncs.BANKFRAME_OPENED = Func
EventFuncs.PLAYERBANKBAGSLOTS_CHANGED = Func

Func = function(self, event, ...)
    BaudBag_DebugMsg("Bags", "Event fired (event)", event);
    BaudBagAutoOpenSet(1, false);

    if (BBConfig.SellJunk and MerchantFrame:IsShown()) then
        BaudBagForEachBag(1,
            function(Bag, Index)
                for Slot = 1, GetContainerNumSlots(Bag) do
                    local quality = select(4, GetContainerItemInfo(Bag, Slot));
                    if (quality and quality <= 0) then
                        BaudBag_DebugMsg("Junk", "Found junk (Container, Slot)", Bag, Slot);
                        UseContainerItem(Bag, Slot);
                    end
                end
            end
        );
    end
end
EventFuncs.MERCHANT_SHOW = Func;

Func = function(self, event, ...)
    BaudBag_DebugMsg("Bags", "Event fired (event)", event);
    BaudBagAutoOpenSet(1, false);
end
EventFuncs.MAIL_SHOW = Func;
EventFuncs.AUCTION_HOUSE_SHOW = Func;

Func = function(self, event, ...)
    BaudBag_DebugMsg("Bags", "Event fired", event);
    BaudBagAutoOpenSet(1, true);
end
EventFuncs.MERCHANT_CLOSED = Func;
EventFuncs.MAIL_CLOSED = Func;
EventFuncs.AUCTION_HOUSE_CLOSED = Func;

Func = function(self, event, ...)
    BaudBag_DebugMsg("Bags", "Event fired (event, source)", event, self:GetName());
    local arg1 = ...;
    -- if there are new bank slots the whole view has to be updated
    if (event == "PLAYERBANKSLOTS_CHANGED") then
        -- bank bag slot
        if (arg1 > NUM_BANKGENERIC_SLOTS) then
            BankFrameItemButton_Update(_G["BaudBBankBag"..(arg1-NUM_BANKGENERIC_SLOTS)]);
            return;
        end

        -- if the main bank bag is visible make sure the content of the sub-bags is also shown  
        local BankBag = _G[Prefix.."SubBag-1"];
        if BankBag:GetParent():IsShown() then
            AddOnTable["SubBags"][-1]:UpdateSlotContents()
        end
        BankFrameItemButton_Update(_G[BankBag:GetName().."Item"..arg1]);
        BagSet = 2;
    else
        BagSet = BaudBag_IsInventory(arg1) and 1 or 2;
    end
    local Container = _G[Prefix.."Container"..BagSet.."_1"];
    if not Container:IsShown() then
        return;
    end
    Container.UpdateSlots = true;
end
EventFuncs.BAG_OPEN = Func;
EventFuncs.BAG_UPDATE = Func;
EventFuncs.BAG_CLOSED = Func;
EventFuncs.PLAYERBANKSLOTS_CHANGED = Func;

--[[ This updates the visual of the given reagent bank item ]]
Func = function(self, event, ...)
    local slot = ...;
    BaudBag_DebugMsg("BankReagent", "Updating Slot", slot);

    -- first basic update
    local Button = _G["BaudBagSubBag-3Item"..(slot)];
    BankFrameItemButton_Update(Button);

    ---- now update custom rarity colloring
    local bagCache = BaudBagGetBagCache(REAGENTBANK_CONTAINER);
    local Link = GetContainerItemLink(REAGENTBANK_CONTAINER, slot);
    local Quality = nil;

    -- even though we are in "online" there might be no item on this slot!
    if Link then
        _, _, Quality, _, _, _, _, _, _, _ = GetItemInfo(Link);
        --isNewItem       = C_NewItems.IsNewItem(REAGENTBANK_CONTAINER, slot);
        --isBattlePayItem = IsBattlePayItem(REAGENTBANK_CONTAINER, slot);
        bagCache[slot]  = {Link = Link, Count = select(2, GetContainerItemInfo(REAGENTBANK_CONTAINER, slot))};
    else
        bagCache[slot] = nil;
    end
    
    BaudBagItemButton_UpdateRarity(
        Button, 
        Quality, 
        BBConfig[2][_G["BaudBagSubBag-3"]:GetParent():GetID()].RarityColor
    );
end
EventFuncs.PLAYERREAGENTBANKSLOTS_CHANGED = Func;

Func = function(self, event, ...)
    _G["BaudBagSubBag-3"]:GetParent().UnlockInfo:Hide();
	_G["BaudBagSubBag-3"]:GetParent().DepositButton:Enable();
end
EventFuncs.REAGENTBANK_PURCHASED = Func;
--[[ END OF NON XML EVENT HANDLERS ]]--


--[[ xml defined (called) BaudBagFrame event handlers ]]--
function BaudBag_OnLoad(self, event, ...)
    BINDING_HEADER_BaudBag					= "Baud Bag";
    BINDING_NAME_BaudBagToggleBank			= "Toggle Bank";
    BINDING_NAME_BaudBagToggleVoidStorage	= "Show Void Storage";

    BaudBag_DebugMsg("Bags", "OnLoad was called");

    -- init item lock info
    BaudBagFrame.ItemLock           = {};
    BaudBagFrame.ItemLock.Move      = false;
    BaudBagFrame.ItemLock.IsReagent = false;

    -- register for global events (actually handled in OnEvent function)
    for Key, Value in pairs(EventFuncs)do
        self:RegisterEvent(Key);
    end

    -- the first container from each set (inventory/bank) is different and is created in the XML
    local SubBag, Container;
    for BagSet = 1, 2 do
        Container = _G[Prefix.."Container"..BagSet.."_1"];
        _G[Container:GetName().."Slots"]:SetPoint("RIGHT",Container:GetName().."MoneyFrame","LEFT");
        Container.BagSet = BagSet;
        Container:SetID(1);
    end

    BaudBag_DebugMsg("Bags", "Create BagSets")
    BackpackSet = AddOnTable:CreateBagSet(BagSetType.Backpack)
    BankSet = AddOnTable:CreateBagSet(BagSetType.Bank)

    -- create all necessary SubBags now with basic initialization, correct referencing later when config is available
    BaudBag_DebugMsg("Bags", "Creating sub bags")
    BackpackSet:PerformInitialBuild()
    BankSet:PerformInitialBuild()

    -- create tooltip for parsing exactly once!
    ItemToolTip = CreateFrame("GameTooltip", "BaudBagScanningTooltip", nil, "GameTooltipTemplate");
    ItemToolTip:SetOwner( WorldFrame, "ANCHOR_NONE" );

    -- now make sure all functions that are supposed to be part of the frame are hooked to the frame, now we know that it is there!
    for Key, Value in pairs(BBFrameFuncs) do
        BaudBagFrame[Key] = Value;
    end
end


--[[ this will call the correct event handler]]--
function BaudBag_OnEvent(self, event, ...)
    EventFuncs[event](self, event, ...);
end

-- this just makes sure the bags will be visible at the correct layer position when opened
function BaudBagBagsFrame_OnShow(self, event, ...)
    local isBags = self:GetName() == "BaudBagContainer1_1BagsFrame";
    local Level = self:GetFrameLevel() + 1;
    BaudBag_DebugMsg("Bank", "BaudBagBagsFrame is shown, correcting frame layer lvls of childs (frame, targetLevel)", self:GetName(), Level);
    -- Adjust frame level because of Blizzard's screw up
    if (isBags) then
        for Bag = 0, 3 do
            _G["BaudBInveBag"..Bag.."Slot"]:SetFrameLevel(Level);
        end
    else
        for Bag = 1, NUM_BANKBAGSLOTS do
            _G["BaudBBankBag"..Bag]:SetFrameLevel(Level);
        end
        _G["BBReagentsBag"]:SetFrameLevel(Level);
    end
end

--[[ Container events ]]--
function BaudBagContainer_OnLoad(self, event, ...)
    tinsert(UISpecialFrames, self:GetName()); -- <- needed?
    self:RegisterForDrag("LeftButton");
end

function BaudBagContainer_OnUpdate(self, event, ...)

    local containerObject = AddOnTable["Sets"][self.BagSet].Containers[self:GetID()]

    if (self.Refresh) then
        containerObject:Update()
        BaudBagUpdateOpenBagHighlight();
    end

    if (self.UpdateSlots) then
        BaudBagUpdateFreeSlots(self);
    end

    if (self.FadeStart) then
        local Alpha = (GetTime() - self.FadeStart) / FadeTime;
        if self.Closing then
            Alpha = 1 - Alpha;
            if (Alpha < 0) then
                self.FadeStart = nil;
                self:Hide();
                self.Closing = nil;
                return;
            end
        elseif (Alpha > 1)then
            self:SetAlpha(1);
            self.FadeStart = nil;
            return;
        end
        self:SetAlpha(Alpha);
    end
end


function BaudBagContainer_OnShow(self, event, ...)
    BaudBag_DebugMsg("Bags", "BaudBagContainer_OnShow was called", self:GetName());
	
    -- check if the container was open before and closing now
    if self.FadeStart then
        return;
    end
	
    -- container seems to not be visible, open and update
    self.FadeStart = GetTime();
    PlaySound(SOUNDKIT.IG_BACKPACK_OPEN);
    BaudBagUpdateContainer(self);
    BaudBagUpdateOpenBagHighlight();
    if (self:GetID() == 1) then
        BaudBagUpdateFreeSlots(self);
    end
	
    -- If there are tokens watched then decide if we should show the bar
    if ( ManageBackpackTokenFrame ) then
        ManageBackpackTokenFrame();
    end
end


function BaudBagContainer_OnHide(self, event, ...)
    -- correctly handle if this is called while the container is still fading out
    if self.Closing then
        if self.FadeStart then
            self:Show();
        end
        return;
    end

    -- set vars for fading out ans start process
    self.FadeStart = GetTime();
    self.Closing = true;
    PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE);
    self.AutoOpened = false;
    BaudBagUpdateOpenBagHighlight();

    --[[TODO: look into merging the set specific close handling!!!]]--
    --[[
    if the option entry requires it close all remaining containers of the bag set
    (first the bag set so the "offline" title doesn't show up before closing and then the bank to disconnect)
    ]]--
    if (self:GetID() == 1) and (BBConfig[self.BagSet].Enabled) and (BBConfig[self.BagSet].CloseAll) then
        if (self.BagSet == 2) and BaudBagFrame.BankOpen then
            CloseBankFrame();
        end
        BaudBagCloseBagSet(self.BagSet);
    end

    -- -- if first backpack container and option is set close whole bag set
    -- if (self.BagSet == 1) and (self:GetID() == 1) and (BBConfig[1].Enabled) and (BBConfig[1].CloseAll) then
    -- BaudBagCloseBagSet(1);
    -- end
    -- 
    -- -- if first bank container close whole bank set
    -- if (self.BagSet == 2) and (self:GetID() == 1) then
    -- if BaudBagFrame.BankOpen and (BBConfig[2].Enabled == true) then
    -- CloseBankFrame();
    -- end
    -- BaudBagCloseBagSet(2);
    -- end
    self:Show();

    -- make sure the search field is closed (and therefor the items are update) before the bag is
    BaudBagSearchFrame_CheckClose(self);

    -- TODO: if the bag is closed and there is a search running clear the items inside the bag from the search marks!
end


function BaudBagContainer_OnDragStart(self, event, ...)
    if not BBConfig[self.BagSet][self:GetID()].Locked then
        self:StartMoving();
    end
end


function BaudBagContainer_OnDragStop(self, event, ...)
    self:StopMovingOrSizing();
    AddOnTable["Sets"][self.BagSet].Containers[self:GetID()]:SaveCoordsToConfig()
end


local DropDownContainer, DropDownBagSet;

function BaudBagContainerDropDown_Show(self, event, ...)
    local Container = self:GetParent();
    DropDownContainer = Container:GetID();
    DropDownBagSet = Container.BagSet;
    ToggleDropDownMenu(1, nil, BaudBagContainerDropDown, self:GetName(), 0, 0);
end


function BaudBagContainerDropDown_OnLoad(self, event, ...)
    UIDropDownMenu_Initialize(self, BaudBagContainerDropDown_Initialize, "MENU");
end


local function ToggleContainerLock(self)
    BBConfig[DropDownBagSet][DropDownContainer].Locked = not BBConfig[DropDownBagSet][DropDownContainer].Locked;
end


local function ShowContainerOptions(self)
    BaudBagOptionsSelectContainer(DropDownBagSet, DropDownContainer);
    InterfaceOptionsFrame_OpenToCategory("Baud Bag");
end

--[[ 
    This initializes the drop down menus for each container.
    Beware that the bank box won't exist yet when this is initialized at first.
  ]]
function BaudBagContainerDropDown_Initialize()
    local header = { isTitle = true, notCheckable = true };
    local info = {  };
    
    -- category bag specifics
    header.text = Localized.MenuCatSpecific;
    UIDropDownMenu_AddButton(header);

    -- bag locking/unlocking
    info.text = not (DropDownBagSet and BBConfig[DropDownBagSet][DropDownContainer].Locked) and Localized.LockPosition or Localized.UnlockPosition;
    info.func = ToggleContainerLock;
    UIDropDownMenu_AddButton(info);

    -- cleanup button first regular
    if (DropDownBagSet == 1) then
        info.text = BAG_CLEANUP_BAGS;
        info.func = SortBags;
        UIDropDownMenu_AddButton(info);
    elseif (DropDownContainer and BaudBagFrame.BankOpen) then
        if(_G["BaudBagContainer"..DropDownBagSet.."_"..DropDownContainer].Bags[1]:GetID() == -3) then
            info.text = BAG_CLEANUP_REAGENT_BANK;
            info.func = SortReagentBankBags;
        else
            info.text = BAG_CLEANUP_BANK;
            info.func = SortBankBags;
        end
        UIDropDownMenu_AddButton(info);
    end


    -- category general
    header.text = Localized.MenuCatGeneral;
    UIDropDownMenu_AddButton(header);

    -- 'show bank' option
    -- we only want to show this option on the backpack when the bank is not currently shown
    if (DropDownBagSet ~= 2) and _G[Prefix.."Container2_1"] and not _G[Prefix.."Container2_1"]:IsShown()then
        info.text = Localized.ShowBank;
        info.func = BaudBagToggleBank;
        UIDropDownMenu_AddButton(info);
    end

    -- open the options
    info.text = Localized.Options;
    info.func = ShowContainerOptions;
    UIDropDownMenu_AddButton(info);

    -- increase backpack size
    local needToShow = not (IsAccountSecured() and GetContainerNumSlots(1) > BACKPACK_BASE_SIZE)
    if (needToShow) then
        info.text = BACKPACK_AUTHENTICATOR_INCREASE_SIZE
        info.func = BaudBag_AddSlotsClick
        UIDropDownMenu_AddButton(info)
    end
end

--[[ This function updates the parent containers for each bag, according to the options setup ]]--
function BaudUpdateJoinedBags()
    BaudBag_DebugMsg("Bags", "Updating joined bags...");
    
    for bagSet = 1, 2 do
        NumCont[bagSet] = AddOnTable["Sets"][bagSet]:RebuildContainers()
    end

    BagsReady = true;
end

function BaudBagUpdateOpenBags()
    local Open, Frame, Slot, ItemButton, QuestTexture;
    for _, subContainer in pairs(AddOnTable["SubBags"]) do
        subContainer:UpdateItemOverlays()
    end
end

--[[ Sets the highlight texture of bag slots indicating wether the contained bag is opened or not ]]--
function BaudBagUpdateOpenBagHighlight()
    BaudBag_DebugMsg("Bags", "[BaudBagUpdateOpenBagHighlight]");
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

--[[ backpack specific original functions ]]--
local pre_OpenBackpack = OpenBackpack;
OpenBackpack = function() 
    BaudBag_DebugMsg("BagOpening", "[OpenBackpack] called!");
    if (not BBConfig or not BBConfig[1].Enabled) then
        BaudBag_DebugMsg("BagOpening", "[OpenBackpack] somethings not right, sending to blizz-bags!");
        return pre_OpenBackpack();
    end

    OpenBag(0);
end

local pre_CloseBackpack = CloseBackpack;
CloseBackpack = function()
    BaudBag_DebugMsg("BagOpening", "[CloseBackpack] called!");
    if (not BBConfig or not BBConfig[1].Enabled) then
        BaudBag_DebugMsg("BagOpening", "[CloseBackpack] somethings not right, sending to blizz-bags!");
        return pre_CloseBackpack();
    end

    CloseBag(0);
end

local pre_ToggleBackpack = ToggleBackpack;
ToggleBackpack = function()
    BaudBag_DebugMsg("BagOpening", "[ToggleBackpack] called");
    -- make sure original is called when BaudBag is disabled for the backpack
    if (not BBConfig or not BBConfig[1].Enabled) then
        BaudBag_DebugMsg("BagOpening", "[ToggleBackpack] BaudBag disabled for inventory calling original UI");
        return pre_ToggleBackpack();
    end
	
    if not BagsReady then
        return;
    end
	
    ToggleBag(0);
end


-- save the original ToggleBag function before overwriting with own
local pre_ToggleBag = ToggleBag;
ToggleBag = function(id)
    -- decide if the current bag needs to be opened by baudbag or blizzard
    if (id > 4) then
        if BBConfig and (BBConfig[2].Enabled == false) then
            return pre_ToggleBag(id);
        end
        if not BagsReady then
            return;
        end
        --The close button thing allows the original blizzard bags to be closed if they're still open
    elseif (BBConfig[1].Enabled == false) then-- or self and (strsub(self:GetName(),-11) == "CloseButton") then
        return pre_ToggleBag(id);
        end

    BaudBag_DebugMsg("BagOpening", "[ToggleBag] toggeling bag (ID)", id);
	
    --Blizzard's stuff will automaticaly try open the bags at the mailbox and vendor.  Baud Bag will be in charge of that.
    -- BaudBag_DebugMsg("Bags", "[ToggleBag] self: "..self:GetName());
    -- if not BagsReady or (self == MailFrame) or (self == MerchantFrame) then
    -- return;
    -- end

    local Container = _G[Prefix.."SubBag"..id];
    if not Container then
        return pre_ToggleBag(id);
    end
    Container = Container:GetParent();

    --if the bag to open is inside the main bank container, don't toggle it
    -- if self and ((Container == _G[Prefix.."Container2_1"]) and (strsub(self:GetName(),1,9) == "BaudBBank") or
    -- (Container == _G[Prefix.."Container1_1"]) and ((strsub(self:GetName(),1,9)== "BaudBInve") or (self == BaudBagKeyRingButton))) then
    -- return;
    -- end

    if Container:IsShown() then
        BaudBag_DebugMsg("BagOpening", "[ToggleBag] container open, closing (name)", Container:GetName());
        Container:Hide();
        -- Hide the token bar if closing the backpack
        if ( id == 0 and BackpackTokenFrame ) then
            BackpackTokenFrame:Hide();
        end
    else
        BaudBag_DebugMsg("BagOpening", "[ToggleBag] container closed, opening (name)", Container:GetName());
        Container:Show();
        -- If there are tokens watched then show the bar
        if ( id == 0 and ManageBackpackTokenFrame ) then
            BackpackTokenFrame_Update();
            ManageBackpackTokenFrame();
        end
    end
end


local pre_OpenAllBags = OpenAllBags;
OpenAllBags = function(frame)
    BaudBag_DebugMsg("BagOpening", "[OpenAllBags] called from (frame)", ((frame ~= nil) and frame:GetName() or "[none]"));
    
    -- call default bags if the addon is disabled for regular bags
    if (not BBConfig or not BBConfig[1].Enabled) then
        BaudBag_DebugMsg("BagOpening", "[OpenAllBags] sent to original frames");
        return pre_OpenAllBags(frame);
    end

    -- also cancel if bags can't be viewed at the moment (CAN this actually happen?)
    if not BagsReady then
        BaudBag_DebugMsg("BagOpening", "[OpenAllBags] bags not ready");
        return;
    end

    -- failsafe check as opening mail or merchant seems to instantly call OpenAllBags instead of the bags registering for the events...
    if (frame ~= nil and (frame:GetName() == "MailFrame" or frame:GetName() == "MerchantFrame")) then
        BaudBag_DebugMsg("BagOpening", "[OpenAllBags] found merchant or mail call, stopping now!");
        return;
    end

    local Container, AnyShown;
    for Bag = 0, 4 do
        BaudBag_DebugMsg("BagOpening", "[OpenAllBags] analyzing bag (ID)", Bag);
        Container = _G[Prefix.."SubBag"..Bag]:GetParent();
        if (GetContainerNumSlots(Bag) > 0) and not Container:IsShown()then
            BaudBag_DebugMsg("BagOpening", "[OpenAllBags] showing bag");
            Container:Show();
            --            AnyShown = true;
        end
    end

    -- if not AnyShown then
    -- BaudBag_DebugMsg("Bags", "[OpenAllBags] nothing opened => all opened, closing...");
    -- BaudBagCloseBagSet(1);
    -- end
end

local pre_CloseAllBags = CloseAllBags;
CloseAllBags = function(frame)
    BaudBag_DebugMsg("BagOpening", "[CloseAllBags] (sourceName)", ((frame ~= nil) and frame:GetName() or "[none]"));

    -- failsafe check as opening mail or merchant seems to instantly call OpenAllBags instead of the bags registering for the events...
    if (frame ~= nil and (frame:GetName() == "MailFrame" or frame:GetName() == "MerchantFrame")) then
        BaudBag_DebugMsg("BagOpening", "[CloseAllBags] found merchant or mail call, stopping now!");
        return;
    end

    for Bag = 0, 4 do
        BaudBag_DebugMsg("BagOpening", "[CloseAllBags] analyzing bag (id)", Bag);
        local Container = _G[Prefix.."SubBag"..Bag]:GetParent();
        if (GetContainerNumSlots(Bag) > 0) and Container:IsShown()then
            BaudBag_DebugMsg("BagOpening", "[CloseAllBags] hiding  bag");
            Container:Hide();
        end
    end
end

local pre_BagSlotButton_OnClick = BagSlotButton_OnClick;
BagSlotButton_OnClick = function(self, event, ...)

    if (not BBConfig or not BBConfig[1].Enabled) then
        return pre_BagSlotButton_OnClick(self, event, ...);
    end

    if not PutItemInBag(self:GetID()) then
        ToggleBag(self:GetID() - CharacterBag0Slot:GetID() + 1);
    end

end
 
local function IsBagShown(BagId)
    local SubContainer = AddOnTable["SubBags"][BagId]
    BaudBag_DebugMsg("BagOpening", "Got SubContainer", SubContainer)
    return SubContainer:IsOpen()
end

local pre_IsBagOpen = IsBagOpen
-- IsBagOpen = function(BagID)
function BaudBag_IsBagOpen(BagId)
    -- fallback
    if (not BBConfig or not BaudBag_BagHandledByBaudBag(BagId)) then
        BaudBag_DebugMsg("BagOpening", "BaudBag is not responsible for this bag, calling default ui")
        return pre_IsBagOpen(BagId)
    end
    
    local open = IsBagShown(BagId)
    BaudBag_DebugMsg("BagOpening", "[IsBagOpen] (BagId, open)", BagId, open)
    return open
end

-- hooksecurefunc("IsBagOpen", BaudBag_IsBagOpen);


local function UpdateThisHighlight(self)
    if BBConfig and (BBConfig[1].Enabled == false) then
        return;
    end
    self:SetChecked(IsBagShown(self:GetID() - CharacterBag0Slot:GetID() + 1));
end

--These function hooks override the bag button highlight changes that Blizzard does
hooksecurefunc("BagSlotButton_OnClick", UpdateThisHighlight);
hooksecurefunc("BagSlotButton_OnDrag", UpdateThisHighlight);
hooksecurefunc("BagSlotButton_OnModifiedClick", UpdateThisHighlight);
hooksecurefunc("BackpackButton_OnClick", function(self)
    if BBConfig and(BBConfig[1].Enabled == false)then
        return;
    end
    self:SetChecked(IsBagShown(0));
end);

--self is hooked to be able to replace the original bank box with this one
local pre_BankFrame_OnEvent = BankFrame_OnEvent;
BankFrame_OnEvent = function(self, event, ...)
    if BBConfig and(BBConfig[2].Enabled == false)then
        return pre_BankFrame_OnEvent(self, event, ...);
    end
end

--[[ custom defined BaudBagSubBag event handlers ]]--
local SubBagEvents = {
    BAG_UPDATE = function(self, event, ...)
        -- only update if this bag needs to be updated
        local arg1 = ...;
        if (self:GetID() ~= arg1) then
            return;
        end

        -- BAG_UPDATE is the only event called when a bag is added, so if no bag existed before, refresh
        if (self.size > 0) then
            BaudBag_DebugMsg("Bags", "Event BAG_UPDATE fired, calling ContainerFrame_Update (BagID)", arg1);
            ContainerFrame_Update(self);
            AddOnTable["SubBags"][self:GetID()]:UpdateSlotContents()
        else
            BaudBag_DebugMsg("Bags", "Event BAG_UPDATE fired, refreshing (BagID)", arg1);
            self:GetParent().Refresh = true;
        end
    end,

    BAG_CLOSED = function(self, event, ...)
        local arg1 = ...;
        if (self:GetID() ~= arg1) then
            return;
        end
        -- self event occurs when bags are swapped too, but updated information is not immediately
        -- available to the addon, so the bag must be updated later.
        BaudBag_DebugMsg("Bags", "Event BAG_CLOSED fired, refreshing (BagID)", arg1);
        self:GetParent().Refresh = true;
    end
};

local Func = function(self, event, ...)
    -- only update if the lock is for this bag!
    local Bag = ...;
    if (self:GetID() ~= Bag) then
        return;
    end
    BaudBag_DebugMsg("ItemHandle", "Event ITEM_LOCK_CHANGED fired for subBag (ID)", self:GetID());
    ContainerFrame_Update(self, event, ...);
end
SubBagEvents.ITEM_LOCK_CHANGED = Func;
SubBagEvents.BAG_UPDATE_COOLDOWN = Func;
SubBagEvents.UPDATE_INVENTORY_ALERTS = Func;

--[[ xml defined (called) BaudBagSubBag event handlers ]]--
function BaudBagSubBag_OnLoad(self, event, ...)
    if BaudBag_IsBankDefaultContainer(self:GetID()) then
        return
    end

    for Key, Value in pairs(SubBagEvents)do
        self:RegisterEvent(Key);
    end
end

function AddOnTable:ItemSlot_Created(bagId, slotId, button)
    -- just an empty hook for other addons
end

function AddOnTable:ItemSlot_Updated(bagId, slotId, button)
    -- just an empty hook for other addons
end

--[[ Updates the rarity for the given button on basis of the given quality and configuration options ]]
--[[ DEPRECATED!!! Goes to ItemButton ]]
function BaudBagItemButton_UpdateRarity(button, quality, showColor)
    -- add rarity coloring
    local Texture = _G[button:GetName().."Border"];
    if quality and (quality > 1) and showColor then
        -- default with set option
        -- Texture:SetVertexColor(GetItemQualityColor(Quality));
        -- alternative rarity coloring
        if (quality ~=2) and (quality ~= 3) and (quality ~= 4) then
            Texture:SetVertexColor(GetItemQualityColor(quality));
        elseif (quality == 2) then        --uncommon
            Texture:SetVertexColor(0.1,   1,   0, 0.5);
        elseif (quality == 3) then        --rare
            Texture:SetVertexColor(  0, 0.4, 0.8, 0.8);
        elseif (quality == 4) then        --epic
            Texture:SetVertexColor(0.6, 0.2, 0.9, 0.5);
        end
        Texture:Show();
    else
        Texture:Hide();
    end
end


function BaudBagSubBag_OnEvent(self, event, ...)
    if not self:GetParent():IsShown() or BaudBag_IsBankDefaultContainer(Bag) or (self:GetID() >= 5) and not BaudBagFrame.BankOpen then
        return;
    end
    SubBagEvents[event](self, event, ...);
end

-- DEPRECATED: move to BagSet!
function BaudBagUpdateFreeSlots(Frame)
    Frame.UpdateSlots = nil;
    local free, overall = AddOnTable["Sets"][Frame.BagSet]:GetSlotInfo()
    _G[Frame:GetName().."Slots"]:SetText(free.."/"..overall..Localized.Free)
end

--This is for the button that toggles the bank bag display
function BaudBagBagsButton_OnClick(self, event, ...)
    local Set = self:GetParent().BagSet;
    --Bank set is automaticaly shown, and main bags are not
    BBConfig[Set].ShowBags = (BBConfig[Set].ShowBags==false);
    BaudBagUpdateBagFrames();
end


function BaudBagUpdateBagFrames()
    BaudBag_DebugMsg("Bags", "Called BaudBagUpdateBagFrames()");
    local Shown, BagFrame, FrameName;
    for BagSet = 1, 2 do
        Shown = (BBConfig[BagSet].ShowBags ~= false);
        _G[Prefix.."Container"..BagSet.."_1BagsButton"]:SetChecked(Shown);
        BagFrame = _G[Prefix.."Container"..BagSet.."_1BagsFrame"];
        BaudBag_DebugMsg("Bags", "Updating (bagName, shown)", BagFrame:GetName(), Shown);
        if Shown then
            BagFrame:Show();
        else
            BagFrame:Hide();
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
    if (not BaudBagUseCache(self:GetParent():GetID())) then
        return;
    end

    if IsModifiedClick("SPLITSTACK")then
        StackSplitFrame:Hide();
    end

    local slotCache = BaudBagGetBagCache(self:GetParent():GetID())[self:GetID()];
    if slotCache then
        HandleModifiedItemClick(slotCache.Link);
    end
end


hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", BaudBag_OnModifiedClick);
hooksecurefunc("BankFrameItemButtonGeneric_OnModifiedClick", BaudBag_OnModifiedClick);

-- TODO: after changes there is some weird behavior after applying changes (like changing the name)
-- Seems to be in Background drawing for Slot Count
function BaudBagUpdateFromBBConfig()
    BaudUpdateJoinedBags();
    BaudBagUpdateBagFrames();
	
    for BagSet = 1, 2 do
        -- make sure the enabled states are current
        if (BBConfig[BagSet].Enabled ~= true) then
            BaudBagCloseBagSet(BagSet);
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
    BaudBag_DebugMsg("BagHover", "Mouse is hovering above item");
    self.HighlightBag		= true;
    self.HighlightBagOn		= false;
    self.HighlightBagCount	= GetTime() + 0.35;
end

--[[ determine if and how long the mouse was hovering and change bag according ]]
function BaudBag_BagSlot_OnUpdate(self, event, ...)
    if (self.HighlightBag and (not self.HighlightBagOn) and GetTime() >= self.HighlightBagCount) then
        BaudBag_DebugMsg("BagHover", "showing item (itemName)", self:GetName());
        self.HighlightBagOn	= true;
        AddOnTable["SubBags"][self.Bag]:SetSlotHighlighting(true)
    end
end

--[[ if the mouse was removed cancel all actions ]]
function BaudBag_BagSlot_OnLeave(self, event, ...)
    BaudBag_DebugMsg("BagHover", "Mouse not hovering above item anymore");
    self.HighlightBag		= false;
	
    if (self.HighlightBagOn) then
        self.HighlightBagOn	= false;
        AddOnTable["SubBags"][self.Bag]:SetSlotHighlighting(false)
    end
	
end

-- TODO: this HAS to stay temporary! the whole addon needs an overhaul according to the recent changes in the official bag code!!!

--[[ this usually only applies to inventory bags ]]--
local pre_ToggleAllBags = ToggleAllBags;
ToggleAllBags = function()
    BaudBag_DebugMsg("BagOpening", "[ToggleAllBags] called");

    if (not BBConfig or not BBConfig[1].Enabled) then
        BaudBag_DebugMsg("BagOpening", "[ToggleAllBags] no config found or addon deactivated for inventory, calling original");
        return pre_ToggleAllBags();
    end

    BaudBag_DebugMsg("BagOpening", "[ToggleAllBags] BaudBag bags are active, close & open");

    local bagsOpen = 0;
    local totalBags = 0;
    
    -- first make sure all bags are closed
    for i=0, NUM_BAG_FRAMES, 1 do
        if ( GetContainerNumSlots(i) > 0 ) then     
            totalBags = totalBags + 1;
        end
        if ( BaudBag_IsBagOpen(i) ) then
            --CloseBag(i);
            bagsOpen = bagsOpen +1;
        end
    end

    -- now correctly open all of them
    if (bagsOpen < totalBags) then
        for i=0, NUM_BAG_FRAMES, 1 do
            OpenBag(i);
        end
    else
        for i=0, NUM_BAG_FRAMES, 1 do
            CloseBag(i);
        end
    end
end

local pre_OpenBag = OpenBag;
OpenBag = function(id)
    BaudBag_DebugMsg("BagOpening", "[OpenBag] called on bag (id)", id);
	
    -- if there is no baud bag config we most likely do not work correctly => send to original bag frames
    if (not BBConfig or not BaudBag_BagHandledByBaudBag(id)) then
        BaudBag_DebugMsg("BagOpening", "[OpenBag] no config or bag not handled by BaudBag, calling original");
        return pre_OpenBag(id);
    end

    -- if (not IsBagOpen(id)) then
    if (not BaudBag_IsBagOpen(id)) then
        local Container = _G[Prefix.."SubBag"..id]:GetParent();
        Container:Show();
    end
end

local pre_CloseBag = CloseBag;
CloseBag = function(id)
    BaudBag_DebugMsg("BagOpening", "[CloseBag] called on bag (id)", id);
    if (not BBConfig or not BaudBag_BagHandledByBaudBag(id)) then
        BaudBag_DebugMsg("BagOpening", "[CloseBag] no config or bag not handled by BaudBag, calling original");
        return pre_CloseBag(id);
    end

    -- if (IsBagOpen(id)) then
    if (BaudBag_IsBagOpen(id)) then
        local Container = _G[Prefix.."SubBag"..id]:GetParent();
        Container:Hide();
    end
end

function BaudBag_ContainerFrameItemButton_OnClick(self, button)
    BaudBag_DebugMsg("ItemHandle", "OnClick called (button, bag)", button, self:GetParent():GetID());
    if (button ~= "LeftButton" and BaudBagFrame.BankOpen) then
        local itemId = GetContainerItemID(self:GetParent():GetID(), self:GetID());
        local isReagent = (itemId and BaudBagFrame.IsCraftingReagent(itemId));
        local sourceIsBank = BaudBag_IsBankContainer(self:GetParent():GetID());
        local targetReagentBank = IsReagentBankUnlocked() and isReagent;
        
        BaudBag_DebugMsg("ItemHandle", "handling item (itemId, isReagent, targetReagentBank)", itemId, isReagent, targetReagentBank);

        -- remember to start a move operation when item was placed in bank by wow!
        if (targetReagentBank) then
            BaudBagFrame.ItemLock.Move      = true;
            BaudBagFrame.ItemLock.IsReagent = true;
        end
    end
end

function BaudBag_FixContainerClickForReagent(Bag, Slot)
    -- determine if there is another item with the same item in the reagent bank
    local _, count, _, _, _, _, link = GetContainerItemInfo(Bag, Slot);
    local maxSize = select(8, GetItemInfo(link));
    local targetSlots = {};
    local emptySlots = GetContainerFreeSlots(REAGENTBANK_CONTAINER);
    for i = 1, GetContainerNumSlots(REAGENTBANK_CONTAINER) do
        local _, targetCount, _, _, _, _, targbcetLink = GetContainerItemInfo(REAGENTBANK_CONTAINER, i);
        if (link == targetLink) then
            local target    = {};
            target.count    = targetCount;
            target.slot     = i;
            table.insert(targetSlots, target);
        end
    end

    BaudBag_DebugMsg("ItemHandle", "fixing reagent bank entry (Bag, Slot, targetSlots, emptySlots)", Bag, Slot, targetSlots, emptySlots);

    -- if there already is a stack of the same item try to join the stacks
    for Key, Value in pairs(targetSlots) do
        BaudBag_DebugMsg("ItemHandle", "there already seem to be items of the same type in the reagent bank", Value);
        
        -- only do something if there are still items to put somewhere (split)
        if (count > 0) then
            -- determine if there is enough space to put everything inside
            local space = maxSize - Value.count;
            BaudBag_DebugMsg("ItemHandle", "The current stack has this amount of (space)", space);
            if (space > 0) then
                if (space < count) then
                    -- doesn't seem so, split and go on
                    SplitContainerItem(Bag, Slot, space);
                    PickupContainerItem(REAGENTBANK_CONTAINER, Value.slot);
                    count = count - space;
                else
                    -- seems so: put everything there
                    PickupContainerItem(Bag, Slot);
                    PickupContainerItem(REAGENTBANK_CONTAINER, Value.slot);
                    count = 0;
                end
            end
        end
    end

    BaudBag_DebugMsg("ItemHandle", "joining complete (leftItemCount)", count);
    
    -- either join didn't work or there's just something left over, we now put the rest in the first empty slot
    if (count > 0) then
        for Key, Value in pairs(emptySlots) do
            BaudBag_DebugMsg("ItemHandle", "putting rest stack into reagent bank slot (restStack)", Value);
            PickupContainerItem(Bag, Slot);
            PickupContainerItem(REAGENTBANK_CONTAINER, Value);
            return;
        end
    end
end

-- new backpack slots stuff
function BaudBag_AddSlotsClick()
    StaticPopup_Show("BACKPACK_INCREASE_SIZE")
    ContainerFrame_SetBackpackForceExtended(true)
end