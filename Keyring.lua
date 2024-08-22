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
        DefaultConfig = {
            Columns = 4,
            Scale = 100,
            GetNameAddition = function(bagId) return Localized.KeyRing end,
            RequiresFreshConfig = function(bagId) return false end,
            Background = 3
        },
        GetItemButtonTemplate = function(containerId) return "ContainerFrameItemButtonTemplate" end,
        GetSize = function(containerId) return AddOnTable.BlizzAPI.GetKeyRingSize() end,
        -- there are no bags for an overview
        BagOverview_Initialize = function() end,
    }
    tinsert(BagSetTypeArray, BagSetType.Keyring)

    AddOnTable.ContainerIdOptionsIndexMap[AddOnTable.BlizzConstants.KEYRING_CONTAINER] = 1
end
hooksecurefunc(AddOnTable, "ExtendBaseTypes", extendBaseType)
