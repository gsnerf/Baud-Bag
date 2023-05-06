local _
local AddOnName, AddOnTable = ...

AddOnTable.Functions = {}
AddOnTable.State = {
    -- switches, intended for differentiation of functions between addon versions (classic/retail, etc.)
    ReagentBankSupported = false,
    -- runtime state
    ItemLock = {
        Move = false,
        IsReagent = false
    },
    BankOpen = false
}

local ItemToolTip

local BaudBag_DebugCfg = {
    
    -- everything that has to do with configuration or configuring
    Config      = { Name = "Config",    Active = false },
    Options     = { Name = "Options",   Active = false },
    Functions   = { Name = "Functions", Active = false },

    -- bags including creation, rendering, opening and special functions
    Bags           = { Name = "Bags",               Active = false },
    BagCreation    = { Name = "Bag Creation",       Active = false },
    BagHover       = { Name = "Bag Hover",          Active = false },
    BagOpening     = { Name = "Bag Opening",        Active = false },
    BagTrigger     = { Name = "Bag Trigger",        Active = false },
    BagBackgrounds = { Name = "Bag Backgrounds",    Active = false },
    Container      = { Name = "Container",          Active = false },
    MenuDropDown   = { Name = "Menu DropDown",      Active = false },
	
    -- everything that has to do with offline capabilities
    Cache       = { Name = "Cache",         Active = false },
    Bank        = { Name = "Bank",          Active = false },
    BankReagent = { Name = "Reagent Bank",  Active = false },
    VoidStorage = { Name = "Void Storage",  Active = false },

    -- additional functionality
    Token       = { Name = "Token",     Active = false },
    Search      = { Name = "Search",    Active = false },
    Tooltip     = { Name = "Tooltip",   Active = false },
    Junk        = { Name = "Junk",      Active = false },
    ItemHandle  = { Name = "Item",      Active = false },

    -- this is for everything else that is supposed to be a temporary debug message
    Temp        = { Name = "Temp",      Active = false }
};

-- make sure to delete log from last session!
BaudBag_DebugLog = false;
BaudBag_Debug = {};


AddOnTable.Functions.DebugMessage = function(type, msg, ...)
    if (BaudBag_DebugCfg[type].Active) then
        DEFAULT_CHAT_FRAME:AddMessage(GetTime().." BaudBag ("..BaudBag_DebugCfg[type].Name.."): "..msg);
        if (... ~= nil) then
            for n=1,select('#',...) do
                local dumpValue = select(n,...)
                AddOnTable.Functions.Vardump(dumpValue)
            end
        end
    end
    if (BaudBag_DebugLog) then
        table.insert(BaudBag_Debug, GetTime().." BaudBag ("..BaudBag_DebugCfg[type].Name.."): "..msg);
    end
end

local function BaudBag_Vardump(value, depth, key)
    local linePrefix = "";
    local spaces = "";

    if key ~= nil then
        linePrefix = "["..key.."] = ";
    end

    if depth == nil then
        depth = 0;
    else
        depth = depth + 1;
        for i=1, depth do
            spaces = spaces .. "  ";
        end
    end

    if type(value) == 'table' then
        local mTable = getmetatable(value);
        if mTable == nil then
            DEFAULT_CHAT_FRAME:AddMessage(GetTime().." BaudBag (vardump): "..spaces..linePrefix.."(table) ");
        else
            DEFAULT_CHAT_FRAME:AddMessage(GetTime().." BaudBag (vardump): "..spaces.."(metatable) ");
            value = mTable;
        end
        for tableKey, tableValue in pairs(value) do
            BaudBag_Vardump(tableValue, depth, tableKey);
        end
    elseif (type(value) == 'function' or type(value) == 'thread' or type(value) == 'userdata' or value == nil) then
        DEFAULT_CHAT_FRAME:AddMessage(GetTime().." BaudBag (vardump): "..spaces..linePrefix..tostring(value));
    else
        DEFAULT_CHAT_FRAME:AddMessage(GetTime().." BaudBag (vardump): "..spaces..linePrefix.."("..type(value)..") "..tostring(value));
    end
end
AddOnTable.Functions.Vardump = BaudBag_Vardump


--[[
    This function takes a set of bags and a function, and then applies the function to each bag of the set.
        The function gets the parameters: 1. Bag, 2. Index
            ]]
--[[ TODO: Before we can get rid of this (in favor of BagSet:ForEachBag) we need to ensure that the bag sets are available everywhere (looking at you, config!) ]]
AddOnTable.Functions.ForEachBag = function(BagSet, Func)
    --[[
        BagsSet Indices:
            1 == inventory
            2 == bank
        Bag Indices:
           -3 == reagent bank
           -2 == keyring & currency
           -1 == bank
            0 == backpack
            1-4 == inventory bags
            5 == reagent bag
            6-12 == bank bags
    ]]--
    if (BagSet == 1) then -- regular bags
        for Bag = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
            Func(Bag, Bag + 1);
        end
    else -- bank
        Func(-1, 1);
        -- bank bags
        for Bag = 1, AddOnTable.BlizzConstants.BANK_CONTAINER_NUM do
            Func(Bag + AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER, Bag + 1);
        end
        -- reagent bank
        if (AddOnTable.State.ReagentBankSupported) then
            Func(-3, AddOnTable.BlizzConstants.BANK_CONTAINER_NUM + 2);
        end
    end
end

AddOnTable.Functions.ForEachContainer = function(func)
    for setId, set in pairs(AddOnTable.Sets) do
        for containerId, container in pairs(set.Containers) do
            func(setId, containerId, container)
        end
    end
end

local function BaudBagForEachOpenContainer(Func)
    for _, set in pairs(AddOnTable.Sets) do
        for _, container in pairs(set.Containers) do
            if (container.Frame:IsShown()) then
                Func(container)
            end
        end
    end
end
AddOnTable.Functions.ForEachOpenContainer = BaudBagForEachOpenContainer


local function BaudBagCopyTable(Value)
    -- end of possible recursion
    if (type(Value) ~= "table") then
        return Value;
    end
    -- create target table
    local Table = {};
    -- copy all entries of the source table
    table.foreach(Value, function(k,v) Table[k] = BaudBagCopyTable(v) end);
    return Table;
end
AddOnTable.Functions.CopyTable = BaudBagCopyTable


AddOnTable.Functions.ShowLinkTooltip = function(self, link)
    -- update positioning
    if (self:GetRight() >= (GetScreenWidth() / 2)) then
        GameTooltip:SetAnchorType("ANCHOR_LEFT")
    else
        GameTooltip:SetAnchorType("ANCHOR_RIGHT")
    end

    -- try to  update tooltip
    if ( LinkUtil.IsLinkType(link, "item") ) then
        AddOnTable.Functions.DebugMessage("Tooltip", "calling SetHyperlink with "..link)
        GameTooltip:SetHyperlink(link)
    elseif (LinkUtil.IsLinkType(link, "battlepet")) then
        AddOnTable.Functions.DebugMessage("Tooltip", "calling BattlePetToolTip_ShowLink with "..link)
        BattlePetToolTip_ShowLink(link)
    else
        return false
    end
    return true
end

local function BaudBag_InitTexturePiece(Texture, File, Width, Height, MinX, MaxX, MinY, MaxY, Layer)
    Texture:ClearAllPoints();
    -- Texture:SetTexture(1.0, 0, 0, 1);
    Texture:SetTexture(File);
    Texture:SetTexCoord(MinX / Width, (MaxX + 1) / Width, MinY / Height, (MaxY + 1) / Height);
    Texture:SetWidth(MaxX - MinX + 1);
    Texture:SetHeight(MaxY - MinY + 1);
    Texture:SetDrawLayer(Layer);
    Texture:Show();
end
AddOnTable.Functions.InitTexturePiece = BaudBag_InitTexturePiece

--[[ this function determines if the given bag is currently handled by baudbag or not ]]--
local function BaudBag_BagHandledByBaudBag(id)
    --[[
        BagsSet Indices:
            1 == inventory
            2 == bank
        Bag Indices:
           -3 == reagent bank
           -2 == keyring & currency
           -1 == bank
            0 == backpack
            1-5 == inventory bags
            6-12 == bank bags

        As the given indices > 0 may vary in the future use these constants instead:
            NUM_BAG_FRAMES (for max inventory bags)
            NUM_TOTAL_EQUIPPED_BAG_SLOTS (first bank bag)
            NUM_BANKBAGSLOTS (number of bank bags)
      ]]
    return (AddOnTable.Functions.IsBankContainer(id) and BBConfig[2].Enabled) or (AddOnTable.Functions.IsInventory(id) and BBConfig[1].Enabled);
end
AddOnTable.Functions.BagHandledByBaudBag = BaudBag_BagHandledByBaudBag

--[[
    These Bag IDs belong to the bank container:
       -3    == REAGENTBANK_CONTAINER
       -1    == BANK_CONTAINER
        6-12 == bank bags
    As the IDs might change we use blizzards own constants instead. Nevertheless we expect:
        1. the special bank containers to stand on their own
        2. the rest bank
  ]]
local function BaudBag_IsBankContainer(bagId)
    return AddOnTable.Functions.IsDefaultContainer(bagId) or (AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER <= bagId and bagId <= AddOnTable.BlizzConstants.BANK_LAST_CONTAINER);
end
AddOnTable.Functions.IsBankContainer = BaudBag_IsBankContainer

--[[
    These are the bank containers that need a special treatment in contrast to "regular" bags:
        -3 == REAGENTBANK_CONTAINER
        -1 == BANK_CONTAINER
  ]]
local function BaudBag_IsBankDefaultContainer(bagId)
    -- replacing REAGENTBANK_CONTAINER constant with it's value (-3) as we aren't sure that this code is run on retail
    local ReagentBankContainer = -3
    return (bagId == AddOnTable.BlizzConstants.BANK_CONTAINER or bagId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER);
end
AddOnTable.Functions.IsDefaultContainer = BaudBag_IsBankDefaultContainer

--[[
    These IDs belong to the inventory containers:
        0   == BACKPACK_CONTAINER
        1-5 == regular bags defined by blizz constants
  ]]
local function BaudBag_IsInventory(bagId)
    return (AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER <= bagId and bagId <= AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER);
end
AddOnTable.Functions.IsInventory = BaudBag_IsInventory

AddOnTable.Functions.InitFunctions = function()
    ItemToolTip = CreateFrame("GameTooltip", "BaudBagScanningTooltip", nil, "GameTooltipTemplate")
    ItemToolTip:SetOwner( WorldFrame, "ANCHOR_NONE" )
end

AddOnTable.Functions.IsCraftingReagent = function (itemId)
    ItemToolTip:SetItemByID(itemId)
    local isReagent = false
    for i = 1, ItemToolTip:NumLines() do
        local text = _G["BaudBagScanningTooltipTextLeft"..i]:GetText()
        if (string.find(text, AddOnTable.Localized.TooltipScanReagent)) then
            isReagent = true
        end
    end
    return isReagent
end
