local AddOnName, AddOnTable = ...
local _

-- -> possibly move this to default config?
local FadeTime = 0.2

local Prototype = {
    Id = nil,
    Name = "DefaultContainer",
    Frame = nil,
    SubContainers = nil,
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

    if ((self.Frame.BagSet == 2) and (not AddOnTable.State.BankOpen)) then
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
    local _, subContainer
    local numberOfSlots = 0
    for _, subContainer in pairs(self.SubContainers) do
        subContainer:Rebuild()
        numberOfSlots = numberOfSlots + subContainer.Size
    end
    self.Frame.Slots = numberOfSlots
    if (numberOfSlots > 0) then
        self:UpdateBackground()
    end
end

function Prototype:Update()
    -- initialize bag update
    self.Frame.Refresh   = false
    self:UpdateName()
    local contCfg         = BBConfig[self.Frame.BagSet][self.Id]
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

    if (contCfg.Background <= 3) then
        self.Frame:SetWidth(numberOfColumns * 42 - 5)
        self.Frame:SetHeight(row * 41 - 4)
    else
        self.Frame:SetWidth(numberOfColumns * 39 - 2)
        self.Frame:SetHeight(row * 39 - 2)
    end
    
    AddOnTable.Functions.DebugMessage("Bags", "Finished Arranging Container.")
    AddOnTable:Container_Updated(self.BagSet, self.Id)
end

function Prototype:UpdateSubContainers(col, row)
    local contCfg       = BBConfig[self.Frame.BagSet][self.Id]
    local background    = contCfg.Background
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

            -- position item slots
            container:UpdateSlotContents()
            col, row = container:UpdateSlotPositions(self.Frame, background, col, row, maxCols, slotLevel)
            container.Frame:Show()
        end
    end

    -- TODO: It seems some how strange to pass this through 2 layers... let's see if we can get rid of that in the future!
    return col, row
end

function Prototype:UpdateBackground()
    local backgroundId = BBConfig[self.Frame.BagSet][self.Id].Background
    local backdrop = self.Frame.Backdrop
    backdrop:SetFrameLevel(self.Frame:GetFrameLevel())
    -- This shifts the name of the bank frame over to make room for the extra button
    local shiftName = (self.Frame:GetID() == 1) and 25 or 0
    
    local left, right, top, bottom = AddOnTable["Backgrounds"][backgroundId]:Update(self.Frame, backdrop, shiftName)
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
    local subContainer
    for _, subContainer in pairs(self.SubContainers) do
        subContainer:UpdateOpenBagHighlight()
    end
end

function Prototype:GetFilterType()
    local id, container
    for _, container in pairs(self.SubContainers) do
        id = container.ContainerId
        if (id ~= BACKPACK_CONTAINER) and (id ~= BANK_CONTAINER) and (id ~= REAGENTBANK_CONTAINER) then
            return container:GetFilterType()
        end
    end

    return nil
end

function Prototype:SetFilterType(type, value)
    for _, container in pairs(self.SubContainers) do
        local id = container.ContainerId
        if (id ~= BACKPACK_CONTAINER) and (id ~= BANK_CONTAINER) and (id ~= REAGENTBANK_CONTAINER) then
            container:SetFilterType(type, value)
        end
    end
end

function Prototype:GetCleanupIgnore()
    for _, container in pairs(self.SubContainers) do
        local id = container.ContainerId
        if (id == BACKPACK_CONTAINER) then
            return AddOnTable.BlizzAPI.GetBackpackAutosortDisabled()
        end
        if (id == AddOnTable.BlizzConstants.BANK_CONTAINER or id == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
            return AddOnTable.BlizzAPI.GetBankAutosortDisabled()
        end
        if (self.BagSet.Id == BagSetType.Backpack.Id) then
            return AddOnTable.BlizzAPI.GetBagSlotFlag(id, AddOnTable.BlizzAPI.GetIgnoreCleanupFlag())
        end
        if (self.BagSet.Id == BagSetType.Bank.Id) then
            -- TODO: check if the ID is really correct for the newer versions of the API, maybe we need that in the API wrapper instead!
            return AddOnTable.BlizzAPI.GetBankBagSlotFlag(id - AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER, AddOnTable.BlizzAPI.GetIgnoreCleanupFlag())
        end

        -- fallback
        return false
    end
end

function Prototype:SetCleanupIgnore(value)
    for _, container in pairs(self.SubContainers) do
        local id = container.ContainerId
        if (id == BACKPACK_CONTAINER) then
            AddOnTable.BlizzAPI.SetBackpackAutosortDisabled(value)
        end
        if (id == BANK_CONTAINER) then
            AddOnTable.BlizzAPI.SetBankAutosortDisabled(value)
        end
        if (self.BagSet.Id == BagSetType.Backpack.Id and id ~= BACKPACK_CONTAINER) then
            AddOnTable.BlizzAPI.SetBagSlotFlag(id, AddOnTable.BlizzAPI.GetIgnoreCleanupFlag(), value)
        end
        if (self.BagSet.Id == BagSetType.Bank.Id and id ~= BANK_CONTAINER) then
            -- TODO: check if the ID is really correct for the newer versions of the API, maybe we need that in the API wrapper instead!
            AddOnTable.BlizzAPI.SetBankBagSlotFlag(id - AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER, AddOnTable.BlizzAPI.GetIgnoreCleanupFlag(), value)
        end
    end
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateContainer(bagSetType, bbContainerId, isReagentBank)
    local container = _G.setmetatable({}, Metatable)
    container.Id = bbContainerId
    container.Name = AddOnName.."Container"..bagSetType.Id.."_"..bbContainerId
    AddOnTable.Functions.DebugMessage("Container", "Creating Container (name)", container.Name)
    local frame = _G[container.Name]
    if (frame == nil) then
        AddOnTable.Functions.DebugMessage("Container", "Frame for container does not yet exist, creating new Frame (name)", name)
        local containerTemplate = isReagentBank and "BaudBagReagentBankTemplate" or "BaudBagContainerTemplate"
        frame = CreateFrame("Frame", container.Name, BaudBagFrame, containerTemplate)
    end
    frame:SetID(bbContainerId)
    frame.BagSet = bagSetType.Id
    frame.Bags = {}
    container.Frame = frame
    container.SubContainers = {}
    container.BagSet = bagSetType
    return container
end

function AddOnTable:Container_Updated(bagSet, containerId)
    -- just an empty hook for other addons
end


--[[ Container events - TO BE MOVED TO MIXIN ]]--
function BaudBagContainer_OnLoad(self, event, ...)
    -- that's to make the frame closable through the ESC key
    tinsert(UISpecialFrames, self:GetName())
    self:RegisterForDrag("LeftButton")
end

function BaudBagContainer_OnUpdate(self, event, ...)

    local containerObject = AddOnTable["Sets"][self.BagSet].Containers[self:GetID()]

    if (self.Refresh) then
        containerObject:Update()
        BaudBagUpdateOpenBagHighlight()
    end

    if (self.UpdateSlots) then
        AddOnTable["Sets"][self.BagSet]:UpdateSlotInfo()
    end

    if (self.FadeStart) then
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


function BaudBagContainer_OnShow(self, event, ...)
    AddOnTable.Functions.DebugMessage("BagOpening", "BaudBagContainer_OnShow was called", self:GetName())
	
    -- check if the container was open before and closing now
    if self.FadeStart then
        return
    end
	
    -- container seems to not be visible, open and update
    self.FadeStart = GetTime()
    PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
    local bagSet = AddOnTable["Sets"][self.BagSet]
    local containerObject = bagSet.Containers[self:GetID()]
    containerObject:Update()
    if (containerObject.Frame.Slots > 0) then
        containerObject:UpdateBagHighlight()
    end

    if (self:GetID() == 1) then
        AddOnTable["Sets"][self.BagSet]:UpdateSlotInfo()
    end
end


function BaudBagContainer_OnHide(self, event, ...)
    AddOnTable.Functions.DebugMessage("BagOpening", "BaudBagContainer_OnHide was called", self:GetName())
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
    PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
    self.AutoOpened = false
    BaudBagUpdateOpenBagHighlight()

    --[[TODO: look into merging the set specific close handling!!!]]--
    --[[
    if the option entry requires it close all remaining containers of the bag set
    (first the bag set so the "offline" title doesn't show up before closing and then the bank to disconnect)
    ]]--
    if (self:GetID() == 1) and (BBConfig[self.BagSet].Enabled) and (BBConfig[self.BagSet].CloseAll) then
        if (self.BagSet == 2) and AddOnTable.State.BankOpen then
            -- [TAINT] can be problematic, but doesn't have to be
            CloseBankFrame()
        end
        AddOnTable.Sets[self.BagSet]:Close()
    end

    self:Show()
end


function BaudBagContainer_OnDragStart(self, event, ...)
    if not BBConfig[self.BagSet][self:GetID()].Locked then
        self:StartMoving()
    end
end


function BaudBagContainer_OnDragStop(self, event, ...)
    self:StopMovingOrSizing()
    AddOnTable["Sets"][self.BagSet].Containers[self:GetID()]:SaveCoordsToConfig()
end