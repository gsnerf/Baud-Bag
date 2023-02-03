local AddOnName, AddOnTable = ...
local _

local Localized = AddOnTable.Localized
local MaxBags   = NUM_BANKBAGSLOTS + 2
local Prefix    = "BaudBagOptions"
local Updating  = false
local CfgBackup
local category = nil

local SelectedBags      = 1
local SelectedContainer = 1
local SetSize           = {6, NUM_BANKBAGSLOTS + 2}

local GlobalSliderBars = {
    { Text=Localized.RarityIntensity, Low=0.5, High=2.5, Step=0.1, SavedVar="RarityIntensity", Default=1, TooltipText=Localized.RarityIntensityTooltip, DependsOn="RarityColor" },
}

local ContainerSliderBars = {
    {Text=Localized.Columns,	Low="2",	High="40",		Step=1,		SavedVar="Columns",		Default={8,14},		TooltipText = Localized.ColumnsTooltip},
    {Text=Localized.Scale,		Low="50%",	High="200%",	Step=1,		SavedVar="Scale",		Default={100,100},	TooltipText = Localized.ScaleTooltip}
}

local GlobalCheckButtons = {
    {Text=Localized.ShowNewItems,        SavedVar="ShowNewItems",        Default=true,  TooltipText=Localized.ShowNewItemsTooltip,        DependsOn=nil, CanBeSet=true,                      UnavailableText = "" },
    {Text=Localized.SellJunk,            SavedVar="SellJunk",            Default=false, TooltipText=Localized.SellJunkTooltip,            DependsOn=nil, CanBeSet=true,                      UnavailableText = "" },
    {Text=Localized.UseMasque,           SavedVar="UseMasque",           Default=false, TooltipText=Localized.UseMasqueTooltp,            DependsOn=nil, CanBeSet=IsAddOnLoaded("Masque"),   UnavailableText = Localized.UseMasqueUnavailable},
    {Text=Localized.RarityColoring,      SavedVar="RarityColor",         Default=true,  TooltipText=Localized.RarityColoringTooltip,      DependsOn=nil, CanBeSet=true,                      UnavailableText = "" },
    {Text=Localized.ShowItemLevel,       SavedVar="ShowItemLevel",       Default=false, TooltipText=Localized.ShowItemLevelTooltip,       DependsOn=nil, CanBeSet=true,                      UnavailableText = "" },
    {Text=Localized.EnableFadeAnimation, SavedVar="EnableFadeAnimation", Default=false, TooltipText=Localized.EnableFadeAnimationTooltip, DependsOn=nil, CanBeSet=true,                      UnavailableText = "" },
}

local ContainerCheckButtons = {
    {Text=Localized.AutoOpen,       SavedVar="AutoOpen",     Default=false, TooltipText=Localized.AutoOpenTooltip,          DependsOn=nil},
    {Text=Localized.AutoClose,      SavedVar="AutoClose",    Default=true,  TooltipText=Localized.AutoCloseTooltip,         DependsOn="AutoOpen"},
    {Text=Localized.BlankOnTop,     SavedVar="BlankTop",     Default=false, TooltipText=Localized.BlankOnTopTooltip,        DependsOn=nil},
}

BaudBagIcons = {
    [0]	    = "Interface\\Buttons\\Button-Backpack-Up",
    [-1]	= "Interface\\Icons\\INV_Box_02",
    [-2]	= "Interface\\ContainerFrame\\KeyRing-Bag-Icon",
    [-3]	= "Interface\\Icons\\INV_MISC_CAT_TRINKET05"
}

local TextureNames = {
    Localized.BlizInventory,
    Localized.BlizBank,
    Localized.BlizKeyring,
    Localized.Transparent,
    Localized.Solid,
    Localized.Transparent2
}

BACKDROP_BB_OPTIONS_CONTAINER = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileEdge = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 5, right = 5, top = 5, bottom = 5 },
}

BaudBagOptionsMixin = {}

--[[
    Needed functions:
    - option window loaded => set all basic control settings and add dynamic components
    - bagset changed (dropdown event) => load bags, choose first container (see next point)
    - selected container changed => load container specific data
    (name, background, columns, scaling, autoopen, empty spaces on top, rarity coloring)
  ]]

--[[ BaudBagOptions frame related events and methods ]]
function BaudBagOptionsMixin:OnLoad(event, ...)
    -- the config needs a reference to this
    BaudBagSetCfgPreReq(GlobalSliderBars, ContainerSliderBars, GlobalCheckButtons, ContainerCheckButtons)
    self:RegisterEvent("ADDON_LOADED")
end

--[[ All actual processing needs to be done after we are sure we have a config to load from! ]]
function BaudBagOptionsMixin:OnEvent(event, ...)

    -- failsafe: we only want to handle the addon loaded event
    local arg1 = ...
    if ((event ~= "ADDON_LOADED") or (arg1 ~= "BaudBag")) then return end
    
    -- make sure there is a BBConfig and a cache
    AddOnTable:InitCache()
    BaudBagRestoreCfg()
    ConvertOldConfig()
    CfgBackup	= BaudBagCopyTable(BBConfig)
	
    -- add to options windows
    self.name			= "Baud Bag"
    self.okay			= self.OnOkay
    self.cancel			= self.OnCancel
    self.refresh		= self.OnRefresh
    
    -- register with wow api
    if (Settings ~= nil and Settings.RegisterCanvasLayoutCategory ~= nil) then
        category = Settings.RegisterCanvasLayoutCategory(self, "Baud Bag")
        Settings.RegisterAddOnCategory(category)
        AddOnTable.Functions.DebugMessage("Options", "Using new settings system to register category", category)
    else
        InterfaceOptions_AddCategory(self)
    end

    -- ensure retail style label adressing is possible
    if (self.GroupContainer.EnabledCheck.text == nil) then
        self.GroupContainer.EnabledCheck.text = _G[self.GroupContainer.EnabledCheck:GetName().."Text"]
    end
    if (self.GroupContainer.CloseAllCheck.text == nil) then
        self.GroupContainer.CloseAllCheck.text = _G[self.GroupContainer.CloseAllCheck:GetName().."Text"]
    end
	
    -- set localized labels
    self.Title:SetText("Baud Bag "..Localized.Options)
    self.Version:SetText("(v"..GetAddOnMetadata("BaudBag","Version")..")")
    
    self.GroupGlobal.Header.Label:SetText(Localized.OptionsGroupGlobal)
    self.GroupGlobal.ResetPositionsButton.Text:SetText(Localized.OptionsResetAllPositions)
    self.GroupGlobal.ResetPositionsButton.tooltipText = Localized.OptionsResetAllPositionsTooltip
    
    self.GroupContainer.Header.Label:SetText(Localized.OptionsGroupContainer)
    self.GroupContainer.SetSelection.Label:SetText(Localized.BagSet)
    self.GroupContainer.NameInput.Text:SetText(Localized.ContainerName)
    self.GroupContainer.BackgroundSelection.Label:SetText(Localized.Background)
    self.GroupContainer.EnabledCheck.tooltipText  = Localized.EnabledTooltip
    self.GroupContainer.CloseAllCheck.tooltipText = Localized.CloseAllTooltip
    self.GroupContainer.EnabledCheck.text:SetText(Localized.Enabled)
    self.GroupContainer.CloseAllCheck.text:SetText(Localized.CloseAll)
    self.GroupContainer.EnabledCheck:SetHitRectInsets(0, -self.GroupContainer.EnabledCheck.text:GetWidth() - 10, 0, 0)
    self.GroupContainer.CloseAllCheck:SetHitRectInsets(0, -self.GroupContainer.CloseAllCheck.text:GetWidth() - 10, 0, 0)
    self.GroupContainer.ResetPositionButton.Text:SetText(Localized.OptionsResetContainerPosition)
    self.GroupContainer.ResetPositionButton.tooltipText = Localized.OptionsResetContainerPositionTooltip

    -- localized global checkbox labels
    for Key, Value in ipairs(GlobalCheckButtons) do
        local checkButton = self.GroupGlobal["CheckButton"..Key]
        if (checkButton.text == nil) then
            checkButton.text = _G[checkButton:GetName().."Text"]
        end
        checkButton.text:SetText(Value.Text)
        checkButton.tooltipText = Value.TooltipText

        if (not Value.CanBeSet) then
            checkButton:Disable()
            checkButton.text:SetFontObject("GameFontDisable")
            checkButton.text:SetText(Value.Text.." ("..Value.UnavailableText..")")
        end
    end
    for Key, Value in ipairs(GlobalSliderBars) do
        local slider = self.GroupGlobal["Slider"..Key]
        slider.Low:SetText(Value.Low)
        slider.High:SetText(Value.High)
        slider.tooltipText = Value.TooltipText
        slider.valueStep   = Value.Step
    end
    
    -- localized checkbox labels
    for Key, Value in ipairs(ContainerCheckButtons) do
        local checkButton = self.GroupContainer["CheckButton"..Key]
        if (checkButton.text == nil) then
            checkButton.text = _G[checkButton:GetName().."Text"]
        end
        checkButton.text:SetText(Value.Text)
        checkButton.tooltipText = Value.TooltipText
    end

    -- set slider bounds
    for Key, Value in ipairs(ContainerSliderBars) do
        local slider = self.GroupContainer["Slider"..Key]
        slider.Low:SetText(Value.Low)
        slider.High:SetText(Value.High)
        slider.tooltipText = Value.TooltipText
        slider.valueStep   = Value.Step
    end
	
    -- some slash command settings
    SlashCmdList[Prefix..'_SLASHCMD'] = function()
        if (category ~= nil) then
            -- retail options system
            AddOnTable.Functions.DebugMessage("Options", "Using new settings system to open category", category:GetID())
            Settings.OpenToCategory(category:GetID())
        else
            -- classic options system
            -- double call is needed to work around what seems to be a bug in blizzards code...
            InterfaceOptionsFrame_OpenToCategory(self)
            InterfaceOptionsFrame_OpenToCategory(self)
        end
    end
    _G["SLASH_"..Prefix.."_SLASHCMD1"] = '/baudbag'
    _G["SLASH_"..Prefix.."_SLASHCMD2"] = '/bb'
    DEFAULT_CHAT_FRAME:AddMessage(Localized.AddMessage)

    --[[
        create stubs for all possibly needed bag buttons:
        1. create bag button
        2. create container frame
        3. create join checkbox if bag > 1
      ]]
    local Button, Container, Check
    for Bag = 1, MaxBags do
        Button		= CreateFrame("Button", Prefix.."Bag"..Bag,       self.GroupContainer.BagFrame, Prefix.."BagTemplate")
        Container	= CreateFrame("Frame",  Prefix.."Container"..Bag, self.GroupContainer.BagFrame, Prefix.."ContainerTemplate")
        if (Bag == 1) then
            -- first bag only has a container
            Container:SetPoint("LEFT", _G[Prefix.."Bag1"], "LEFT", -6, 0)
        else
            -- all other bags also have a button to mark joins with the previous bags
            Button:SetPoint("LEFT", Prefix.."Bag"..(Bag-1), "RIGHT", 8, 0)
            Check = CreateFrame("CheckButton", Prefix.."JoinCheck"..Bag, Button, Prefix.."JoinCheckTemplate")
            Check:SetPoint("BOTTOM", Button, "TOPLEFT", -4, 4)
            Check:SetID(Bag)
            Check.tooltipText = Localized.CheckTooltip

            if (Bag == MaxBags) then
                Check:SetChecked(false)
                Check:Disable()
                Check:Hide()
            end
        end
    end
	
    -- make sure the view is updated with the data loaded from the config
    self:Update()
end

function BaudBagOptionsMixin:OnRefresh(event, ...)
    AddOnTable.Functions.DebugMessage("Options", "OnRefresh was called!")
    self:Update()
end

function BaudBagOptionsMixin:OnOkay(event, ...)
    AddOnTable.Functions.DebugMessage("Options", "'Okay' pressed, saving BBConfig.")
    CfgBackup = BBConfig
    BaudBagSaveCfg(BBConfig)
end

function BaudBagOptionsMixin:OnCancel(event, ...)
    AddOnTable.Functions.DebugMessage("Options", "'Cancel' pressed, reset to last BBConfig.")
    BBConfig = CfgBackup
    ReloadConfigDependant()
    self:Update()
end


--[[ SetBags DropDown functions ]]
function BaudBagOptionsSetDropDown_Initialize()
    -- prepare dropdown entries
    local info		= UIDropDownMenu_CreateInfo()
    info.func		= BaudBagOptionsSetDropDown_OnClick

    -- inventory set
    info.text		= Localized.Inventory
    info.value		= 1
    info.checked	= (info.value == SelectedBags) and 1 or nil
    UIDropDownMenu_AddButton(info)

    -- bank set
    info.text		= Localized.BankBox
    info.value		= 2
    info.checked    = (info.value == SelectedBags) and 1 or nil
    UIDropDownMenu_AddButton(info)
end

function BaudBagOptionsSetDropDown_OnClick(self)
    SelectedBags = self.value
    BaudBagOptions:Update()
end


--[[ BagSet specific CheckBox functions ]]

function BaudBagEnabledCheck_OnClick(self, event, ...)
    PlayCheckBoxSound(self)
    if (not self:GetChecked()) then
        BaudBagCloseBagSet(SelectedBags) -- TODO: move to BaudBagConfig save?
    end

    BBConfig[SelectedBags].Enabled = self:GetChecked()
    -- TODO: move to BaudBagBBConfig save?
    if BBConfig and (BBConfig[2].Enabled == true) then BankFrame:UnregisterEvent("BANKFRAME_OPENED") end
    if BBConfig and (BBConfig[2].Enabled == false) then BankFrame:RegisterEvent("BANKFRAME_OPENED") end
    if (BackpackTokenFrame_Update ~= nil) then
        BackpackTokenFrame_Update()
    else
        BackpackTokenFrame:Update()
    end
end

function BaudBagCloseAllCheck_OnClick(self, event, ...)
    PlayCheckBoxSound(self)
    BBConfig[SelectedBags].CloseAll = self:GetChecked()
end

function BaudBagSellJunkCheck_OnClick(self, event, ...)
    if (SelectedBags == 1) then
        PlayCheckBoxSound(self)
        BBConfig[SelectedBags].SellJunk = self:GetChecked()
    end
end


--[[ Dynamic Bags/Container Clicks ]]
function BaudBagOptionsBag_OnClick(self, event, ...)
    SelectedContainer = self:GetID()
    BaudBagOptions:Update()
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
    BaudBagOptions:Update()
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
function BaudBagOptionsNameEditBox_OnTextChanged(self, wasUserInput)
    if Updating or not wasUserInput then
        return
    end

    BBConfig[SelectedBags][SelectedContainer].Name = BaudBagOptions.GroupContainer.NameInput:GetText()
    AddOnTable["Sets"][SelectedBags].Containers[SelectedContainer]:UpdateName() -- TODO: move to BaudBagBBConfig save?
end



--[[ Background Dropdown functions ]]
-- init
function BaudBagOptionsBackgroundDropDown_Initialize()
    local info			= UIDropDownMenu_CreateInfo()
    info.func			= BaudBagOptionsBackgroundDropDown_OnClick
    local Selected		= BBConfig[SelectedBags][SelectedContainer].Background
	
    for Key, Value in pairs(TextureNames)do
        info.text		= Value
        info.value		= Key
        info.checked	= (Key == Selected) and 1 or nil
        UIDropDownMenu_AddButton(info)
    end
end

-- onclick
function BaudBagOptionsBackgroundDropDown_OnClick(self)
    BBConfig[SelectedBags][SelectedContainer].Background = self.value
    UIDropDownMenu_SetSelectedValue(BaudBagOptions.GroupContainer.BackgroundSelection, self.value)
    local container = AddOnTable["Sets"][SelectedBags].Containers[SelectedContainer]
    container:Rebuild()
    container:Update()
end


--[[ CheckBox (non "enabled") functions ]]
function BaudBagOptionsCheckButton_OnClick(self, event, ...)
    -- make the apropriate sound
    PlaySound(self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    
    -- apply change based on group
    local SavedVar
    if (self:GetParent() == BaudBagOptions.GroupGlobal) then
        SavedVar = GlobalCheckButtons[self:GetID()].SavedVar
        AddOnTable.Functions.DebugMessage("Options", "Update global variable: "..SavedVar)
        BBConfig[SavedVar] = self:GetChecked()

        if (SavedVar == "RarityColor") then
            BaudBagForEachOpenContainer(
                function (container)
                    container:Update()
                end
            )
        end
    else
        SavedVar = ContainerCheckButtons[self:GetID()].SavedVar
        AddOnTable.Functions.DebugMessage("Options", "Update container variable: "..SavedVar)
        BBConfig[SelectedBags][SelectedContainer][SavedVar] = self:GetChecked()

        -- make sure options who need it (visible things) update the affected container
        if (SavedVar == "BlankTop") or (SavedVar == "RarityColor") then -- or (SavedVar == "RarityColorAltern") then
            AddOnTable.Functions.DebugMessage("Options", "Want to update container: "..Prefix.."Container"..SelectedBags.."_"..SelectedContainer)
            BaudBagUpdateContainer(_G["BaudBagContainer"..SelectedBags.."_"..SelectedContainer]) -- TODO: move to BaudBagBBConfig save?
        end
    end
    BaudBagOptions:Update()
end


--[[ slider functions ]]--
BaudBagOptionsSliderTemplateMixin = {}
function BaudBagOptionsSliderTemplateMixin:OnValueChanged()
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
        local sliderText = BaudBagOptions.GroupGlobal["Slider"..self:GetID()].Text
        sliderText:SetText( format( GlobalSliderBars[self:GetID()].Text, self:GetValue() ) )
    else
        local sliderText = BaudBagOptions.GroupContainer["Slider"..self:GetID()].Text
        sliderText:SetText( format( ContainerSliderBars[self:GetID()].Text, self:GetValue() ) )
    end
    
    
    -- events are also called when values are set on load, make sure to not end in an update loop
    if Updating then
        AddOnTable.Functions.DebugMessage("Options", "It seems we are already updating, skipping further update...")
        return
    end
    
    if (self:GetParent() == BaudBagOptions.GroupGlobal) then
        AddOnTable.Functions.DebugMessage("Options", "Updating value of global slider with id "..self:GetID().." to "..self:GetValue())
        
        -- save BBConfig entry
        local SavedVar = GlobalSliderBars[self:GetID()].SavedVar
        AddOnTable.Functions.DebugMessage("Options", "The variable associated with this value is "..SavedVar)
        BBConfig[SavedVar] = self:GetValue()

        BaudBagForEachOpenContainer(
            function (container)
                container:Update()
            end
        )
    else
        AddOnTable.Functions.DebugMessage("Options", "Updating value of container slider with id "..self:GetID().." to "..self:GetValue())

        -- save BBConfig entry
        local SavedVar = ContainerSliderBars[self:GetID()].SavedVar
        AddOnTable.Functions.DebugMessage("Options", "The variable associated with this value is "..SavedVar)
        BBConfig[SelectedBags][SelectedContainer][SavedVar] = self:GetValue()

        -- cause the appropriate update  -- TODO: move to BaudBagBBConfig save?
        if (SavedVar == "Scale") then
            AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:UpdateFromConfig()
        elseif (SavedVar=="Columns") then
            AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:Rebuild()
            AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:Update()
        end
        if (BackpackTokenFrame_Update ~= nil) then
            BackpackTokenFrame_Update()
        else
            BackpackTokenFrame:Update()
        end
    end
end


function BaudBagOptionsMixin:Update()
    -- prepare vars
    local Button, Check, Container, Texture
    local ContNum = 1
    local Bags = SetSize[SelectedBags]
    Updating = true

    -- first reload the drop down (weird problems if not done)
    local containerDropDown = self.GroupContainer.SetSelection
    UIDropDownMenu_Initialize(containerDropDown, BaudBagOptionsSetDropDown_Initialize)
    UIDropDownMenu_SetSelectedValue(containerDropDown, SelectedBags)

    -- is the box enabled
    self.GroupContainer.EnabledCheck:SetChecked(BBConfig[SelectedBags].Enabled~=false)
    self.GroupContainer.CloseAllCheck:SetChecked(BBConfig[SelectedBags].CloseAll~=false)

    -- load global checkbox and slider values
    for Key, Value in ipairs(GlobalCheckButtons) do
        local Button = self.GroupGlobal["CheckButton"..Key]
        Button:SetChecked(BBConfig[Value.SavedVar])
    end
    for Key, Value in ipairs(GlobalSliderBars) do
        local slider = self.GroupGlobal["Slider"..Key]
        slider:SetValue(BBConfig[Value.SavedVar])

        if (Value.DependsOn ~= nil and not BBConfig[Value.DependsOn]) then
            slider:Disable()
            slider.Text:SetFontObject("GameFontDisable")
        else
            slider:Enable()
            slider.Text:SetFontObject("GameFontNormal")
        end
    end
    
    -- load bag specific options (position and show each button that belongs to the current set,
    --		check joined box and create container frames)
    local bagParent = self.GroupContainer.BagFrame

    if (AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER ~= nil) then
        -- for backback set we need to ensure, that the reagent bag(s) cannot be joined with the regular bags
        if SelectedBags == 1 then
            _G[Prefix.."JoinCheck"..(AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER+1)]:Hide()
        else
            _G[Prefix.."JoinCheck"..(AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER+1)]:Show()
        end
    end
    AddOnTable.Functions.ForEachBag(SelectedBags,
        function(Bag, Index)
            Button	= _G[Prefix.."Bag"..Index]
            Check	= _G[Prefix.."JoinCheck"..Index]

            if (Index == 1) then
                -- only the first bag needs its position set, since the others are anchored to it
                Button:SetPoint("LEFT", bagParent, "CENTER", ((Bags / 2) * -44), 0)
            elseif (Index == AddOnTable.BlizzConstants.BANK_CONTAINER_NUM + 2 or (SelectedBags == 1 and  Index == (AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER + 1))) then
                -- the reagent bank and the reagent bag might not be joined with anything else (for the moment?)
                _G[Prefix.."Container"..ContNum]:SetPoint("RIGHT", Prefix.."Bag"..(Index - 1), "RIGHT", 6,0)
                ContNum = ContNum + 1
                _G[Prefix.."Container"..ContNum]:SetPoint("LEFT", Prefix.."Bag"..Index, "LEFT", -6,0)
            else
                -- all other bags may have a joined state
                Check:SetChecked(BBConfig[SelectedBags].Joined[Index]~=false)
                if not Check:GetChecked() then
                    -- if not joined the last container needs to be aligned to the last bag and the current container needs to start here
                    _G[Prefix.."Container"..ContNum]:SetPoint("RIGHT", Prefix.."Bag"..(Index - 1), "RIGHT", 6,0)
                    ContNum = ContNum + 1
                    _G[Prefix.."Container"..ContNum]:SetPoint("LEFT", Prefix.."Bag"..Index, "LEFT", -6,0)
                end
            end
			
            -- try to find out which bag texture to use
            local bagCache = AddOnTable.Cache:GetBagCache(Bag)
            if BaudBagIcons[Bag]then
                Texture = BaudBagIcons[Bag]
            elseif(SelectedBags == 1)then
                Texture = GetInventoryItemTexture("player", AddOnTable.BlizzAPI.ContainerIDToInventoryID(Bag))
            elseif bagCache and bagCache.BagLink then
                Texture = GetItemIcon(bagCache.BagLink)
            else
                Texture = nil
            end
			
            -- assign texture, id and get item to be shown
            Button.Icon:SetTexture(Texture or select(2, AddOnTable.BlizzAPI.GetInventorySlotInfo("BAG0SLOT")))
            Button:SetID(ContNum)
            Button:Show()
        end
        )
    _G[Prefix.."Container"..ContNum]:SetPoint("RIGHT", Prefix.."Bag"..Bags,"RIGHT",6,0)

    -- make sure all bags after the last visible bag to be shown is hidden (e.g. the inventory has less bags then the bank)
    for Index = Bags + 1, MaxBags do
        _G[Prefix.."Bag"..Index]:Hide()
    end

    -- it must be made sure an existing container is selected
    if (SelectedContainer > ContNum) then
        SelectedContainer = 1
    end

    -- mark currently selected bags and container or reset the markings
    -- (checked-state for buttons and border for container)
    local R, G, B
    for Bag = 1, MaxBags do
        Container	= _G[Prefix.."Container"..Bag]
        Button		= _G[Prefix.."Bag"..Bag]
        if (Button:GetID()==SelectedContainer) then
            Button.SlotHighlightTexture:Show()
        else
            Button.SlotHighlightTexture:Hide()
        end
        if (Bag <= ContNum) then
            if (Bag==SelectedContainer) then
                Container:SetBackdropColor(1, 1, 0)
                Container:SetBackdropBorderColor(1, 1, 0)
            else
                Container:SetBackdropColor(1, 1, 1)
                Container:SetBackdropBorderColor(1, 1, 1)
            end
            Container:Show()
        else
            Container:Hide()
        end
    end

    -- load container name into the textbox
    local nameInput = self.GroupContainer.NameInput
    nameInput:SetText(BBConfig[SelectedBags][SelectedContainer].Name or "test")
    nameInput:SetCursorPosition(0)

    -- load background state (initialized here to work around some strange behavior)
    local backgroundDropDown = self.GroupContainer.BackgroundSelection
    UIDropDownMenu_Initialize(backgroundDropDown, BaudBagOptionsBackgroundDropDown_Initialize)
    UIDropDownMenu_SetSelectedValue(backgroundDropDown, BBConfig[SelectedBags][SelectedContainer].Background)

    -- load slider values
    for Key, Value in ipairs(ContainerSliderBars) do
        local Slider = self.GroupContainer["Slider"..Key]
        Slider:SetValue(BBConfig[SelectedBags][SelectedContainer][Value.SavedVar])
    end

    -- load checkbox values
    for Key, Value in ipairs(ContainerCheckButtons) do
        local Button = self.GroupContainer["CheckButton"..Key]
        Button:SetChecked(BBConfig[SelectedBags][SelectedContainer][Value.SavedVar])
    end
	
    -- load checkbox enabled
    for Key, Value in ipairs(ContainerCheckButtons) do
        local Button = self.GroupContainer["CheckButton"..Key]
        local ButtonText = _G[Button:GetName().."Text"]
        if (Value.DependsOn ~= nil and not BBConfig[SelectedBags][SelectedContainer][Value.DependsOn]) then
            Button:Disable()
            ButtonText:SetFontObject("GameFontDisable")
        else
            Button:Enable()
            ButtonText:SetFontObject("GameFontNormal")
        end
    end

    Updating = false
end

function BaudBagOptionsSelectContainer(BagSet, Container)
    SelectedBags = BagSet
    SelectedContainer = Container
    BaudBagOptions:Update()
end

hooksecurefunc(AddOnTable, "Configuration_Updated", function(self) BaudBagOptions:Update() end)

local function ResetContainerPosition(bagSet, containerId, container)
    container.Frame:ClearAllPoints()
    container.Frame:SetPoint("CENTER", UIParent)
    local x, y = container.Frame:GetCenter()
    BBConfig[bagSet][containerId].Coords = {x, y}
end

PositionResetMixin = {}
function PositionResetMixin:ResetPosition()
    if (self:GetParent() == BaudBagOptions.GroupGlobal) then
        AddOnTable.Functions.ForEachContainer(function(bagSet, containerId, container)
            ResetContainerPosition(bagSet, containerId, container)
        end)
    else
        local container = AddOnTable["Sets"][SelectedBags].Containers[SelectedContainer]
        ResetContainerPosition(SelectedBags, SelectedContainer, container)
    end
end

