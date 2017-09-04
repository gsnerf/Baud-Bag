local AddOnName, AddOnTable = ...
local _

local Prototype = {
    Type = nil,
    --[[  sub tables have to be reassigned on init or ALL new elements will have the SAME tables for access... ]]
    Containers = nil,
    MaxContainerNumber = 0,
    SubContainers = nil
}

function Prototype:GetType()
    return self.Type
end

--[[ This will be called ONCE when the BaudBag Frame is loaded (this is usually before the ADDON_LOADED event is called) ]]
function Prototype:PerformInitialBuild()
    for containerId = -3, NUM_BANKBAGSLOTS + NUM_BAG_SLOTS do
        if self.Type.IsSubContainerOf(containerId) then
            -- todo: somehow get reasonable values here
            local subContainer = AddOnTable:CreateSubContainer(self.Type, containerId)
            -- necessary at least for migration
            AddOnTable["SubBags"][containerId] = subContainer
            self.SubContainers[containerId] = subContainer

            -- a little bit of legacy code hopefully not needed at some point in the future
            local subContainerFrame = subContainer.Frame
            subContainerFrame:SetID(containerId);
            subContainerFrame:SetParent(AddOnName.."Container"..subContainerFrame.BagSet.."_1");
        end
    end
end

--[[ This will be called on first load as well as every configuration change (via options screen) ]]
function Prototype:RebuildContainers()
    local bagSetConfig = AddOnTable.Config[self.Type.Id]
    local containerNumber = 0
    local containerObject
    for id, subContainer in pairs(self.SubContainers) do
        local index = AddOnTable.ContainerIdOptionsIndexMap[id]
        if (containerNumber == 0) or (bagSetConfig.Joined[index] == false) then
            -- if we aren't opening the first container, make sure the previous one is correctly closed and updated
            if (containerNumber ~= 0) then
                -- TODO
                --FinishContainer()
            end

            containerNumber = containerNumber + 1;
            if (self.MaxContainerNumber < containerNumber) then
                containerObject = AddOnTable:CreateContainer(bagSetType, containerNumber)

                self.Containers[containerNumber] = containerObject
                self.MaxContainerNumber = containerNumber

                --Container = containerObject.Frame
            end
            containerObject = self.Containers[containerNumber]
            containerObject:UpdateFromConfig()
        end

        -- TODO: add SubBags to container here?
        tinsert(containerObject.SubContainers, subContainer)
        subContainer.Frame:SetParent(containerObject.Frame)

        -- TODO: handle open state of bags???

    end
    --FinishContainer()

    -- TODO: save current number of containers?

    -- hide all containers that where created but configured away
    for index = (containerNumber + 1), self.MaxContainerNumber do
        self.Containers[index].Frame:Hide();
    end
end

function Prototype:GetSlotInfo()
    local free = 0
    local overall = 0

    BaudBag_DebugMsg("Bags", "Counting free slots for (set)", self.Type.Id)

    for id, subContainer in pairs(self.SubContainers) do
        if (id ~= -3) then
            local subFree, subOverall = subContainer:GetSlotInfo()
            free = free + subFree
            overall = overall + subOverall
        end
    end
    
    return free, overall
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