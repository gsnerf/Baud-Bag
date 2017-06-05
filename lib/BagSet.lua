local AddOnName, AddOnTable = ...
local _

local Prototype = {
    Type = nil,
    Containers = {},
    SubContainers = {}
}

function Prototype:GetType()
    return self.Type
end

function Prototype:PerformInitialBuild()
    for containerId = -3, NUM_BANKBAGSLOTS + NUM_BAG_SLOTS do
        if self.Type.IsSubContainerOf(containerId) then
            -- todo: somehow get reasonable values here
            local subContainer = AddOnTable:CreateSubContainer(self, containerId)
            table.insert(self.SubContainers, subContainer)
        end
    end
end

function Prototype:ApplyConfiguration(configuration)
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateBagSet(type)
    local bagSet = _G.setmetatable({}, Metatable)
    bagSet.Type = type
    return bagSet
end