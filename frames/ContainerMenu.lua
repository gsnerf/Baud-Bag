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

function BaudBagContainerMenuMixin:SetupBagSpecific()
    self.BagSpecific.Header.Label:SetText(Localized.MenuCatSpecific)
    self.BagSpecific.Lock.Text:SetText(Localized.LockPosition)
    
    -- create sorting stuff if applicable
    if (AddOnTable.BlizzAPI.SupportsContainerSorting()) then
        AddOnTable.Functions.DebugMessage("ContainerMenu", "Creating sorting buttons for container", self.BagSet, self.ContainerId, self.Container)
        local cleanupIgnoreButton = CreateFrame("CheckButton", nil, self.BagSpecific.SortingFunctions, "BaudBagContainerMenuCheckButtonTemplate")
        self.BagSpecific.SortingFunctions.CleanupIgnore = cleanupIgnoreButton
        cleanupIgnoreButton:SetScript("OnClick", function() self.Container:SetCleanupIgnore( not self.Container:GetCleanupIgnore()) end)
        cleanupIgnoreButton.Text:SetText(BAG_FILTER_IGNORE)
        
        -- TODO: these kind of operations cannot be done on initialization, because the container can't have that information yet
        --cleanupIgnoreButton:SetChecked(container:GetCleanupIgnore())
    end
end

function BaudBagContainerMenuMixin:SetupGeneral()
    self.General.Header.Label:SetText(Localized.MenuCatGeneral)
    self.General.ShowOptions.Text:SetText(Localized.Options)

    -- create general buttons if applicable
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

local function updateHeight(frame)
    local children = { frame:GetChildren() }
    local targetHeight = 0
    for i, child in ipairs(children) do
        targetHeight = targetHeight + child:GetHeight()
    end
    targetHeight = targetHeight + 5 -- this is for the bottom "padding" between the frames border and the content
    frame:SetHeight(targetHeight)
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
    updateHeight(menu.BagSpecific.SortingFunctions)
    updateHeight(menu.BagSpecific)
    updateHeight(menu.General)
    updateHeight(menu)
    return menu
end