local AddOnName, AddOnTable = ...
local _
local Localized = AddOnTable.Localized

-- Definition
---@enum BagSetType
BagSetType = {
    ---@class BagSetTypeClass
    Backpack = {
        Id = 1,
        Name = Localized.Inventory,
        IsSubContainerOf = function(containerId)
            local isBackpackContainer = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER <= containerId and containerId <= AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER
            return isBackpackContainer
        end,
        ContainerIterationOrder = {}
    },
    Bank = {
        Id = 2,
        Name = Localized.BankBox,
        IsSubContainerOf = function(containerId)
            local isBankDefaultContainer = (containerId == AddOnTable.BlizzConstants.BANK_CONTAINER) or (containerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER)
            local isBankSubContainer = (AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER <= containerId) and (containerId <= AddOnTable.BlizzConstants.BANK_LAST_CONTAINER)
            return isBankDefaultContainer or isBankSubContainer
        end,
        ContainerIterationOrder = {}
    },
    Keyring = {
        Id = 3,
        Name = Localized.KeyRing,
        IsSubContainerOf = function(containerId)
            return containerId == AddOnTable.BlizzConstants.KEYRING_CONTAINER
        end,
        ContainerIterationOrder = { AddOnTable.BlizzConstants.KEYRING_CONTAINER }
    } --[[,
    GuildBank = {
        Id = 3,
        IsSubContainerOf = function(containerId)
            return false
        end
    },
    VoidStorage = {
        Id = 4,
        IsSubContainerOf = function(containerId)
            return false
        end
    } ]]
}

-- INITIALIZATION of BagSetType:
-- * Backpack:
for bag = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
    table.insert(BagSetType.Backpack.ContainerIterationOrder, bag)
end
-- * Bank:
table.insert(BagSetType.Bank.ContainerIterationOrder, AddOnTable.BlizzConstants.BANK_CONTAINER)
for bag = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
    table.insert(BagSetType.Bank.ContainerIterationOrder, bag)
end
-- explicitly using the numerical value of the expansion instead of the enum, as classic variants seemingly do not contain those enums
if (GetExpansionLevel() >= 5) then
    table.insert(BagSetType.Bank.ContainerIterationOrder, AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER)
end

-- Definition
---@enum ContainerType
ContainerType = {
    Joined,
    Tabbed
}

--[[ this is a really dump way to access the config to get the joined state... ]]
local idIndexMap = {}
idIndexMap[AddOnTable.BlizzConstants.BANK_CONTAINER] = 1
idIndexMap[AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER] = AddOnTable.BlizzConstants.BANK_CONTAINER_NUM + 2
for id = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
    idIndexMap[id] = id + 1
end
if (AddOnTable.State.KeyringSupported) then
    idIndexMap[AddOnTable.BlizzConstants.KEYRING_CONTAINER] = 1
end
for id = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
    idIndexMap[id] = id - AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER + 1
end
AddOnTable.ContainerIdOptionsIndexMap = idIndexMap