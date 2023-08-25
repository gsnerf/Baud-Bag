local AddOnName, AddOnTable = ...
local Localized = AddOnTable.Localized
local _

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
    backdropColorAlpha = 0.5
}

local function setupCleanupOptions(self)
    local cleanupIgnoreButton = CreateFrame("CheckButton", nil, self.BagSpecific.Cleanup, "BaudBagContainerMenuCheckButtonTemplate")
    cleanupIgnoreButton:SetPoint("TOP")
    cleanupIgnoreButton:SetScript("OnClick", function() self.Container:SetCleanupIgnore( not self.Container:GetCleanupIgnore()) end)
    cleanupIgnoreButton:SetText(AddOnTable.BlizzConstants.BAG_FILTER_IGNORE)
    self.BagSpecific.Cleanup.CleanupIgnore = cleanupIgnoreButton

    if (self.BagSet == BagSetType.Backpack.Id) then
        local cleanupBagsButton = CreateFrame("CheckButton", nil, self.BagSpecific.Cleanup, "BaudBagContainerMenuCheckButtonTemplate")
        cleanupBagsButton:SetPoint("TOP", self.BagSpecific.Cleanup.CleanupIgnore, "BOTTOM", 0, 0)
        cleanupBagsButton:SetText(AddOnTable.BlizzConstants.BAG_CLEANUP_BAGS)
        cleanupBagsButton:SetScript("OnClick", AddOnTable.BlizzAPI.SortBags)
        self.BagSpecific.Cleanup.CleanupBags = cleanupBagsButton
    elseif (self.BagSet == BagSetType.Bank.Id and AddOnTable.State.BankOpen) then
        local cleanupBagsButton = CreateFrame("CheckButton", nil, self.BagSpecific.Cleanup, "BaudBagContainerMenuCheckButtonTemplate")
        cleanupBagsButton:SetPoint("TOP", self.BagSpecific.Cleanup.CleanupIgnore, "BOTTOM", 0, 0)
        if self.ContainerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER then
            cleanupBagsButton:SetText(AddOnTable.BlizzConstants.BAG_CLEANUP_REAGENT_BANK)
            cleanupBagsButton:SetScript("OnClick", AddOnTable.BlizzAPI.SortReagentBankBags)
        else
            cleanupBagsButton:SetText(AddOnTable.BlizzConstants.BAG_CLEANUP_BANK)
            cleanupBagsButton:SetScript("OnClick", AddOnTable.BlizzAPI.SortBankBags)
        end
        self.BagSpecific.Cleanup.CleanupBags = cleanupBagsButton
    end
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

    local lastButton = menu.BagSpecific.Filter.Header
    for index, filterType in AddOnTable.BlizzAPI.EnumerateBagGearFilters() do
        local filterButton = CreateFrame("CheckButton", nil, menu.BagSpecific.Filter, "BaudBagContainerMenuCheckButtonTemplate")
        filterButton:SetPoint("TOP", lastButton, "BOTTOM", 0, 0)
        filterButton:HookScript("OnClick", function(button) updateFilter(filterType, button:GetChecked()) end)
        filterButton:SetText(AddOnTable.BlizzConstants.BAG_FILTER_LABELS[filterType])
        lastButton = filterButton
        menu.BagSpecific.Filter["FilterButton"..index] = filterButton
    end
end

function BaudBagContainerMenuMixin:SetupBagSpecific()
    self.BagSpecific.Header.Label:SetText(Localized.MenuCatSpecific)
    self.BagSpecific.Lock:SetText(Localized.LockPosition)
    self.BagSpecific.Filter.Header.Label:SetText(AddOnTable.BlizzConstants.BAG_FILTER_ASSIGN_TO)
    
    -- create sorting stuff if applicable
    if (AddOnTable.BlizzAPI.SupportsContainerSorting()) then
        AddOnTable.Functions.DebugMessage("ContainerMenu", "Creating sorting buttons for container", self.BagSet, self.ContainerId, self.Container)
        
        setupCleanupOptions(self)
        setupFilterOptions(self)
        
        -- TODO: these kind of operations cannot be done on initialization, because the container can't have that information yet
        --cleanupIgnoreButton:SetChecked(container:GetCleanupIgnore())
    end
end

function BaudBagContainerMenuMixin:SetupGeneral()
    self.General.Header.Label:SetText(Localized.MenuCatGeneral)
    self.General.ShowOptions:SetText(Localized.Options)

    -- create general buttons if applicable

    if (self.BagSet == BagSetType.Backpack.Id) then
        local showBankButton = CreateFrame("CheckButton", nil, self.General, "BaudBagContainerMenuCheckButtonTemplate")
        showBankButton:SetText(Localized.ShowBank)
        showBankButton:SetScript("OnClick", showBankButton.ToggleBank)
        showBankButton:SetPoint("TOP", self.General.ShowOptions, "BOTTOM")

        
        local backpackCanBeExtended = not (IsAccountSecured() and AddOnTable.BlizzAPI.GetContainerNumSlots(AddOnTable.BlizzConstants.BACKPACK_CONTAINER) > AddOnTable.BlizzConstants.BACKPACK_BASE_SIZE)
        if (backpackCanBeExtended) then
            local extendBackpack = CreateFrame("CheckButton", nil, self.General, "BaudBagContainerMenuCheckButtonTemplate")
            extendBackpack:SetText(AddOnTable.BlizzConstants.BACKPACK_AUTHENTICATOR_INCREASE_SIZE)
            extendBackpack:SetScript("OnClick", extendBackpack.AddSlots)
            extendBackpack:SetPoint("TOP", showBankButton, "BOTTOM")
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

function BaudBagContainerMenuMixin:OnShow()
    AddOnTable.Functions.DebugMessage("ContainerMenu", "Called OnShow")
    self.General.ShowOptions:SetChecked(false)
    updateFilterSelection(self)
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

local function getCheckboxWidth(checkbox)
    if (checkbox) then
        return checkbox:GetWidth() + 20 + checkbox.Text:GetWidth()
    end
    return 0
end

local function updateWidth(frame)
    local widths = {}
    table.insert(widths, getCheckboxWidth(frame.BagSpecific.Lock))
    table.insert(widths, getCheckboxWidth(frame.BagSpecific.Cleanup.CleanupIgnore))
    table.insert(widths, getCheckboxWidth(frame.General.ShowOptions))

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

local function updateFilter(menu, container)
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

function BaudBagContainerMenuMixin:Update()
    updateFilter(self, self.Container)
    updateSize(self)
end

function BaudBagContainerMenuMixin:OnEvent(event, ...)
    AddOnTable.Functions.DebugMessage("ContainerMenu", "OnEvent was called with '"..event.."' event, with values",  ...)
    self:Update()
end

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

function BaudBagContainerMenuButtonMixin:JumpToOptions()
    local containerMenu = self:GetParent():GetParent()

    local bagSet = containerMenu.BagSet
    local containerId = containerMenu.ContainerId

    BaudBagOptionsSelectContainer(bagSet, containerId)
    -- working around what seems to be a bug in blizzards code, preventing this to work on the first try..
    InterfaceOptionsFrame_OpenToCategory("Baud Bag")
    InterfaceOptionsFrame_OpenToCategory("Baud Bag")

    containerMenu:Hide()
end

function BaudBagContainerMenuButtonMixin:ToggleBank()
    local firstBankContainer = AddOnTable.Sets[2].Containers[1]
    if firstBankContainer.Frame:IsShown() then
        firstBankContainer.Frame:Hide()
        AddOnTable.Sets[2]:AutoClose()
    else
        firstBankContainer.Frame:Show()
        AddOnTable.Sets[2]:AutoOpen()
    end
end

function BaudBagContainerMenuButtonMixin:AddSlots()
    StaticPopup_Show("BACKPACK_INCREASE_SIZE")
end

function AddOnTable:CreateContainerMenuFrame(parentContainer)
    local menu = CreateFrame("Frame", name, parentContainer.Frame, "BaudBagContainerMenuTemplate")
    menu:Hide()
    menu.BagSet = parentContainer.BagSet.Id
    menu.ContainerId = parentContainer.Id
    menu.Container = parentContainer

    menu:SetupBagSpecific()
    menu:SetupGeneral()

    if (parentContainer.BagSet.Id == BagSetType.Backpack.Id) then
        menu:RegisterEvent("BAG_SLOT_FLAGS_UPDATED")
    elseif (parentContainer.BagSet.Id == BagSetType.Bank.Id) then
        menu:RegisterEvent("BANK_BAG_SLOT_FLAGS_UPDATED")
    end
    menu:SetScript("OnEvent", menu.OnEvent)
    
    updateSize(menu)
    
    return menu
end