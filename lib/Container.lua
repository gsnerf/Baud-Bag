local AddOnName, AddOnTable = ...
local _

local Prototype = {
    Id = nil,
    Name = "DefaultContainer",
    Frame = nil,
    SubContainers = nil,
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

    if ((self.Frame.BagSet == 2) and (not BaudBagFrame.BankOpen)) then
        targetName = containerConfig.Name..AddOnTable["Localized"].Offline
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

function Prototype:Render()
    -- TODO
end

function Prototype:Update()
    -- TODO
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

            container:CreateMissingSlots()
			
            -- update container contents (special bank containers don't need this, regular bank only when open)
            if (not BaudBag_IsBankDefaultContainer(container.ContainerId)) and (BaudBagFrame.BankOpen or (container.ContainerId < 5)) then
                ContainerFrame_Update(container.Frame)
            end

            -- position item slots
            container:UpdateSlotContents()
            col, row = container:UpdateSlotPositions(self.Frame, background, col, row, maxCols, slotLevel)
            container.Frame:Show()
        end
    end

    -- TODO: It seems some how strange to pass this through 2 layers... let's see if we can get rid of that in the future!
    return col, row
end

function Prototype:SaveCoordinates()
    -- TODO
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
        frame = CreateFrame("Frame", container.Name, UIParent, "BaudBagContainerTemplate")
    end
    frame:SetID(bbContainerId)
    frame.BagSet = bagSetType.Id
    frame.Bags = {}
    container.Frame = frame
    container.SubContainers = {}
    return container
end