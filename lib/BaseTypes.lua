local AddOnName, AddOnTable = ...
local _
local Localized = AddOnTable.Localized
-- replacing REAGENTBANK_CONTAINER constant with a local variable as we aren't sure that this code is run on retail
local ReagentBankContainer = -3

-- Definition
BagSetType = {
    Backpack = {
        Id = 1,
        Name = Localized.Inventory,
        IsSubContainerOf = function(containerId)
            return (BACKPACK_CONTAINER <= containerId  and containerId <= BACKPACK_CONTAINER + NUM_BAG_SLOTS)
        end,
        ContainerIterationOrder = {}
    },
    Bank = {
        Id = 2,
        Name = Localized.BankBox,
        IsSubContainerOf = function(containerId)
            local isBankDefaultContainer = (containerId == BANK_CONTAINER) or (containerId == ReagentBankContainer)
            local isBankSubContainer = (ITEM_INVENTORY_BANK_BAG_OFFSET < containerId) and (containerId <= ITEM_INVENTORY_BANK_BAG_OFFSET + NUM_BANKBAGSLOTS)
            return isBankDefaultContainer or isBankSubContainer
        end,
        ContainerIterationOrder = {}
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
for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
    table.insert(BagSetType.Backpack.ContainerIterationOrder, bag)
end
-- * Bank:
table.insert(BagSetType.Bank.ContainerIterationOrder, BANK_CONTAINER)
for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
    table.insert(BagSetType.Bank.ContainerIterationOrder, bag)
end
-- explicitly using the numerical value of the expansion instead of the enum, as classic variants seemingly do not contain those enums
if (GetExpansionLevel() >= 5) then
    table.insert(BagSetType.Bank.ContainerIterationOrder, ReagentBankContainer)
end

-- Definition
ContainerType = {
    Joined,
    Tabbed
}

--[[ this is a really dump way to access the config to get the joined state... ]]
local idIndexMap = {}
idIndexMap[BANK_CONTAINER] = 1
idIndexMap[ReagentBankContainer] = NUM_BANKBAGSLOTS + 2
for id = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
    idIndexMap[id] = id + 1
end
for id = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
    idIndexMap[id] = id - NUM_BAG_SLOTS + 1
end
AddOnTable.ContainerIdOptionsIndexMap = idIndexMap