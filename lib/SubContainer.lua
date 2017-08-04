local AddOnName, AddOnTable = ...
local _

local Prototype = {
    BagSet = nil,
    ContainerId = nil,
    Name = "",
    StartColumn = 0,
    Size = 0,
    FreeSlots = 0,
    IsHighlighted = false,
    Frame = nil
}

function Prototype:GetID()
    return self.ContainerId
end

function Prototype:ToggleHighlight()
    self.IsHighlighted = not self.IsHighlighted
end

function Prototype:GetFrame()
    return self.Frame
end

function Prototype:Render()
    -- TODO
end

function Prototype:Update()
    -- TODO
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateSubContainer(bagSet, containerId)
    local subContainer = _G.setmetatable({}, Metatable)
    -- TODO this is a really nasty workaround... I don't like it AT ALL... but I don't see a good way right now :(
    local templateName = "BaudBagSubBagTemplate"
    if (BaudBag_IsBankDefaultContainer(containerId)) then
        templateName = nil
    end
    subContainer.Frame = CreateFrame("Frame", AddOnName.."SubBag"..containerId, nil, templateName)
    subContainer.BagSet = bagSet
    subContainer.ContainerId = containerId
    return subContainer
end

local function EventUpdateFunction(self, event, ...)
    -- only update if the event is for the current bag!
    local idOfBagToUpdate = ...;
    if (self.ContainerId ~= idOfBagToUpdate) then
        return;
    end
    BaudBag_DebugMsg("ItemHandle", "Event fired for subBag, Params[Event, ID]", event, self.ContainerId);
    self:Update(event, ...);
end

local Events = {
    BAG_UPDATE,
    BAG_UPDATE_COOLDOWN = EventUpdateFunction,
    BAG_CLOSED,
    ITEM_LOCK_CHANGED = EventUpdateFunction,
    UPDATE_INVENTORY_ALERTS = EventUpdateFunction
}

-- TODO: don't know if this mixup of object orientation and wow function handly really works like that
function Prototype:OnLoad(self, event, ...)

end

-- TODO: don't know if this mixup of object orientation and wow function handly really works like that
function Prototype:OnEvent(self, event, ...)
    if not self:GetParent():IsShown() or (self:GetID() >= 5) and not BaudBagFrame.BankOpen then
        return;
    end
    Events[event](self, event, ...);
end