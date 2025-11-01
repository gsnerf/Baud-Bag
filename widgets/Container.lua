---@class AddonNamespace
local AddOnTable = select(2, ...)
local AddOnName = select(1, ...)
local Localized = AddOnTable.Localized
local _

-- -> possibly move this to default config?
local FadeTime = 0.2

---@class Container
local Prototype = {
    Id = nil,
    Name = "DefaultContainer",
    ---@class Frame
    Frame = nil,
    ---@type SubContainer[]
    SubContainers = nil,
    ---@class BagSetTypeClass
    BagSet = nil,
    -- the values below aren't used yet
    Columns = 11,
    Icon = "",
    Locked = false
}

function Prototype:GetName()
    return self.Name
end

function Prototype:SetName(name)
    self.Name = name
end

function Prototype:UpdateName()
    local containerConfig = BBConfig[self.Frame.BagSet][self.Id]
    local targetName = containerConfig.Name or ""
    local targetColor = NORMAL_FONT_COLOR

    if (self.BagSet.SupportsCache and self.BagSet.ShouldUseCache()) then
        targetName = containerConfig.Name..AddOnTable.Localized.Offline
        targetColor = RED_FONT_COLOR
    end

    local nameWidget = self.Frame.Name
    nameWidget:SetText(targetName)
    nameWidget:SetTextColor(targetColor.r, targetColor.g, targetColor.b)
end

function Prototype:SaveCoordsToConfig()
    AddOnTable.Functions.DebugMessage("Container", "Saving container coords to config (name)", self.Name)
    local scale = self.Frame:GetScale()
    local x, y = self.Frame:GetCenter()
    x = x * scale
    y = y * scale
    BBConfig[self.Frame.BagSet][self.Id].Coords = {x, y}
end

function Prototype:UpdateFromConfig()
    if (self.Frame == nil) then
        AddOnTable.Functions.DebugMessage("Container", "Frame doesn't exist yet. Called UpdateFromConfig() to early???", self.Id, self.Name)
        return
    end
    AddOnTable.Functions.DebugMessage("Container", "Updating container from config (name)", self.Name)

    local containerConfig = BBConfig[self.Frame.BagSet][self.Id]

    if not containerConfig.Coords then
        self:SaveCoordsToConfig()
    end

    local scale = containerConfig.Scale / 100
    local x, y = unpack(containerConfig.Coords)

    self.Frame:ClearAllPoints()
    self.Frame:SetScale(scale)
    self.Frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (x / scale), (y / scale))
    self.Frame.Name:SetText(containerConfig.Name or "")
end

function Prototype:Rebuild()
    local numberOfSlots = 0
    for _, subContainer in pairs(self.SubContainers) do
        subContainer:Rebuild()
        numberOfSlots = numberOfSlots + subContainer.Size
    end
    self.Frame.Slots = numberOfSlots
    if (numberOfSlots > 0) then
        self:UpdateBackground()
    end
    self.Menu:Update()
end

function Prototype:Update()
    -- initialize bag update
    self.Frame.Refresh   = false
    self:UpdateName()
    local contCfg         = BBConfig[self.Frame.BagSet][self.Id]
    local theme           = AddOnTable.Themes[contCfg.Theme]
    local numberOfColumns = contCfg.Columns

    -- this will happen with the new reagent bag system when no reagent bag is equipped yet..
    if (self.Frame.Slots <= 0) then
        if self.Frame:IsShown() then
            AddOnTable.Functions.DebugMessage("Bags", "Container '"..contCfg.Name.."' has no contents, hiding...")
            self.Frame:Hide()
        end
        return
    end

    -- fix container slot size when only one item row exists
    if (self.Frame.Slots < numberOfColumns) then
        numberOfColumns = self.Frame.Slots
    end

    local column, row = 0, 1
    --The textured background puts its empty space on the upper left
    if contCfg.BlankTop then
        column = numberOfColumns - mod(self.Frame.Slots - 1, numberOfColumns) - 1
    end

    -- now go through all sub bags
    _, row = self:UpdateSubContainers(column, row)
    self.Frame:SetWidth(numberOfColumns * math.abs(theme.ItemButton.WidthOffset) - theme.BorderOffset.X)
    self.Frame:SetHeight(row * math.abs(theme.ItemButton.HeightOffset) - theme.BorderOffset.Y)
    
    AddOnTable.Functions.DebugMessage("Bags", "Finished Arranging Container.")
    AddOnTable:Container_Updated(self.BagSet, self.Id)
end

function Prototype:UpdateSubContainers(col, row)
    local contCfg       = BBConfig[self.Frame.BagSet][self.Id]
    local background    = contCfg.Theme
    local maxCols       = contCfg.Columns
    local slotLevel     = self.Frame:GetFrameLevel() + 1
    local container

    AddOnTable.Functions.DebugMessage("Container", "Started Updating SubContainers For Container", self.Id)

    for _, container in pairs(self.SubContainers) do
        AddOnTable.Functions.DebugMessage("Container", "Updating SubContainer with ID and Size", container.ContainerId, container.Size)
        -- not existing subbags (bags with no itemslots) are hidden
        if (container.Size <= 0) then
            container.Frame:Hide()
        else
            AddOnTable.Functions.DebugMessage("Bags", "Adding (bagName)", container.Name)

            local itemButtonConfig = AddOnTable.Themes[background] and AddOnTable.Themes[background].ItemButton or nil
            
            -- position item slots
            container:UpdateSlotContents(itemButtonConfig)
            col, row = container:UpdateSlotPositions(self.Frame, itemButtonConfig, col, row, maxCols, slotLevel)
            container.Frame:Show()
        end
    end

    -- TODO: It seems some how strange to pass this through 2 layers... let's see if we can get rid of that in the future!
    return col, row
end

function Prototype:UpdateBackground()
    local backgroundId = BBConfig[self.Frame.BagSet][self.Id].Background
    local themeId = BBConfig[self.Frame.BagSet][self.Id].Theme
    local backdrop = self.Frame.Backdrop
    backdrop:SetFrameLevel(self.Frame:GetFrameLevel())
    -- This shifts the name of the first bag frame over to make room for the extra button (bags button)
    local shiftName = (self.Frame:GetID() == 1) and 25 or 0
    -- TODO: this is a migration path away from "Backgrounds" towards "Themes"
    local left, right, top, bottom
    if (AddOnTable.Themes[themeId] ~= nil and AddOnTable.Themes[themeId].ContainerBackground ~= nil) then
        left, right, top, bottom = AddOnTable.Themes[themeId].ContainerBackground:Update(self.Frame, backdrop, shiftName)
    else
        left, right, top, bottom = AddOnTable["Backgrounds"][backgroundId]:Update(self.Frame, backdrop, shiftName)
    end
    self.Frame.Name:SetPoint("RIGHT", self.Frame:GetName().."MenuButton", "LEFT")

    backdrop:ClearAllPoints()
    backdrop:SetPoint("TOPLEFT", -left, top)
    backdrop:SetPoint("BOTTOMRIGHT", right, -bottom)
    self.Frame:SetHitRectInsets(-left, -right, -top, -bottom)
    if (self.Frame.UnlockInfo) then
        self.Frame.UnlockInfo:ClearAllPoints()
        self.Frame.UnlockInfo:SetPoint("TOPLEFT", -10, 3)
        self.Frame.UnlockInfo:SetPoint("BOTTOMRIGHT", 10, -3)
    end
end

function Prototype:UpdateFreeSlotsOverview(free, overall)
    if (self.Frame.FreeSlots == nil) then
        return
    end

    self.Frame.UpdateSlots = nil
    local columns = BBConfig[self.Frame.BagSet][self.Id].Columns
    self.Frame.FreeSlots:SetText(free.."/"..overall..(columns >= 4 and AddOnTable.Localized.Free or ""))
end

function Prototype:UpdateBagHighlight()
    for _, subContainer in pairs(self.SubContainers) do
        subContainer:UpdateOpenBagHighlight()
    end
end

function Prototype:GetFilterType()
    for _, container in pairs(self.SubContainers) do
        return self.BagSet.FilterData.GetFilterType(container)
    end

    return nil
end

function Prototype:SetFilterType(type, value)
    for _, container in pairs(self.SubContainers) do
        self.BagSet.FilterData.SetFilterType(container, type, value)
    end
end

function Prototype:GetCleanupIgnore()
    for _, container in pairs(self.SubContainers) do
        return self.BagSet.FilterData.GetCleanupIgnore(container)
    end
end

function Prototype:SetCleanupIgnore(value)
    for _, container in pairs(self.SubContainers) do
        self.BagSet.FilterData.SetCleanupIgnore(container, value)
    end
end

local Metatable = { __index = Prototype }

---@param bagSetType BagSetTypeClass
---@param bbContainerId integer the ID of the container indexed from 1 to X for each bag set
---@param containerTemplate string the name of the container template to use (it is expected that everything extends from BaudBagContainerTemplate)
function AddOnTable:CreateContainer(bagSetType, bbContainerId, containerTemplate)
    local container = _G.setmetatable({}, Metatable)
    container.Id = bbContainerId
    container.Name = AddOnName.."Container"..bagSetType.Id.."_"..bbContainerId
    AddOnTable.Functions.DebugMessage("Container", "Creating Container (name)", container.Name)
    local frame = _G[container.Name]
    if (frame == nil) then
        AddOnTable.Functions.DebugMessage("Container", "Frame for container does not yet exist, creating new Frame (name)", name)
        frame = CreateFrame("Frame", container.Name, BaudBagFrame, containerTemplate)
    end
    frame:SetID(bbContainerId)
    frame.BagSet = bagSetType.Id
    frame.Bags = {}
    container.Frame = frame
    container.SubContainers = {}
    container.BagSet = bagSetType
    if (container.Menu == nil) then
        container.Menu = AddOnTable:CreateContainerMenuFrame(container)
    end
    return container
end

function AddOnTable:Container_Updated(bagSet, containerId)
    -- just an empty hook for other addons
end


BaudBagContainerMixin = {}

function BaudBagContainerMixin:OnLoad(event, ...)
    tinsert(UISpecialFrames, self:GetName())
    self:RegisterForDrag("LeftButton")
end

function BaudBagContainerMixin:OnShow(event, ...)
    AddOnTable.Functions.DebugMessage("BagOpening", "BaudBagContainer_OnShow was called", self:GetName())
	
    if BBConfig.EnableFadeAnimation then
        -- check if the container was open before and closing now
        if self.FadeStart then
            return
        end
        
        -- container seems to not be visible, open and update
        self.FadeStart = GetTime()
    end
    PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
    local bagSet = AddOnTable.Sets[self.BagSet]
    ---@type Container
    local containerObject = bagSet.Containers[self:GetID()]
    containerObject:Update()
    if (containerObject.Frame.Slots > 0) then
        if (containerObject.Frame.UpdateBagHighlight) then
            containerObject.Frame:UpdateBagHighlight()
        else
            containerObject:UpdateBagHighlight()
        end
    end

    if (self:GetID() == 1) then
        AddOnTable.Sets[self.BagSet]:UpdateSlotInfo()
        self.BagsFrame:SetShown(BBConfig[self.BagSet].ShowBags ~= false)
    end
end

function BaudBagContainerMixin:OnUpdate(event, ...)
    ---@type Container
    local containerObject = AddOnTable.Sets[self.BagSet].Containers[self:GetID()]

    if (self.Refresh) then
        containerObject:Update()
        containerObject:UpdateBagHighlight()
    end

    if (self.UpdateSlots) then
        AddOnTable.Sets[self.BagSet]:UpdateSlotInfo()
    end

    if (AddOnTable.Config.EnableFadeAnimation and self.FadeStart) then
        local Alpha = (GetTime() - self.FadeStart) / FadeTime
        if not BBConfig.EnableFadeAnimation then
            -- immediate show/hide without animation
            Alpha = 1.1
        end
        if self.Closing then
            Alpha = 1 - Alpha
            if (Alpha < 0) then
                self.FadeStart = nil
                self:Hide()
                self.Closing = nil
                return
            end
        elseif (Alpha > 1) then
            self:SetAlpha(1)
            self.FadeStart = nil
            return
        end
        self:SetAlpha(Alpha)
    end
end

function BaudBagContainerMixin:OnHide(event, ...)
    AddOnTable.Functions.DebugMessage("BagOpening", "BaudBagContainer_OnHide was called", self:GetName())
    if (AddOnTable.Config.EnableFadeAnimation) then
        -- correctly handle if this is called while the container is still fading out
        if self.Closing then
            if self.FadeStart then
                self:Show()
            end
            return
        end

        -- set vars for fading out ans start process
        self.FadeStart = GetTime()
        self.Closing = true
    end
    PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
    self.AutoOpened = false
    
    local containerObject = AddOnTable.Sets[self.BagSet].Containers[self:GetID()]
    containerObject:UpdateBagHighlight()
    
    -- handle "close all" case
    if (self:GetID() == 1) and (BBConfig[self.BagSet].Enabled) and (BBConfig[self.BagSet].CloseAll) then
        AddOnTable.Sets[self.BagSet]:Close()
        AddOnTable.Sets[self.BagSet].Type.CustomCloseAllFunction()
    end
    
    if (AddOnTable.Config.EnableFadeAnimation) then
        self:Show()
    end
    AddOnTable.Sets[self.BagSet].Containers[self:GetID()].Menu:Hide()
end

function BaudBagContainerMixin:OnDragStart(event, ...)
    if not BBConfig[self.BagSet][self:GetID()].Locked then
        self:StartMoving()
    end
end

function BaudBagContainerMixin:OnDragStop(event, ...)
    self:StopMovingOrSizing()
    AddOnTable.Sets[self.BagSet].Containers[self:GetID()]:SaveCoordsToConfig()
end


BaudBagSearchButtonMixin = {}

function BaudBagSearchButtonMixin:OnClick(event, ...)
    -- get references to all needed frames and data
    local container		= self:GetParent()
    local scale			= BBConfig[container.BagSet][container:GetID()].Scale / 100
    local theme	= BBConfig[container.BagSet][container:GetID()].Theme
    
    BaudBagSearchFrame_ShowFrame(container, scale, theme)
end

function BaudBagSearchButtonMixin:OnEnter(event, ...)
    GameTooltip:SetOwner(self)
    GameTooltip:SetText(Localized.SearchBagTooltip)
    GameTooltip:Show()
end

BaudBagBagsButtonMixin = {}

function BaudBagBagsButtonMixin:OnClick(event, ...)
    local bagSetId = self:GetParent().BagSet
    local bagsFrame = self:GetParent().BagsFrame
    if (bagsFrame ~= nil) then
        BBConfig[bagSetId].ShowBags = (BBConfig[bagSetId].ShowBags==false)
        local isShown = (BBConfig[bagSetId].ShowBags ~= false)
        self:SetChecked(isShown)
        if (isShown) then
            bagsFrame:Show()
        else
            bagsFrame:Hide()
        end
    end
end

BaudBagContainerUnlockMixin = {}

function BaudBagContainerUnlockMixin:OnLoad()
    RaiseFrameLevel(self)
end

function BaudBagContainerUnlockMixin:OnShow()
    if self.Refresh then
		self:Refresh()
	end
end

BaudBagContainerUnlockCostMoneyMixin = {}

function BaudBagContainerUnlockCostMoneyMixin:OnLoad()
    SmallMoneyFrame_OnLoad(self)
    MoneyFrame_SetType(self, "STATIC")
end