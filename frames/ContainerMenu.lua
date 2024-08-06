local AddOnName, AddOnTable = ...
local Localized = AddOnTable.Localized
local _

-- ------------------------------------------------------------------------------
--  check button for usage in container menu   
-- ------------------------------------------------------------------------------

BaudBagContainerMenuButtonMixin = {}

function BaudBagContainerMenuButtonMixin:ToggleContainerLock()
    local containerMenu = self:GetParent():GetParent()

    local bagSet = containerMenu.BagSet
    local containerId = containerMenu.ContainerId
    local currentValue = AddOnTable.Config[bagSet][containerId].Locked

    AddOnTable.Functions.DebugMessage("ContainerMenu", "toggeling container lock (bagSet, containerId, currentConfig)", bagSet, containerId, currentValue)

    AddOnTable.Config[bagSet][containerId].Locked = not currentValue
    containerMenu:Hide()
end

function BaudBagContainerMenuButtonMixin:ToggleCleanupIgnore()
    local container = self.Menu.Container
    container:SetCleanupIgnore( not container:GetCleanupIgnore())
    self.Menu:Hide()
end

function BaudBagContainerMenuButtonMixin:SortBags()
    AddOnTable.BlizzAPI.SortBags()
    self.Menu:Hide()
end

function BaudBagContainerMenuButtonMixin:SortBankBags()
    AddOnTable.BlizzAPI.SortBankBags()
    self.Menu:Hide()
end

function BaudBagContainerMenuButtonMixin:SortReagentBankBags()
    AddOnTable.BlizzAPI.SortReagentBankBags()
    self.Menu:Hide()
end

function BaudBagContainerMenuButtonMixin:JumpToOptions()
    local containerMenu = self:GetParent():GetParent()

    local bagSet = containerMenu.BagSet
    local containerId = containerMenu.ContainerId

    BaudBagOptionsSelectContainer(bagSet, containerId)
    local category = AddOnTable.SettingsCategory
    if (category ~= nil) then
        -- retail options system
        AddOnTable.Functions.DebugMessage("Options", "Using new settings system to open category", category:GetID())
        Settings.OpenToCategory(category:GetID())
    else
        -- classic options system
        -- working around what seems to be a bug in blizzards code, preventing this to work on the first try..
        InterfaceOptionsFrame_OpenToCategory("Baud Bag")
        InterfaceOptionsFrame_OpenToCategory("Baud Bag")
    end

    containerMenu:Hide()
end

function BaudBagContainerMenuButtonMixin:ToggleBank()
    local firstBankContainer = AddOnTable.Sets[BagSetType.Bank.Id].Containers[1]
    if firstBankContainer.Frame:IsShown() then
        firstBankContainer.Frame:Hide()
        AddOnTable.Sets[BagSetType.Bank.Id]:AutoClose()
    else
        firstBankContainer.Frame:Show()
        AddOnTable.Sets[BagSetType.Bank.Id]:AutoOpen()
    end

    local containerMenu = self:GetParent():GetParent()
    containerMenu:Hide()
end

function BaudBagContainerMenuButtonMixin:ToggleEnableBank()
    local currentValue = AddOnTable.Config[2].Enabled
    AddOnTable.Config[2].Enabled = not currentValue
    AddOnTable.Sets[2]:Close()
    BaudBagUpdateFromBBConfig()
    --AddOnTable.UpdateBankParents()
    self:GetParent().EnableBankButton:SetChecked(AddOnTable.Config[2].Enabled)
end

function BaudBagContainerMenuButtonMixin:AddSlots()
    StaticPopup_Show("BACKPACK_INCREASE_SIZE")

    local containerMenu = self:GetParent():GetParent()
    containerMenu:Hide()
end

function BaudBagContainerMenuButtonMixin:GetMinimumWidth()
    return self.textureWidth + 5 + self.Text:GetWidth()
end

-- ------------------------------------------------------------------------------
--  container menu itself  
-- ------------------------------------------------------------------------------

BaudBagContainerMenuMixin = {
    backdropInfo = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
         edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
         tile = true,
         tileEdge = true,
         tileSize = 8,
         edgeSize = 8,
         insets = { left = 2, right = 2, top = 2, bottom = 2 },
    },
    backdropColor = CreateColor( 0.0, 0.0, 0.0 ),
    backdropColorAlpha = 0.9,
    headers = {},
    checkButtons = {}
}

function BaudBagContainerMenuMixin:CollectHeaders()
    table.insert(self.headers, self.BagSpecific.Header.Label)
    table.insert(self.headers, self.BagSpecific.Filter.Header.Label)
    table.insert(self.headers, self.General.Header.Label)
end

local function setupCleanupOptions(self)
    self.BagSpecific.Cleanup:Show()

    local cleanupIgnoreButton = CreateFrame("CheckButton", nil, self.BagSpecific.Cleanup, "BaudBagContainerMenuCheckButtonTemplate")
    cleanupIgnoreButton.Menu = self
    cleanupIgnoreButton:SetPoint("TOP")
    cleanupIgnoreButton:SetScript("OnClick", cleanupIgnoreButton.ToggleCleanupIgnore)
    cleanupIgnoreButton:SetText(AddOnTable.BlizzConstants.BAG_FILTER_IGNORE)
    self.BagSpecific.Cleanup.CleanupIgnore = cleanupIgnoreButton
    table.insert(self.checkButtons, cleanupIgnoreButton)

    local cleanupBagsButton = CreateFrame("CheckButton", nil, self.BagSpecific.Cleanup, "BaudBagContainerMenuCheckButtonTemplate")
    cleanupBagsButton.Menu = self
    cleanupBagsButton:SetPoint("TOP", self.BagSpecific.Cleanup.CleanupIgnore, "BOTTOM", 0, 0)
    -- for bank bags it's not possible to identify which text or script to call right now, need to do that in the update/onshow handlers
    if (self.BagSet == BagSetType.Backpack.Id) then
        cleanupBagsButton:SetText(AddOnTable.BlizzConstants.BAG_CLEANUP_BAGS)
        cleanupBagsButton:SetScript("OnClick", cleanupBagsButton.SortBags)
    end
    self.BagSpecific.Cleanup.CleanupBags = cleanupBagsButton
    table.insert(self.checkButtons, cleanupBagsButton)
end

local function updateFilterSelection(self)
    for index, flag in AddOnTable.BlizzAPI.EnumerateBagGearFilters() do
        self.BagSpecific.Filter["FilterButton"..index]:SetChecked(self.Container:GetFilterType() == flag)
    end
end

local function setupFilterOptions(menu)
    local updateFilter = function(filterType, newValue)
        AddOnTable.Functions.DebugMessage("ContainerMenu", "Toggelling filter '"..AddOnTable.BlizzConstants.BAG_FILTER_LABELS[filterType].."' with value for container '"..menu.Container.Id.."'", newValue)
        menu.Container:SetFilterType(filterType, newValue)
        menu:Hide()
    end

    menu.BagSpecific.Filter:Show()

    local lastButton = menu.BagSpecific.Filter.Header
    for index, filterType in AddOnTable.BlizzAPI.EnumerateBagGearFilters() do
        local filterButton = CreateFrame("CheckButton", nil, menu.BagSpecific.Filter, "BaudBagContainerMenuCheckButtonTemplate")
        filterButton:SetPoint("TOP", lastButton, "BOTTOM", 0, 0)
        filterButton:HookScript("OnClick", function(button) updateFilter(filterType, button:GetChecked()) end)
        filterButton:SetText(AddOnTable.BlizzConstants.BAG_FILTER_LABELS[filterType])
        lastButton = filterButton
        menu.BagSpecific.Filter["FilterButton"..index] = filterButton
        table.insert(menu.checkButtons, filterButton)
    end
end

function BaudBagContainerMenuMixin:SetupBagSpecific()
    self.BagSpecific.Header.Label:SetText(Localized.MenuCatSpecific)
    self.BagSpecific.Lock:SetText(Localized.LockPosition)
    self.BagSpecific.Filter.Header.Label:SetText(AddOnTable.BlizzConstants.BAG_FILTER_ASSIGN_TO)

    table.insert(self.checkButtons, self.BagSpecific.Lock)
    
    -- create sorting stuff if applicable
    if (AddOnTable.BlizzAPI.SupportsContainerSorting()) then
        AddOnTable.Functions.DebugMessage("ContainerMenu", "Creating sorting buttons for container", self.BagSet, self.ContainerId, self.Container)
        
        setupCleanupOptions(self)
        setupFilterOptions(self)
    end
end

function BaudBagContainerMenuMixin:SetupGeneral()
    self.General.Header.Label:SetText(Localized.MenuCatGeneral)
    self.General.ShowOptions:SetText(Localized.Options)

    table.insert(self.checkButtons, self.General.ShowOptions)

    -- create general buttons if applicable

    if (self.BagSet == BagSetType.Backpack.Id) then
        local showBankButton = CreateFrame("CheckButton", nil, self.General, "BaudBagContainerMenuCheckButtonTemplate")
        showBankButton:SetText(Localized.ShowBank)
        showBankButton:SetScript("OnClick", showBankButton.ToggleBank)
        showBankButton:SetPoint("TOP", self.General.ShowOptions, "BOTTOM")
        self.General.ShowBankButton = showBankButton
        table.insert(self.checkButtons, showBankButton)

        local enableBankButton = CreateFrame("CheckButton", nil, self.General, "BaudBagContainerMenuCheckButtonTemplate")
        enableBankButton:SetText(Localized.EnableBank)
        enableBankButton:SetScript("OnClick", enableBankButton.ToggleEnableBank)
        enableBankButton:SetPoint("TOP", showBankButton, "BOTTOM" )
        enableBankButton:SetChecked(AddOnTable.Config[2].Enabled)
        self.General.EnableBankButton = enableBankButton
        table.insert(self.checkButtons, enableBankButton)

        local backpackCanBeExtended = not (IsAccountSecured() and AddOnTable.BlizzAPI.GetContainerNumSlots(AddOnTable.BlizzConstants.BACKPACK_CONTAINER) > AddOnTable.BlizzConstants.BACKPACK_BASE_SIZE)
        if (backpackCanBeExtended) then
            local extendBackpack = CreateFrame("CheckButton", nil, self.General, "BaudBagContainerMenuCheckButtonTemplate")
            extendBackpack:SetText(AddOnTable.BlizzConstants.BACKPACK_AUTHENTICATOR_INCREASE_SIZE)
            extendBackpack:SetScript("OnClick", extendBackpack.AddSlots)
            extendBackpack:SetPoint("TOP", showBankButton, "BOTTOM")
            table.insert(self.checkButtons, extendBackpack)
        end
    end

end

function BaudBagContainerMenuMixin:Toggle()
    AddOnTable.Functions.DebugMessage("ContainerMenu", "Called Toggle", self:IsVisible())
    if (self:IsVisible()) then
        self:Hide()
    else
        self:Show()
    end
end

local function finishCleanupButtonSetup(menu)
    if (menu.BagSet == BagSetType.Bank.Id) then
        local container = menu.Container
        local cleanupBagsButton = menu.BagSpecific.Cleanup.CleanupBags
        
        local isReagentBank = container.SubContainers[1]:GetID() == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER

        cleanupBagsButton:SetShown(AddOnTable.State.BankOpen)
        cleanupBagsButton:SetText(isReagentBank and AddOnTable.BlizzConstants.BAG_CLEANUP_REAGENT_BANK or AddOnTable.BlizzConstants.BAG_CLEANUP_BANK)
        cleanupBagsButton:SetScript("OnClick", isReagentBank and cleanupBagsButton.SortReagentBankBags or cleanupBagsButton.SortBankBags)
    end
end

local function finishFilterSetup(menu, container)
    if next(container.SubContainers) == nil then
        return
    end
    
    -- update visibility based on container content
    local numberOfSubContainers = table.getn(container.SubContainers)
    local firstSubContainerId = container.SubContainers[1].ContainerId
    local shouldShowFilters = true
    if (numberOfSubContainers == 1 and
        (
            firstSubContainerId == AddOnTable.BlizzConstants.BACKPACK_CONTAINER
            or
            firstSubContainerId == AddOnTable.BlizzConstants.BANK_CONTAINER
            or
            firstSubContainerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER
            or
            AddOnTable.BlizzAPI.IsInventoryItemProfessionBag("player", AddOnTable.BlizzAPI.ContainerIDToInventoryID(firstSubContainerId))
        )
    ) then
        -- the backpack, bank or reagent bank themselves cannot have filters!
        shouldShowFilters = false
    end

    menu.BagSpecific.Filter:SetShown(shouldShowFilters)

    if (shouldShowFilters) then
        updateFilterSelection(menu)
    end
end

local function updateHeight(frame, bottomOffset)
    bottomOffset = bottomOffset or 0
    local children = { frame:GetChildren() }
    local targetHeight = 0
    for i, child in ipairs(children) do
        targetHeight = targetHeight + (child:IsShown() and child:GetHeight() or 0)
    end
    targetHeight = targetHeight + bottomOffset
    frame:SetHeight(targetHeight)
end

local function updateWidth(frame)
    local widths = {}
    for _, header in ipairs (frame.headers) do
        table.insert(widths, header:GetWidth() + 10) -- width + offset (for padding)
    end
    for _, checkButton in ipairs (frame.checkButtons) do
        table.insert(widths, checkButton:GetMinimumWidth())
    end

    local targetWidth = 0
    for _, width in ipairs(widths) do
        targetWidth = (width > targetWidth) and width or targetWidth
    end
    frame:SetWidth(targetWidth + 10)
end

local function updateSize(menu)
    -- set size based on children
    updateHeight(menu.BagSpecific.Cleanup)
    updateHeight(menu.BagSpecific.Filter)
    updateHeight(menu.BagSpecific)
    updateHeight(menu.General)
    updateHeight(menu, 5)
    updateWidth(menu)
end

function BaudBagContainerMenuMixin:OnShow()
    AddOnTable.Functions.DebugMessage("ContainerMenu", "Called OnShow")

    -- events
    if (self.BagSet == BagSetType.Backpack.Id) then
        self:RegisterEvent("BAG_SLOT_FLAGS_UPDATED")
    elseif (self.BagSet == BagSetType.Bank.Id) then
        self:RegisterEvent("BANK_BAG_SLOT_FLAGS_UPDATED")
    end
    self:RegisterEvent("GLOBAL_MOUSE_DOWN")

    -- general stuff
    self.BagSpecific.Lock:SetChecked(AddOnTable.Config[self.BagSet][self.ContainerId].Locked)
    self.General.ShowOptions:SetChecked(false)
    if (self.General.ShowBankButton) then
        self.General.ShowBankButton:SetChecked(false)
    end
    
    -- expansion specific feature container sorting
    if (AddOnTable.BlizzAPI.SupportsContainerSorting()) then
        self.BagSpecific.Cleanup.CleanupIgnore:SetChecked(self.Container:GetCleanupIgnore())
        self.BagSpecific.Cleanup.CleanupBags:SetChecked(false)

        finishCleanupButtonSetup(self)
        finishFilterSetup(self, self.Container)
    end
    updateSize(self)
end

function BaudBagContainerMenuMixin:OnHide()
    self:UnregisterEvent("BAG_SLOT_FLAGS_UPDATED")
    self:UnregisterEvent("BANK_BAG_SLOT_FLAGS_UPDATED")
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
end

function BaudBagContainerMenuMixin:Update()
    if self.BagSpecific.Filter:IsShown() and AddOnTable.BlizzAPI.SupportsContainerSorting() then
        updateFilterSelection(self)
    end
end

function BaudBagContainerMenuMixin:OnEvent(event, ...)
    AddOnTable.Functions.DebugMessage("ContainerMenu", "OnEvent was called with '"..event.."' event, with values",  ...)
    
    if (event == "BAG_SLOT_FLAGS_UPDATED" or event == "BANK_BAG_SLOT_FLAGS_UPDATED") then
        self:Update()
    end

    if (event == "GLOBAL_MOUSE_DOWN") then
        if not self:IsMouseOver() then
            self:Hide()
        end
    end
end

-- ------------------------------------------------------------------------------
--  creator in addon name space
-- ------------------------------------------------------------------------------

function AddOnTable:CreateContainerMenuFrame(parentContainer)
    local menu = CreateFrame("Frame", name, parentContainer.Frame, "BaudBagContainerMenuTemplate")
    menu:Hide()
    menu.BagSet = parentContainer.BagSet.Id
    menu.ContainerId = parentContainer.Id
    menu.Container = parentContainer

    menu:CollectHeaders()
    menu:SetupBagSpecific()
    menu:SetupGeneral()

    updateSize(menu)
    
    return menu
end

-- this is supposed to be a temporary event handler, until container has been rewritten to use mixins
function BaudBagContainerMenu_Show(self)
    local Container = self:GetParent()
    local containerMenu = AddOnTable.Sets[Container.BagSet].Containers[Container:GetID()].Menu
    containerMenu:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
    containerMenu:Toggle()
end
