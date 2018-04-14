local AddOnName, AddOnTable = ...
local _

local Prototype = {
    Type = nil,
    --[[  sub tables have to be reassigned on init or ALL new elements will have the SAME tables for access... ]]
    Containers = nil,
    MaxContainerNumber = 0,
    SubContainers = nil,
    BagButtons = nil
}

function Prototype:GetType()
    return self.Type
end

--[[ This will be called ONCE when the BaudBag Frame is loaded (this is usually before the ADDON_LOADED event is called) ]]
function Prototype:PerformInitialBuild()
    for _, containerId in ipairs(self.Type.ContainerIterationOrder) do
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

--[[ This will be called on first load as well as every configuration change (via options screen) ]]
function Prototype:RebuildContainers()
    local function FinishContainer(localContainerObject, localIsOpen, maxSubContainerIndex)
        -- first remove all subcontainers that are not contained anymore
        local currentSubContainerCount = table.getn(localContainerObject.SubContainers)
        if (maxSubContainerIndex < currentSubContainerCount) then
            for i = maxSubContainerIndex, currentSubContainerCount do
                localContainerObject.SubContainers[i] = nil
            end
        end
        -- now update visibility
        if localIsOpen then
            BaudBag_DebugMsg("Container", "Showing Container (Name)", localContainerObject.Name)
            localContainerObject.Frame:Show()
        else
            BaudBag_DebugMsg("Container", "Hiding Container (Name)", localContainerObject.Name)
            localContainerObject.Frame:Hide()
        end

        -- and now update complete content
        localContainerObject:Rebuild()
        localContainerObject:Update()
    end

    -- we need to remember the open state before rearranging the containers or bags will close while they are expected to be seen
    local originallyOpen = {}
    for _, subContainer in pairs(AddOnTable.SubBags) do
        originallyOpen[subContainer.ContainerId] = subContainer:IsOpen()
    end

    --local bagSetConfig = AddOnTable.Config[self.Type.Id]
    local bagSetConfig = BBConfig[self.Type.Id]
    local containerNumber = 0
    local containerObject
    local isOpen = false
    local subContainerIndex = 1

    for _, id in ipairs(self.Type.ContainerIterationOrder) do
        local subContainer = self.SubContainers[id]
        local index = AddOnTable.ContainerIdOptionsIndexMap[id]
        if (containerNumber == 0) or (bagSetConfig.Joined[index] == false) then
            -- if we aren't opening the first container, make sure the previous one is correctly closed and updated
            if (containerNumber ~= 0) then
                FinishContainer(containerObject, isOpen, subContainerIndex)
                subContainerIndex = 1
            end

            isOpen = false
            containerNumber = containerNumber + 1
            if (self.MaxContainerNumber < containerNumber) then
                containerObject = AddOnTable:CreateContainer(self.Type, containerNumber)

                self.Containers[containerNumber] = containerObject
                self.MaxContainerNumber = containerNumber
            end
            containerObject = self.Containers[containerNumber]
            containerObject:UpdateFromConfig()
        end

        BaudBag_DebugMsg("Container", "(orderIndex, id)", orderIndex, id)
        containerObject.SubContainers[subContainerIndex] = subContainer
        containerObject.Frame.Bags[subContainerIndex] = subContainer.Frame
        subContainer.Frame:SetParent(containerObject.Frame)
        subContainerIndex = subContainerIndex + 1
        if originallyOpen[subContainer.ContainerId] then
            isOpen = true
        end
    end
    FinishContainer(containerObject, isOpen, subContainerIndex)

    -- hide all containers that where created but configured away
    for index = (containerNumber + 1), self.MaxContainerNumber do
        self.Containers[index].Frame:Hide();
    end

    return containerNumber
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

function Prototype:UpdateSlotInfo()
    local firstContainer = self.Containers[1]
    if (firstContainer) then
        local free, overall = self:GetSlotInfo()
        firstContainer:UpdateFreeSlotsOverview(free, overall)
    end
end

function Prototype:ApplyConfiguration(configuration)
end

function Prototype:Open()
    for _, container in ipairs(self.Containers) do
        container.Frame:Show()
    end
end

function Prototype:Close()
    for _, container in ipairs(self.Containers) do
        container.Frame:Hide()
    end
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateBagSet(type)
    local bagSet = _G.setmetatable({}, Metatable)
    bagSet.Type = type
    bagSet.Containers = {}
    bagSet.SubContainers = {}
    bagSet.BagButtons = {}
    AddOnTable["Sets"][type.Id] = bagSet
    return bagSet
end