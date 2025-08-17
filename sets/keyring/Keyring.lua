---@class AddonNamespace
local AddOnTable = select(2, ...)
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
        ApplyConfigRestorationSpecificalities = function(configObject) end,
        CanContainerBeJoined = function(subContainerId) return true end,
        LinkedSet = function() return nil end,
        GetContainerTemplate = function(containerId) return "BaudBagContainerTemplate" end,
        GetItemButtonTemplate = function(containerId) return "ContainerFrameItemButtonTemplate" end,
        GetSize = function(containerId) return AddOnTable.BlizzAPI.GetKeyRingSize() end,
        SupportsCache = false,
        ShouldUseCache = function() return false end,
        -- there are no bags for an overview
        BagOverview_Initialize = function() end,
        UpdateOpenBagHighlight = function(subContainer) end,
        BagFilterGetFunction = nil,
        BagFilterSetFunction = function() end,
        CanInteractWithBags = function() return true end,
        OnItemButtonCustomEnter = function(self) end,
        FilterData = {
            GetFilterType = function(container) return false end,
            SetFilterType = function(container, type, value) end,
            GetCleanupIgnore = function(container) return false end,
            SetCleanupIgnore = function(container, value) end,
        },
        CustomCloseAllFunction = function() end,
        GetSpecialBagTexture = function(subContainerId)
            if (subContainerId == AddOnTable.BlizzConstants.KEYRING_CONTAINER) then
                return "Interface\\ContainerFrame\\KeyRing-Bag-Icon"
            else
                return nil
            end
        end,
    }
    tinsert(BagSetTypeArray, BagSetType.Keyring)

    AddOnTable.ContainerIdOptionsIndexMap[AddOnTable.BlizzConstants.KEYRING_CONTAINER] = 1
end
hooksecurefunc(AddOnTable, "ExtendBaseTypes", extendBaseType)
