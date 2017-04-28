local AddOnName, AddOnTable = ...
local _

local Prototype = {
    startColumn = 0,
    highlighted = false,
    frame = nil
}

function Prototype:ToggleHighlight()
    self.highlighted = not self.highlighted
end

function Prototype:GetFrame()
    return self.frame
end

function Prototype:Render()
    -- TODO
end

function Prototype:Update()
    -- TODO
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateSubContainer(subBagTemplate)
    local subContainer = _G.setmetatable({}, Metatable)
    subContainer.frame = CreateFrame("Frame", AddOnName.."SubBag"..Bag, nil, subBagTemplate);
    return subContainer
end

local function EventUpdateFunction(self, event, ...)
    -- only update if the event is for the current bag!
    local bag = ...;
    if (self:GetID() ~= bag) then
        return;
    end
    BaudBag_DebugMsg("ItemHandle", "Event fired for subBag, Params[Event, ID]", event, self:GetID());
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