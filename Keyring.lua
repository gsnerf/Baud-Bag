local AddOnName, AddOnTable = ...
local _
local Funcs = AddOnTable.Functions
local Events = AddOnTable.Events
local Localized = AddOnTable.Localized

local function extendBaseType()
    Funcs.DebugMessage("Keyring", "Keyring#extendBaseType()")
    BagSetType["Keyring"] = {
        Id = 3,
        Name = Localized.KeyRing,
        TypeName = "Keyring",
        IsSupported = function() return true end,
        IsSubContainerOf = function(containerId)
            return containerId == AddOnTable.BlizzConstants.KEYRING_CONTAINER
        end,
        ContainerIterationOrder = { AddOnTable.BlizzConstants.KEYRING_CONTAINER },
        Init = function() end,
        NumberOfContainers = 1,
        DefaultColumns = 4,
        DefaultScale = 100,
        GetItemButtonTemplate = function(containerId) return "ContainerFrameItemButtonTemplate" end,
        GetSize = function(containerId) return AddOnTable.BlizzAPI.GetKeyRingSize() end
    }
    tinsert(BagSetTypeArray, BagSetType.Keyring)

    AddOnTable.ContainerIdOptionsIndexMap[AddOnTable.BlizzConstants.KEYRING_CONTAINER] = 1
end
hooksecurefunc(AddOnTable, "ExtendBaseTypes", extendBaseType)

local function initBagSet()
    Funcs.DebugMessage("Keyring", "Keyring#initBagSet()")
    local Keyring = AddOnTable:CreateBagSet(BagSetType.Keyring)
    Keyring:PerformInitialBuild()
end
hooksecurefunc(AddOnTable, "InitBagSets", initBagSet)