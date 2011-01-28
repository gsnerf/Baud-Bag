-- Author      : gsnerf
-- Create Date : 10/30/2010 10:13:36 PM
local Localized	= BaudBagLocalized;
local MaxBags		= NUM_BANKBAGSLOTS + 1;
local Prefix		= "BaudBagOptions";
local Updating, CfgBackup;

local SelectedBags			= 1;
local SelectedContainer	= 1;
local SetSize						= {6, NUM_BANKBAGSLOTS + 1};

local SliderBars = {
	{Text=Localized.Columns,	Low="2",	High="20",		SavedVar="Columns",	Default={8,12},			TooltipText = Localized.ColumnsTooltip},
	{Text=Localized.Scale,	Low="50%",	High="200%",	SavedVar="Scale",		Default={100,100},	TooltipText = Localized.ScaleTooltip}
};

local CheckButtons = {
	{Text=Localized.AutoOpen,	SavedVar="AutoOpen",	Default=false,	TooltipText=Localized.AutoOpenTooltip},
	{Text=Localized.BlankOnTop,	SavedVar="BlankTop",	Default=false,	TooltipText=Localized.BlankOnTopTooltip},
	{Text=Localized.RarityColoring,	SavedVar="RarityColor",	Default=true,	TooltipText=Localized.RarityColoringTooltip}
};

BaudBagIcons = {
  [0]	= "Interface\\Buttons\\Button-Backpack-Up",
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

--[[
	Needed functions:
		- option window loaded => set all basic control settings and add dynamic components
		- bagset changed (dropdown event) => load bags, choose first container (see next point)
		- selected container changed => load container specific data
							(name, background, columns, scaling, autoopen, empty spaces on top, rarity coloring)
]]--

--[[ BaudBagOptions frame related events and methods ]]--
function BaudBagOptions_OnLoad(self, event, ...)
	BaudBagSetCfgPreReq(SliderBars, CheckButtons);
	self:RegisterEvent("ADDON_LOADED");
end

function BaudBagOptions_OnEvent(self, event, ...)
	local arg1 = ...;
	if ((event ~= "ADDON_LOADED") or (arg1 ~= "BaudBag")) then return; end
	-- make sure there is a BBConfig
	BaudBagRestoreCfg();
	CfgBackup	= BaudBagCopyTable(BBConfig);
	
	-- add to options windows
	self.name			= "Baud Bag";
	self.okay			= BaudBagOptions_OnOkay;
	self.cancel			= BaudBagOptions_OnCancel;
	self.refresh		= BaudBagOptions_OnRefresh;
	InterfaceOptions_AddCategory(self);
	
	-- set localized labels
	BaudBagOptionsTitle:SetText("Baud Bag "..Localized.Options);
	BaudBagOptionsVersionText:SetText("(v"..GetAddOnMetadata("BaudBag","Version")..")");
	BaudBagOptionsSetDropDownLabel:SetText(Localized.BagSet);
	BaudBagOptionsNameEditBoxText:SetText(Localized.ContainerName);
	BaudBagOptionsBackgroundDropDownLabel:SetText(Localized.Background);
	BaudBagOptionsEnabledCheckText:SetText(Localized.Enabled);
	BaudBagOptionsEnabledCheck.tooltipText  = Localized.EnabledTooltip;
	BaudBagOptionsCloseAllCheckText:SetText(Localized.CloseAll);
	BaudBagOptionsCloseAllCheck.tooltipText = Localized.CloseAllTooltip;
	
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
	
	-- some slash command settings
	SlashCmdList[Prefix..'_SLASHCMD'] = function() InterfaceOptionsFrame_OpenToCategory(self); end
	_G["SLASH_"..Prefix.."_SLASHCMD1"] = '/baudbag';
	_G["SLASH_"..Prefix.."_SLASHCMD2"] = '/bb';
	DEFAULT_CHAT_FRAME:AddMessage(Localized.AddMessage);

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
	
	-- make sure the view is updated with the data loaded from the config
	BaudBagOptionsUpdate();
end

function BaudBagOptions_OnRefresh(self, event, ...)
	BaudBag_DebugMsg(2, "OnRefresh was called!");
	BaudBagOptionsUpdate();
end

function BaudBagOptions_OnOkay(self, event, ...)
	BaudBag_DebugMsg(2, "'Okay' pressed, saving BBConfig.");
	CfgBackup = BBConfig;
	BaudBagSaveCfg(BBConfig);
end

function BaudBagOptions_OnCancel(self, event, ...)
	BaudBag_DebugMsg(2, "'Cancel' pressed, reset to last BBConfig.");
	BBConfig = CfgBackup;
	ReloadConfigDependant();
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
    BaudBagCloseBagSet(SelectedBags); -- TODO: move to BaudBagConfig save?
  end
  BBConfig[SelectedBags].Enabled = (self:GetChecked() == 1);
  if BBConfig and (BBConfig[2].Enabled == true) then BankFrame:UnregisterEvent("BANKFRAME_OPENED") end -- TODO: move to BaudBagBBConfig save?
  if BBConfig and (BBConfig[2].Enabled == false) then BankFrame:RegisterEvent("BANKFRAME_OPENED") end -- TODO: move to BaudBagBBConfig save?
  BackpackTokenFrame_Update();
end


--[[ CloseAll CheckBox functions ]]--
function BaudBagCloseAllCheck_OnClick(self, event, ...)
	if(self:GetChecked())then
    PlaySound("igMainMenuOptionCheckBoxOff");
  else
    PlaySound("igMainMenuOptionCheckBoxOn");
  end
  BBConfig[SelectedBags].CloseAll = (self:GetChecked() == 1);
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
  
  BBConfig[SelectedBags].Joined[self:GetID()] = self:GetChecked() and true or false;
  local ContNum = 2;
  for Bag = 2,(self:GetID()-1)do
    if (BBConfig[SelectedBags].Joined[Bag] == false) then
      ContNum = ContNum + 1;
    end
  end
  if self:GetChecked()then
    tremove(BBConfig[SelectedBags],ContNum);
  else
    tinsert(BBConfig[SelectedBags], ContNum, BaudBagCopyTable(BBConfig[SelectedBags][ContNum-1]));
  end
  BaudBagOptionsUpdate();
  BaudUpdateJoinedBags();
end


--[[ Name TextBox functions ]]--
function BaudBagOptionsNameEditBox_OnTextChanged()
  if Updating then
    return;
  end
  BBConfig[SelectedBags][SelectedContainer].Name = _G[Prefix.."NameEditBox"]:GetText();
  BaudBagUpdateName(_G["BaudBagContainer"..SelectedBags.."_"..SelectedContainer]);  -- TODO: move to BaudBagBBConfig save?
end



--[[ Background Dropdown functions ]]--
-- init
function BaudBagOptionsBackgroundDropDown_Initialize()
  local info			= UIDropDownMenu_CreateInfo();
  info.func				= BaudBagOptionsBackgroundDropDown_OnClick;
  local Selected	= BBConfig[SelectedBags][SelectedContainer].Background;

  for Key, Value in pairs(TextureNames)do
    info.text			= Value;
    info.value		= Key;
    info.checked	= (Key == Selected) and 1 or nil;
    UIDropDownMenu_AddButton(info);
  end
end

-- onclick
function BaudBagOptionsBackgroundDropDown_OnClick(self)
  BBConfig[SelectedBags][SelectedContainer].Background = self.value;
  UIDropDownMenu_SetSelectedValue(BaudBagOptionsBackgroundDropDown, self.value);
  BaudBagUpdateContainer(_G["BaudBagContainer"..SelectedBags.."_"..SelectedContainer]); -- TODO: move to BaudBagBBConfig save?
end


--[[ CheckBox (non "enabled") functions ]]--
function BaudBagOptionsCheckButton_OnClick(self, event, ...)
  if(self:GetChecked())then
    PlaySound("igMainMenuOptionCheckBoxOff");
  else
    PlaySound("igMainMenuOptionCheckBoxOn");
  end
  local SavedVar = CheckButtons[self:GetID()].SavedVar;
  BBConfig[SelectedBags][SelectedContainer][SavedVar] = (self:GetChecked() == 1);
  if (SavedVar == "BlankTop") or (SavedVar == "RarityColor") then -- or (SavedVar == "RarityColorAltern") then
		BaudBag_DebugMsg(2, "Want to update container: "..Prefix.."Container"..SelectedBags.."_"..SelectedContainer);
    BaudBagUpdateContainer(_G["BaudBagContainer"..SelectedBags.."_"..SelectedContainer]); -- TODO: move to BaudBagBBConfig save?
  end
end


--[[ slider functions ]]--
function BaudBagSlider_OnValueChanged(self)
--[[
	This is called when the value of a slider is changed.
	First the new value directly shown in the title.
	Next the new value is saved in the correct BBConfig entry.
]]--

  -- change appearance
  _G[self:GetName().."Text"]:SetText(format(SliderBars[self:GetID()].Text,self:GetValue()));
  
  -- TODO: find out why this check is necessary
  if Updating then
    return;
  end
  
  -- save BBConfig entry
  local SavedVar = SliderBars[self:GetID()].SavedVar;
  BBConfig[SelectedBags][SelectedContainer][SavedVar] = self:GetValue();
  
  -- cause the appropriate update  -- TODO: move to BaudBagBBConfig save?
  if (SavedVar == "Scale") then
    BaudUpdateContainerData(SelectedBags, SelectedContainer);
  elseif (SavedVar=="Columns") then
    BaudBagUpdateContainer(_G["BaudBagContainer"..SelectedBags.."_"..SelectedContainer]);
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
	_G[Prefix.."EnabledCheck"]:SetChecked(BBConfig[SelectedBags].Enabled~=false);
	_G[Prefix.."CloseAllCheck"]:SetChecked(BBConfig[SelectedBags].CloseAll~=false);

	-- load bag specific options (position and show each button that belongs to the current set,
	--		check joined box and create container frames)
	BaudBagForEachBag(SelectedBags,
		function(Bag,Index)
			Button	= _G[Prefix.."Bag"..Index];
			Check	= _G[Prefix.."JoinCheck"..Index];

			if (Index == 1) then
				-- only the first bag needs its position set, since the others are anchored to it
				Button:SetPoint("LEFT", BaudBagOptions, "TOP", (Bags / 2) * -44,-140);
			else
				-- all bags after the first may have a joined state
				Check:SetChecked(BBConfig[SelectedBags].Joined[Index]~=false);
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
  
  -- load container name into the textbox
  _G[Prefix.."NameEditBox"]:SetText(BBConfig[SelectedBags][SelectedContainer].Name or "test");
  _G[Prefix.."NameEditBox"]:SetCursorPosition(0);

	-- load background state (initialized here to work around some strange behavior)
	UIDropDownMenu_Initialize(_G[Prefix.."BackgroundDropDown"], BaudBagOptionsBackgroundDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(_G[Prefix.."BackgroundDropDown"], BBConfig[SelectedBags][SelectedContainer].Background);
 
  for Key, Value in ipairs(SliderBars)do
    local Slider = _G[Prefix.."Slider"..Key];
    Slider:SetValue(BBConfig[SelectedBags][SelectedContainer][Value.SavedVar]);
  end

  for Key, Value in ipairs(CheckButtons)do
    local Button = _G[Prefix.."CheckButton"..Key];
    Button:SetChecked(BBConfig[SelectedBags][SelectedContainer][Value.SavedVar]);
  end
  Updating = false;
end

function BaudBagOptionsSelectContainer(BagSet, Container)
	SelectedBags = BagSet;
	SelectedContainer = Container;
	BaudBagOptionsUpdate();
end