-- Author      : gsnerf
-- Create Date : 10/30/2010 10:13:36 PM
local Localized	= BaudBagLocalized;
local MaxBags		= NUM_BANKBAGSLOTS + 1;
local Prefix		= "BaudBagOptions";
local Config;

local SelectedBags			= 1;
local SelectedContainer	= 1;
local SetSize						= {6, NUM_BANKBAGSLOTS + 1};


local SliderBars = {
	{Text=Localized.Columns,	Low="2",	High="20",	SavedVar="Columns",	Default={8,12},		TooltipText = Localized.ColumnsTooltip},
	{Text=Localized.Scale,	Low="50%",	High="200%",	SavedVar="Scale",	Default={100,100},	TooltipText = Localized.ScaleTooltip}
};

local CheckButtons = {
	{Text=Localized.AutoOpen,	SavedVar="AutoOpen",	Default=false,	TooltipText=Localized.AutoOpenTooltip},
	{Text=Localized.BlankOnTop,	SavedVar="BlankTop",	Default=false,	TooltipText=Localized.BlankOnTopTooltip},
	{Text=Localized.RarityColoring,	SavedVar="RarityColor",	Default=true,	TooltipText=Localized.RarityColoringTooltip}
};

local BaudBagIcons = {
  [0]		= "Interface\\Buttons\\Button-Backpack-Up",
  [-1]	= "Interface\\Icons\\INV_Box_02",
  [-2]	= "Interface\\ContainerFrame\\KeyRing-Bag-Icon"
};

local TextureNames = {
	Localized.BlizInventory,
	Localized.BlizBank,
	Localized.BlizKeyring,
	Localized.Transparent,
	Localized.Solid
};

local BaudBag_Debug = true;

local function BaudBag_DebugMsg(msg)
  if BaudBag_Debug then
    DEFAULT_CHAT_FRAME:AddMessage(msg);
  end
end

--[[
	Needed functions:
		- option window loaded => set all basic control settings and add dynamic components
		- bagset changed (dropdown event) => load bags, choose first container (see next point)
		- selected container changed => load container specific data
							(name, background, columns, scaling, autoopen, empty spaces on top, rarity coloring)
]]--

--[[ BaudBagOptions frame related events and methods ]]--
function BaudBagOptions_OnLoad(self, event, ...)
	-- make sure there is a config
	BaudBagRestoreCfg();
	
	-- add to options windows
	self.name = "Baud Bag";
	InterfaceOptions_AddCategory(self);
	
	-- set localized labels
	BaudBagOptionsTitle:SetText("Baud Bag "..Localized.Options);
	BaudBagOptionsVersionText:SetText("(v"..GetAddOnMetadata("BaudBag","Version")..")");
	BaudBagOptionsSetDropDownLabel:SetText(Localized.BagSet);
	BaudBagOptionsNameEditBoxText:SetText(Localized.ContainerName);
	BaudBagOptionsBackgroundDropDownLabel:SetText(Localized.Background);
	BaudBagOptionsEnabledCheckText:SetText(Localized.Enabled);
	BaudBagOptionsEnabledCheck.tooltipText = Localized.EnabledTooltip;
	
	-- localized checkbox labels
	for Key, Value in ipairs(CheckButtons) do
		_G[Prefix.."CheckButton"..Key.."Text"]:SetText(Value.Text);
		_G[Prefix.."CheckButton"..Key].tooltipText = Value.TooltipText;
	end

	-- set slider bounds
	for Key, Value in ipairs(SliderBars) do
		_G[Prefix.."Slider"..Key.."Low"]:SetText(Value.Low);
		_G[Prefix.."Slider"..Key.."High"]:SetText(Value.High);
		_G[Prefix.."Slider"..Key].tooltipText = Value.TooltipText;
	end
	
	-- init dropdowns (does not change while playing)
	
	-- needed?
	self:RegisterEvent("PLAYER_LOGIN");
	self:RegisterEvent("ADDON_LOADED");
	-- SlashCmdList[Prefix.."_Options"] = function() BaudBagOptionsFrame:Show();end
	-- SLASH_BaudBag_Options1 = "/baudbag";
	-- SLASH_BaudBag_OptionsMenuName = "Baud Bag"; --Baud Menu Info
	-- DEFAULT_CHAT_FRAME:AddMessage(Localized.AddMessage);

	--[[
		create stubs for all possibly needed bag buttons:
			1. create bag button
			2. create container frame
			3. create join checkbox if bag > 1
	]]--
	local Button, Container, Check;
	for Bag = 1, MaxBags do
		Button		= CreateFrame("CheckButton",	Prefix.."Bag"..Bag, BaudBagOptions, Prefix.."BagTemplate");
		Container	= CreateFrame("Frame", Prefix.."Container"..Bag, BaudBagOptions, Prefix.."ContainerTemplate");
		if(Bag == 1)then
			-- first bag only has a container
			Container:SetPoint("LEFT", _G[Prefix.."Bag1"], "LEFT", -6, 0);
		else
			-- all other bags also have a button to mark joins with the previous bags
			Button:SetPoint("LEFT", Prefix.."Bag"..(Bag-1), "RIGHT", 8, 0);
			Check = CreateFrame("CheckButton", Prefix.."JoinCheck"..Bag, Button, Prefix.."JoinCheckTemplate");
			Check:SetPoint("BOTTOM", Button, "TOPLEFT", -4, 4);
			Check:SetID(Bag);
			Check.tooltipText = Localized.CheckTooltip;
		end
	end
end

function BaudBagOptions_OnShow(self, event, ...)
	-- CfgBackup = CopyTable(Config);
	-- self.SaveChanges = false;
	BaudBagOptionsUpdate();
end

function BaudBagOptionsFrame_OnHide(self, event, ...)
  -- if(self.SaveChanges==false)and CfgBackup then
    -- DebugMsg("Restoring config from backup.");
    -- self.SaveChanges = true;
    -- BaudBag_Cfg = CfgBackup;
    -- BaudBagRestoreCfg();
  -- end
  -- CfgBackup = nil;
end


--[[ SetBags DropDown functions ]]--
function BaudBagOptionsSetDropDown_Initialize()
	-- prepare dropdown entries
  local info		= UIDropDownMenu_CreateInfo();
  info.func			= BaudBagOptionsSetDropDown_OnClick;

	-- inventory set
  info.text			= Localized.Inventory;
  info.value		= 1;
  info.checked	= (info.value == SelectedBags) and 1 or nil;
  UIDropDownMenu_AddButton(info);

	-- bank set
  info.text			= Localized.BankBox;
  info.value		= 2;
  info.checked	= (info.value == SelectedBags) and 1 or nil;
  UIDropDownMenu_AddButton(info);
end

function BaudBagOptionsSetDropDown_OnClick(self)
	SelectedBags = self.value;
	BaudBagOptionsUpdate();
end


--[[ Enabled CheckBox functions ]]--
function BaudBagEnabledCheck_OnClick(self, event, ...)
	if(self:GetChecked())then
    PlaySound("igMainMenuOptionCheckBoxOff");
  else
    PlaySound("igMainMenuOptionCheckBoxOn");
    --BaudBagCloseBagSet(SelectedBags);
  end
  Config[SelectedBags].Enabled = (self:GetChecked() == 1);
  --if Config and (Config[2].Enabled == true) then BankFrame:UnregisterEvent("BANKFRAME_OPENED") end
  --if Config and (Config[2].Enabled == false) then BankFrame:RegisterEvent("BANKFRAME_OPENED") end
end


--[[ Dynamic Bags/Container Clicks ]]--
function BaudBagOptionsBag_OnClick(self, event, ...)
  SelectedContainer = self:GetID();
  BaudBagOptionsUpdate();
end

function BaudBagOptionsJoinCheck_OnClick(self, event, ...)
  if (self:GetChecked()) then
    PlaySound("igMainMenuOptionCheckBoxOff");
  else
    PlaySound("igMainMenuOptionCheckBoxOn");
  end
  
  Config[SelectedBags].Joined[self:GetID()] = self:GetChecked() and true or false;
  local ContNum = 2;
  for Bag = 2,(self:GetID()-1)do
    if (Config[SelectedBags].Joined[Bag] == false) then
      ContNum = ContNum + 1;
    end
  end
  if self:GetChecked()then
    tremove(Config[SelectedBags],ContNum);
  else
    tinsert(Config[SelectedBags],ContNum,CopyTable(Config[SelectedBags][ContNum-1]));
  end
  BaudBagOptionsUpdate();
  --BaudUpdateJoinedBags();
  --Newly created bags could "Jump" infront of the options frame
  --BaudBagOptions:Raise();
end


--[[ Name TextBox functions ]]--
function BaudBagOptionsNameEditBox_OnTextChanged()
  if Updating then
    return;
  end
  Config[SelectedBags][SelectedContainer].Name = _G[Prefix.."NameEditBox"]:GetText();
  --BaudBagUpdateName(_G["BBCont"..SelectedBags.."_"..SelectedContainer]);
end



--[[ Background Dropdown functions ]]--
-- init
function BaudBagOptionsBackgroundDropDown_Initialize()
  local info			= UIDropDownMenu_CreateInfo();
  info.func				= BaudBagOptionsBackgroundDropDown_OnClick;
  local Selected	= Config[SelectedBags][SelectedContainer].Background;

  for Key, Value in pairs(TextureNames)do
    info.text			= Value;
    info.value		= Key;
    info.checked	= (Key == Selected) and 1 or nil;
    UIDropDownMenu_AddButton(info);
  end
end

-- onclick
function BaudBagOptionsBackgroundDropDown_OnClick(self)
  Config[SelectedBags][SelectedContainer].Background = self.value;
  UIDropDownMenu_SetSelectedValue(BaudBagOptionsBackgroundDropDown, self.value);
  --BaudBagUpdateContainer(_G["BBCont"..SelectedBags.."_"..SelectedContainer]);
end


--[[ CheckBox (non "enabled") functions ]]--
function BaudBagOptionsCheckButton_OnClick(self, event, ...)
  if(self:GetChecked())then
    PlaySound("igMainMenuOptionCheckBoxOff");
  else
    PlaySound("igMainMenuOptionCheckBoxOn");
  end
  local SavedVar = CheckButtons[self:GetID()].SavedVar;
  Config[SelectedBags][SelectedContainer][SavedVar] = (self:GetChecked() == 1);
  if (SavedVar == "BlankTop") or (SavedVar == "RarityColor") then
    --BaudBagUpdateContainer(_G["BBCont"..SelectedBags.."_"..SelectedContainer]);
  end
end


--[[ slider functions ]]--
function BaudBagSlider_OnValueChanged(self)
--[[
	This is called when the value of a slider is changed.
	First the new value directly shown in the title.
	Next the new value is saved in the correct config entry.
]]--

  -- change appearance
  _G[self:GetName().."Text"]:SetText(format(SliderBars[self:GetID()].Text,self:GetValue()));
  
  -- TODO: find out why this check is necessary
  if Updating then
    return;
  end
  
  -- save config entry
  local SavedVar = SliderBars[self:GetID()].SavedVar;
  Config[SelectedBags][SelectedContainer][SavedVar] = self:GetValue();
  
  -- cause the appropriate update
  -- if(SavedVar=="Scale")then
    -- BaudUpdateContainerData(SelectedBags,SelectedContainer);
  -- elseif(SavedVar=="Columns")then
    -- BaudBagUpdateContainer(_G["BBCont"..SelectedBags.."_"..SelectedContainer]);
  -- end
end



--[[ This function takes a set of bags and a function, and then applies the function to each bag of the set ]]--
function BaudBagForEachBag(BagSet,Func)
  if(BagSet==1)then
    for Bag = 1, 5 do
      Func(Bag - 1, Bag);
    end
    Func(-2, 6);
  else
    Func(-1, 1);
    for Bag = 1, NUM_BANKBAGSLOTS do
      Func(Bag + 4, Bag + 1);
    end
  end
end


function BaudBagOptionsUpdate()
	-- prepare vars
  local Button, Check, Container, Texture;
  local ContNum = 1;
  local Bags = SetSize[SelectedBags];
  Updating = true;

	-- first reload the drop down (weird problems if not done)
	UIDropDownMenu_Initialize(_G[Prefix.."SetDropDown"], BaudBagOptionsSetDropDown_Initialize);
  UIDropDownMenu_SetSelectedValue(_G[Prefix.."SetDropDown"], SelectedBags);
  
	-- is the box enabled
  _G[Prefix.."EnabledCheck"]:SetChecked(Config[SelectedBags].Enabled~=false);

	-- load bag specific options (position and show each button that belongs to the current set,
	--		check joined box and create container frames)
  BaudBagForEachBag(SelectedBags,
		function(Bag,Index)
			Button	= _G[Prefix.."Bag"..Index];
			Check		= _G[Prefix.."JoinCheck"..Index];

			if (Index == 1) then
				-- only the first bag needs its position set, since the others are anchored to it
				Button:SetPoint("LEFT", BaudBagOptions, "TOP", (Bags / 2) * -44,-140);
			else
				-- all bags after the first may have a joined state
				Check:SetChecked(Config[SelectedBags].Joined[Index]~=false);
				if not Check:GetChecked()then
					-- if not joined the last container needs to be aligned to the last bag and the current container needs to start here
					_G[Prefix.."Container"..ContNum]:SetPoint("RIGHT", Prefix.."Bag"..(Index - 1), "RIGHT", 6,0);
					ContNum = ContNum + 1;
					_G[Prefix.."Container"..ContNum]:SetPoint("LEFT", Prefix.."Bag"..Index, "LEFT", -6,0);
				end
			end
			
			-- try to find out which bag texture to use
			if BaudBagIcons[Bag]then
				Texture = BaudBagIcons[Bag];
			elseif(SelectedBags == 1)then
				Texture = GetInventoryItemTexture("player",ContainerIDToInventoryID(Bag));
			elseif BaudBag_Cache[Bag] and BaudBag_Cache[Bag].BagLink then
				Texture = GetItemIcon(BaudBag_Cache[Bag].BagLink);
			else
				Texture = nil;
			end
			
			-- assign texture, id and get item to be shown
			_G[Button:GetName().."IconTexture"]:SetTexture(Texture or select(2,GetInventorySlotInfo("Bag0Slot")));
			Button:SetID(ContNum);
			Button:Show();
		end
	);
  _G[Prefix.."Container"..ContNum]:SetPoint("RIGHT", Prefix.."Bag"..Bags,"RIGHT",6,0);

	-- make sure all bags after the last visible bag to be shown is hidden (e.g. the inventory has less bags then the bank)
  for Index = Bags + 1, MaxBags do
    _G[Prefix.."Bag"..Index]:Hide();
  end

	-- it must be made sure an existing container is selected
  if (SelectedContainer > ContNum) then
    SelectedContainer = 1;
  end
  
  -- mark currently selected bags and container or reset the markings
  -- (checked-state for buttons and border for container)
  local R, G, B;
  for Bag = 1, MaxBags do
    Container	= _G[Prefix.."Container"..Bag];
    Button		= _G[Prefix.."Bag"..Bag];
    Button:SetChecked(Button:GetID()==SelectedContainer);
    if(Bag <= ContNum)then
      if(Bag==SelectedContainer)then
        Container:SetBackdropColor(1,1,0);
        Container:SetBackdropBorderColor(1,1,0);
      else
        Container:SetBackdropColor(1,1,1);
        Container:SetBackdropBorderColor(1,1,1);
      end
      Container:Show();
    else
      Container:Hide();
    end
  end
  
  -- load textbox name (TODO: does not work on first load, why?)
  _G[Prefix.."NameEditBox"]:SetText(Config[SelectedBags][SelectedContainer].Name or "test");
  _G[Prefix.."NameEditBox"]:SetCursorPosition(0);

	-- load background state (initialized here to work around some strange behavior)
	UIDropDownMenu_Initialize(_G[Prefix.."BackgroundDropDown"], BaudBagOptionsBackgroundDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(_G[Prefix.."BackgroundDropDown"], Config[SelectedBags][SelectedContainer].Background);
 
  for Key, Value in ipairs(SliderBars)do
    local Slider = _G[Prefix.."Slider"..Key];
    Slider:SetValue(Config[SelectedBags][SelectedContainer][Value.SavedVar]);
  end

  for Key, Value in ipairs(CheckButtons)do
    local Button = _G[Prefix.."CheckButton"..Key];
    Button:SetChecked(Config[SelectedBags][SelectedContainer][Value.SavedVar]);
  end
  Updating = false;
end


-- config related stuff
function BaudBagRestoreCfg()
  --BaudBag_DebugMsg("Restoring config structure.");
  
  if (type(BaudBag_Cfg)~="table") then BaudBag_Cfg = {}; end
  Config = BaudBag_Cfg;
  
  for BagSet = 1, 2 do
	-- BaudBag_DebugMsg("Checking for consistent BagSet ("..BagSet..")");
    if (type(Config[BagSet]) ~= "table") then
		Config[BagSet] = {};
	end
    if (type(Config[BagSet].Enabled) ~= "boolean") then
		Config[BagSet].Enabled = true;
    end
    if (type(Config[BagSet].Joined) ~= "table") then
		Config[BagSet].Joined = {};
    end
    if (type(Config[BagSet].ShowBags) ~= "boolean") then
		Config[BagSet].ShowBags = ((BagSet == 2) and true or false);
	end
    
    local Container = 0;
    BaudBagForEachBag(BagSet, function(Bag, Index)
      if (Bag == -2) and (Config[BagSet].Joined[Index] == nil) then
        Config[BagSet].Joined[Index] = false;
      end
      if (Container == 0) or (Config[BagSet].Joined[Index] == false) then
        Container = Container + 1;
        if(type(Config[BagSet][Container])~="table")then
          if(Container == 1)or(Bag==-2)then
            Config[BagSet][Container] = {};
          else
            Config[BagSet][Container] = CopyTable(Config[BagSet][Container-1]);
          end
        end
        if not Config[BagSet][Container].Name then
          --With the key ring, there isn't enough room for the player name aswell
          Config[BagSet][Container].Name = (Bag==-2)and Localized.KeyRing or UnitName("player")..Localized.Of..((BagSet==1)and Localized.Inventory or Localized.BankBox);
        end
        if(type(Config[BagSet][Container].Background)~="number")then
          Config[BagSet][Container].Background = (Bag==-2)and 3 or 1;
        end
        for Key, Value in ipairs(SliderBars)do
          if(type(Config[BagSet][Container][Value.SavedVar])~="number")then
            Config[BagSet][Container][Value.SavedVar] = (Bag==-2)and(Value.SavedVar=="Columns")and 4 or Value.Default[BagSet];
          end
        end
        for Key, Value in ipairs(CheckButtons)do
          if(type(Config[BagSet][Container][Value.SavedVar])~="boolean")then
            Config[BagSet][Container][Value.SavedVar] = Value.Default;
          end
        end
      end
    end);
  end

  --BaudUpdateJoinedBags();
  --BaudBagUpdateBagFrames();
  --BaudBagOptionsUpdate();
end


--This function updates misc. options for a bag
-- function BaudUpdateContainerData(BagSet, ContNum)
  -- local Container = _G["BBCont"..BagSet.."_"..ContNum];
  -- BaudBag_DebugMsg("Updating container data: "..Container:GetName());
  -- _G[Container:GetName().."Name"]:SetText(Config[BagSet][ContNum].Name or "");
  -- local Scale = Config[BagSet][ContNum].Scale / 100;
  -- Container:SetScale(Scale);
  -- if not Config[BagSet][ContNum].Coords then
    -- --BaudBagContainerSaveCoords(Container);
  -- end
  -- Container:ClearAllPoints();
  -- local X, Y = unpack(Config[BagSet][ContNum].Coords);
  -- Container:SetPoint("CENTER",UIParent,"BOTTOMLEFT",(X / Scale), (Y / Scale));
-- end


-- function BaudBagOptions_Defaults()
  -- DebugMsg("Setting default config.");
  -- BaudBag_Cfg = nil;
  -- BaudBagRestoreCfg();
-- end
-- 
-- 