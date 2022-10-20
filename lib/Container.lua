local AddOnName, AddOnTable = ...
local _

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
    BaudBag_DebugMsg("Container", "Saving container coords to config (name)", self.Name)
    local scale = self.Frame:GetScale()
    local x, y = self.Frame:GetCenter()
    x = x * scale
    y = y * scale
    BBConfig[self.Frame.BagSet][self.Id].Coords = {x, y}
end

function Prototype:UpdateFromConfig()
    if (self.Frame == nil) then
        BaudBag_DebugMsg("Container", "Frame doesn't exist yet. Called UpdateFromConfig() to early???", self.Id, self.Name)
        return
    end
    BaudBag_DebugMsg("Container", "Updating container from config (name)", self.Name)

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

    -- this should only happen when the dev coded some bullshit!
    if (self.Frame.Slots <= 0) then
        if self.Frame:IsShown() then
            DEFAULT_CHAT_FRAME:AddMessage("Container \""..contCfg.Name.."\" has no contents.", 1, 1, 0)
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
    
    BaudBag_DebugMsg("Bags", "Finished Arranging Container.")
    AddOnTable:Container_Updated(self.BagSet, self.Id)
end

function Prototype:UpdateSubContainers(col, row)
    local contCfg       = BBConfig[self.Frame.BagSet][self.Id]
    local background    = contCfg.Background
    local maxCols       = contCfg.Columns
    local slotLevel     = self.Frame:GetFrameLevel() + 1
    local container

    BaudBag_DebugMsg("Container", "Started Updating SubContainers For Container", self.Id)

    for _, container in pairs(self.SubContainers) do
        BaudBag_DebugMsg("Container", "Updating SubContainer with ID and Size", container.ContainerId, container.Size)
        -- not existing subbags (bags with no itemslots) are hidden
        if (container.Size <= 0) then
            container.Frame:Hide()
        else
            BaudBag_DebugMsg("Bags", "Adding (bagName)", container.Name)

            -- position item slots
            container:UpdateSlotContents()
            col, row = container:UpdateSlotPositions(self.Frame, background, col, row, maxCols, slotLevel)
            container.Frame:Show()

            -- last but not least update visibility for deposit button of reagent bank
            if (container.ContainerId == REAGENTBANK_CONTAINER and AddOnTable.State.BankOpen) then
                self.Frame.DepositButton:Show()
            else
                self.Frame.DepositButton:Hide()
            end
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
    self.Frame.UnlockInfo:ClearAllPoints()
    self.Frame.UnlockInfo:SetPoint("TOPLEFT", -10, 3)
    self.Frame.UnlockInfo:SetPoint("BOTTOMRIGHT", 10, -3)
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
        if (id == BANK_CONTAINER) then
            return AddOnTable.BlizzAPI.GetBankAutosortDisabled()
        end
        if (self.BagSet.Id == BagSetType.Backpack.Id) then
            return GetBagSlotFlag(id, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP)
        end
        if (self.BagSet.Id == BagSetType.Bank.Id) then
            return GetBankBagSlotFlag(id - NUM_BAG_SLOTS, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP)
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
            SetBagSlotFlag(id, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, value)
        end
        if (self.BagSet.Id == BagSetType.Bank.Id and id ~= BANK_CONTAINER) then
            SetBankBagSlotFlag(id - NUM_BAG_SLOTS, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, value)
        end
    end
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateContainer(bagSetType, bbContainerId)
    local container = _G.setmetatable({}, Metatable)
    container.Id = bbContainerId
    container.Name = AddOnName.."Container"..bagSetType.Id.."_"..bbContainerId
    BaudBag_DebugMsg("Container", "Creating Container (name)", container.Name)
    local frame = _G[container.Name]
    if (frame == nil) then
        BaudBag_DebugMsg("Container", "Frame for container does not yet exist, creating new Frame (name)", name)
        frame = CreateFrame("Frame", container.Name, BaudBagFrame, "BaudBagContainerTemplate")
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