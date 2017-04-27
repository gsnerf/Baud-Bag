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

end

local Metatable = { __index = Prototype }

function AddOnTable:CreateSubContainer(subBagTemplate)
    local subContainer = _G.setmetatable({}, Metatable)
    subContainer.frame = CreateFrame("Frame", AddOnName.."SubBag"..Bag, nil, subBagTemplate);
    return subContainer
end