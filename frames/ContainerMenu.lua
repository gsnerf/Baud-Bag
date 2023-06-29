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
    cleanupIgnoreButton.Text:SetText(AddOnTable.BlizzConstants.BAG_FILTER_IGNORE)
    self.BagSpecific.Cleanup.CleanupIgnore = cleanupIgnoreButton

    if (self.BagSet == BagSetType.Backpack.Id) then
        local cleanupBagsButton = CreateFrame("CheckButton", nil, self.BagSpecific.Cleanup, "BaudBagContainerMenuCheckButtonTemplate")
        cleanupBagsButton:SetPoint("TOP", self.BagSpecific.Cleanup.CleanupIgnore, "BOTTOM", 0, 0)
        cleanupBagsButton.Text:SetText(AddOnTable.BlizzConstants.BAG_CLEANUP_BAGS)
        cleanupBagsButton:SetScript("OnClick", AddOnTable.BlizzAPI.SortBags)
        self.BagSpecific.Cleanup.CleanupBags = cleanupBagsButton
    elseif (self.BagSet == BagSetType.Bank.Id and AddOnTable.State.BankOpen) then
        local cleanupBagsButton = CreateFrame("CheckButton", nil, self.BagSpecific.Cleanup, "BaudBagContainerMenuCheckButtonTemplate")
        cleanupBagsButton:SetPoint("TOP", self.BagSpecific.Cleanup.CleanupIgnore, "BOTTOM", 0, 0)
        if self.ContainerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER then
            cleanupBagsButton.Text:SetText(AddOnTable.BlizzConstants.BAG_CLEANUP_REAGENT_BANK)
            cleanupBagsButton:SetScript("OnClick", AddOnTable.BlizzAPI.SortReagentBankBags)
        else
            cleanupBagsButton.Text:SetText(AddOnTable.BlizzConstants.BAG_CLEANUP_BANK)
            cleanupBagsButton:SetScript("OnClick", AddOnTable.BlizzAPI.SortBankBags)
        end
        self.BagSpecific.Cleanup.CleanupBags = cleanupBagsButton
    end
end

local function setupFilterOptions(self)
    
    --[[
    local numberOfSubContainers = table.getn(containerObject.SubContainers)
    local firstSubContainerId = containerObject.SubContainers[1].ContainerId
    if (numberOfSubContainers == 1 and
        (
            firstSubContainerId == AddOnTable.BlizzConstants.BACKPACK_CONTAINER
            or
            firstSubContainerId == AddOnTable.BlizzConstants.BANK_CONTAINER
            or
            firstSubContainerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER
            or
            IsInventoryItemProfessionBag("player", AddOnTable.BlizzAPI.ContainerIDToInventoryID(firstSubContainerId))
        )
    ) then
        -- the backpack, bank or reagent bank themselves cannot have filters!
        return
    end
    ]]
    
    local toggleFilter = function(button, type, value)
        value = not value
        self.Container:SetFilterType(type, value)
        button:SetChecked(value)
        if (value) then
            -- todo: optionally show some kind of visualization
            --frame.FilterIcon.Icon:SetAtlas(BAG_FILTER_ICONS[i])
            --frame.FilterIcon:Show()
        else
            -- todo: hide optional visualization again
            --frame.FilterIcon:Hide()
        end
    end

    local lastButton = self.BagSpecific.Filter.Header
    for _, flag in AddOnTable.BlizzAPI.EnumerateBagGearFilters() do
        local filterButton = CreateFrame("CheckButton", nil, self.BagSpecific.Filter, "BaudBagContainerMenuCheckButtonTemplate")
        filterButton:SetPoint("TOP", lastButton, "BOTTOM", 0, 0)
        filterButton:SetChecked(self.Container:GetFilterType() == flag)
        filterButton:SetScript("OnClick", function() toggleFilter(filterButton, flag, self.Container:GetFilterType() == flag) end)
        filterButton.Text:SetText(AddOnTable.BlizzConstants.BAG_FILTER_LABELS[flag])
        lastButton = filterButton
    end
end

function BaudBagContainerMenuMixin:SetupBagSpecific()
    self.BagSpecific.Header.Label:SetText(Localized.MenuCatSpecific)
    self.BagSpecific.Lock.Text:SetText(Localized.LockPosition)
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
    self.General.ShowOptions.Text:SetText(Localized.Options)

    -- create general buttons if applicable

    if (self.BagSet == BagSetType.Backpack.Id) then
        local showBankButton = CreateFrame("CheckButton", nil, self.General, "BaudBagContainerMenuCheckButtonTemplate")
        showBankButton.Text:SetText(Localized.ShowBank)
        showBankButton:SetScript("OnClick", showBankButton.ToggleBank)
        showBankButton:SetPoint("TOP", self.General.ShowOptions, "BOTTOM")

        
        local backpackCanBeExtended = not (IsAccountSecured() and AddOnTable.BlizzAPI.GetContainerNumSlots(AddOnTable.BlizzConstants.BACKPACK_CONTAINER) > AddOnTable.BlizzConstants.BACKPACK_BASE_SIZE)
        if (backpackCanBeExtended) then
            local extendBackpack = CreateFrame("CheckButton", nil, self.General, "BaudBagContainerMenuCheckButtonTemplate")
            extendBackpack.Text:SetText(AddonTable.BlizzConstants.BACKPACK_AUTHENTICATOR_INCREASE_SIZE)
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

local function updateHeight(frame, bottomOffset)
    bottomOffset = bottomOffset or 0
    local children = { frame:GetChildren() }
    local targetHeight = 0
    for i, child in ipairs(children) do
        targetHeight = targetHeight + child:GetHeight()
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

function AddOnTable:CreateContainerMenuFrame(parentContainer)
    local menu = CreateFrame("Frame", name, parentContainer.Frame, "BaudBagContainerMenuTemplate")
    menu:Hide()
    menu.BagSet = parentContainer.BagSet.Id
    menu.ContainerId = parentContainer.Id
    menu.Container = parentContainer

    menu:SetupBagSpecific()
    menu:SetupGeneral()

    -- set size based on children
    updateHeight(menu.BagSpecific.Cleanup)
    updateHeight(menu.BagSpecific.Filter)
    updateHeight(menu.BagSpecific)
    updateHeight(menu.General)
    updateHeight(menu, 5)
    updateWidth(menu)
    return menu
end