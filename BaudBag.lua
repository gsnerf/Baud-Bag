--[[To do list:
Slash commands
Multi character viewing
Option for disabling fading
Update offline bank even when it's disabled
Vertex color for backgrounds
]]

--[[ defining variables for the events ]]--
local Localized = BaudBagLocalized;

local Prefix = "BaudBag";
local LastBagID = NUM_BANKBAGSLOTS + 4;
local MaxCont = {1,1};
local NumCont = {};
local BankOpen = false;
local FadeTime = 0.2;
local BagsReady;
local BagsSearched = {};
local _;


-- Adds container name when mousing over bags, aswell as simulating offline bank item mouse over
hooksecurefunc(GameTooltip, "SetInventoryItem", function (Data, Unit, InvID)
  if (Unit ~= "player") then
    return;
  end
  
  if (InvID >= 20) and (InvID <= 23) then
    if BBConfig and (BBConfig[1].Enabled==false) then
      return;
    end
    BaudBagModifyBagTooltip(InvID - 19);
  elseif (InvID >= 68) and (InvID < 68 + NUM_BANKBAGSLOTS) then
    if BBConfig and (BBConfig[2].Enabled == false) then
      return;
    end
    BaudBagModifyBagTooltip(4 + InvID - 67);
  end
end);


MainMenuBarBackpackButton:HookScript("OnEnter", function(...)
  if BBConfig and (BBConfig[1].Enabled ~= false) then
    BaudBagModifyBagTooltip(0);
  end
end);

function BaudBagModifyBagTooltip(BagID)
  if not GameTooltip:IsShown()then
    return;
  end
  local Container = _G[Prefix.."SubBag"..BagID]:GetParent();
  Container = BBConfig[Container.BagSet][Container:GetID()].Name;
  if not Container or not strfind(Container, "%S") then
    return;
  end  
  local Current, Next;
  for Line = GameTooltip:NumLines(), 3, -1 do
    Current, Next = _G["GameTooltipTextLeft"..Line], _G["GameTooltipTextLeft"..(Line - 1)];
    Current:SetTextColor(Next:GetTextColor());     
  end
  if Next then
    Next:SetText(Container);
    Next:SetTextColor(1,0.82,0);
  end
  GameTooltip:Show();
  GameTooltip:AppendText("");
end

--[[ NON XML EVENT HANDLERS ]]--
--[[ these are the custom defined BaudBagFrame event handlers attached to a single event type]]--

local EventFuncs =
{
	ADDON_LOADED = function(self, event, ...)
		-- check if the event was loaded for this addon
		local arg1 = ...;
		if (arg1 ~= "BaudBag") then return end;

		BaudBag_DebugMsg(4, "Event ADDON_LOADED fired");
		
		
		-- this seem to be an embed to the no longer developed cosmos addon, propably safe to remove
		if (EarthFeature_AddButton) then   --add by Isler
			EarthFeature_AddButton(
			{
				id = "BaudBag";
				name = Localized.FeatureFrameName;
				subtext = "BaudBag";
				tooltip = Localized.FeatureFrameTooltip;
				icon = "Interface\\Icons\\Spell_Fire_SunKey";
				callback = function() InterfaceOptionsFrame_OpenToCategory(BaudBagOptionsFrame); end;
			}
			);
		end

		-- make sure the cache is initialized
		BaudBagInitCache();
    
		-- the rest of the bank slots are cleared in the next event
		BaudBagBankSlotPurchaseButton:Disable();
    
	end,

  PLAYER_LOGIN = function(self, event, ...)
	BaudBag_DebugMsg(4, "Event PLAYER_LOGIN fired");
    BaudBag_DebugMsg(4, "Creating bag slot buttons.");
    -- prepare BagSlot creation
    local BagSlot, Texture;
    local BBContainer1 = _G[Prefix.."Container1_1BagsFrame"];
    local BBContainer2 = _G[Prefix.."Container2_1BagsFrame"];
    
    -- create BagSlots for the bag overview in the inventory (frame that pops out and only shows the available bags)
    for Bag = 1, 4 do
        -- the slot name before "BagXSlot" has to be 10 chars long or else this will HARDCRASH
        BagSlot	= CreateFrame("CheckButton", "BaudBInveBag"..(Bag - 1).."Slot", BBContainer1, "BagSlotButtonTemplate");
        -- BagSlot:SetPoint("TOPLEFT", 8, -8 - (Bag - 1) * 39);
        BagSlot:SetPoint("TOPLEFT", 8, -8 - (Bag - 1) * 30);
        BagSlot.HighlightBag = false;
        BagSlot.Bag = Bag;
        BagSlot:HookScript("OnEnter", BaudBag_BagSlot_OnEnter);
        BagSlot:HookScript("OnUpdate", BaudBag_BagSlot_OnUpdate);
        BagSlot:HookScript("OnLeave", BaudBag_BagSlot_OnLeave);
        -- _G[BagSlot:GetName().."ItemAnim"]:UnregisterAllEvents();
    end
    -- BBContainer1:SetWidth(13 + 39);
    -- BBContainer1:SetHeight(13 + 4 * 39 + 20);
    BBContainer1:SetWidth(15 + 30);
    BBContainer1:SetHeight(15 + 4 * 30);

    -- create BagSlots for the bag oberview in the bank (frame that pops out and only shows the available bags)
    for Bag = 1, NUM_BANKBAGSLOTS do
      -- the slot name before "BankBagX" has to be 10 chars long or else this will HARDCRASH
      BagSlot = CreateFrame("Button", "BaudBBankBag"..Bag, BBContainer2, "BankItemButtonBagTemplate");
      BagSlot:SetID(Bag + 4);
      BagSlot.Bag = Bag + 4;
      BagSlot:SetPoint("TOPLEFT",8 + mod(Bag - 1, 2) * 39, -8 - floor((Bag - 1) / 2) * 39);
      BagSlot:HookScript("OnEnter", BaudBag_BagSlot_OnEnter);
      BagSlot:HookScript("OnLeave", BaudBag_BagSlot_OnLeave);
      
      -- init cache for the current bank bag
      if (type(BaudBag_Cache[Bag + 4]) ~= "table") then
        BaudBag_Cache[Bag + 4] = {Size = 0};
      end
      
      -- if there is a bag, create icon with correct texture etc
      if (BaudBag_Cache[Bag + 4].BagLink) then
        Texture = GetItemIcon(BaudBag_Cache[Bag + 4].BagLink);
        SetItemButtonCount(BagSlot, BaudBag_Cache[Bag + 4].BagCount or 0);
      else
        Texture = select(2, GetInventorySlotInfo("Bag"..Bag));
      end
      SetItemButtonTexture(BagSlot,Texture);
    end
    BBContainer2:SetWidth(91);
    --Height changes depending if there is a purchase button
    BBContainer2.Height = 13 + ceil(NUM_BANKBAGSLOTS / 2) * 39;
    BaudBagBankBags_Update();
    BaudBagUpdateFromBBConfig();
    if BBConfig and (BBConfig[2].Enabled == true) then 
		BaudBag_DebugMsg(5, "BaudBag enabled for Bank, disable default bank event");
        BankFrame:UnregisterEvent("BANKFRAME_OPENED"); 
    end 
  end,

  BANKFRAME_CLOSED = function(self, event, ...)
	BaudBag_DebugMsg(5, "Event BANKFRAME_CLOSED fired");
    BankOpen = false;
    BaudBagBankSlotPurchaseButton:Disable();
    if _G[Prefix.."Container2_1"].AutoOpened then
      _G[Prefix.."Container2_1"]:Hide();
    else
      --Add offline again to bag name
      for ContNum = 1, NumCont[2]do
        BaudBagUpdateName(_G[Prefix.."Container2_"..ContNum]);
      end
    end
    BaudBagAutoOpenSet(1, true);
  end,

  PLAYER_MONEY = function(self, event, ...)
	BaudBag_DebugMsg(4, "Event PLAYER_MONEY fired");
    BaudBagBankBags_Update();
  end,

  ITEM_LOCK_CHANGED = function(self, event, ...)
	BaudBag_DebugMsg(4, "Event ITEM_LOCK_CHANGED fired");
    local Bag, Slot = ...;
    if (Bag == BANK_CONTAINER) then
      if (Slot <= NUM_BANKGENERIC_SLOTS) then
        BankFrameItemButton_UpdateLocked(_G[Prefix.."SubBag-1Item"..Slot]);
      else
        BankFrameItemButton_UpdateLocked(_G["BaudBBankBag"..(Slot-NUM_BANKGENERIC_SLOTS)]);
      end
    end
  end
};

--[[ here come functions that will be hooked up to multiple events ]]--
local Func = function(self, event, ...)
	
	BaudBag_DebugMsg(5, "Event "..event.." fired");
	
	-- set bank open marker if it was opend
  if (event == "BANKFRAME_OPENED") then
    BankOpen = true;
  end
  
  -- make sure the player can buy new bankslots
  BaudBagBankSlotPurchaseButton:Enable();
  for Index = 1, NUM_BANKGENERIC_SLOTS do
    BankFrameItemButton_Update(_G[Prefix.."SubBag-1Item"..Index]);
  end
  for Index = 1, NUM_BANKBAGSLOTS do
    BankFrameItemButton_Update(_G["BaudBBankBag"..Index]);
  end
  BaudBagBankBags_Update();
  BaudBag_DebugMsg(4, "Recording bank bag info.");
  for Bag = 1, NUM_BANKBAGSLOTS do
    BaudBag_Cache[Bag + 4].BagLink	= GetInventoryItemLink("player", 67 + Bag);
    BaudBag_Cache[Bag + 4].BagCount = GetInventoryItemCount("player", 67 + Bag);
  end

	-- everything coming now is only needed if the bank is visible
  if (BBConfig[2].Enabled == false) or (event ~= "BANKFRAME_OPENED") then
	BaudBag_DebugMsg(5, "Bankframe does not really seem to be open or event was not BANKFRAME_OPENED. Stepping over actually opening the Bankframes");
    return;
  end
  
  local BBContainer2_1 = _G[Prefix.."Container2_1"];
  if BBContainer2_1:IsShown()then
    BaudBagUpdateContainer(BBContainer2_1);
    BaudBagUpdateFreeSlots(BBContainer2_1);
  else
    BBContainer2_1.AutoOpened = true;
    BBContainer2_1:Show();
  end
  BaudBagAutoOpenSet(1);
  BaudBagAutoOpenSet(2);
end
EventFuncs.BANKFRAME_OPENED = Func;
EventFuncs.PLAYERBANKBAGSLOTS_CHANGED = Func;

Func = function(self, event, ...)
  BaudBag_DebugMsg(4, "Event "..event.." fired");
  BaudBagAutoOpenSet(1, false);
end
EventFuncs.MERCHANT_SHOW = Func;
EventFuncs.MAIL_SHOW = Func;
EventFuncs.AUCTION_HOUSE_SHOW = Func;

Func = function(self, event, ...)
  BaudBag_DebugMsg(4, "Event "..event.." fired");
  BaudBagAutoOpenSet(1,true);
end
EventFuncs.MERCHANT_CLOSED = Func;
EventFuncs.MAIL_CLOSED = Func;
EventFuncs.AUCTION_HOUSE_CLOSED = Func;

Func = function(self, event, ...)
  BaudBag_DebugMsg(4, "Event "..event.." fired for "..self:GetName());
  local arg1 = ...;
  -- if there are new bank slots the whole view has to be updated
  if (event == "PLAYERBANKSLOTS_CHANGED") then
    if (arg1 > NUM_BANKGENERIC_SLOTS) then
      BankFrameItemButton_Update(_G["BaudBBankBag"..(arg1-NUM_BANKGENERIC_SLOTS)]);
      return;
    end
  
	-- if the main bag is visible make sure the content of the sub-bags is also shown  
    local BankBag = _G[Prefix.."SubBag-1"];
    if BankBag:GetParent():IsShown()then
       BaudBagUpdateSubBag(BankBag);
    end
    BankFrameItemButton_Update(_G[BankBag:GetName().."Item"..arg1]);
    BagSet = 2;
  else
    BagSet = (arg1 ~= -1) and (arg1 <= 4) and 1 or 2;
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
--[[ END OF NON XML EVENT HANDLERS ]]--


--[[ xml defined (called) BaudBagFrame event handlers ]]--
function BaudBag_OnLoad(self, event, ...)
	BINDING_HEADER_BaudBag					= "Baud Bag";
	BINDING_NAME_BaudBagToggleBank			= "Toggle Bank";
	BINDING_NAME_BaudBagToggleVoidStorage	= "Show Void Storage";

	BaudBag_DebugMsg(4, "OnLoad was called");

	-- register for global events (actually handled in OnEvent function)
  for Key, Value in pairs(EventFuncs)do
    self:RegisterEvent(Key);
  end

  -- the first container from each set (inventory/bank) is different and is created in the XML
  local SubBag, Container;
  for BagSet = 1, 2 do
    Container = _G[Prefix.."Container"..BagSet.."_1"];
    _G[Container:GetName().."Slots"]:SetPoint("RIGHT",Container:GetName().."MoneyFrame","LEFT");
    -- what is that for?
    Container.BagSet = BagSet;
    Container:SetID(1);
  end

  --The first bag from the bank is unique and is created in the XML
  BaudBag_DebugMsg(4, "Creating sub bags.");
  for Bag = -1, LastBagID do
    if(Bag == -1)then
      SubBag = _G[Prefix.."SubBag"..Bag];
    else
      SubBag = CreateFrame("Frame", Prefix.."SubBag"..Bag, nil, "BaudBagSubBagTemplate");
    end
    SubBag:SetID(Bag);
    SubBag.BagSet = (Bag ~= -1) and (Bag < 5) and 1 or 2;
    SubBag:SetParent(Prefix.."Container"..SubBag.BagSet.."_1");
  end
end

--[[ this will call the correct event handler]]--
function BaudBag_OnEvent(self, event, ...)
  EventFuncs[event](self, event, ...);
end

-- this just makes sure the bags will be visible at the correct layer position when opened
-- function BaudBagBagsFrame_OnShow(self, event, ...)
	-- BaudBag_DebugMsg(5, "BaudBagBagsFrame is shown, correcting frame layer lvls of childs");
  -- --Adjust frame level because of Blizzard's screw up
  -- local Level = self:GetFrameLevel() + 1;
  -- for Key, Value in pairs(self:GetChildren())do
    -- if(type(Value)=="table")then
      -- Value:SetFrameLevel(Level);
    -- end
  -- end
-- end

--[[ Container events ]]--
function BaudBagContainer_OnLoad(self, event, ...)
  tinsert(UISpecialFrames, self:GetName()); -- <- needed?
  self:RegisterForDrag("LeftButton");
end

function BaudBagContainer_OnUpdate(self, event, ...)
  if (self.Refresh) then
    BaudBagUpdateContainer(self);
    BaudBagUpdateOpenBags();
  end
  if (self.UpdateSlots) then
    BaudBagUpdateFreeSlots(self);
  end
  if (self.FadeStart) then
    local Alpha = (GetTime() - self.FadeStart) / FadeTime;
    if self.Closing then
      Alpha = 1 - Alpha;
      if(Alpha < 0)then
        self.FadeStart = nil;
        self:Hide();
        self.Closing = nil;
        return;
      end
    elseif(Alpha > 1)then
      self:SetAlpha(1);
      self.FadeStart = nil;
      return;
    end
    self:SetAlpha(Alpha);
  end
end


function BaudBagContainer_OnShow(self, event, ...)
	BaudBag_DebugMsg(4, "BaudBagContainer_OnShow was called for "..self:GetName());
	
	-- check if the container was open before and closing now
	if self.FadeStart then
		return;
	end
	
	-- container seems to not be visible, open and update
	self.FadeStart = GetTime();
	PlaySound("igBackPackOpen");
	BaudBagUpdateContainer(self);
	BaudBagUpdateOpenBags();
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
  PlaySound("igBackPackClose");
  self.AutoOpened = false;
  BaudBagUpdateOpenBags();
  
  --[[TODO: look into merging the set specific close handling!!!]]--
  --[[
    if the option entry requires it close all remaining containers of the bag set
    (first the bag set so the "offline" title doesn't show up before closing and then the bank to disconnect)
  ]]--
  if (self:GetID() == 1) and (BBConfig[self.BagSet].Enabled) and (BBConfig[self.BagSet].CloseAll) then
	if (self.BagSet == 2) and BankOpen then
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
    -- if BankOpen and (BBConfig[2].Enabled == true) then
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
  BaudBagContainerSaveCoords(self);
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
  BaudBagOptionsSelectContainer(DropDownBagSet,DropDownContainer);
  InterfaceOptionsFrame_OpenToCategory("Baud Bag");
end


function BaudBagToggleBank(self)
  if _G[Prefix.."Container2_1"]:IsShown() then
    _G[Prefix.."Container2_1"]:Hide();
    BaudBagAutoOpenSet(2, true);
  else
    _G[Prefix.."Container2_1"]:Show();
    BaudBagAutoOpenSet(2, false);
  end
end

function BaudBagContainerDropDown_Initialize()
  local info = UIDropDownMenu_CreateInfo();

  info.text = not (DropDownBagSet and BBConfig[DropDownBagSet][DropDownContainer].Locked) and Localized.LockPosition or Localized.UnlockPosition;
  info.func = ToggleContainerLock;
  UIDropDownMenu_AddButton(info);

  --The bank box won't exist yet when this is initialized at first
  if (DropDownBagSet ~= 2) and _G[Prefix.."Container2_1"] and not _G[Prefix.."Container2_1"]:IsShown()then
    info.text = Localized.ShowBank;
    info.func = BaudBagToggleBank;
    UIDropDownMenu_AddButton(info);
  end

  info.text = Localized.Options;
  info.func = ShowContainerOptions;
  UIDropDownMenu_AddButton(info);
end


--This function updates misc. options for a bag
function BaudUpdateContainerData(BagSet, ContNum)
  local Container = _G[Prefix.."Container"..BagSet.."_"..ContNum];
  BaudBag_DebugMsg(4, "Updating container data: "..Container:GetName());
  _G[Container:GetName().."Name"]:SetText(BBConfig[BagSet][ContNum].Name or "");
  local Scale = BBConfig[BagSet][ContNum].Scale / 100;
  Container:SetScale(Scale);
  if not BBConfig[BagSet][ContNum].Coords then
    BaudBagContainerSaveCoords(Container);
  end
  Container:ClearAllPoints();
  local X, Y = unpack(BBConfig[BagSet][ContNum].Coords);
  Container:SetPoint("CENTER",UIParent,"BOTTOMLEFT",(X / Scale), (Y / Scale));
end


local function HideObject(Object)
  Object = _G[Object];
  if not Object then
    return;
  end
  Object:Hide();
end

local TextureFile, TextureWidth, TextureHeight, TextureParent;

local function GetTexturePiece(Name, MinX, MaxX, MinY, MaxY, Layer)
  local Texture = _G[TextureParent:GetName()..Name];
  if not Texture then
    Texture = TextureParent:CreateTexture(TextureParent:GetName()..Name);
  end
  Texture:ClearAllPoints();
  Texture:SetTexture(TextureFile);
  Texture:SetTexCoord(MinX / TextureWidth, (MaxX + 1) / TextureWidth, MinY / TextureHeight, (MaxY + 1) / TextureHeight);
  Texture:SetWidth(MaxX - MinX + 1);
  Texture:SetHeight(MaxY - MinY + 1);
  Texture:SetDrawLayer(Layer);
  Texture:Show();
--  Texture:SetVertexColor(0.2,0.2,1);
  return Texture;
end

-- [[ maybe TODO: remove artwork for keyring container (check if artwork still exists uppon launch) ]] --
function BaudBagUpdateBackground(Container)
	local Background = BBConfig[Container.BagSet][Container:GetID()].Background;
	local Backdrop = _G[Container:GetName().."Backdrop"];
	Backdrop:SetFrameLevel(Container:GetFrameLevel());
	local Left, Right, Top, Bottom;
	-- This shifts the name of the bank frame over to make room for the extra button
	local ShiftName = (Container:GetID()==1) and 25 or 0;

	-- these are the default blizz-frames
	if (Background <= 3) then
		Left, Right, Top, Bottom = 10, 10, 25, 7;
		local Cols = BBConfig[Container.BagSet][Container:GetID()].Columns;
		if (Container.Slots < Cols) then
			Cols = Container.Slots;
		end
		local Col = 0;
		local Blanks = Cols - mod(Container.Slots - 1, Cols) - 1;
		local BlankTop = BBConfig[Container.BagSet][Container:GetID()].BlankTop and(Blanks ~= 0);

		if BlankTop then
			Col = Blanks;
		else
			Top = Top + 18;
		end

		local Parent = Backdrop:GetName().."Textures";
		TextureParent = _G[Parent];
		TextureParent:SetFrameLevel(Container:GetFrameLevel());
		local Texture;

		-- choose the correct texture file with correct sizes
		TextureFile = "Interface\\ContainerFrame\\UI-Bag-Components";
		if (Background == 2) then
			TextureFile = TextureFile.."-Bank";
		elseif(Background == 3)then
			TextureFile = TextureFile.."-Keyring";
		end
		TextureWidth, TextureHeight = 256, 512;

		-- --------------------------
		-- create new textures now
		-- --------------------------
		-- BORDERS FIRST
		-- transparent circle top left
		Texture = GetTexturePiece("TopLeft", 65, 116, 1, 49,"ARTWORK");
		Texture:SetPoint("TOPLEFT", -7, 4);

		-- right end of header + transparent piece for close button (with or without blank part on the bottom)
		Texture = GetTexturePiece("TopRight", 223, 252, 5, BlankTop and 30 or 49,"ARTWORK");
		Texture:SetPoint("TOPRIGHT");

		-- bottom left round corner
		Texture = GetTexturePiece("BottomLeft",72,79,169,177,"ARTWORK");
		Texture:SetPoint("BOTTOMLEFT");

		-- bottom right round corner
		Texture = GetTexturePiece("BottomRight",247,252,172,177,"ARTWORK");
		Texture:SetPoint("BOTTOMRIGHT");

		-- container header (contains name, with or without blank part on the bottom)
		Texture = GetTexturePiece("Top", 117, 222, 5, BlankTop and 30 or 49,"ARTWORK");
		Texture:SetPoint("TOP");
		Texture:SetPoint("RIGHT",Parent.."TopRight","LEFT");
		Texture:SetPoint("LEFT",Parent.."TopLeft","RIGHT");

		-- left border
		Texture = GetTexturePiece("Left",72,76,182,432,"ARTWORK");
		Texture:SetPoint("LEFT");
		Texture:SetPoint("BOTTOM",Parent.."BottomLeft","TOP");
		Texture:SetPoint("TOP",Parent.."TopLeft","BOTTOM");

		-- right border
		Texture = GetTexturePiece("Right",248,252,182,432,"ARTWORK");
		Texture:SetPoint("RIGHT");
		Texture:SetPoint("BOTTOM",Parent.."BottomRight","TOP");
		Texture:SetPoint("TOP",Parent.."TopRight","BOTTOM");

		-- bottom border
		Texture = GetTexturePiece("Bottom",80,246,173,177,"OVERLAY");
		Texture:SetPoint("BOTTOM");
		Texture:SetPoint("LEFT",Parent.."BottomLeft","RIGHT");
		Texture:SetPoint("RIGHT",Parent.."BottomRight","LEFT");
		
		-- BLANKS NEXT
		if (Blanks > 0) then
			local Width = Blanks * 42;
			if BlankTop then
				Texture = GetTexturePiece("BlankFillEdge", 116, 223, 31, 34,"ARTWORK");
				Texture:SetPoint("TOPLEFT",Parent.."Top","BOTTOMLEFT");
				Texture:SetPoint("RIGHT",Container,"LEFT",Width,0);

				Texture = GetTexturePiece("BlankFillLeft", 72, 116, 142, 162,"ARTWORK");
				Texture:SetPoint("TOPRIGHT",Parent.."TopLeft","BOTTOMRIGHT",0,3);
				Texture:SetPoint("BOTTOM",Container,"TOP",0,-42);

				--Since the texture in already stretched about double in height, try to keep the ratio
				local TexWidth = (Width / 2 > 107)and 107 or (Width / 2);
				Texture = GetTexturePiece("BlankFill", 223-TexWidth, 223, 35, 49,"ARTWORK");
				Texture:SetPoint("TOPRIGHT",Parent.."BlankFillEdge","BOTTOMRIGHT");
				Texture:SetPoint("BOTTOMLEFT",Parent.."BlankFillLeft","BOTTOMRIGHT");
			else
				Texture = GetTexturePiece("BlankFillEdge",245,248,30,49,"ARTWORK");
				Texture:SetPoint("BOTTOM",Container,"BOTTOM",0,-5);
				Texture:SetPoint("RIGHT",Parent.."Right","LEFT");
				Texture:SetHeight(42);
				--Avoids the texture becomming too compressed if the space is infact small
				local TexWidth = (Width > 132)and 132 or Width;
				Texture = GetTexturePiece("BlankFill",245-TexWidth,244,30,49,"ARTWORK");
				Texture:SetPoint("BOTTOMRIGHT",Parent.."BlankFillEdge","BOTTOMLEFT");
				Texture:SetPoint("TOPRIGHT",Parent.."BlankFillEdge","TOPLEFT");
				Texture:SetPoint("LEFT",Container,"RIGHT",-Width,0);
				HideObject(Parent.."BlankFillLeft");
			end
		else
			HideObject(Parent.."BlankFill");
			HideObject(Parent.."BlankFillEdge");
			HideObject(Parent.."BlankFillLeft");
		end

		-- CREATE SLOT BACKGROUNDS
		-- Width is 42, Height is 41
		local Row = 1;
		local OffsetX, OffsetY;
		for Slot = 1, Container.Slots do
			Col = Col + 1;
			if (Col > Cols) then
				Col = 1;
				Row = Row + 1;
			end
			Texture = GetTexturePiece("Slot"..Slot,118,164,213,258,"BORDER");
			OffsetX, OffsetY = -2, -2;
			Texture:SetPoint("TOPLEFT", Container, "TOPLEFT", (Col - 1) * 42 + OffsetX - 3, (Row - 1) * -41 + 2 - OffsetY);
		end
		
		-- TODO: don't know what this is for where do "to much" slots come from?
		if (Container.Slots > (TextureParent.Slots or -1)) then
			TextureParent.Slots = Container.Slots;
		else
			-- Hide extra slot textures
			for Slot = (Container.Slots + 1), TextureParent.Slots do
				_G[TextureParent:GetName().."Slot"..Slot]:Hide();
			end
		end
		
		-- Makes corner gap look better
		HideObject(Parent.."Corner");
		if (Blanks > 0) then
			local Slot = BlankTop and (Cols + 1) or (Container.Slots - Cols);
			if (Slot >= 1) or (Slot <= Container.Slots) then
				if not BlankTop then
					Texture = GetTexturePiece("Corner",154,164,248,258,"OVERLAY");
					Texture:SetPoint("BOTTOMRIGHT",Parent.."Slot"..Slot);
				else
					Texture = GetTexturePiece("Corner",118,128,213,223,"OVERLAY");
					Texture:SetPoint("TOPLEFT",Parent.."Slot"..Slot);
				end
			end
		end

		-- Adds the box for the money/slot indicators and if needed the token frame
		if (Container:GetID() == 1) then
			if (BackpackTokenFrame_IsShown() == 1 and Container:GetName() == "BaudBagContainer1_1") then
				BaudBag_DebugMsg(3, "Showing Token Frame for Container '"..Container:GetName().."' ("..Container:GetID()..")");
				-- make sure the window gets big enough and the correct texture is chosen
				Bottom = Bottom + 39;
				TextureFile = "Interface\\ContainerFrame\\UI-BackpackBackground.blp";
				TextureWidth, TextureHeight = 256, 256;
				
				-- left part of ONLY the yellow border
				Texture = GetTexturePiece("BottomFillLeft",80,84,213,231,"BACKGROUND");
				Texture:SetPoint("LEFT", Parent.."Left", "RIGHT");
				Texture:SetPoint("BOTTOM", Parent.."Bottom", "TOP", 0, 17);

				-- right part of ONLY the yellow border
				Texture = GetTexturePiece("BottomFillRight",240,244,213,231,"BACKGROUND");
				Texture:SetPoint("RIGHT", Parent.."Right", "LEFT");
				Texture:SetPoint("BOTTOM", Parent.."Bottom", "TOP", 0, 17);
				
				-- center part of ONLY the yellow border
				Texture = GetTexturePiece("BottomFillCenter",85,239,213,231,"BACKGROUND");
				Texture:SetPoint("LEFT", Parent.."BottomFillLeft", "RIGHT");
				Texture:SetPoint("RIGHT", Parent.."BottomFillRight", "LEFT");
				
				TextureFile = "Interface\\ContainerFrame\\UI-Backpack-TokenFrame.blp";
				TextureWidth, TextureHeight = 256, 32;
				local TexLeftStart, TexLeftEnd = 0, 10;
				local TexRightStart, TexRightEnd = 165, 179;
				
				Texture = GetTexturePiece("TokensFillLeft", 7, 13, 6, 24, "BACKGROUND");
				Texture:SetPoint("LEFT", Parent.."Left", "RIGHT");
				Texture:SetPoint("BOTTOM", Parent.."Bottom", "TOP", 0, -2);

				Texture = GetTexturePiece("TokensFillRight", 165, 171, 6, 24, "BACKGROUND");
				Texture:SetPoint("RIGHT", Parent.."Right", "LEFT");
				Texture:SetPoint("BOTTOM", Parent.."Bottom", "TOP", 0, -2);
				
				Texture = GetTexturePiece("TokensFillCenter", 14, 164, 6, 24, "BACKGROUND");
				Texture:SetPoint("LEFT", Parent.."TokensFillLeft", "RIGHT");
				Texture:SetPoint("RIGHT", Parent.."TokensFillRight", "LEFT");
			else
				-- make sure the window gets big enough and the correct texture is chosen
				Bottom = Bottom + 20;
				TextureFile = "Interface\\ContainerFrame\\UI-BackpackBackground.blp";
				TextureWidth, TextureHeight = 256, 256;
				
				-- left part of ONLY the yellow border
				Texture = GetTexturePiece("BottomFillLeft",80,84,213,231,"BACKGROUND");
				Texture:SetPoint("LEFT", Parent.."Left", "RIGHT");
				Texture:SetPoint("BOTTOM", Parent.."Bottom", "TOP", 0, -2);

				-- right part of ONLY the yellow border
				Texture = GetTexturePiece("BottomFillRight",240,244,213,231,"BACKGROUND");
				Texture:SetPoint("RIGHT", Parent.."Right", "LEFT");
				Texture:SetPoint("BOTTOM", Parent.."Bottom", "TOP", 0, -2);
				
				-- center part of ONLY the yellow border
				Texture = GetTexturePiece("BottomFillCenter",85,239,213,231,"BACKGROUND");
				Texture:SetPoint("LEFT", Parent.."BottomFillLeft", "RIGHT");
				Texture:SetPoint("RIGHT", Parent.."BottomFillRight", "LEFT");
			end
		end

		-- Add a picture of the bag in the circle
		Texture = _G[Parent.."Bag"];
		if not Texture then
			Texture = TextureParent:CreateTexture(Parent.."Bag");
			Texture:SetWidth(40);
			Texture:SetHeight(40);
			Texture:ClearAllPoints();
			Texture:SetPoint("TOPLEFT", Parent.."TopLeft", "TOPLEFT", 3, -3);
			Texture:SetDrawLayer("BACKGROUND");
		end
		
		local Icon;
		local BagID = Container.Bags[1]:GetID();
		if (BagID <= 0) then
			Icon = BaudBagIcons[BagID];
		elseif (Container.BagSet == 2) and not BankOpen and BaudBag_Cache[BagID].BagLink then
			Icon = GetItemIcon(BaudBag_Cache[BagID].BagLink);
		else
			Icon = GetInventoryItemTexture("player", ContainerIDToInventoryID(BagID));
		end
		
		SetPortraitToTexture(Texture, Icon or "Interface\\Icons\\INV_Misc_QuestionMark");
		Backdrop:SetBackdrop(nil);

		-- Adjust the positioning of several bag components
		_G[Container:GetName().."Name"]:SetPoint("TOPLEFT",Backdrop,"TOPLEFT",(45 + ShiftName),-7);
		_G[Container:GetName().."CloseButton"]:SetPoint("TOPRIGHT",Backdrop,"TOPRIGHT",3,3);
		TextureParent:Show();
		if (Container:GetID() == 1) then
			if (BackpackTokenFrame_IsShown() == 1 and Container:GetName() == "BaudBagContainer1_1") then
				_G[Container:GetName().."Slots"]:SetPoint("BOTTOMLEFT",Backdrop,"BOTTOMLEFT",12,26);
				_G[Container:GetName().."MoneyFrame"]:SetPoint("BOTTOMRIGHT",Backdrop,"BOTTOMRIGHT",0,26);
				_G[Container:GetName().."TokenFrame"]:SetPoint("BOTTOMRIGHT",Backdrop,"BOTTOMRIGHT",0,4);
			else
				_G[Container:GetName().."Slots"]:SetPoint("BOTTOMLEFT",Backdrop,"BOTTOMLEFT",12,7);
				_G[Container:GetName().."MoneyFrame"]:SetPoint("BOTTOMRIGHT",Backdrop,"BOTTOMRIGHT",0,6);
			end
		end
	else
		Left, Right, Top, Bottom = 8, 8, 28, 8;
		_G[Backdrop:GetName().."Textures"]:Hide();
		_G[Container:GetName().."Name"]:SetPoint("TOPLEFT",(2 + ShiftName),18);
		_G[Container:GetName().."CloseButton"]:SetPoint("TOPRIGHT",8,28);
		if (Container:GetID() == 1) then
			if (BackpackTokenFrame_IsShown() == 1  and Container:GetName() == "BaudBagContainer1_1") then
				_G[Container:GetName().."Slots"]:SetPoint("BOTTOMLEFT",2,-17);
				_G[Container:GetName().."MoneyFrame"]:SetPoint("BOTTOMRIGHT",8,-18);
				_G[Container:GetName().."TokenFrame"]:SetPoint("BOTTOMRIGHT",8,-36);
				Bottom = Bottom + 36;
			else
				_G[Container:GetName().."Slots"]:SetPoint("BOTTOMLEFT",2,-17);
				_G[Container:GetName().."MoneyFrame"]:SetPoint("BOTTOMRIGHT",8,-18);
				Bottom = Bottom + 18;
			end
		end

		if (Background == 5) then
			Backdrop:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true, tileSize = 8, edgeSize = 32,
				insets = { left = 11, right = 12, top = 12, bottom = 11 }
			});
			Left, Right, Top, Bottom = Left+8, Right+8, Top+8, Bottom+8;
			Backdrop:SetBackdropColor(0.1,0.1,0.1,1);
		else
			Backdrop:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 5, right = 5, top = 5, bottom = 5 }
			});
			Backdrop:SetBackdropColor(0,0,0,1);
		end
	end
	_G[Container:GetName().."Name"]:SetPoint("RIGHT",Container:GetName().."MenuButton","LEFT");

	Backdrop:ClearAllPoints();
	Backdrop:SetPoint("TOPLEFT",-Left,Top);
	Backdrop:SetPoint("BOTTOMRIGHT",Right,-Bottom);
	Container:SetHitRectInsets(-Left,-Right,-Top,-Bottom);
end


--This function updates the parent containers for each bag, according to the options setup
function BaudUpdateJoinedBags()
	BaudBag_DebugMsg(4, "Updating joined bags...");
	local OpenBags = {};
	for Bag = -1, LastBagID do
		OpenBags[Bag] = _G[Prefix.."SubBag"..Bag]:GetParent():IsShown();
		if OpenBags[Bag] then
			BaudBag_DebugMsg(4, "Bag open: "..Bag);
		end
	end
	
	local SubBag, Container, IsOpen, ContNum, BagID;
	local function FinishContainer()
		if IsOpen then
			BaudBag_DebugMsg(4, "Showing Container "..Container:GetName());
			Container:Show();
		else
			BaudBag_DebugMsg(4, "Hiding Container "..Container:GetName());
			Container:Hide();
		end
		BaudBagUpdateContainer(Container);
	end

	for BagSet = 1, 2 do
	ContNum = 0;
	BaudBagForEachBag(BagSet, function(Bag, Index)
		if (ContNum==0) or (BBConfig[BagSet].Joined[Index] == false) then
			if (ContNum ~= 0) then
				FinishContainer();
			end
			IsOpen = false;
			ContNum = ContNum + 1;
			if (MaxCont[BagSet] < ContNum) then
				Container = CreateFrame("Frame",Prefix.."Container"..BagSet.."_"..ContNum, UIParent, "BaudBagContainerTemplate");
				Container:SetID(ContNum);
				Container.BagSet = BagSet;
				MaxCont[BagSet] = ContNum;
			end
			Container = _G[Prefix.."Container"..BagSet.."_"..ContNum];
			Container.Bags = {};
			BaudUpdateContainerData(BagSet,ContNum);
		end
		SubBag = _G[Prefix.."SubBag"..Bag];
		tinsert(Container.Bags, SubBag);
		SubBag:SetParent(Container);
		if OpenBags[Bag]then
			IsOpen = true;
		end
	end);
	FinishContainer();

	NumCont[BagSet] = ContNum;
	--Hide extra containers that were created before
	for ContNum = (ContNum + 1), MaxCont[BagSet]do
		_G[Prefix.."Container"..BagSet.."_"..ContNum]:Hide();
	end
	end
	BagsReady = true;
end

function BaudBagUpdateOpenBags()
    BaudBag_DebugMsg(4, "[BaudBagUpdateOpenBags]");
	local Open, Frame, Highlight, Highlight2;
	--The bank bag(-1) has no open indicator
	for Bag = -1, LastBagID do
		Frame = _G[Prefix.."SubBag"..Bag];
		Open	= Frame:IsShown()and Frame:GetParent():IsShown()and not Frame:GetParent().Closing;
        -- Keyring was REMOVED as of WoW 4.2
		-- if (Bag == -2) then
			-- if Open then
				-- BaudBagKeyRingButton:SetButtonState("PUSHED", 1);
				-- KeyRingButton:SetButtonState("PUSHED", 1);
			-- else
				-- BaudBagKeyRingButton:SetButtonState("NORMAL");
				-- KeyRingButton:SetButtonState("NORMAL");
			-- end
		-- else
        if (Bag == 0) then
			MainMenuBarBackpackButton:SetChecked(Open);
		elseif(Bag > 4)then
			Highlight  = _G["BaudBBankBag"..(Bag-4).."HighlightFrameTexture"];
			Highlight2 = _G["BankFrameBag"..(Bag-4).."HighlightFrameTexture"];
			if Open then
				Highlight:Show();
				Highlight2:Show();
			else
				Highlight:Hide();
				Highlight2:Hide();
			end
		elseif(Bag > 0)then
			_G["CharacterBag"..(Bag-1).."Slot"]:SetChecked(Open);
			_G["BaudBInveBag"..(Bag-1).."Slot"]:SetChecked(Open);
		end
	end
end

--[[
	this function opens or closes a bag set (main bag with sub bags)
	BagSet (int): BagSet to open or close (1 - default bags, 2 - bank bags)
	Close (bool): should the set be closed instead of opened?
]]--
function BaudBagAutoOpenSet(BagSet, Close)
    -- debug messages:
    local closeState = Close and "true" or "false";
    BaudBag_DebugMsg(8, "[AutoOpenSet Entry] BagSet: "..BagSet.."; Close: "..closeState);
    
    --Set 2 doesn't need container 1 to be shown because that's a given
    local Container;
    for ContNum = BagSet, NumCont[BagSet] do
  
        --[[ DEBUG ]]--
        local autoOpenState = BBConfig[BagSet][ContNum].AutoOpen and "true" or "false";
        BaudBag_DebugMsg(8, "[AutoOpenSet FOR] ContNum: "..ContNum.."; AutoOpen: "..autoOpenState);
  
        if BBConfig[BagSet][ContNum].AutoOpen then
            Container = _G[Prefix.."Container"..BagSet.."_"..ContNum];
            if not Close then
                if not Container:IsShown() then
                    BaudBag_DebugMsg(8, "[AutoOpenSet FOR (IsShown)] FALSE");
                    Container.AutoOpened = true;
                    Container:Show();
                else
                    BaudBag_DebugMsg(8, "[AutoOpenSet FOR (IsShown)] TRUE");
                end
            elseif Container.AutoOpened then
                BaudBag_DebugMsg(8, "[AutoOpenSet FOR (AutoOpened)] TRUE");
				Container.AutoOpened = false;
				if BBConfig[BagSet][ContNum].AutoClose then
					BaudBag_DebugMsg(8, "[AutoOpenSet FOR (AutoOpened)] AutoClose set, hiding!");
					Container:Hide();
				else
					BaudBag_DebugMsg(8, "[AutoOpenSet FOR (AutoOpened)] AutoClose not set, ignoring hide!");
				end
            else
                BaudBag_DebugMsg(8, "[AutoOpenSet FOR (AutoOpened)] FALSE");
            end
        end
    end
end

function BaudBagCloseBagSet(BagSet)
  for ContNum = 1, MaxCont[BagSet] do
    _G[Prefix.."Container"..BagSet.."_"..ContNum]:Hide();
  end
end

--[[ backpack specific original functions ]]--
local pre_OpenBackpack = OpenBackpack;
OpenBackpack = function() 
	BaudBag_DebugMsg(8, "[OpenBackpack] called!");
	if (not BBConfig or not BBConfig[1].Enabled) then
        BaudBag_DebugMsg(8, "[OpenBackpack] somethings not right, sending to blizz-bags!");
		return pre_OpenBackpack();
	end

    OpenBag(0);
end

local pre_CloseBackpack = CloseBackpack;
CloseBackpack = function()
    BaudBag_DebugMsg(8, "[CloseBackpack] called!");
	if (not BBConfig or not BBConfig[1].Enabled) then
        BaudBag_DebugMsg(8, "[CloseBackpack] somethings not right, sending to blizz-bags!");
		return pre_CloseBackpack();
	end

    CloseBag(0);
end

local pre_ToggleBackpack = ToggleBackpack;
ToggleBackpack = function()
    BaudBag_DebugMsg(8, "[ToggleBackpack] called");
	-- make sure original is called when BaudBag is disabled for the backpack
	if (not BBConfig or not BBConfig[1].Enabled) then
        BaudBag_DebugMsg(8, "[ToggleBackpack] BaudBag disabled for inventory calling original UI");
		return pre_ToggleBackpack();
	end
	
	if not BagsReady then
		return;
	end
	
	if this and (this == FuBarPluginBagFuFrame) then
		OpenAllBags();
	else
		ToggleBag(0);
	end
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

    BaudBag_DebugMsg(8, "[ToggleBag] toggeling bag "..id.." ("..Prefix.."SubBag"..id..")");
	
    --Blizzard's stuff will automaticaly try open the bags at the mailbox and vendor.  Baud Bag will be in charge of that.
    -- BaudBag_DebugMsg(4, "[ToggleBag] self: "..self:GetName());
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
    BaudBag_DebugMsg(8, "[ToggleBag] container "..Container:GetName().." open, closing");
	Container:Hide();
    -- Hide the token bar if closing the backpack
		if ( id == 0 and BackpackTokenFrame ) then
			BackpackTokenFrame:Hide();
		end
  else
        BaudBag_DebugMsg(8, "[ToggleBag] container "..Container:GetName().." closed, opening");
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
    BaudBag_DebugMsg(8, "[OpenAllBags] called from "..((frame ~= nil) and frame:GetName() or "[none]"));
    
    -- call default bags if the addon is disabled for regular bags
    if (not BBConfig or not BBConfig[1].Enabled) then
        BaudBag_DebugMsg(8, "[OpenAllBags] sent to original frames");
        return pre_OpenAllBags(frame);
    end
  
    -- also cancel if bags can't be viewed at the moment (CAN this actually happen?)
    if not BagsReady then
        BaudBag_DebugMsg(8, "[OpenAllBags] bags not ready");
        return;
    end

    -- failsafe check as opening mail or merchant seems to instantly call OpenAllBags instead of the bags registering for the events...
    if (frame ~= nil and (frame:GetName() == "MailFrame" or frame:GetName() == "MerchantFrame")) then
        BaudBag_DebugMsg(8, "[OpenAllBags] found merchant or mail call, stopping now!");
        return;
    end
  
    local Container, AnyShown;
    for Bag = 0, 4 do
        BaudBag_DebugMsg(8, "[OpenAllBags] analyzing bag "..Bag);
        Container = _G[Prefix.."SubBag"..Bag]:GetParent();
        if (GetContainerNumSlots(Bag) > 0) and not Container:IsShown()then
            BaudBag_DebugMsg(8, "[OpenAllBags] showing bag");
            Container:Show();
--            AnyShown = true;
        end
    end

    -- if not AnyShown then
        -- BaudBag_DebugMsg(4, "[OpenAllBags] nothing opened => all opened, closing...");
        -- BaudBagCloseBagSet(1);
    -- end
end

local pre_CloseAllBags = CloseAllBags;
CloseAllBags = function(frame)
	BaudBag_DebugMsg(8, "[CloseAllBags] called from "..((frame ~= nil) and frame:GetName() or "[none]"));

	-- failsafe check as opening mail or merchant seems to instantly call OpenAllBags instead of the bags registering for the events...
    if (frame ~= nil and (frame:GetName() == "MailFrame" or frame:GetName() == "MerchantFrame")) then
        BaudBag_DebugMsg(8, "[CloseAllBags] found merchant or mail call, stopping now!");
        return;
    end

	for Bag = 0, 4 do
        BaudBag_DebugMsg(8, "[CloseAllBags] analyzing bag "..Bag);
        local Container = _G[Prefix.."SubBag"..Bag]:GetParent();
        if (GetContainerNumSlots(Bag) > 0) and Container:IsShown()then
            BaudBag_DebugMsg(8, "[CloseAllBags] hiding  bag");
            Container:Hide();
        end
    end
end
 -- 
-- function CloseAllBags()
    -- CloseBackpack();
    -- for i=1, NUM_CONTAINER_FRAMES, 1 do
        -- CloseBag(i);
    -- end
-- end

local pre_BagSlotButton_OnClick = BagSlotButton_OnClick;
BagSlotButton_OnClick = function(self, event, ...)

  if (not BBConfig or not BBConfig[1].Enabled) then
    return pre_BagSlotButton_OnClick(self, event, ...);
  end

  if not PutItemInBag(self:GetID()) then
    ToggleBag(self:GetID() - CharacterBag0Slot:GetID() + 1);
  end

end


-- Keyring was REMOVED as of WoW 4.2
-- local pre_ToggleKeyRing = ToggleKeyRing;
-- ToggleKeyRing = function(self)
  -- if BBConfig and (BBConfig[1].Enabled == false) then
    -- return pre_ToggleKeyRing();
  -- end
  -- if not BagsReady then
    -- return;
  -- end
  -- ToggleBag(-2);
-- end
 
local function IsBagShown(BagID)
  local SubBag = _G[Prefix.."SubBag"..BagID];
  return SubBag:IsShown()and SubBag:GetParent():IsShown()and not SubBag:GetParent().Closing;
end

local pre_IsBagOpen = IsBagOpen;
-- IsBagOpen = function(BagID)
function BaudBag_IsBagOpen(BagID)

    -- fallback
	if (not BBConfig or not BaudBag_BagHandledByBaudBag(BagID)) then
        BaudBag_DebugMsg(8, "BaudBag is not responsible for this bag, calling default ui");
        return pre_IsBagOpen(BagID);
    end
    
    local SubBag = _G[Prefix.."SubBag"..BagID];
    local open = SubBag and SubBag:IsShown() and SubBag:GetParent():IsShown() and not SubBag:GetParent().Closing;

    if (bagContainer) then
        BaudBag_DebugMsg(8, "[IsBagOpen] called on bag "..BagID.." with result "..tostring(open));
    end
    if (bankContainer) then
        BaudBag_DebugMsg(8, "[IsBagOpen] called on bank bag "..BagID.." with result "..tostring(open));
    end

    return open;
end

-- hooksecurefunc("IsBagOpen", BaudBag_IsBagOpen);


local function UpdateThisHighlight(self)
  if BBConfig and (BBConfig[1].Enabled == false) then
    return;
  end
  self:SetChecked(IsBagShown(self:GetID() - CharacterBag0Slot:GetID() + 1));
end

--These function hooks override the bag button highlight changes that Blizzard does
hooksecurefunc("BagSlotButton_OnClick",UpdateThisHighlight);
hooksecurefunc("BagSlotButton_OnDrag",UpdateThisHighlight);
hooksecurefunc("BagSlotButton_OnModifiedClick",UpdateThisHighlight);
hooksecurefunc("BackpackButton_OnClick",function(self)
  if BBConfig and(BBConfig[1].Enabled == false)then
    return;
  end
  self:SetChecked(IsBagShown(0));
end);

-- hooksecurefunc("UpdateMicroButtons",function()
  -- if BBConfig and (BBConfig[1].Enabled == false) then
    -- return;
  -- end
	-- if IsBagShown(KEYRING_CONTAINER)then
		-- KeyRingButton:SetButtonState("PUSHED", 1);
	-- else
		-- KeyRingButton:SetButtonState("NORMAL");
	-- end
-- end);


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
            BaudBag_DebugMsg(4, "Event BAG_UPDATE fired on BagID "..arg1.." (calling ContainerFrame_Update)");
			ContainerFrame_Update(self);
			BaudBagUpdateSubBag(self);
		else
            BaudBag_DebugMsg(4, "Event BAG_UPDATE fired on BagID "..arg1.." (refreshing)");
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
        BaudBag_DebugMsg(4, "Event BAG_CLOSED fired on BagID "..arg1.." (refreshing)");
		self:GetParent().Refresh = true;
	end
};

local Func = function(self, event, ...)
  ContainerFrame_Update(self, event, ...);
end
SubBagEvents.ITEM_LOCK_CHANGED = Func;
SubBagEvents.BAG_UPDATE_COOLDOWN = Func;
SubBagEvents.UPDATE_INVENTORY_ALERTS = Func;

--[[ xml defined (called) BaudBagSubBag event handlers ]]--
function BaudBagSubBag_OnLoad(self, event, ...)
  for Key, Value in pairs(SubBagEvents)do
    self:RegisterEvent(Key);
  end
end


function BaudBagUpdateSubBag(SubBag)
  local Name, Link, Quality, Texture, ItemButton;
  local ShowColor = BBConfig[SubBag.BagSet][SubBag:GetParent():GetID()].RarityColor;
  --local ShowColorAltern = BBConfig[SubBag.BagSet][SubBag:GetParent():GetID()].RarityColorAltern;
  SubBag.FreeSlots = 0;
  
  for Slot = 1, SubBag.size do
    Quality = nil;
    ItemButton = _G[SubBag:GetName().."Item"..Slot];
    if (SubBag.BagSet ~= 2) or BankOpen then
      Link = GetContainerItemLink(SubBag:GetID(), Slot);
      
      if (SubBag.BagSet == 2) then
        if not Link then
          BaudBag_Cache[SubBag:GetID()][Slot] = nil;
        else
          BaudBag_Cache[SubBag:GetID()][Slot] = {Link = Link, Count = select(2, GetContainerItemInfo(SubBag:GetID(), Slot))};
        end
      end
      
      if Link then
        Name, _, Quality, _, _, _, _, _, _, _ = GetItemInfo(Link);
      end
    elseif BaudBag_Cache[SubBag:GetID()][Slot]then
      Link = BaudBag_Cache[SubBag:GetID()][Slot].Link;
      SetItemButtonCount(ItemButton, BaudBag_Cache[SubBag:GetID()][Slot].Count or 0);
      if Link then
         Name, _, Quality, _, _, _, _, _, _, Texture = GetItemInfo(Link);
      else
        Texture = nil;
      end
      SetItemButtonTexture(ItemButton,Texture);
    end
    
    if not Link then
      SubBag.FreeSlots = SubBag.FreeSlots + 1;
    end
    
    -- add rarity coloring
	Texture = _G[ItemButton:GetName().."Border"];
	if Quality and (Quality > 1) and ShowColor then
		-- default with set option
		-- Texture:SetVertexColor(GetItemQualityColor(Quality));
		-- alternative rarity coloring
		if(Quality ~=2)and(Quality ~= 3)and(Quality ~= 4)then
			Texture:SetVertexColor(GetItemQualityColor(Quality));
		elseif(Quality == 2)then        --uncommon
			Texture:SetVertexColor(0.1,   1,   0, 0.5);
		elseif(Quality == 3)then        --rare
			Texture:SetVertexColor(  0, 0.4, 0.8, 0.8);
		elseif(Quality == 4)then        --epic
			Texture:SetVertexColor(0.6, 0.2, 0.9, 0.5);
		end
		Texture:Show();
    else
      Texture:Hide();
    end
    
    -- highlight the slots to show the connection to the bag
    if (SubBag.Highlight) then
		Texture:SetVertexColor(0.5, 0.5, 0, 1);
		Texture:Show();
	end
  end
end


function BaudBagSubBag_OnEvent(self, event, ...)
  if not self:GetParent():IsShown() or (self:GetID() >= 5) and not BankOpen then
    return;
  end
  SubBagEvents[event](self, event, ...);
end


function BaudBagContainerSaveCoords(Frame)
  BaudBag_DebugMsg(4, "Saving container coords: "..Frame:GetName());
  local Scale = Frame:GetScale();
  local X, Y = Frame:GetCenter();
  X = X * Scale;
  Y = Y * Scale;
  BBConfig[Frame.BagSet][Frame:GetID()].Coords = {X, Y};
end


local TotalFree, TotalSlots;

local function AddFreeSlots(Bag)
  if (Bag<=-1) then
    return;
  end
  local Cache = BaudBagUseCache(Bag);
  local NumSlots;
  if not Cache then
    local Free, Family = GetContainerNumFreeSlots(Bag);
    if (Family ~= 0) then
      return;
    end
    TotalFree = TotalFree + Free;
    NumSlots = GetContainerNumSlots(Bag);
  else
    if(Bag > 0)then
      local Link = BaudBag_Cache[Bag].BagLink;
      if not Link or(GetItemFamily(Link)~=0)then
        return;
      end
    end
    NumSlots = BaudBag_Cache[Bag].Size;
    for Slot = 1, NumSlots do
      if not BaudBag_Cache[Bag][Slot]then
        TotalFree = TotalFree + 1;
      end
    end
  end
  TotalSlots = TotalSlots + NumSlots;
end


function BaudBagUpdateFreeSlots(Frame)
  Frame.UpdateSlots = nil;
  BaudBag_DebugMsg(4, "Counting free slots for set "..Frame.BagSet);
  TotalFree, TotalSlots = 0, 0;
  if(Frame.BagSet==1)then
    for Bag = 0, 4 do
      AddFreeSlots(Bag);
    end
  else
    AddFreeSlots(-1);
    for Bag = 5, LastBagID do
      AddFreeSlots(Bag);
    end
  end
  _G[Frame:GetName().."Slots"]:SetText(TotalFree.."/"..TotalSlots..Localized.Free);
end


function BaudBagBankBags_Update()
  local Purchase = BaudBagBankSlotPurchaseFrame;
  local Slots, Full = GetNumBankSlots();
  local BagSlot;
  
  BaudBag_DebugMsg(5, "BankBags: updating");

  for Bag = 1, NUM_BANKBAGSLOTS do
    BagSlot = _G["BaudBBankBag"..Bag];

    if (Bag <= Slots) then
      SetItemButtonTextureVertexColor(BagSlot, 1.0, 1.0, 1.0);
      BagSlot.tooltipText = BANK_BAG;
    else
      SetItemButtonTextureVertexColor(BagSlot, 1.0, 0.1, 0.1);
      BagSlot.tooltipText = BANK_BAG_PURCHASE;
    end
  end

	local BBContainer2 = _G[Prefix.."Container2_1BagsFrame"];

  if Full then
	BaudBag_DebugMsg(5, "BankBags: all bags bought hiding purchase button");
    Purchase:Hide();
    BBContainer2:SetHeight(BBContainer2.Height);
    return;
  end

  local Cost = GetBankSlotCost(Slots);
  BaudBag_DebugMsg(5, "BankBags: buyable bag slots left, currentCost = "..Cost);

  -- This line allows the confirmation box to show the cost
  BankFrame.nextSlotCost = Cost;

  if (GetMoney() >= Cost) then
    -- SetMoneyFrameColor(Purchase:GetName().."MoneyFrame", 1.0, 1.0, 1.0);
    SetMoneyFrameColor(Purchase:GetName().."MoneyFrame");
  else
    SetMoneyFrameColor(Purchase:GetName().."MoneyFrame", "red");
  end
  MoneyFrame_Update(Purchase:GetName().."MoneyFrame", Cost);

  Purchase:Show();
  BBContainer2:SetHeight(BBContainer2.Height + 40);
end


--This is for the button that toggles the bank bag display
function BaudBagBagsButton_OnClick(self, event, ...)
  local Set = self:GetParent().BagSet;
  --Bank set is automaticaly shown, and main bags are not
  BBConfig[Set].ShowBags = (BBConfig[Set].ShowBags==false);
  BaudBagUpdateBagFrames();
end


function BaudBagUpdateBagFrames()
  local Shown, BagFrame;
  for BagSet = 1, 2 do
    Shown = (BBConfig[BagSet].ShowBags ~= false);
    _G[Prefix.."Container"..BagSet.."_1BagsButton"]:SetChecked(Shown);
    BagFrame = _G[Prefix.."Container"..BagSet.."_1BagsFrame"];
    if Shown then
      BagFrame:Show();
    else
      BagFrame:Hide();
    end
  end
end


function BaudBagUpdateName(Container)
  local Name = _G[Container:GetName().."Name"];
  if (Container.BagSet ~= 2) or BankOpen then
    Name:SetText(BBConfig[Container.BagSet][Container:GetID()].Name or "");
    Name:SetTextColor(NORMAL_FONT_COLOR.r,NORMAL_FONT_COLOR.g,NORMAL_FONT_COLOR.b);
  else
    Name:SetText(BBConfig[Container.BagSet][Container:GetID()].Name..Localized.Offline);
    Name:SetTextColor(RED_FONT_COLOR.r,RED_FONT_COLOR.g,RED_FONT_COLOR.b);
  end
end

function BaudBagUpdateContainer(Container)
  BaudBag_DebugMsg(4, "Updating Container: "..Container:GetName());
  Container.Refresh = false;
  BaudBagUpdateName(Container);
  local SlotLevel = Container:GetFrameLevel() + 1;
  local ContCfg = BBConfig[Container.BagSet][Container:GetID()];
  local Background = ContCfg.Background;
  local MaxCols = ContCfg.Columns;
  local Size, KeyRing;
  Container.Slots = 0;
  -- calculate sizes in all subbags
  for _, SubBag in ipairs(Container.Bags)do
  
		-- process inventory, bank only if it is open
    if (Container.BagSet ~= 2) or BankOpen then
      Size = GetContainerNumSlots(SubBag:GetID());
      
        -- Keyring was REMOVED as of WoW 4.2
      -- -- process keyring
      -- if (SubBag:GetID() == -2) then
        -- local LastUsed = 0;
        -- local FirstEmpty;
        -- 
        -- for Slot = 1, Size do
          -- if GetContainerItemLink(-2, Slot) then
            -- LastUsed = Slot;
          -- elseif not FirstEmpty then
            -- FirstEmpty = Slot;
          -- end
        -- end
        -- 
        -- if FirstEmpty and (LastUsed < Size) then
          -- KeyRing = SubBag;
          -- local Max = Size;
          -- Size = max(FirstEmpty, LastUsed);
          -- KeyRing.Expandable = Max - Size;
        -- end
      -- end
      
      -- process bank
      if (Container.BagSet == 2) then
        -- Clear out excess information if the size of a bag decreases
        if (BaudBag_Cache[SubBag:GetID()].Size > Size)then
          for Slot = Size, BaudBag_Cache[SubBag:GetID()].Size do
            if BaudBag_Cache[SubBag:GetID()][Slot]then
              BaudBag_Cache[SubBag:GetID()][Slot] = nil;
            end
          end
        end
        BaudBag_Cache[SubBag:GetID()].Size = Size;
      end
    else
      Size = BaudBag_Cache[SubBag:GetID()]and BaudBag_Cache[SubBag:GetID()].Size or 0;
    end
    
    SubBag.size = Size;
    Container.Slots = Container.Slots + Size;
  end
  
  -- how can this happen?
  if(Container.Slots <= 0)then
    if Container:IsShown() then
      DEFAULT_CHAT_FRAME:AddMessage("Container \""..ContCfg.Name.."\" has no contents.",1,1,0);
      Container:Hide();
    end
    return;
  end
  
  if (Container.Slots < MaxCols) then
    MaxCols = Container.Slots;
  -- elseif KeyRing and (Container.Slots % MaxCols ~= 0) then
    -- local Increase = min(KeyRing.Expandable, MaxCols - Container.Slots % MaxCols);
    -- KeyRing.size = KeyRing.size + Increase;
    -- Container.Slots = Container.Slots + Increase;
  end

  local Col, Row = 0, 1;
  --The textured background puts its empty space on the upper left
  if ContCfg.BlankTop then
    Col = MaxCols - mod(Container.Slots - 1,MaxCols) - 1;
  end

  local Slots, SubBag, ItemButton;
  for _, SubBag in pairs(Container.Bags)do
    if (SubBag.size <= 0) then
      SubBag:Hide();
    else
      BaudBag_DebugMsg(4, "Adding "..SubBag:GetName());
      -- Create extra slots if needed
      if (SubBag.size > (SubBag.maxSlots or 0)) then
        for Slot = (SubBag.maxSlots or 0) + 1, SubBag.size do
					-- what the fug is THIS in the last argument???
          local Button = CreateFrame("Button", SubBag:GetName().."Item"..Slot, SubBag, (SubBag:GetID() ~= -1) and "ContainerFrameItemButtonTemplate" or "BankItemButtonGenericTemplate");
          Button:SetID(Slot);
          local Texture = Button:CreateTexture(Button:GetName().."Border","OVERLAY");
          Texture:Hide();
          Texture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border");
          Texture:SetPoint("CENTER");
          Texture:SetBlendMode("ADD");
          Texture:SetAlpha(0.8);
          Texture:SetHeight(70);
          Texture:SetWidth(70);
        end
        SubBag.maxSlots = SubBag.size;
      end
      
      if (SubBag:GetID() ~= -1) and (BankOpen or(SubBag:GetID() < 5)) then
        ContainerFrame_Update(SubBag);
      end
      
      BaudBagUpdateSubBag(SubBag);
      for Slot = 1, SubBag.maxSlots do
        ItemButton = _G[SubBag:GetName().."Item"..Slot];
        if(Slot <= SubBag.size)then
          Col = Col + 1;
          if(Col > MaxCols)then
            Col = 1;
            Row = Row + 1;
          end
          ItemButton:ClearAllPoints();
          --Slot spacing is different for the blizzard textured background
          if (Background <= 3) then
            ItemButton:SetPoint("TOPLEFT", Container, "TOPLEFT", (Col-1)*42, (Row-1)*-41);
          else
            ItemButton:SetPoint("TOPLEFT", Container, "TOPLEFT", (Col-1)*39, (Row-1)*-39);
          end
          ItemButton:SetFrameLevel(SlotLevel);
          ItemButton:Show();
        else
          ItemButton:Hide();
        end
      end
      SubBag:Show();
    end
  end
  
  if (Background <= 3) then
    Container:SetWidth(MaxCols * 42 - 5);
    Container:SetHeight(Row * 41 - 4);
  else
    Container:SetWidth(MaxCols * 39 - 2);
    Container:SetHeight(Row * 39 - 2);
  end
  
  BaudBagUpdateBackground(Container);
  BaudBag_DebugMsg(4, "Finished Arranging Container.");
end


function BaudBag_OnModifiedClick(self, button)
	if not BaudBagUseCache(self:GetParent():GetID()) then
		return;
	end

	if IsModifiedClick("SPLITSTACK")then
		StackSplitFrame:Hide();
	end

	if BaudBag_Cache[self:GetParent():GetID()][self:GetID()] then
		HandleModifiedItemClick(BaudBag_Cache[self:GetParent():GetID()][self:GetID()].Link);
	end
end


hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", BaudBag_OnModifiedClick);
hooksecurefunc("BankFrameItemButtonGeneric_OnModifiedClick", BaudBag_OnModifiedClick);

-- Keyring was REMOVED as of WoW 4.2
-- function BaudBagKeyRing_OnLoad(self, event, ...)
  -- local Clone = KeyRingButton;
  -- Clone:GetScript("OnLoad")(self);
  -- self:SetScript("OnClick", Clone:GetScript("OnClick"));
  -- self:SetScript("OnReceiveDrag", Clone:GetScript("OnReceiveDrag"));
  -- self:SetScript("OnEnter", Clone:GetScript("OnEnter"));
  -- self:SetScript("OnLeave", Clone:GetScript("OnLeave"));
  -- self:GetNormalTexture():SetTexCoord(0.5625,0,0,0,0.5625,0.60937,0,0.60937);
  -- self:GetHighlightTexture():SetTexCoord(0.5625,0,0,0,0.5625,0.60937,0,0.60937);
  -- self:GetPushedTexture():SetTexCoord(0.5625,0,0,0,0.5625,0.60937,0,0.60937);
-- end

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
		-- now make sure the bag names are up to date
		-- for Container = 1, 
		-- BaudBagUpdateName(_G[Prefix.."Container"..BagSet.."_"..SelectedContainer]);
	end
end


function BaudBagSearchButton_Click(self, event, ...)
	-- get references to all needed frames and data
	local SearchFrame	= _G[Prefix.."SearchFrame"];
	local Container		= self:GetParent();
	local Scale			= BBConfig[Container.BagSet][Container:GetID()].Scale / 100;
	local Background	= BBConfig[Container.BagSet][Container:GetID()].Background;
	local Backdrop		= _G[SearchFrame:GetName().."Backdrop"];
	local EditBox		= _G[SearchFrame:GetName().."EditBox"];
	local BagSearchHeightOffset = 0;
	local BagSearchHeight		= 20;
	
	-- remember the element the search frame is attached to
	SearchFrame.AttachedTo = Container:GetName();
	
	-- draw the background depending on the containers background
	--Backdrop:SetFrameLevel(SearchFrame:GetFrameLevel());
	local Left, Right, Top, Bottom;
	
	-- these are the default blizz-frames
	if (Background <= 3) then
	
		Left, Right, Top, Bottom	= 10, 10, 25, 7;
		BagSearchHeightOffset		= 22;
		local Parent	= Backdrop:GetName().."Textures";
		TextureParent	= _G[Parent];
		TextureParent:SetFrameLevel(SearchFrame:GetFrameLevel());
		local Texture;
		
		-- choose the correct texture file with correct sizes
		TextureFile = "Interface\\ContainerFrame\\UI-Bag-Components";
		if (Background == 2) then
			TextureFile = TextureFile.."-Bank";
		elseif (Background == 3)then
			TextureFile = TextureFile.."-Keyring";
		end
		TextureWidth, TextureHeight = 256, 512;

		-- --------------------------
		-- create new textures now
		-- --------------------------
		-- BORDERS FIRST
		-- transparent circle top left
		Texture = GetTexturePiece("Left", 106, 117, 5, 30,"ARTWORK");
		Texture:SetPoint("TOPLEFT");

		-- right end of header + transparent piece for close button (with or without blank part on the bottom)
		Texture = GetTexturePiece("Right", 223, 252, 5, 30,"ARTWORK");
		Texture:SetPoint("TOPRIGHT");

		-- container header (contains name, with or without blank part on the bottom)
		Texture = GetTexturePiece("Center", 117, 222, 5, 30,"ARTWORK");
		Texture:SetPoint("TOP");
		Texture:SetPoint("RIGHT", Parent.."Right", "LEFT");
		Texture:SetPoint("LEFT", Parent.."Left", "RIGHT");

		-- fix positions of some elements
		_G[SearchFrame:GetName().."CloseButton"]:SetPoint("TOPRIGHT",Backdrop,"TOPRIGHT",3,3);
		_G[SearchFrame:GetName().."EditBox"]:SetPoint("TOPLEFT", -1, 18);
		
		-- make sure the backdrop of "else" is removed and the texture is actually shown
		Backdrop:SetBackdrop(nil);
		TextureParent:Show();
	else
		Left, Right, Top, Bottom = 8, 8, 8, 8;
		BagSearchHeightOffset = 32;
		BagSearchHeight	= 12;
		_G[Backdrop:GetName().."Textures"]:Hide();
		_G[SearchFrame:GetName().."CloseButton"]:SetPoint("TOPRIGHT", 9, 10);
		_G[SearchFrame:GetName().."EditBox"]:SetPoint("TOPLEFT", -1, 0);
		
		-- "solid"
		if (Background == 5) then
			Backdrop:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true, tileSize = 8, edgeSize = 32,
				insets = { left = 11, right = 12, top = 12, bottom = 11 }
			});
			Left, Right, Top, Bottom = Left+8, Right+8, Top+8, Bottom+8;
			BagSearchHeightOffset = BagSearchHeightOffset + 8;
			Backdrop:SetBackdropColor(0.1, 0.1, 0.1, 1);
		-- "transparent"
		else
			Backdrop:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 14, edgeSize = 14,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }
			});
			Backdrop:SetBackdropColor(0.0, 0.0, 0.0, 1.0);
		end
	end
	
	-- correct the sizes depending on the frame backdrop
	Backdrop:ClearAllPoints();
	Backdrop:SetPoint("TOPLEFT", -Left, Top);
	Backdrop:SetPoint("BOTTOMRIGHT", Right, -Bottom);
	SearchFrame:SetHitRectInsets(-Left, -Right, -Top, -Bottom);
	
	-- position the frame above the calling container
	SearchFrame:SetPoint("BOTTOMLEFT", self:GetParent(), "TOPLEFT", 0, BagSearchHeightOffset);
	SearchFrame:SetPoint("RIGHT", self:GetParent(), "RIGHT");
	SearchFrame:SetHeight(BagSearchHeight);
	
	-- make sure the frame lies on the same lvl as the calling container
	SearchFrame:SetFrameLevel(self:GetParent():GetFrameLevel());
	Backdrop:SetFrameLevel(SearchFrame:GetFrameLevel());
	_G[SearchFrame:GetName().."CloseButton"]:SetFrameLevel(SearchFrame:GetFrameLevel()+1);
	_G[SearchFrame:GetName().."EditBox"]:SetFrameLevel(SearchFrame:GetFrameLevel()+1);
	
	-- adjust the scaling according to the calling container
	SearchFrame:SetScale(Scale);
	
	-- finally show it
	BaudBagSearchFrame:Show();
	BaudBagSearchFrameEditBox:SetFocus();
end

function BaudBagSearchFrame_CheckClose(caller)
	BaudBag_DebugMsg(6, "Checking if searchframe needs to be closed:");
	if (BaudBagSearchFrame:IsVisible()) then
		BaudBag_DebugMsg(6, caller:GetName().." "..BaudBagSearchFrame.AttachedTo);
		local isSelf		= (caller:GetName() == BaudBagSearchFrame:GetName());
		local isAttached	= (caller:GetName() == BaudBagSearchFrame.AttachedTo);
		local isClosed		= _G[BaudBagSearchFrame.AttachedTo].Closing or (not _G[BaudBagSearchFrame.AttachedTo]:IsVisible());
		local selfString	 = isSelf and "true" or "false";
		local attachedString = isAttached and "true" or "false";
		local closedString	 = isClosed and "true" or "false";
		
		BaudBag_DebugMsg(6, selfString.." "..attachedString.." "..closedString);
		if (isSelf or (isAttached and isClosed)) then
			BaudBagSearchFrame:Hide();
		end
	end
end

--[[
	if the SearchFrame is hidden the search text and any existing search markers needs to be cleared
 ]]--
function BaudBagSearchFrame_OnHide(self, event, ...)
	_G[self:GetName().."EditBox"]:SetText("");
	BaudBagSearchFrame.AttachedTo = nil;
	BaudBagSearchFrameEditBox_RemoveHighlights();
end

function BaudBagSearchFrameEditBox_OnTextChanged(self, isUserInput)
	BaudBag_DebugMsg(6, "Changed search phrase, researching open bags");
	local compareString = _G[Prefix.."SearchFrameEditBox"]:GetText();
	
	-- check search text for validity
	if (false) then
		-- TODO!!!a
		return
	end
	
	-- go through all bags to find the open ones
	local SubBag, Frame, Open, ItemButton, Link, Name, Texture;
	local Status, Result;
	for Bag = -1, LastBagID do
		SubBag = _G[Prefix.."SubBag"..Bag];
		Open	= SubBag:IsShown()and SubBag:GetParent():IsShown() and not SubBag:GetParent().Closing;
		
		-- if the bag is open go through its items and compare the itemname
		if (Open) then
			BaudBag_DebugMsg(6, "Bag '"..Bag.."' is open, going through items");
			BagsSearched[Bag] = true;
		
			for Slot = 1, SubBag.size do
				ItemButton = _G[SubBag:GetName().."Item"..Slot];
				
				-- get item link according to the type of bag
				if (SubBag.BagSet ~= 2) or BankOpen then
					Link = GetContainerItemLink(SubBag:GetID(), Slot);
				elseif BaudBag_Cache[SubBag:GetID()][Slot] then
					Link = BaudBag_Cache[SubBag:GetID()][Slot].Link;
				end
				
				-- get the name for that link
				if Link then
					-- debug message
					printableLink = gsub(Link, "\124", "\124\124");
					BaudBag_DebugMsg(6, "Found a link: '"..printableLink.."'");

					-- we can have different types of links, usually it is an item...
					if (strmatch(Link, "|Hitem:")) then
						Name, _, _, _, _, _, _, _, _, _ = GetItemInfo(Link);

					-- ... or a cages battle pet ...
					elseif (strmatch(Link, "|Hbattlepet:")) then
						local _, speciesID, _, _, _, _, _, battlePetID = strsplit(":", Link)
						Name, _, _, _, _, _, _, _, _, _= C_PetJournal.GetPetInfoBySpeciesID(speciesID);

					-- ... we don't know about everything else
					else
						Name = "Unknown";
					end
				end
				
				-- add transparency if search active but not a result
				Texture = ItemButton;
				if (Link and compareString ~= "") then
					BaudBag_DebugMsg(6, "Searching for String: '"..compareString.."' in Item '"..Name.."'");
					
					-- first run string search and go through results later (because of error handling)
					Status, Result = pcall(string.find, string.lower(Name), string.lower(compareString));
					
					-- find was run successfull: act depending on result
					if (Status) then
						--if (string.find(string.lower(Name), string.lower(compareString)) == nil) then
						if (Result == nil) then
							BaudBag_DebugMsg(6, "Itemname does not match");
							Texture:SetAlpha(0.2);
						else
							BaudBag_DebugMsg(6, "Item seems to match");
							Texture:SetAlpha(1);
						end
					-- find failed, create debug message
					else
						BaudBag_DebugMsg(6, "current search creates problem: ("..Result..")");
						return;
					end
				else
					Texture:SetAlpha(1);
				end
			end
		end
	end
end

function BaudBagSearchFrameEditBox_RemoveHighlights()
	local SubBag, Frame, Open, ItemButton, Link, Name, Texture;
	for Bag = -1, LastBagID do
		if (BagsSearched[Bag]) then
			SubBag = _G[Prefix.."SubBag"..Bag];
			for Slot = 1, SubBag.size do
				ItemButton = _G[SubBag:GetName().."Item"..Slot];
				ItemButton:SetAlpha(1);
			end
			BagsSearched[Bag] = false;
		end
	end
end

--[[ if the mouse hovers over the bag slot item the slots belonging to this bag should be shown after a certain time (atm 350ms or 0.35s) ]]
function BaudBag_BagSlot_OnEnter(self, event, ...)
	BaudBag_DebugMsg(7, "Mouse is hovering above item");
	self.HighlightBag		= true;
	self.HighlightBagOn		= false;
	self.HighlightBagCount	= GetTime() + 0.35;
end

--[[ determine if and how long the mouse was hovering and change bag according ]]
function BaudBag_BagSlot_OnUpdate(self, event, ...)
	if (self.HighlightBag and (not self.HighlightBagOn) and GetTime() >= self.HighlightBagCount) then
		BaudBag_DebugMsg(7, "showing item '"..self:GetName().."'");
		self.HighlightBagOn	= true;
		local SubBag		= _G[Prefix.."SubBag"..self.Bag];
		SubBag.Highlight	= true;
		BaudBagUpdateSubBag(SubBag);
	end
end

--[[ if the mouse was removed cancel all actions ]]
function BaudBag_BagSlot_OnLeave(self, event, ...)
	BaudBag_DebugMsg(7, "Mouse not hovering above item anymore");
	self.HighlightBag		= false;
	
	if (self.HighlightBagOn) then
		self.HighlightBagOn	= false;
		local SubBag		= _G[Prefix.."SubBag"..self.Bag];
		SubBag.Highlight	= false;
		BaudBagUpdateSubBag(SubBag);
	end
	
end

-- TODO: this HAS to stay temporary! the whole addon needs an overhaul according to the recent changes in the official bag code!!!

--[[ this usually only applies to inventory bags ]]--
local pre_ToggleAllBags = ToggleAllBags;
ToggleAllBags = function()
    BaudBag_DebugMsg(8, "[ToggleAllBags] called");

    if (not BBConfig or not BBConfig[1].Enabled) then
        BaudBag_DebugMsg(8, "[ToggleAllBags] no config found or addon deactivated for inventory, calling original");
        return pre_ToggleAllBags();
    end

    BaudBag_DebugMsg(8, "[ToggleAllBags] BaudBag bags are active, close & open");
        
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
    BaudBag_DebugMsg(8, "[OpenBag] called on id: "..id);
	
	-- if there is no baud bag config we most likely do not work correctly => send to original bag frames
    if (not BBConfig or not BaudBag_BagHandledByBaudBag(id)) then
		BaudBag_DebugMsg(8, "[OpenBag] no config or bag not handled by BaudBag, calling original");
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
    BaudBag_DebugMsg(8, "[CloseBag] called on id: "..id);
    if (not BBConfig or not BaudBag_BagHandledByBaudBag(id)) then
		BaudBag_DebugMsg(8, "[CloseBag] no config or bag not handled by BaudBag, calling original");
        return pre_CloseBag(id);
    end

    -- if (IsBagOpen(id)) then
    if (BaudBag_IsBagOpen(id)) then
        local Container = _G[Prefix.."SubBag"..id]:GetParent();
        Container:Hide();
    end
end
