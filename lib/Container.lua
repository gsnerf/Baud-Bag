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

function Prototype:Render()
    -- TODO
end

function Prototype:Update()
    -- TODO
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