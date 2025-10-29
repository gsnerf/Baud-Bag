---@class AddonNamespace
local AddOnTable = select(2, ...)
local AddOnName = select(1, ...)
local _

---@class BagSet
local Prototype = {
    ---@type BagSetTypeClass
    Type = nil,
    MaxContainerNumber = 0,
    ContainerNumber = 0,
    --[[  sub tables have to be reassigned on init or ALL new elements will have the SAME tables for access... ]]
    ---@type Container[]
    Containers = nil,
    ---@type SubContainer[]
    SubContainers = nil,
    ---@type BagButton[]
    BagButtons = nil,
    ---@type BagButton[]
    ReagentBagButtons = nil,
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
        subContainerFrame:SetID(containerId)
        subContainerFrame:SetParent(_G[AddOnName.."Container"..subContainerFrame.BagSet.."_1"])
    end
end

--[[ This will be called on first load as well as every configuration change (via options screen) ]]
function Prototype:ReloadConfig()
    self:RebuildContainers()
end

function Prototype:RebuildContainers()
    ---comment
    ---@param localContainerObject Container
    ---@param localIsOpen boolean
    ---@param maxSubContainerIndex integer
    local function FinishContainer(localContainerObject, localIsOpen, maxSubContainerIndex)
        -- update complete content
        localContainerObject:Rebuild()
        localContainerObject:Update()
        
        -- update visibility
        if localIsOpen then
            AddOnTable.Functions.DebugMessage("Container", "Showing Container (Name)", localContainerObject.Name)
            localContainerObject.Frame:Show()
        else
            AddOnTable.Functions.DebugMessage("Container", "Hiding Container (Name)", localContainerObject.Name)
            localContainerObject.Frame:Hide()
        end
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
                FinishContainer(containerObject, isOpen, subContainerIndex - 1)
                subContainerIndex = 1
            end

            isOpen = false
            containerNumber = containerNumber + 1
            if (self.MaxContainerNumber < containerNumber and subContainer ~= nil) then
                local containerTemplate = self.Type.GetContainerTemplate(id)
                containerObject = AddOnTable:CreateContainer(self.Type, containerNumber, containerTemplate)

                self.Containers[containerNumber] = containerObject
                self.MaxContainerNumber = containerNumber
            end
            -- switch to next container
            containerObject = self.Containers[containerNumber]
            -- ensure config is up to date with recent changes
            containerObject:UpdateFromConfig()
            -- to avoid dealing with leftovers later, just reset now and refill with rest of the iteration
            containerObject.SubContainers = {}
        end

        AddOnTable.Functions.DebugMessage("Container", "(orderIndex, id)", subContainerIndex, id)
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
        self.Containers[index].Frame:Hide()
        self.Containers[index].SubContainers = {}
    end

    self.ContainerNumber = containerNumber
    return containerNumber
end

function Prototype:GetSlotInfo()
    local free = 0
    local overall = 0

    AddOnTable.Functions.DebugMessage("Bags", "Counting free slots for (set)", self.Type.Id)

    for id, subContainer in pairs(self.SubContainers) do
        if (id ~= AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
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

function Prototype:UpdateBagHighlight()
    for _, container in ipairs(self.Containers) do
        container:UpdateBagHighlight()
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

function Prototype:AutoOpen()
    AddOnTable.Functions.DebugMessage("BagTrigger", "[BagSet:AutoOpen] auto opening", self.Type.Name)
    for index, container in ipairs(self.Containers) do
        local autoOpenConfigured = BBConfig[self.Type.Id][index].AutoOpen
        AddOnTable.Functions.DebugMessage("BagOpening", "[BagSet:AutoOpen] Considering container configured as (containerId, autoOpenConfigured)", index, autoOpenConfigured)

        if autoOpenConfigured then
            if not BBConfig[self.Type.Id].Enabled then
                container.Frame.AutoOpened = true
                return
            end

            if not container.Frame:IsShown() then
                AddOnTable.Functions.DebugMessage("BagOpening", "[BagSet:AutoOpen] IsShown == FALSE")
                if (#container.SubContainers > 0) then
                    container.Frame.AutoOpened = true
                    container.Frame:Show()
                else
                    AddOnTable.Functions.DebugMessage("BagOpening", "[BagSet:AutoOpen] container "..index.." has no sub containers, ignoring show...")
                end
            else
                AddOnTable.Functions.DebugMessage("BagOpening", "[BagSet:AutoOpen] IsShown == TRUE")
            end
            container:Update()
        end
    end
end

function Prototype:AutoClose()
    AddOnTable.Functions.DebugMessage("BagTrigger", "[BagSet:AutoClose] auto closing ", self.Type.Name)
    for index, container in ipairs(self.Containers) do
        local autoOpenConfigured = BBConfig[self.Type.Id][index].AutoOpen
        local autoCloseConfigured = BBConfig[self.Type.Id][index].AutoClose
        AddOnTable.Functions.DebugMessage("BagOpening", "[BagSet:AutoClose] Considering container configured as (containerId, autoOpenConfigured, autoCloseConfigured)", index, autoOpenConfigured, autoCloseConfigured)

        if autoOpenConfigured then
            if container.Frame.AutoOpened then
                if not BBConfig[self.Type.Id].Enabled then
                    container.Frame.AutoOpened = false
                    return
                end
                
                AddOnTable.Functions.DebugMessage("BagOpening", "[BagSet:AutoClose] AutoOpened == TRUE")
                container.Frame.AutoOpened = false
                if autoCloseConfigured then
                    AddOnTable.Functions.DebugMessage("BagOpening", "[BagSet:AutoClose] AutoClose set, hiding!")
                    container.Frame:Hide()
                else
                    AddOnTable.Functions.DebugMessage("BagOpening", "[BagSet:AutoClose] AutoClose not set, ignoring hide!")
                end
            else
                AddOnTable.Functions.DebugMessage("BagOpening", "[AutoOpBagSet:AutoCloseenSet] FALSE")
                container:Update()
            end
        end
    end
end

function Prototype:GetSubContainerTexture(subContainerId)
    local specialTexture = self.Type.GetSpecialBagTexture(subContainerId)
    if specialTexture ~= nil then
        return specialTexture
    elseif (self.Type.SupportsCache) then
        local bagCache = AddOnTable.Cache:GetBagCache(subContainerId)
        if bagCache and bagCache.BagLink then
            return AddOnTable.BlizzAPI.GetItemIcon(bagCache.BagLink)
        elseif bagCache and bagCache.TabData then
            return bagCache.TabData.icon
        else
            return nil
        end
    else
        local inventoryId = AddOnTable.BlizzAPI.ContainerIDToInventoryID(subContainerId)
        return AddOnTable.BlizzAPI.GetInventoryItemTexture("player", inventoryId)
    end
end

--[[
    This function takes a function, and then applies the function to each bag of the set.
    The function gets the parameters: 1. ID of the bag, 2. Index of the bag (as provided by ContainerIterationOrder)

    Bag IDs are expected to be:
        -5 == account bank
        -3 == reagent bank
        -2 == keyring & currency
        -1 == bank
        0 == backpack
        1-4 == inventory bags
        5 == reagent bag
        6-12 == bank bags
        13-17 == account bank bags
  ]]
function Prototype:ForEachBag(func)
    for index, bagId in ipairs(self.Type.ContainerIterationOrder) do
        func(bagId, index)
    end
end

local Metatable = { __index = Prototype }
---@param type BagSetTypeClass
function AddOnTable:CreateBagSet(type)
    ---@type BagSet
    local bagSet = _G.setmetatable({}, Metatable)
    bagSet.Type = type
    bagSet.Containers = {}
    bagSet.SubContainers = {}
    bagSet.BagButtons = {}
    bagSet.ReagentBagButtons = {}
    AddOnTable.Sets[type.Id] = bagSet
    return bagSet
end