local AddOnName, AddOnTable = ...
local _
local Localized = AddOnTable.Localized

--[[
    This enum is pre-filled with the default values that are _aways_ available.
    It can be extended with more depending on feature availability (for example keyring or warband bank)
]]
---@enum BagSetType this contains all bag set types supported by this flavor
BagSetType = {
    ---@class BagSetTypeClass
    Backpack = {
        Id = 1,
        Name = Localized.Inventory,
        TypeName = "Backpack",
        IsSupported = function() return true end,
        IsSubContainerOf = function(containerId)
            local isBackpackContainer = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER <= containerId and containerId <= AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER
            return isBackpackContainer
        end,
        ContainerIterationOrder = {},
        Init = function()
            for bag = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
                table.insert(BagSetType.Backpack.ContainerIterationOrder, bag)
            end
        end
    },
    Bank = {
        Id = 2,
        Name = Localized.BankBox,
        TypeName = "Bank",
        IsSupported = function() return true end,
        IsSubContainerOf = function(containerId)
            local isBankDefaultContainer = (containerId == AddOnTable.BlizzConstants.BANK_CONTAINER) or (containerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER)
            local isBankSubContainer = (AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER <= containerId) and (containerId <= AddOnTable.BlizzConstants.BANK_LAST_CONTAINER)
            return isBankDefaultContainer or isBankSubContainer
        end,
        ContainerIterationOrder = {},
        Init = function()
            table.insert(BagSetType.Bank.ContainerIterationOrder, AddOnTable.BlizzConstants.BANK_CONTAINER)
            for bag = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
                table.insert(BagSetType.Bank.ContainerIterationOrder, bag)
            end
            -- explicitly using the numerical value of the expansion instead of the enum, as classic variants seemingly do not contain those enums
            if (GetExpansionLevel() >= 5) then
                table.insert(BagSetType.Bank.ContainerIterationOrder, AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER)
            end
        end
    },
    --[[
        GuildBank = {
        Id = 4,
        IsSubContainerOf = function(containerId)
            return false
        end
    },
    VoidStorage = {
        Id = 5,
        IsSubContainerOf = function(containerId)
            return false
        end
    } ]]
}

--[[
    This will seem unnecessary at first glance, but it ensures a specific order for iterating over all existing BagSetTypes.
    At the moment this is necessary at least for the tab list in the options as long as BagSetType itself is a "map" type table instead of an "array" type table.
  ]]
BagSetTypeArray = { BagSetType.Backpack, BagSetType.Bank }

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
for id = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
    idIndexMap[id] = id - AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER + 1
end
AddOnTable.ContainerIdOptionsIndexMap = idIndexMap