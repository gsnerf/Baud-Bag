--[[
	This handles mostly everything that has to do with the TokenFrame in the Backpack container.
	As the control of which tokens should be shown in the backpack is controlled by the default blizzard ui for tokens,
	its needed to first save and then overwrite the original functions, so that it can be decided here
	wether this AddOn needs to handle the token, or wether the original frames need to be called.
	The original frame has to be called in two cases:
	1. BaudBag is not enabled for the backpack
	2. The user disabled to show the frame in the options (TODO: not implemented yet!!!)
	
	NOTICE:
	As the BaudBag_Cfg only needs to be READ here (no local changes whatsoever) it is read directly
	from the automatically saved BaudBag_Cfg instead of handling a local copy of the variable!
]]--

local pre_BackpackTokenFrame_Update = BackpackTokenFrame_Update;
BackpackTokenFrame_Update = function()
	BaudBag_DebugMsg("Update was called on BaudBagTokenFrame");
	-- make sure the old is called when BaudBag is disabled for the backpack
	if (BaudBag_Cfg and BaudBag_Cfg[1].Enabled == false) then
		BaudBag_DebugMsg("BaudBag disabled for Backpack, calling original!");
		return pre_BackpackTokenFrame_Update();
	end

	-- do whatever the original does but for our own frame
	local watchButton;
	local name, count, icon;
	for i=1, MAX_WATCHED_TOKENS do
		name, count, icon, itemID = GetBackpackCurrencyInfo(i);
		-- Update watched tokens
		if ( name ) then
			watchButton = _G["BaudBagTokenFrameToken"..i];
			
			-- set icon
			watchButton.icon:SetTexture(icon);
			
			-- and count
			if ( count <= 99999 ) then
				watchButton.count:SetText(count);
			else
				watchButton.count:SetText("*");
			end
			
			-- make visible
			watchButton:Show();
			BaudBagTokenFrame.shouldShow = 1;
			BaudBagTokenFrame.numWatchedTokens = i;
			watchButton.itemID = itemID;
		else
			_G["BaudBagTokenFrameToken"..i]:Hide();
			if ( i == 1 ) then
				BackpackTokenFrame.shouldShow = nil;
			end
			_G["BaudBagTokenFrameToken"..i].itemID = nil;
		end
	end
end


local pre_GetNumWatchedTokens = GetNumWatchedTokens;
GetNumWatchedTokens = function()
	-- make sure the old is called when baudbag is disabled for the bagpack
	if (BaudBag_Cfg and BaudBag_Cfg[1].Enabled == false) then
		BaudBag_DebugMsg("BaudBag disabled for Backpack, calling original!");
		return pre_GetNumWatchedTokens();
	end
	
	if (not BaudBagTokenFrame.numWatchedTokens) then
		-- No count yet so get it 
		BackpackTokenFrame_Update(); 
	end
	return BaudBagTokenFrame.numWatchedTokens or 0;
end

local pre_BackpackTokenFrame_IsShown = BackpackTokenFrame_IsShown;
BackpackTokenFrame_IsShown = function()
	BaudBag_DebugMsg("IsShown was called on BaudBagTokenFrame");
	-- make sure the old is called when BaudBag is disabled for the backpack
	if (BaudBag_Cfg and BaudBag_Cfg[1].Enabled == false) then
		BaudBag_DebugMsg("BaudBag disabled for Backpack, calling original!");
		return pre_BackpackTokenFrame_IsShown();
	end

	return BaudBagTokenFrame.shouldShow; 
end

local pre_ManageBackpackTokenFrame = ManageBackpackTokenFrame;
ManageBackpackTokenFrame = function(backpack)
	BaudBag_DebugMsg("Manage was called on BaudBagTokenFrame");
	-- make sure the old is called when baudbag is disabled for the bagpack
	if (BaudBag_Cfg and BaudBag_Cfg[1].Enabled == false) then
		BaudBag_DebugMsg("BaudBag disabled for Backpack, calling original!");
		pre_ManageBackpackTokenFrame(backpack);
	end

	if (not backpack) then
		backpack = _G["BaudBagContainer1_1"];--GetBackpackFrame(); -- TODO!!!
	end
	if (not backpack) then
		-- If still no backpack then we don't show the frame 
		BaudBagTokenFrame:Hide(); 
		return; 
	end
	if (BackpackTokenFrame_IsShown() and (not BaudBagTokenFrame:IsShown())) then
		BaudBagTokenFrame:SetParent(backpack); 
		BaudBagTokenFrame:SetPoint("TOPLEFT", backpack, "BOTTOMLEFT", 0, -BACKPACK_TOKENFRAME_HEIGHT); 
		--backpack:SetHeight(backpack:GetHeight() + BACKPACK_TOKENFRAME_HEIGHT); 
		BaudBagTokenFrame:SetWidth(backpack:GetWidth());
		BaudBagTokenFrame:Show(); 
	elseif (not BackpackTokenFrame_IsShown() and BaudBagTokenFrame:IsShown()) then 
		--backpack:SetHeight(backpack:GetHeight() - BACKPACK_TOKENFRAME_HEIGHT); 
		BaudBagTokenFrame:Hide(); 
	end
end

local pre_BackpackTokenButton_OnClick = BackpackTokenButton_OnClick;
BackpackTokenButton_OnClick = function(self, button) 

	-- make sure the old is called when baudbag is disabled for the bagpack
	if (BaudBag_Cfg and BaudBag_Cfg[1].Enabled == false) then
		pre_BackpackTokenButton_OnClick(self, button);
	end
	
	if ( IsModifiedClick("CHATLINK") ) then
		ChatEdit_InsertLink(select(2, GetItemInfo(self.itemID))); 
	end
end