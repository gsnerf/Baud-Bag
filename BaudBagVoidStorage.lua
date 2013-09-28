-- this method is called from a user defined shortcut (see bindings.xml)
function BaudBagToggleVoidStorage(self)
	BaudBag_DebugMsg("VoidStorage", "Toggle was called...");

	-- void storage is an LoadOnDemand addon, make sure its loaded
	LoadAddOn("Blizzard_VoidStorageUI");

	-- toggle switch
	if (not VoidStorageFrame:IsShown()) then
		BaudBag_DebugMsg("VoidStorage", "... not yet visible, updating and showing! ("..CanUseVoidStorage().."|"..tostring(IsVoidStorageReady())..")");
		-- before showing we need to make sure the items where initialized
		-- else the void storage will show up empty
		VoidStorageFrame_Update();
		VoidStorageFrame_Show();
	else
		BaudBag_DebugMsg("VoidStorage", "... already visible, hiding!");
		VoidStorageFrame_Hide();
	end
end
