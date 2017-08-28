local AddOnName, AddOnTable = ...
local _

local Prototype = {
    Type = nil,
    -- sub tables have to be reassigned on init or ALL new elements will have the SAME tables for access...
    Containers = nil,
    SubContainers = nil
}

function Prototype:GetType()
    return self.Type
end

function Prototype:PerformInitialBuild()
    for containerId = -3, NUM_BANKBAGSLOTS + NUM_BAG_SLOTS do
        if self.Type.IsSubContainerOf(containerId) then
            -- todo: somehow get reasonable values here
            local subContainer = AddOnTable:CreateSubContainer(self.Type, containerId)
            -- necessary at least for migration
            AddOnTable["SubBags"][containerId] = subContainer
            self.SubContainers[containerId] = subContainer
--            table.insert(self.SubContainers, subContainer)

            -- a little bit of legacy code hopefully not needed at some point in the future
            local subContainerFrame = subContainer.Frame
            subContainerFrame:SetID(containerId);
            subContainerFrame:SetParent(AddOnName.."Container"..subContainerFrame.BagSet.."_1");
        end
    end

end

function Prototype:ApplyConfiguration(configuration)
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateBagSet(type)
    local bagSet = _G.setmetatable({}, Metatable)
    bagSet.Type = type
    bagSet.Containers = {}
    bagSet.SubContainers = {}
    AddOnTable["Sets"][type.Id] = bagSet
    return bagSet
end