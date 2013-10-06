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


--[[ This will be called when ever we are at an accessible void storage point ]]
local eventFunc = function(self, event, ...)
	BaudBag_DebugMsg("VoidStorage", "Updating cache content "..event);
	local voidCache = BaudBagGetVoidCache();

	-- go through all items in the storage and cache them (overriding all values in the process)
	for i = 1, 80 do
		local itemID, textureName, locked, recentDeposit, isFiltered = GetVoidItemInfo(i);
		voidCache[i] = itemID and itemID or nil;
	end
end
EventFuncs.VOID_STORAGE_OPEN = eventFunc;
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

	-- make sure all needed events are registered to this frame
	for Key, Value in pairs(EventFuncs) do
		self:RegisterEvent(Key);
	end

	-- remember all original references to the storage item buttons
	for i = 1, VOID_DEPOSIT_MAX do
		origVoidItemButtons["VoidStorageDepositButton"..i] = _G["VoidStorageDepositButton"..i];
	end
	for i = 1, VOID_WITHDRAW_MAX do
		origVoidItemButtons["VoidStorageWithdrawButton"..i] = _G["VoidStorageWithdrawButton"..i];
	end
	for i = 1, VOID_STORAGE_MAX do
		origVoidItemButtons["VoidStorageStorageButton"..i] = _G["VoidStorageStorageButton"..i];
	end
end

function BaudBagVoidStorage_OnEvent(self, event, ...)
	EventFuncs[event](self, event, ...);
end


--[[               PreHooks for original void storage               ]]
--[[ -------------------------------------------------------------- ]]

local origVoidStorageFrame_Show = VoidStorageFrame_Show;
VoidStorageFrame_Show = function(...)
	BaudBag_DebugMsg("VoidStorage", "Tried to catch the Show event");
	return origVoidStorageFrame_Show(...);
end

local origVoidStorageFrame_Hide = VoidStorageFrame_Hide;
VoidStorageFrame_Hide = function(...)
	BaudBag_DebugMsg("VoidStorage", "Tried to catch the Hide event");
	return origVoidStorageFrame_Hide(...);
end

--[[     functions for activating/deactivating BB void storage      ]]
--[[ -------------------------------------------------------------- ]]
-- TODO: check if this actually works
function BaudBagVoidStorage_ResetItemButtons()
	table.foreach(origVoidItemButtons, function(k,v) _G[k] = origVoidItemButtons[k] end);
end