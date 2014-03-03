--[[
	This handles mostly everything that has to do with the TokenFrame in the Backpack container.
	As the control of which tokens should be shown in the backpack is controlled by the default blizzard ui for tokens,
	its needed to first save and then overwrite the original functions, so that it can be decided here
	wether this AddOn needs to handle the token, or wether the original frames need to be called.
	The original frame has to be called in two cases:
	1. BaudBag is not enabled for the backpack
	2. The user disabled to show the frame in the options (TODO: not implemented yet!!!)

	Additionally to the self rendering in our bags (done in BaudBag.lua BaudBagUpdateBackground()) the max trackable tokens are raised to 5.
]]--
local _;
MAX_WATCHED_TOKENS_ORIG = MAX_WATCHED_TOKENS;
MAX_WATCHED_TOKENS_BAUD_BAG = 5;

local pre_BackpackTokenFrame_Update = BackpackTokenFrame_Update;
BackpackTokenFrame_Update = function()
	BaudBag_DebugMsg(3, "Update was called on TokenFrame");
	-- make sure the old is called when BaudBag is disabled for the backpack
	if (BBConfig and BBConfig[1].Enabled == false) then
		BaudBag_DebugMsg(3, "BaudBag disabled for Backpack, calling original!");
		MAX_WATCHED_TOKENS = MAX_WATCHED_TOKENS_ORIG;
		return pre_BackpackTokenFrame_Update();
	end
	
	-- get the token frame and reset to default values (will be updated bellow)
	local TokenFrame = _G["BaudBagContainer1_1TokenFrame"];
	TokenFrame.shouldShow = 0;
	TokenFrame.numWatchedTokens = 0;

	-- do whatever the original does but for our own frame
	MAX_WATCHED_TOKENS = MAX_WATCHED_TOKENS_BAUD_BAG;
	local watchButton;
	local name, count, icon;
	local digits, countSize;
	local usedWidth = 0;
	local digitWidth = 8;
	for i=1, MAX_WATCHED_TOKENS do
		name, count, icon, itemID = GetBackpackCurrencyInfo(i);
		watchButton = _G[TokenFrame:GetName().."Token"..i];

		-- Update watched tokens
		if ( name ) then
			BaudBag_DebugMsg(3, "Update: Token "..i.." found with name '"..name.."' and count '"..count.."'");
			
			-- set icon
			watchButton.icon:SetTexture(icon);
			
			-- and count
			if ( count <= 99999 ) then
				watchButton.count:SetText(count);
			else
				watchButton.count:SetText("*");
			end
			
			-- update width based on text to show
			digits = string.len(tostring(count));
			BaudBag_DebugMsg(3, "number of digits in currency '"..name.."': "..digits);
			countSize = digits * digitWidth + math.floor(6 / digits);
			watchButton.count:SetWidth(countSize);
			-- 12 (icon width) + 1 (space between count & icon) + count width + 5 (space to the left)
			watchButton:SetWidth(18 + countSize);

			-- recalc used width now
			usedWidth = usedWidth + watchButton:GetWidth();
			BaudBag_DebugMsg(3, "used width after currency '"..name.."': "..usedWidth.."; space available: "..TokenFrame:GetWidth());
			
			-- make only visible if there is enough space 
			watchButton:Hide();
			if (usedWidth < TokenFrame:GetWidth()) then
				watchButton:Show();
				watchButton.itemID = itemID;
				TokenFrame.shouldShow = 1;
				TokenFrame.numWatchedTokens = i;
			end
		else
			BaudBag_DebugMsg(3, "Update: Token "..i.." NOT found");
			watchButton:Hide();
			watchButton.itemID = nil;
			if ( i == 1 ) then
				BaudBag_DebugMsg(3, "Update: Token 1 => hiding backpack");
				TokenFrame.shouldShow = 0;
			end
		end
	end
end


local pre_GetNumWatchedTokens = GetNumWatchedTokens;
GetNumWatchedTokens = function()
	-- make sure the old is called when baudbag is disabled for the bagpack
	if (BBConfig and BBConfig[1].Enabled == false) then
		BaudBag_DebugMsg(3, "BaudBag disabled for Backpack, calling original!");
		return pre_GetNumWatchedTokens();
	end
	
	local TokenFrame = _G["BaudBagContainer1_1TokenFrame"];
	
	if (not TokenFrame.numWatchedTokens) then
		-- No count yet so get it 
		BackpackTokenFrame_Update(); 
	end
	return TokenFrame.numWatchedTokens or 0;
end

local pre_BackpackTokenFrame_IsShown = BackpackTokenFrame_IsShown;
BackpackTokenFrame_IsShown = function()
	BaudBag_DebugMsg(3, "IsShown was called on BaudBagTokenFrame");
	-- make sure the old is called when BaudBag is disabled for the backpack
	if (BBConfig and BBConfig[1].Enabled == false) then
		BaudBag_DebugMsg(3, "BaudBag disabled for Backpack, calling original!");
		return pre_BackpackTokenFrame_IsShown();
	end

	return _G["BaudBagContainer1_1TokenFrame"].shouldShow; 
end


local pre_ManageBackpackTokenFrame = ManageBackpackTokenFrame;
ManageBackpackTokenFrame = function(backpack)
	BaudBag_DebugMsg(3, "Manage was called on TokenFrame");
	-- make sure the old is called when baudbag is disabled for the bagpack
	if (BBConfig and BBConfig[1].Enabled == false) then
		BaudBag_DebugMsg(3, "BaudBag disabled for Backpack, calling original!");
		return pre_ManageBackpackTokenFrame(backpack);
	end
	
	-- get references to all frames needed for the management
	local TokenFrame = _G["BaudBagContainer1_1TokenFrame"];
	local Backpack   = _G["BaudBagContainer1_1"];

	if (BackpackTokenFrame_IsShown() == 1) and (not TokenFrame:IsShown()) then
		BaudBag_DebugMsg(3, "Manage: TokenFrame visible, update settings");
		TokenFrame:Show();
		BaudBagUpdateContainer(Backpack);
	elseif (BackpackTokenFrame_IsShown() ~= 1 and TokenFrame:IsShown()) then
		BaudBag_DebugMsg(3, "Manage: TokenFrame NOT visible, hide it");
		TokenFrame:Hide(); 
		BaudBagUpdateContainer(Backpack);
	end
end

local pre_BackpackTokenButton_OnClick = BackpackTokenButton_OnClick;
BackpackTokenButton_OnClick = function(self, button) 

	-- make sure the old is called when baudbag is disabled for the bagpack
	if (BBConfig and BBConfig[1].Enabled == false) then
		pre_BackpackTokenButton_OnClick(self, button);
	end
	
	if ( IsModifiedClick("CHATLINK") ) then
		ChatEdit_InsertLink(select(2, GetItemInfo(self.itemID))); 
	end
end