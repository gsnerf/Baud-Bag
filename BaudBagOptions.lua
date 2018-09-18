local AddOnName, AddOnTable = ...
local _

local Localized	= BaudBagLocalized;
local MaxBags   = NUM_BANKBAGSLOTS + 2;
local Prefix    = "BaudBagOptions";
local Updating  = false
local CfgBackup

local SelectedBags      = 1;
local SelectedContainer = 1;
local SetSize           = {5, NUM_BANKBAGSLOTS + 2};

local GlobalSliderBars = {
    --{ Text=Localized.RarityIntensity, Low=0.5, High=2.5, Step=0.1, SavedVar="RarityIntensity", Default=1, TooltipText = Localized.RarityIntensityTooltip},
    { Text=Localized.RarityIntensity, Low=0.5, High=2.5, Step=0.1, SavedVar="RarityIntensity", Default=1, TooltipText=Localized.RarityIntensityTooltip, DependsOn="RarityColor" },
}

local ContainerSliderBars = {
    {Text=Localized.Columns,	Low="2",	High="40",		Step=1,		SavedVar="Columns",		Default={8,14},		TooltipText = Localized.ColumnsTooltip},
    {Text=Localized.Scale,		Low="50%",	High="200%",	Step=1,		SavedVar="Scale",		Default={100,100},	TooltipText = Localized.ScaleTooltip}
};

local GlobalCheckButtons = {
    {Text=Localized.ShowNewItems,   SavedVar="ShowNewItems", Default=true,  TooltipText=Localized.ShowNewItemsTooltip,      DependsOn=nil,  CanBeSet=true,                      UnavailableText = "" },
    {Text=Localized.SellJunk,       SavedVar="SellJunk",     Default=false, TooltipText=Localized.SellJunkTooltip,          DependsOn=nil,  CanBeSet=true,                      UnavailableText = "" },
    {Text=Localized.UseMasque,      SavedVar="UseMasque",    Default=false, TooltipText=Localized.UseMasqueTooltp,          DependsOn=nil,  CanBeSet=IsAddOnLoaded("Masque"),   UnavailableText = Localized.UseMasqueUnavailable},
    {Text=Localized.RarityColoring, SavedVar="RarityColor",  Default=true,  TooltipText=Localized.RarityColoringTooltip,    DependsOn=nil,  CanBeSet=true,                      UnavailableText = "" },
}

local ContainerCheckButtons = {
    {Text=Localized.AutoOpen,       SavedVar="AutoOpen",     Default=false, TooltipText=Localized.AutoOpenTooltip,          DependsOn=nil},
    {Text=Localized.AutoClose,      SavedVar="AutoClose",    Default=true,  TooltipText=Localized.AutoCloseTooltip,         DependsOn="AutoOpen"},
    {Text=Localized.BlankOnTop,     SavedVar="BlankTop",     Default=false, TooltipText=Localized.BlankOnTopTooltip,        DependsOn=nil},
};

BaudBagIcons = {
    [0]	    = "Interface\\Buttons\\Button-Backpack-Up",
    [-1]	= "Interface\\Icons\\INV_Box_02",
    [-2]	= "Interface\\ContainerFrame\\KeyRing-Bag-Icon",
    [-3]	= "Interface\\Icons\\INV_MISC_CAT_TRINKET05"
};

local TextureNames = {
    Localized.BlizInventory,
    Localized.BlizBank,
    Localized.BlizKeyring,
    Localized.Transparent,
    Localized.Solid,
    Localized.Transparent2
};

--[[
    Needed functions:
    - option window loaded => set all basic control settings and add dynamic components
    - bagset changed (dropdown event) => load bags, choose first container (see next point)
    - selected container changed => load container specific data
    (name, background, columns, scaling, autoopen, empty spaces on top, rarity coloring)
  ]]

--[[ BaudBagOptions frame related events and methods ]]
function BaudBagOptions_OnLoad(self, event, ...)
    -- the config needs a reference to this
    BaudBagSetCfgPreReq(GlobalSliderBars, ContainerSliderBars, GlobalCheckButtons, ContainerCheckButtons);
    self:RegisterEvent("ADDON_LOADED");
end

--[[ All actual processing needs to be done after we are sure we have a config to load from! ]]
function BaudBagOptions_OnEvent(self, event, ...)

    -- failsafe: we only want to handle the addon loaded event
    local arg1 = ...;
    if ((event ~= "ADDON_LOADED") or (arg1 ~= "BaudBag")) then return; end

    -- make sure there is a BBConfig and a cache
    AddOnTable:InitCache()
    BaudBagRestoreCfg();
    ConvertOldConfig();
    CfgBackup	= BaudBagCopyTable(BBConfig);
	
    -- add to options windows
    self.name			= "Baud Bag";
    self.okay			= BaudBagOptions_OnOkay;
    self.cancel			= BaudBagOptions_OnCancel;
    self.refresh		= BaudBagOptions_OnRefresh;
    InterfaceOptions_AddCategory(self);
	
    -- set localized labels
    self.Title:SetText("Baud Bag "..Localized.Options);
    self.Version:SetText("(v"..GetAddOnMetadata("BaudBag","Version")..")");

    self.GroupContainer.SetSelection.Label:SetText(Localized.BagSet);
    self.GroupContainer.NameInput.Text:SetText(Localized.ContainerName);
    self.GroupContainer.BackgroundSelection.Label:SetText(Localized.Background);
    self.GroupContainer.EnabledCheck.tooltipText  = Localized.EnabledTooltip;
    self.GroupContainer.CloseAllCheck.tooltipText = Localized.CloseAllTooltip;
    BaudBagOptionsGroupContainerEnabledCheckText:SetText(Localized.Enabled);
    BaudBagOptionsGroupContainerCloseAllCheckText:SetText(Localized.CloseAll);
    self.GroupContainer.EnabledCheck:SetHitRectInsets(0, -BaudBagOptionsGroupContainerEnabledCheckText:GetWidth()-10, 0, 0);
    self.GroupContainer.CloseAllCheck:SetHitRectInsets(0, -BaudBagOptionsGroupContainerCloseAllCheckText:GetWidth()-10, 0, 0);

    -- localized global checkbox labels
    local GroupGlobal = self.GroupGlobal;
    for Key, Value in ipairs(GlobalCheckButtons) do
        local checkButton = GroupGlobal["CheckButton"..Key]
        local checkButtonText = _G[Prefix.."GroupGlobalCheckButton"..Key.."Text"]

        checkButtonText:SetText(Value.Text)
        checkButton.tooltipText = Value.TooltipText

        if (not Value.CanBeSet) then
            checkButton:Disable()
            checkButtonText:SetFontObject("GameFontDisable")
            checkButtonText:SetText(Value.Text.." ("..Value.UnavailableText..")")
        end
    end
    for Key, Value in ipairs(GlobalSliderBars) do
        _G[Prefix.."GroupGlobalSlider"..Key.."Low"]:SetText(Value.Low);
        _G[Prefix.."GroupGlobalSlider"..Key.."High"]:SetText(Value.High);
        _G[Prefix.."GroupGlobalSlider"..Key].tooltipText = Value.TooltipText;
        _G[Prefix.."GroupGlobalSlider"..Key].valueStep = Value.Step;
    end
    
    -- localized checkbox labels
    for Key, Value in ipairs(ContainerCheckButtons) do
        _G[Prefix.."GroupContainerCheckButton"..Key.."Text"]:SetText(Value.Text);
        _G[Prefix.."GroupContainerCheckButton"..Key].tooltipText = Value.TooltipText;
    end

    -- set slider bounds
    for Key, Value in ipairs(ContainerSliderBars) do
        _G[Prefix.."GroupContainerSlider"..Key.."Low"]:SetText(Value.Low);
        _G[Prefix.."GroupContainerSlider"..Key.."High"]:SetText(Value.High);
        _G[Prefix.."GroupContainerSlider"..Key].tooltipText = Value.TooltipText;
        _G[Prefix.."GroupContainerSlider"..Key].valueStep = Value.Step;
    end
	
    -- some slash command settings
    SlashCmdList[Prefix..'_SLASHCMD'] = function() 
        -- double call is needed to work around what seems to be a bug in blizzards code...
        InterfaceOptionsFrame_OpenToCategory(self)
        InterfaceOptionsFrame_OpenToCategory(self)
    end
    _G["SLASH_"..Prefix.."_SLASHCMD1"] = '/baudbag';
    _G["SLASH_"..Prefix.."_SLASHCMD2"] = '/bb';
    DEFAULT_CHAT_FRAME:AddMessage(Localized.AddMessage);

    --[[
        create stubs for all possibly needed bag buttons:
        1. create bag button
        2. create container frame
        3. create join checkbox if bag > 1
      ]]
    local Button, Container, Check;
    for Bag = 1, MaxBags do
        Button		= CreateFrame("CheckButton",    Prefix.."Bag"..Bag,         BaudBagOptions.GroupContainer.BagFrame, Prefix.."BagTemplate");
        Container	= CreateFrame("Frame",          Prefix.."Container"..Bag,   BaudBagOptions.GroupContainer.BagFrame, Prefix.."ContainerTemplate");
        if (Bag == 1) then
            -- first bag only has a container
            Container:SetPoint("LEFT", _G[Prefix.."Bag1"], "LEFT", -6, 0);
        else
            -- all other bags also have a button to mark joins with the previous bags
            Button:SetPoint("LEFT", Prefix.."Bag"..(Bag-1), "RIGHT", 8, 0);
            Check = CreateFrame("CheckButton", Prefix.."JoinCheck"..Bag, Button, Prefix.."JoinCheckTemplate");
            Check:SetPoint("BOTTOM", Button, "TOPLEFT", -4, 4);
            Check:SetID(Bag);
            Check.tooltipText = Localized.CheckTooltip;

            if (Bag == MaxBags) then
                Check:SetChecked(false);
                Check:Disable();
                Check:Hide();
            end
        end
    end
	
    -- make sure the view is updated with the data loaded from the config
    BaudBagOptionsUpdate();
end

function BaudBagOptions_OnRefresh(self, event, ...)
    BaudBag_DebugMsg("Options", "OnRefresh was called!");
    BaudBagOptionsUpdate();
end

function BaudBagOptions_OnOkay(self, event, ...)
    BaudBag_DebugMsg("Options", "'Okay' pressed, saving BBConfig.");
    CfgBackup = BBConfig;
    BaudBagSaveCfg(BBConfig);
end

function BaudBagOptions_OnCancel(self, event, ...)
    BaudBag_DebugMsg("Options", "'Cancel' pressed, reset to last BBConfig.");
    BBConfig = CfgBackup;
    ReloadConfigDependant();
end


--[[ SetBags DropDown functions ]]
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


--[[ BagSet specific CheckBox functions ]]

function BaudBagEnabledCheck_OnClick(self, event, ...)
    PlayCheckBoxSound(self);
    if (not self:GetChecked()) then
        BaudBagCloseBagSet(SelectedBags); -- TODO: move to BaudBagConfig save?
    end

    BBConfig[SelectedBags].Enabled = (self:GetChecked());
    -- TODO: move to BaudBagBBConfig save?
    if BBConfig and (BBConfig[2].Enabled == true) then BankFrame:UnregisterEvent("BANKFRAME_OPENED"); end
    if BBConfig and (BBConfig[2].Enabled == false) then BankFrame:RegisterEvent("BANKFRAME_OPENED"); end
    BackpackTokenFrame_Update();
end

function BaudBagCloseAllCheck_OnClick(self, event, ...)
    PlayCheckBoxSound(self);
    BBConfig[SelectedBags].CloseAll = self:GetChecked();
end

function BaudBagSellJunkCheck_OnClick(self, event, ...)
    if (SelectedBags == 1) then
        PlayCheckBoxSound(self);
        BBConfig[SelectedBags].SellJunk = self:GetChecked();
    end
end


--[[ Dynamic Bags/Container Clicks ]]
function BaudBagOptionsBag_OnClick(self, event, ...)
    SelectedContainer = self:GetID();
    BaudBagOptionsUpdate();
end

function BaudBagOptionsJoinCheck_OnClick(self, event, ...)
    PlayCheckBoxSound(self)

    BBConfig[SelectedBags].Joined[self:GetID()] = self:GetChecked() and true or false
    local ContNum = 2
    for Bag = 2,(self:GetID()-1) do
        if (BBConfig[SelectedBags].Joined[Bag] == false) then
            ContNum = ContNum + 1
        end
    end
    if self:GetChecked() then
        tremove(BBConfig[SelectedBags], ContNum)
    else
        tinsert(BBConfig[SelectedBags], ContNum, BaudBagCopyTable(BBConfig[SelectedBags][ContNum-1]))
    end
    BaudBagOptionsUpdate()
    BaudUpdateJoinedBags()
end

function PlayCheckBoxSound(self)
    if (self:GetChecked()) then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
end

--[[ Name TextBox functions ]]
function BaudBagOptionsNameEditBox_OnTextChanged()
    if Updating then
        return;
    end
    -- BBConfig[SelectedBags][SelectedContainer].Name = _G[Prefix.."NameEditBox"]:GetText();
    BBConfig[SelectedBags][SelectedContainer].Name = BaudBagOptions.GroupContainer.NameInput:GetText();
    AddOnTable["Sets"][SelectedBags].Containers[SelectedContainer]:UpdateName() -- TODO: move to BaudBagBBConfig save?
end



--[[ Background Dropdown functions ]]
-- init
function BaudBagOptionsBackgroundDropDown_Initialize()
    local info			= UIDropDownMenu_CreateInfo();
    info.func			= BaudBagOptionsBackgroundDropDown_OnClick;
    local Selected		= BBConfig[SelectedBags][SelectedContainer].Background;
	
    for Key, Value in pairs(TextureNames)do
        info.text		= Value;
        info.value		= Key;
        info.checked	= (Key == Selected) and 1 or nil;
        UIDropDownMenu_AddButton(info);
    end
end

-- onclick
function BaudBagOptionsBackgroundDropDown_OnClick(self)
    BBConfig[SelectedBags][SelectedContainer].Background = self.value;
    UIDropDownMenu_SetSelectedValue(BaudBagOptions.GroupContainer.BackgroundSelection, self.value);
    BaudBagUpdateContainer(_G["BaudBagContainer"..SelectedBags.."_"..SelectedContainer]); -- TODO: move to BaudBagBBConfig save?
end


--[[ CheckBox (non "enabled") functions ]]
function BaudBagOptionsCheckButton_OnClick(self, event, ...)
    -- make the apropriate sound
    PlaySound(self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    
    -- apply change based on group
    local SavedVar;
    if (self:GetParent() == BaudBagOptions.GroupGlobal) then
        SavedVar = GlobalCheckButtons[self:GetID()].SavedVar;
        BaudBag_DebugMsg("Options", "Update global variable: "..SavedVar);
        BBConfig[SavedVar] = self:GetChecked();

        if (SavedVar == "RarityColor") then
            BaudBagForEachOpenContainer(
                function (container)
                    container:Update()
                end
            )
        end
    else
        SavedVar = ContainerCheckButtons[self:GetID()].SavedVar;
        BaudBag_DebugMsg("Options", "Update container variable: "..SavedVar);
        BBConfig[SelectedBags][SelectedContainer][SavedVar] = self:GetChecked();

        -- make sure options who need it (visible things) update the affected container
        if (SavedVar == "BlankTop") or (SavedVar == "RarityColor") then -- or (SavedVar == "RarityColorAltern") then
            BaudBag_DebugMsg("Options", "Want to update container: "..Prefix.."Container"..SelectedBags.."_"..SelectedContainer);
            BaudBagUpdateContainer(_G["BaudBagContainer"..SelectedBags.."_"..SelectedContainer]); -- TODO: move to BaudBagBBConfig save?
        end
    end
    BaudBagOptionsUpdate();
end


--[[ slider functions ]]--
function BaudBagSlider_OnValueChanged(self)
    --[[
        This is called when the value of a slider is changed.
        First the new value directly shown in the title.
        Next the new value is saved in the correct BBConfig entry.
      ]]

    --[[ !!!TEMPORARY!!! This is a workaround for a possible bug in the sliders behavior ignoring the set step size when dragging the slider]]--
    if not self._onsetting then   -- is single threaded 
        self._onsetting = true
        self:SetValue(self:GetValue())
        value = self:GetValue()     -- cant use original 'value' parameter
        self._onsetting = false
    else 
        return 
    end               -- ignore recursion for actual event handler
    --[[ END !!!TEMPORARY!!! ]]--

    -- update description of slider
    if (self:GetParent() == BaudBagOptions.GroupGlobal) then
        _G[self:GetName().."Text"]:SetText( format( GlobalSliderBars[self:GetID()].Text, self:GetValue() ) )
    else
        _G[self:GetName().."Text"]:SetText( format( ContainerSliderBars[self:GetID()].Text, self:GetValue() ) )
    end
    
    
    -- events are also called when values are set on load, make sure to not end in an update loop
    if Updating then
        BaudBag_DebugMsg("Options", "It seems we are already updating, skipping further update...")
        return
    end
    
    if (self:GetParent() == BaudBagOptions.GroupGlobal) then
        BaudBag_DebugMsg("Options", "Updating value of global slider with id "..self:GetID().." to "..self:GetValue())
        
        -- save BBConfig entry
        local SavedVar = GlobalSliderBars[self:GetID()].SavedVar
        BaudBag_DebugMsg("Options", "The variable associated with this value is "..SavedVar)
        BBConfig[SavedVar] = self:GetValue()

        BaudBagForEachOpenContainer(
            function (container)
                container:Update()
            end
        )
    else
        BaudBag_DebugMsg("Options", "Updating value of container slider with id "..self:GetID().." to "..self:GetValue())

        -- save BBConfig entry
        local SavedVar = ContainerSliderBars[self:GetID()].SavedVar
        BaudBag_DebugMsg("Options", "The variable associated with this value is "..SavedVar)
        BBConfig[SelectedBags][SelectedContainer][SavedVar] = self:GetValue()

        -- cause the appropriate update  -- TODO: move to BaudBagBBConfig save?
        if (SavedVar == "Scale") then
            AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:UpdateFromConfig()
        elseif (SavedVar=="Columns") then
            AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:Rebuild()
            AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:Update()
        end
        BackpackTokenFrame_Update();
    end
end


function BaudBagOptionsUpdate()
    -- prepare vars
    local Button, Check, Container, Texture;
    local ContNum = 1;
    local Bags = SetSize[SelectedBags];
    Updating = true;

    -- first reload the drop down (weird problems if not done)
    local containerDropDown = BaudBagOptions.GroupContainer.SetSelection;
    UIDropDownMenu_Initialize(containerDropDown, BaudBagOptionsSetDropDown_Initialize);
    UIDropDownMenu_SetSelectedValue(containerDropDown, SelectedBags);

    -- is the box enabled
    --_G[Prefix.."GroupGlobalSellJunkCheck"]:SetChecked(BBConfig.SellJunk == true);
    _G[Prefix.."GroupContainerEnabledCheck"]:SetChecked(BBConfig[SelectedBags].Enabled~=false);
    _G[Prefix.."GroupContainerCloseAllCheck"]:SetChecked(BBConfig[SelectedBags].CloseAll~=false);

    -- load global checkbox and slider values
    for Key, Value in ipairs(GlobalCheckButtons) do
        local Button = _G[Prefix.."GroupGlobalCheckButton"..Key]
        Button:SetChecked(BBConfig[Value.SavedVar])
    end
    for Key, Value in ipairs(GlobalSliderBars) do
        local slider = _G[Prefix.."GroupGlobalSlider"..Key]
        slider:SetValue(BBConfig[Value.SavedVar])

        if (Value.DependsOn ~= nil and not BBConfig[Value.DependsOn]) then
            slider:Disable();
            slider.Text:SetFontObject("GameFontDisable");
        else
            slider:Enable();
            slider.Text:SetFontObject("GameFontNormal");
        end
    end
    
    -- load bag specific options (position and show each button that belongs to the current set,
    --		check joined box and create container frames)
    local bagParent = BaudBagOptions.GroupContainer.BagFrame;
    BaudBagForEachBag(SelectedBags,
        function(Bag, Index)
            Button	= _G[Prefix.."Bag"..Index];
            Check	= _G[Prefix.."JoinCheck"..Index];

            if (Index == 1) then
                -- only the first bag needs its position set, since the others are anchored to it
                Button:SetPoint("LEFT", bagParent, "CENTER", ((Bags / 2) * -44), 0);
            elseif (Index == NUM_BANKBAGSLOTS + 2) then
                -- the reagent bank might not be joined with anything else (for the moment?)
                _G[Prefix.."Container"..ContNum]:SetPoint("RIGHT", Prefix.."Bag"..(Index - 1), "RIGHT", 6,0);
                ContNum = ContNum + 1;
                _G[Prefix.."Container"..ContNum]:SetPoint("LEFT", Prefix.."Bag"..Index, "LEFT", -6,0);
            else
                -- all other bags may have a joined state
                Check:SetChecked(BBConfig[SelectedBags].Joined[Index]~=false);
                if not Check:GetChecked() then
                    -- if not joined the last container needs to be aligned to the last bag and the current container needs to start here
                    _G[Prefix.."Container"..ContNum]:SetPoint("RIGHT", Prefix.."Bag"..(Index - 1), "RIGHT", 6,0);
                    ContNum = ContNum + 1;
                    _G[Prefix.."Container"..ContNum]:SetPoint("LEFT", Prefix.."Bag"..Index, "LEFT", -6,0);
                end
            end
			
            -- try to find out which bag texture to use
            local bagCache = AddOnTable.Cache:GetBagCache(Bag);
            if BaudBagIcons[Bag]then
                Texture = BaudBagIcons[Bag];
            elseif(SelectedBags == 1)then
                Texture = GetInventoryItemTexture("player", ContainerIDToInventoryID(Bag));
            elseif bagCache and bagCache.BagLink then
                Texture = GetItemIcon(bagCache.BagLink);
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
    local nameInput = BaudBagOptions.GroupContainer.NameInput;
    nameInput:SetText(BBConfig[SelectedBags][SelectedContainer].Name or "test");
    nameInput:SetCursorPosition(0);

    -- load background state (initialized here to work around some strange behavior)
    local backgroundDropDown = BaudBagOptions.GroupContainer.BackgroundSelection;
    UIDropDownMenu_Initialize(backgroundDropDown, BaudBagOptionsBackgroundDropDown_Initialize);
    UIDropDownMenu_SetSelectedValue(backgroundDropDown, BBConfig[SelectedBags][SelectedContainer].Background);

    -- load slider values
    for Key, Value in ipairs(ContainerSliderBars)do
        local Slider = _G[Prefix.."GroupContainerSlider"..Key];
        Slider:SetValue(BBConfig[SelectedBags][SelectedContainer][Value.SavedVar]);
    end

    -- load checkbox values
    for Key, Value in ipairs(ContainerCheckButtons)do
        local Button = _G[Prefix.."GroupContainerCheckButton"..Key];
        Button:SetChecked(BBConfig[SelectedBags][SelectedContainer][Value.SavedVar]);
    end
	
    -- load checkbox enabled
    for Key, Value in ipairs(ContainerCheckButtons) do
        local Button = _G[Prefix.."GroupContainerCheckButton"..Key];
        local ButtonText = _G[Prefix.."GroupContainerCheckButton"..Key.."Text"];
        if (Value.DependsOn ~= nil and not BBConfig[SelectedBags][SelectedContainer][Value.DependsOn]) then
            Button:Disable();
            ButtonText:SetFontObject("GameFontDisable");
        else
            Button:Enable();
            ButtonText:SetFontObject("GameFontNormal");
        end
    end

    Updating = false;
end

function BaudBagOptionsSelectContainer(BagSet, Container)
    SelectedBags = BagSet;
    SelectedContainer = Container;
    BaudBagOptionsUpdate();
end