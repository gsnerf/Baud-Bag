---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

local Localized = AddOnTable.Localized
local MaxBags   = 1 + AddOnTable.BlizzConstants.BANK_CONTAINER_NUM + (AddOnTable.State.ReagentBankSupported and 1 or 0) -- 1 for bank + BANK_CONTAINER_NUM + 1 for reagent bank if supported
local Prefix    = "BaudBagOptions"
local Updating  = false
local category = nil

local SelectedBags      = BagSetType.Backpack.Id
local SelectedContainer = 1
local SetSize           = {} -- this list will be filled with values read from the specific BagSetType defined at time of AddOnTable:EssentialsLoaded()

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

---@class BaudBagOptions: Frame
---@field GroupContainer OptionsGroupContainer the group representing the container options for a specific bag set
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
	
    -- add to options windows
    self.name			= "Baud Bag"
    self.okay			= self.OnOkay
    self.cancel			= self.OnCancel
    self.refresh		= self.OnRefresh
    
    -- register with wow api
    if (Settings ~= nil and Settings.RegisterCanvasLayoutCategory ~= nil) then
        local category = Settings.RegisterCanvasLayoutCategory(self, "Baud Bag")
        Settings.RegisterAddOnCategory(category)
        AddOnTable.Functions.DebugMessage("Options", "Using new settings system to register category", category)
        AddOnTable.SettingsCategory = category
    else
        InterfaceOptions_AddCategory(self)
    end

    -- set localized labels
    self.Title:SetText("Baud Bag "..Localized.Options)
    self.Version:SetText("(v"..AddOnTable.BlizzAPI.GetAddOnMetadata("BaudBag","Version")..")")
    
    self.GroupGlobal.Header.Label:SetText(Localized.OptionsGroupGlobal)
    self.GroupGlobal.ResetPositionsButton.Text:SetText(Localized.OptionsResetAllPositions)
    self.GroupGlobal.ResetPositionsButton.tooltipText = Localized.OptionsResetAllPositionsTooltip

    -- localized global checkbox labels
    for Key, Value in ipairs(AddOnTable.ConfigOptions.Global.CheckButtons) do
        local checkButton = self.GroupGlobal["CheckButton"..Key]
        checkButton:UpdateText(Value.Text, Value.TooltipText)

        if (not Value.CanBeSet) then
            checkButton:Disable()
            checkButton:SetText(Value.Text.." ("..Value.UnavailableText..")")
        end
    end
    for Key, Value in ipairs(AddOnTable.ConfigOptions.Global.SliderBars) do
        local slider = self.GroupGlobal["Slider"..Key]
        slider.Low:SetText(Value.Low)
        slider.High:SetText(Value.High)
        slider.tooltipText = Value.TooltipText
        slider.valueStep   = Value.Step
    end

    self.GroupContainer.BagSet:InitializeContent()

    -- some slash command settings
    SlashCmdList[Prefix..'_SLASHCMD'] = function()
        local category = AddOnTable.SettingsCategory
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

    -- make sure the view is updated with the data loaded from the config
    self:Update()
end

-- TODO: identify if this is still a thing!
function BaudBagOptionsMixin:OnRefresh(event, ...)
    AddOnTable.Functions.DebugMessage("Options", "OnRefresh was called!")
    self:Update()
end

--[[ Dynamic Bags/Container Clicks ]]
function BaudBagOptionsBag_OnClick(self, event, ...)
    SelectedContainer = self:GetID()
    BaudBagOptions:Update()
end

--[[ Name TextBox functions ]]
function BaudBagOptionsNameEditBox_OnTextChanged(self, wasUserInput)
    if Updating or not wasUserInput then
        return
    end

    BBConfig[SelectedBags][SelectedContainer].Name =self:GetText()
    AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:UpdateName() -- TODO: move to BaudBagBBConfig save?
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
        self._onsetting = false
    else
        return
    end               -- ignore recursion for actual event handler
    --[[ END !!!TEMPORARY!!! ]]--

    -- update description of slider
    if (self:GetParent() == BaudBagOptions.GroupGlobal) then
        local sliderText = BaudBagOptions.GroupGlobal["Slider"..self:GetID()].Text
        sliderText:SetText( format( AddOnTable.ConfigOptions.Global.SliderBars[self:GetID()].Text, self:GetValue() ) )
    else
        local sliderText = BaudBagOptions.GroupContainer.BagSet["Slider"..self:GetID()].Text
        sliderText:SetText( format( AddOnTable.ConfigOptions.Container.SliderBars[self:GetID()].Text, self:GetValue() ) )
    end
    
    
    -- events are also called when values are set on load, make sure to not end in an update loop
    if Updating then
        AddOnTable.Functions.DebugMessage("Options", "It seems we are already updating, skipping further update...")
        return
    end
    
    if (self:GetParent() == BaudBagOptions.GroupGlobal) then
        AddOnTable.Functions.DebugMessage("Options", "Updating value of global slider with id "..self:GetID().." to "..self:GetValue())
        
        -- save BBConfig entry
        local SavedVar = AddOnTable.ConfigOptions.Global.SliderBars[self:GetID()].SavedVar
        AddOnTable.Functions.DebugMessage("Options", "The variable associated with this value is "..SavedVar)
        BBConfig[SavedVar] = self:GetValue()

        AddOnTable.Functions.ForEachOpenContainer(
            function (container)
                container:Update()
            end
        )
    else
        AddOnTable.Functions.DebugMessage("Options", "Updating value of container slider with id "..self:GetID().." to "..self:GetValue())

        -- save BBConfig entry
        local SavedVar = AddOnTable.ConfigOptions.Container.SliderBars[self:GetID()].SavedVar
        AddOnTable.Functions.DebugMessage("Options", "The variable associated with this value is "..SavedVar)
        BBConfig[SelectedBags][SelectedContainer][SavedVar] = self:GetValue()

        -- cause the appropriate update  -- TODO: move to BaudBagBBConfig save?
        if (SavedVar == "Scale") then
            AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:UpdateFromConfig()
        elseif (SavedVar=="Columns") then
            AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:Rebuild()
            AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:Update()
        end
    end
end


function BaudBagOptionsMixin:Update()
    Updating = true

    -- load global checkbox and slider values
    for Key, Value in ipairs(AddOnTable.ConfigOptions.Global.CheckButtons) do
        local Button = self.GroupGlobal["CheckButton"..Key]
        Button:SetChecked(BBConfig[Value.SavedVar])
    end
    for Key, Value in ipairs(AddOnTable.ConfigOptions.Global.SliderBars) do
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
    
    self.GroupContainer.BagSet:UpdateContent()

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
        local container = AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]
        ResetContainerPosition(SelectedBags, SelectedContainer, container)
    end
end

---@class OptionsGroupContainer
---@field Header FontString
---@field BagSet OptionsBagSet the options for a specific container in the selected bag set
BaudBagOptionsGroupContainerMixin = {}

---Creates a tab button for a bag set by it's BagSetType, structure can be seen as comment in the GroupContainer in XML
---@param parent Frame the frame to use as a parent for the new button
---@param bagSetType BagSetTypeClass the bag set type as used in BagSetType global as value
---@param lastTabButton Button the previous tab button used as an anchor for the new one
---@return Button|MinimalTabTemplate
local function CreateBagSetTabButton(parent, bagSetType, lastTabButton)
    local tabButtonName = "Tab"..bagSetType.TypeName
    local tabButton = CreateFrame("Button", nil, parent, "MinimalTabTemplate")
    parent[tabButtonName] = tabButton
    tabButton:SetHeight(37)
    tabButton.tabText = bagSetType.Name
    tabButton.tabId = bagSetType.Id
    if (lastTabButton) then
        tabButton:SetPoint("TOPRIGHT", lastTabButton, "TOPLEFT", 0, 0)
    else
        tabButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, 10)
    end
    tabButton:OnLoad()
    return tabButton
end

function BaudBagOptionsGroupContainerMixin:OnLoad()
    self.Header:SetText(Localized.OptionsGroupContainer)
    self.tabButtons = {}
    self.tabFrames = {}
    self.tabsGroup = CreateRadioButtonGroup()


    local loadEssentials = function()
        AddOnTable.Functions.DebugMessage("Temp", "BaudBagOptionsBagSetMixin:EssentialsLoaded()")
        local lastTabButton
        for _, type in ipairs(BagSetTypeArray) do
            -- create tabs for bagset selection
            local tabButton = CreateBagSetTabButton(self, type, lastTabButton)
            table.insert(self.tabButtons, tabButton)
            lastTabButton = tabButton

            -- ensure that we know how many container buttons are needed for this BagSetType
            SetSize[type.Id] = type.NumberOfContainers
        end
    
        self.tabsGroup:AddButtons(self.tabButtons)
        self.tabsGroup:SelectAtIndex(1)
        self.tabsGroup:RegisterCallback(ButtonGroupBaseMixin.Event.Selected, self.OnTabSelected, self)
    end
    hooksecurefunc(AddOnTable, "EssentialsLoaded", loadEssentials)
end

function BaudBagOptionsGroupContainerMixin:OnTabSelected(tab, tabIndex)
    self.BagSet:ChangeBagSet(tab.tabId)
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
end


---@class OptionsBagSet: Frame
---@field NameInput EditBox
---@field ResetPositionButton Button
---@field BackgroundSelection DropdownButton
---@field EnabledCheck CheckButton
---@field CloseAllCheck CheckButton
BaudBagOptionsBagSetMixin = {}

local function CreateBagSetBagButtons(self)
    --[[
        create stubs for all possibly needed bag buttons:
        1. create bag button
        2. create container frame
        3. create join checkbox if bag > 1
    ]]
    local Button, Container, Check
    for Bag = 1, MaxBags do
        Button    = CreateFrame("Button", Prefix.."Bag"..Bag,       self.BagFrame, Prefix.."BagTemplate")
        Container = CreateFrame("Frame",  Prefix.."Container"..Bag, self.BagFrame, Prefix.."ContainerTemplate")
        if (Bag == 1) then
            -- first bag only has a container
            Container:SetPoint("LEFT", _G[Prefix.."Bag1"], "LEFT", -6, 0)
        else
            -- all other bags also have a button to mark joins with the previous bags
            Button:SetPoint("LEFT", Prefix.."Bag"..(Bag-1), "RIGHT", 8, 0)
            Check = CreateFrame("CheckButton", Prefix.."JoinCheck"..Bag, Button, "BaudBagOptionsBagJoinCheckButtonTemplate")
            Check:SetPoint("BOTTOM", Button, "TOP", 0, 4)
            Check:SetPoint("LEFT", Button, "LEFT", -17, 0)
            Check:SetID(Bag)
            Check.tooltipText = Localized.CheckTooltip

            if (Bag == MaxBags) then
                Check:SetChecked(false)
                Check:Disable()
                Check:Hide()
            end
        end
    end
end

--- Initializes the BagSet group frame:
--- * puts localized texts on all UI elements
--- * hooks events
--- * assigns fixed boundaries
--- * reates all the bag buttons that might be necessary for all of the bag sets
function BaudBagOptionsBagSetMixin:OnLoad()
    -- localized text fields and buttons
    self.NameInput.Text:SetText(Localized.ContainerName)
    self.ResetPositionButton.Text:SetText(Localized.OptionsResetContainerPosition)
    self.ResetPositionButton.tooltipText = Localized.OptionsResetContainerPositionTooltip
    self.BackgroundSelection:SetDefaultText(Localized.Background)
    
    -- localized checkbox labels
    self.EnabledCheck:UpdateText(Localized.Enabled, Localized.EnabledTooltip)
    self.CloseAllCheck:UpdateText(Localized.CloseAll, Localized.CloseAllTooltip)
    for Key, Value in ipairs(AddOnTable.ConfigOptions.Container.CheckButtons) do
        local checkButton = self["CheckButton"..Key]
        checkButton:UpdateText(Value.Text, Value.TooltipText)
    end

    -- set slider bounds
    for Key, Value in ipairs(AddOnTable.ConfigOptions.Container.SliderBars) do
        local slider = self["Slider"..Key]
        slider.Low:SetText(Value.Low)
        slider.High:SetText(Value.High)
        slider.tooltipText = Value.TooltipText
        slider.valueStep   = Value.Step
    end

    CreateBagSetBagButtons(self)
end

local function ContainerBackgroundChanged(newBackgroundId)
    AddOnTable.Functions.DebugMessage("Temp", "container background was changed", newBackgroundId)

    BBConfig[SelectedBags][SelectedContainer].Background = newBackgroundId
    local container = AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]
    container:Rebuild()
    container:Update()
end

local function BackgroundSelection_isSelected(index)
    return index == BBConfig[SelectedBags][SelectedContainer].Background
end

function BaudBagOptionsBagSetMixin:InitializeContent()
    self.BackgroundSelection:Setup(TextureNames, BackgroundSelection_isSelected, ContainerBackgroundChanged)
end

local function UpdateBagButtons(self)
    -- prepare vars
    local Button, Check, Container, Texture
    local ContNum = 1
    local Bags = SetSize[SelectedBags]
    local BagSet = AddOnTable.Sets[SelectedBags]

    -- load bag specific options (position and show each button that belongs to the current set,
    --		check joined box and create container frames)
    BagSet:ForEachBag(
        function(Bag, Index)
            Button	= _G[Prefix.."Bag"..Index]
            Check	= _G[Prefix.."JoinCheck"..Index]

            if (Index == 1) then
                -- only the first bag needs its position set, since the others are anchored to it
                Button:SetPoint("LEFT", self.BagFrame, "CENTER", ((Bags / 2) * -44), 0)
            elseif (not BagSet.Type.CanContainerBeJoined(Bag)) then
                -- some containers, like the reagent bank and the reagent bag might not be joined with anything else
                _G[Prefix.."Container"..ContNum]:SetPoint("RIGHT", Prefix.."Bag"..(Index - 1), "RIGHT", 6,0)
                ContNum = ContNum + 1
                _G[Prefix.."Container"..ContNum]:SetPoint("LEFT", Prefix.."Bag"..Index, "LEFT", -6,0)
                Check:SetChecked(false)
                Check:Disable()
            else
                -- all other bag slots that are actually filled with bags may have a changeable joined state
                if (BagSet.SubContainers[Bag].Size == 0) then
                    Check:SetChecked(true)
                    Check:Disable()
                else
                    Check:SetChecked(BBConfig[SelectedBags].Joined[Index]~=false)
                    Check:Enable()
                end

                if not Check:GetChecked() then
                    -- if not joined the last container needs to be aligned to the last bag and the current container needs to start here
                    _G[Prefix.."Container"..ContNum]:SetPoint("RIGHT", Prefix.."Bag"..(Index - 1), "RIGHT", 6,0)
                    ContNum = ContNum + 1
                    _G[Prefix.."Container"..ContNum]:SetPoint("LEFT", Prefix.."Bag"..Index, "LEFT", -6,0)
                end
            end
			
            -- assign bag texture, id and get item to be shown
            Texture = BagSet:GetSubContainerTexture(Bag)
            Button.Icon:SetTexture(Texture or select(2, AddOnTable.BlizzAPI.GetInventorySlotInfo("BAG0SLOT")))
            Button:SetID(ContNum)
            Button.SubContainerId = Bag
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
end

function BaudBagOptionsBagSetMixin:UpdateContent()
    -- update global checkboxes
    self.EnabledCheck:SetChecked(BBConfig[SelectedBags].Enabled~=false)
    self.CloseAllCheck:SetChecked(BBConfig[SelectedBags].CloseAll~=false)

    local linkedSetType = AddOnTable.Sets[SelectedBags].Type.LinkedSet()
    if (linkedSetType) then
        self.LinkedSet.Image:Show()
        self.LinkedSet.tooltipText = format( Localized.EnabledLinkedSet, linkedSetType.Name)
    else
        self.LinkedSet.Image:Hide()
        self.LinkedSet.tooltipText = ""
    end

    UpdateBagButtons(self)

    -- load container name into the textbox
    local nameInput = self.NameInput
    nameInput:SetText(BBConfig[SelectedBags][SelectedContainer].Name or "test")
    nameInput:SetCursorPosition(0)

    -- load slider values
    for Key, Value in ipairs(AddOnTable.ConfigOptions.Container.SliderBars) do
        local Slider = self["Slider"..Key]
        Slider:SetValue(BBConfig[SelectedBags][SelectedContainer][Value.SavedVar])
    end

    -- load checkbox values
    for Key, Value in ipairs(AddOnTable.ConfigOptions.Container.CheckButtons) do
        local Button = self["CheckButton"..Key]
        Button:SetChecked(BBConfig[SelectedBags][SelectedContainer][Value.SavedVar])
    end

    -- load checkbox enabled
    for Key, Value in ipairs(AddOnTable.ConfigOptions.Container.CheckButtons) do
        local Button = self["CheckButton"..Key]
        if (Value.DependsOn ~= nil and not BBConfig[SelectedBags][SelectedContainer][Value.DependsOn]) then
            Button:Disable()
        else
            Button:Enable()
        end
    end

    local selectedBackground = BBConfig[SelectedBags][SelectedContainer].Background
    self.BackgroundSelection:UpdateSelection(selectedBackground)
end

function BaudBagOptionsBagSetMixin:ChangeBagSet(bagSetId)
    SelectedBags = bagSetId
    BaudBagOptions:Update()
end

BaudBagLinkedSetMixin = {}

function BaudBagLinkedSetMixin:LinkedSet_OnEnter()
    if ( self.tooltipText ) then
        GetAppropriateTooltip():SetOwner(self, self.tooltipOwnerPoint or "ANCHOR_RIGHT")
        GetAppropriateTooltip():SetText(self.tooltipText, nil, nil, nil, nil, true)
    end
end

---@class OptionsCheckButton: CheckButton
---@field Text FontString Holds the visible text for the button. Note: tag in XML is named ButtonText which (according to schema) is just an alias for FontString
---@field tooltipText string text to show in tooltip on hover
---@field tooltipOwnerPoint TooltipAnchor
---@field tooltipRequirement string
BaudBagOptionsCheckButtonMixin = {}

function BaudBagOptionsCheckButtonMixin:UpdateText(text, tooltip)
    self:SetText(text)
    self.tooltipText = tooltip
    self:SetWidth(self:GetNormalTexture():GetWidth() + self.Text:GetWidth() + 5) -- first 5 is the offset between text and texture, the second 5 is extra spacing that the text seems to need
end

function BaudBagOptionsCheckButtonMixin:OnEnter()
    if ( self.tooltipText ) then
        GetAppropriateTooltip():SetOwner(self, self.tooltipOwnerPoint or "ANCHOR_RIGHT")
        GetAppropriateTooltip():SetText(self.tooltipText, nil, nil, nil, nil, true)
    end
    if ( self.tooltipRequirement ) then
        GetAppropriateTooltip():AddLine(self.tooltipRequirement, 1.0, 1.0, 1.0, true)
        GetAppropriateTooltip():Show()
    end
end

function BaudBagOptionsCheckButtonMixin:OnLeave()
    GetAppropriateTooltip():Hide()
end

function BaudBagOptionsCheckButtonMixin:OnClick()
    if self.settingsType == "Global" then
        local savedVar = AddOnTable.ConfigOptions.Global.CheckButtons[self:GetID()].SavedVar
        AddOnTable.Functions.DebugMessage("Options", "Update global variable: "..savedVar)
        BBConfig[savedVar] = self:GetChecked()

        if (savedVar == "RarityColor") then
            AddOnTable.Functions.ForEachOpenContainer(
                function (container)
                    container:Update()
                end
            )
        end
    elseif self.settingsType == "BagSet" then
        local savedVar = self.savedVar
        AddOnTable.Functions.DebugMessage("Options", "Update bag set variable: "..savedVar)
        
        BBConfig[SelectedBags][savedVar] = self:GetChecked()

        if (savedVar == "Enabled") then
            local linkedSetType = AddOnTable.Sets[SelectedBags].Type.LinkedSet()
            if (linkedSetType) then
                BBConfig[linkedSetType.Id][savedVar] = self:GetChecked()
            end
            if (not self:GetChecked()) then
                AddOnTable.Sets[SelectedBags]:Close()
                if (linkedSetType) then
                    AddOnTable.Sets[linkedSetType.Id]:Close()
                end
            end        
            AddOnTable:ConfigUpdated()
        end
    elseif self.settingsType == "Container" then
        local savedVar = AddOnTable.ConfigOptions.Container.CheckButtons[self:GetID()].SavedVar
        AddOnTable.Functions.DebugMessage("Options", "Update container variable: "..savedVar)
        BBConfig[SelectedBags][SelectedContainer][savedVar] = self:GetChecked()

        -- make sure options who need it (visible things) update the affected container
        if (savedVar == "BlankTop") or (savedVar == "RarityColor") then -- or (SavedVar == "RarityColorAltern") then
            AddOnTable.Functions.DebugMessage("Options", "Want to update container: "..Prefix.."Container"..SelectedBags.."_"..SelectedContainer)
            AddOnTable.Sets[SelectedBags].Containers[SelectedContainer]:Update() -- TODO: move to BaudBagBBConfig save?
        end
    elseif self.settingsType == "BagJoin" then
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
            tinsert(BBConfig[SelectedBags], ContNum, AddOnTable.Functions.CopyTable(BBConfig[SelectedBags][ContNum-1]))
        end
        AddOnTable.Sets[SelectedBags]:ReloadConfig()
    end
    BaudBagOptions:Update()
end
