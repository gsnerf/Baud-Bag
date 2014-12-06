local next = next;
local _;

-- this method is called from a user defined shortcut (see bindings.xml)
function BaudBagToggleVoidStorage(self)
    BaudBag_DebugMsg("VoidStorage", "Toggle was called...");

    -- void storage is an LoadOnDemand addon, make sure its loaded
    LoadAddOn("Blizzard_VoidStorageUI");

    -- toggle switch
    if (not VoidStorageFrame:IsShown()) then
        BaudBag_DebugMsg("VoidStorage", "... not yet visible, updating and showing! ("..tostring(CanUseVoidStorage()).."|"..tostring(IsVoidStorageReady())..")");
        -- before showing we need to make sure the items where initialized
        -- else the void storage will show up empty
        VoidStorageFrame_Update();
        VoidStorageFrame_Show();
    else
        BaudBag_DebugMsg("VoidStorage", "... already visible, hiding!");
        VoidStorageFrame_Hide();
    end
end

--[[ Event functions that will be called from the frame script functions later ]]
local EventFuncs = {}


--[[ 
This will be called whenever we are at an accessible void storage point and the content changed.
]]--
local eventFunc = function(self, event, ...)
    BaudBag_DebugMsg("Cache", "Void Storage event received: "..event, ...);
    local voidCache = BaudBagGetVoidCache();

    -- go through all items in the storage and cache them (overriding all values in the process)
    if (IsVoidStorageReady()) then
        for i = 1, 80 do
            local itemID, textureName, locked, recentDeposit, isFiltered = GetVoidItemInfo(i);
            voidCache[i] = itemID and itemID or nil;
        end
    else
        BaudBag_DebugMsg("Cache", "Void Storage not ready yet, not doing anything!");
    end

    if (next(voidCache) == nil) then
        BaudBag_DebugMsg("Cache", "ATTENTION: the void storage cache is empty!");
    end
	
    -- for content updates usually just the changed item is updated, which will create problems with the cached items
    --if (event == "VOID_STORAGE_CONTENTS_UPDATE") then
    --    VoidStorage_ItemsUpdate(true, true);
    --end
end
EventFuncs.VOID_STORAGE_OPEN = eventFunc;
EventFuncs.VOID_STORAGE_UPDATE = eventFunc;
EventFuncs.VOID_STORAGE_CONTENTS_UPDATE = eventFunc;

--EventFuncs.VOID_STORAGE_OPEN = Func;
--EventFuncs.VOID_DEPOSIT_WARNING = Func;
--EventFuncs.VOID_STORAGE_DEPOSIT_UPDATE = Func;
--EventFuncs.VOID_TRANSFER_DONE = Func;
--EventFuncs.VOID_STORAGE_CONTENTS_UPDATE = Func;
--EventFuncs.VOID_STORAGE_UPDATE = Func;
--EventFuncs.VOID_STORAGE_CLOSE = Func;

--[[       different local variables with various background        ]]
--[[         (see specific variable comments for more info)         ]]
--[[ -------------------------------------------------------------- ]]
--[[ safe references to original VoidStorageItemButtons so we can alter the references ]]
local origVoidFrames = {};
local origVoidItemButtons = {};
local bbVoidItemButtons = {};
--[[ this is just a copy from the original values found in Blizzard_VoidStorageUI.lua ]]
local VOID_DEPOSIT_MAX = 9;
local VOID_WITHDRAW_MAX = 9;
local VOID_STORAGE_MAX = 80;

function BaudBagGetVoidItemButtons()
    return origVoidItemButtons;
end


--[[                  Frame script functions                        ]]
--[[ -------------------------------------------------------------- ]]
function BaudBagVoidStorage_OnLoad(self, event, ...)

    --    -- make sure all needed events are registered to this frame
    --    for Key, Value in pairs(EventFuncs) do
    --        self:RegisterEvent(Key);
    --    end

    --    -- remember original frame
    --    origVoidFrames["VoidStorageFrame"]			= _G["VoidStorageFrame"];
    --    origVoidFrames["VoidStorageBorderFrame"]	= _G["VoidStorageBorderFrame"];
    --    origVoidFrames["VoidStorageDepositFrame"]	= _G["VoidStorageDepositFrame"];
    --    origVoidFrames["VoidStorageWithdrawFrame"]	= _G["VoidStorageWithdrawFrame"];
    --    origVoidFrames["VoidStorageStorageFrame"]	= _G["VoidStorageStorageFrame"];
	
    --    -- remember all original references to the storage item buttons
    --    for i = 1, VOID_DEPOSIT_MAX do
    --        origVoidItemButtons["VoidStorageDepositButton"..i] = _G["VoidStorageDepositButton"..i];
    --    end
    --    for i = 1, VOID_WITHDRAW_MAX do
    --        origVoidItemButtons["VoidStorageWithdrawButton"..i] = _G["VoidStorageWithdrawButton"..i];
    --    end
    --    for i = 1, VOID_STORAGE_MAX do
    --        origVoidItemButtons["VoidStorageStorageButton"..i] = _G["VoidStorageStorageButton"..i];
    --    end
	
    --    BaudBagVoidStorage_TakeOverStorage();
end

function BaudBagVoidStorage_OnEvent(self, event, ...)
    EventFuncs[event](self, event, ...);
end


--[[               PreHooks for original void storage               ]]
--[[ -------------------------------------------------------------- ]]

--local origVoidStorageFrame_Show = VoidStorageFrame_Show;
--VoidStorageFrame_Show = function(...)
--    BaudBag_DebugMsg("VoidStorage", "Tried to catch the Show event");
--    return origVoidStorageFrame_Show(...);
--end

--local origVoidStorageFrame_Hide = VoidStorageFrame_Hide;
--VoidStorageFrame_Hide = function(...)
--    BaudBag_DebugMsg("VoidStorage", "Tried to catch the Hide event");
--    return origVoidStorageFrame_Hide(...);
--end

--local origVoidStorage_ItemsUpdate = VoidStorage_ItemsUpdate;
--VoidStorage_ItemsUpdate = function(doDeposit, doContents)
--    BaudBag_DebugMsg("VoidStorage", "executing VoidStorage_ItemsUpdate ("..tostring(doDeposit).."||"..tostring(doContents)..")");
--    local voidCache = BaudBagGetVoidCache();
--    local button;
--    if ( doDeposit ) then
--        for i = 1, VOID_DEPOSIT_MAX do
--            local itemID, textureName = GetVoidTransferDepositInfo(i);
--            button = _G["VoidStorageDepositButton"..i];
--            button.icon:SetTexture(textureName);
--            if ( itemID ) then
--                button.hasItem = true;
--            else
--                button.hasItem = nil;
--            end
--        end
--    end
--    if ( doContents ) then
--        -- withdrawal
--        for i = 1, VOID_WITHDRAW_MAX do
--            local itemID, textureName = GetVoidTransferWithdrawalInfo(i);
--            button = _G["VoidStorageWithdrawButton"..i];
--            button.icon:SetTexture(textureName);
--            if ( itemID ) then
--                button.hasItem = true;
--            else
--                button.hasItem = nil;
--            end
--        end
		
--        -- storage
--        for i = 1, VOID_STORAGE_MAX do
--            local itemID, textureName, locked, recentDeposit, isFiltered = GetVoidItemInfo(i);

--            --if (not itemID and voidCache[i]) then
--            --	itemID = voidCache[i];
--            --	_, _, _, _, _, _, _, _, _, textureName, _ = GetItemInfo(itemID);
--            --end

--            button = _G["VoidStorageStorageButton"..i];
--            button.icon:SetTexture(textureName);
--            if ( itemID ) then
--                button.icon:SetDesaturated(locked);
--                button.hasItem = true;
--            else
--                button.hasItem = nil;
--            end
			
--            if ( recentDeposit ) then
--                local antsFrame = button.antsFrame;
--                if ( not antsFrame ) then
--                    antsFrame = VoidStorageFrame_GetAntsFrame();
--                    antsFrame:SetParent(button);
--                    antsFrame:SetPoint("CENTER");
--                    button.antsFrame = antsFrame;
--                end
--                antsFrame:Show();
--            elseif ( button.antsFrame ) then
--                button.antsFrame:Hide();
--                button.antsFrame = nil;
--            end
			
--            if ( isFiltered ) then
--                button.searchOverlay:Show();
--            else
--                button.searchOverlay:Hide();
--            end
--        end
--    end
--    if ( VoidStorageFrame.mousedOverButton ) then
--        VoidStorageItemButton_OnEnter(VoidStorageFrame.mousedOverButton);
--    end
--    local hasWarningDialog = StaticPopup_FindVisible("VOID_DEPOSIT_CONFIRM");
--    VoidStorage_UpdateTransferButton(hasWarningDialog);
--end

--[[     functions for activating/deactivating BB void storage      ]]
--[[ -------------------------------------------------------------- ]]
function BaudBagVoidStorage_TakeOverStorage() 
    -- take over main frames
    _G["VoidStorageFrame"]			= _G["BaudBagVoidStorage"];
    _G["VoidStorageBorderFrame"]	= _G["BBVoidStorageBorderFrame"];
    _G["VoidStorageDepositFrame"]	= _G["BBVoidStorageDepositFrame"];
    _G["VoidStorageWithdrawFrame"]	= _G["BBVoidStorageWithdrawFrame"];
    _G["VoidStorageStorageFrame"]	= _G["VoidStorageStorageFrame"];

    -- reset original item frames ...
    for i = 1, VOID_DEPOSIT_MAX do
        table.foreach(origVoidItemButtons, function(k,v) _G[k] = nil end);
    end
    -- ... so we can set the initial ones to our template
    _G["VoidStorageDepositButton1"] = _G["BBVoidStorageDepositButton1"];
    _G["VoidStorageWithdrawButton1"] = _G["BBVoidStorageWithdrawButton1"];
    _G["VoidStorageStorageButton1"] = _G["BBVoidStorageStorageButton1"];
	
    -- now apply original changes and recreate items based on our new templates
    VoidStorageFrame_OnLoad(_G["VoidStorageFrame"]);

    -- and unregister events for original frames
    origVoidFrames["VoidStorageFrame"]:UnregisterEvent("VOID_STORAGE_UPDATE");
    origVoidFrames["VoidStorageFrame"]:UnregisterEvent("VOID_STORAGE_CONTENTS_UPDATE");
    origVoidFrames["VoidStorageFrame"]:UnregisterEvent("VOID_STORAGE_DEPOSIT_UPDATE");
    origVoidFrames["VoidStorageFrame"]:UnregisterEvent("VOID_TRANSFER_DONE");
    origVoidFrames["VoidStorageFrame"]:UnregisterEvent("INVENTORY_SEARCH_UPDATE");
    origVoidFrames["VoidStorageFrame"]:UnregisterEvent("VOID_DEPOSIT_WARNING");
end

function BaudBagVoidStorage_ReleaseStorage()
    -- re-register all original frames
    _G["VoidStorageFrame"]			= origVoidFrames["VoidStorageFrame"];
    _G["VoidStorageBorderFrame"]	= origVoidFrames["VoidStorageBorderFrame"];
    _G["VoidStorageDepositFrame"]	= origVoidFrames["VoidStorageDepositFrame"];
    _G["VoidStorageWithdrawFrame"]	= origVoidFrames["VoidStorageWithdrawFrame"];
    _G["VoidStorageStorageFrame"]	= origVoidFrames["VoidStorageStorageFrame"];

    -- now reset items
    table.foreach(origVoidItemButtons, function(k,v) _G[k] = origVoidItemButtons[k] end);

    -- re-register events
    origVoidFrames["VoidStorageFrame"]:RegisterEvent("VOID_STORAGE_UPDATE");
    origVoidFrames["VoidStorageFrame"]:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE");
    origVoidFrames["VoidStorageFrame"]:RegisterEvent("VOID_STORAGE_DEPOSIT_UPDATE");
    origVoidFrames["VoidStorageFrame"]:RegisterEvent("VOID_TRANSFER_DONE");
    origVoidFrames["VoidStorageFrame"]:RegisterEvent("INVENTORY_SEARCH_UPDATE");
    origVoidFrames["VoidStorageFrame"]:RegisterEvent("VOID_DEPOSIT_WARNING");

    -- und unregister own events
    _G["BBVoidStorageFrame"]:UnregisterEvent("VOID_STORAGE_UPDATE");
    _G["BBVoidStorageFrame"]:UnregisterEvent("VOID_STORAGE_CONTENTS_UPDATE");
    _G["BBVoidStorageFrame"]:UnregisterEvent("VOID_STORAGE_DEPOSIT_UPDATE");
    _G["BBVoidStorageFrame"]:UnregisterEvent("VOID_TRANSFER_DONE");
    _G["BBVoidStorageFrame"]:UnregisterEvent("INVENTORY_SEARCH_UPDATE");
    _G["BBVoidStorageFrame"]:UnregisterEvent("VOID_DEPOSIT_WARNING");
end