local _
local AddOnName, AddOnTable = ...

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
    BagBackgrounds = { Name = "Bag Backgrounds",    Active = false },
    Container      = { Name = "Container",          Active = false },
	
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


function BaudBag_DebugMsg(type, msg, ...)
    if (BaudBag_DebugCfg[type].Active) then
        DEFAULT_CHAT_FRAME:AddMessage(GetTime().." BaudBag ("..BaudBag_DebugCfg[type].Name.."): "..msg);
        if (... ~= nil) then
            for n=1,select('#',...) do
                local dumpValue = select(n,...)
                BaudBag_Vardump(dumpValue)
            end
        end
    end
    if (BaudBag_DebugLog) then
        table.insert(BaudBag_Debug, GetTime().." BaudBag ("..BaudBag_DebugCfg[type].Name.."): "..msg);
    end
end

function BaudBag_Vardump(value, depth, key)
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
        mTable = getmetatable(value);
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


--[[
    This function takes a set of bags and a function, and then applies the function to each bag of the set.
    The function gets the parameters: 1. Bag, 2. Index
  ]]
function BaudBagForEachBag(BagSet, Func)
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
            5-11 == bank bags
    ]]--
    if (BagSet == 1) then -- regular bags
        for Bag = 1, 5 do
            Func(Bag - 1, Bag);
        end
    else -- bank
        Func(-1, 1);
        -- bank bags
        for Bag = 1, NUM_BANKBAGSLOTS do
            Func(Bag + 4, Bag + 1);
        end
        -- reagent bank
        Func(-3, NUM_BANKBAGSLOTS + 2);
    end
end


function BaudBagCopyTable(Value)
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


function ShowHyperlink(Owner, Link)
    local ItemString = strmatch(Link or "","(item[%d:%-]+)");
    if not ItemString then
        return;
    end
    if(Owner:GetRight() >= (GetScreenWidth() / 2))then
        GameTooltip:SetOwner(Owner, "ANCHOR_LEFT");
    else
        GameTooltip:SetOwner(Owner, "ANCHOR_RIGHT");
    end
    GameTooltip:SetHyperlink(ItemString);
    return true;
end

function BaudBag_InitTexturePiece(Texture, File, Width, Height, MinX, MaxX, MinY, MaxY, Layer)
    Texture:ClearAllPoints();
    -- Texture:SetTexture(1.0, 0, 0, 1);
    Texture:SetTexture(File);
    Texture:SetTexCoord(MinX / Width, (MaxX + 1) / Width, MinY / Height, (MaxY + 1) / Height);
    Texture:SetWidth(MaxX - MinX + 1);
    Texture:SetHeight(MaxY - MinY + 1);
    Texture:SetDrawLayer(Layer);
    Texture:Show();
end

--[[ this function determines if the given bag is currently handled by baudbag or not ]]--
function BaudBag_BagHandledByBaudBag(id)
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
            5-11 == bank bags

        As the given indices > 0 may vary in the future use these constants instead:
            NUM_BAG_FRAMES (for max inventory bags)
            ITEM_INVENTORY_BANK_BAG_OFFSET (first bank bag)
            NUM_BANKBAGSLOTS (number of bank bags)
      ]]
    return (BaudBag_IsBankContainer(id) and BBConfig[2].Enabled) or (BaudBag_IsInventory(id) and BBConfig[1].Enabled);
end

--[[
    These Bag IDs belong to the bank container:
       -3    == REAGENTBANK_CONTAINER
       -1    == BANK_CONTAINER
        5-11 == bank bags
    As the IDs might change we use blizzards own constants instead. Nevertheless we expect:
        1. the special bank containers to stand on their own
        2. the rest bank
  ]]
function BaudBag_IsBankContainer(bagId)
    return BaudBag_IsBankDefaultContainer(bagId) or (bagId > ITEM_INVENTORY_BANK_BAG_OFFSET and bagId <= ITEM_INVENTORY_BANK_BAG_OFFSET + NUM_BANKBAGSLOTS);
end

--[[
    These are the bank containers that need a special treatment in contrast to "regular" bags:
        -3 == REAGENTBANK_CONTAINER
        -1 == BANK_CONTAINER
  ]]
function BaudBag_IsBankDefaultContainer(bagId)
    return (bagId == BANK_CONTAINER or bagId == REAGENTBANK_CONTAINER);
end

--[[
    These IDs belong to the inventory containers:
        0   == BACKPACK_CONTAINER
        1-5 == regular bags defined by NUM_BAG_SLOTS
  ]]
function BaudBag_IsInventory(bagId)
    return (bagId >= BACKPACK_CONTAINER and bagId <= BACKPACK_CONTAINER + NUM_BAG_SLOTS);
end