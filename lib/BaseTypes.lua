---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local Localized = AddOnTable.Localized

--[[
    This enum is pre-filled with the default values that are _always_ available.
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
            for id = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
                AddOnTable.ContainerIdOptionsIndexMap[id] = id + 1
            end
        end,
        -- backpack + number of additional bags
        NumberOfContainers = 1 + AddOnTable.BlizzConstants.BACKPACK_TOTAL_BAGS_NUM,
        DefaultConfig = {
            Columns = 8,
            Scale = 100,
            GetNameAddition = function(bagId)
                local isReagentBag = AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER ~= nil and AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER <= bagId and bagId <= AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER
                if (isReagentBag) then
                    return Localized.ReagentBag
                else
                    return Localized.Inventory
                end
            end,
            RequiresFreshConfig = function(bagId)
                local isReagentBag = AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER ~= nil and AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER <= bagId and bagId <= AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER
                return isReagentBag
            end,
            Background = 1
        },
        ApplyConfigRestorationSpecificalities = function(configObject)
            -- make sure the reagent bag is NOT joined by default!
            if (configObject[BagSetType.Backpack.Id].Joined[6] == nil) then
                AddOnTable.Functions.DebugMessage("Config", "- reagent bag join for BagSet "..BagSetType.Backpack.Id.." damaged or missing, creating now")
                configObject[BagSetType.Backpack.Id].Joined[6] = false;
            end
        end,
        GetContainerTemplate = function(containerId) return "BaudBagContainerTemplate" end,
        GetItemButtonTemplate = function(containerId) return "ContainerFrameItemButtonTemplate" end,
        GetSize = function(containerId) return AddOnTable.BlizzAPI.GetContainerNumSlots(containerId) end,
        SupportsCache = false,
        ShouldUseCache = function() return false end,
        -- intended to be set in Backpack.lua
        BagOverview_Initialize = nil,
        BagFilterGetFunction = AddOnTable.BlizzAPI.GetBagSlotFlag,
        BagFilterSetFunction = AddOnTable.BlizzAPI.SetBagSlotFlag,
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

            AddOnTable.ContainerIdOptionsIndexMap[AddOnTable.BlizzConstants.BANK_CONTAINER] = 1
            AddOnTable.ContainerIdOptionsIndexMap[AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER] = AddOnTable.BlizzConstants.BANK_CONTAINER_NUM + 2
            for id = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
                AddOnTable.ContainerIdOptionsIndexMap[id] = id - AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER + 1
            end
        end,
        -- bank container + number of additional bags in bank + optionally reagent bank
        NumberOfContainers = 1 + AddOnTable.BlizzConstants.BANK_CONTAINER_NUM + (GetExpansionLevel() >= 5 and 1 or 0),
        DefaultConfig = {
            Columns = 14,
            Scale = 100,
            GetNameAddition = function(bagId)
                local isReagentBank = bagId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER
                if (isReagentBank) then
                    return Localized.ReagentBankBox
                else
                    return Localized.BankBox
                end
            end,
            RequiresFreshConfig = function(bagId)
                local isReagentBank = bagId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER
                return isReagentBank
            end,
            Background = 2
        },
        ApplyConfigRestorationSpecificalities = function(configObject)
            -- make sure the reagent bank is NOT joined by default!
            if (configObject[BagSetType.Bank.Id].Joined[9] == nil) then
                AddOnTable.Functions.DebugMessage("Config", "- reagent bank join for BagSet "..BagSetType.Bank.Id.." damaged or missing, creating now")
                configObject[BagSetType.Bank.Id].Joined[9] = false
            end
        end,
        GetContainerTemplate = function(containerId)
            if (containerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
                return "BaudBagReagentBankTemplate"
            else
                return "BaudBagContainerTemplate"
            end
        end,
        GetItemButtonTemplate = function(containerId)
            if (containerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
                return "ReagentBankItemButtonGenericTemplate"
            else
                return "BankItemButtonGenericTemplate"
            end
        end,
        GetSize = function(containerId)
            local useCache = not AddOnTable.State.BankOpen
            if useCache and (containerId ~= AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
                local bagCache = AddOnTable.Cache:GetBagCache(containerId)
                return bagCache.Size
            else
                return AddOnTable.BlizzAPI.GetContainerNumSlots(containerId)
            end
        end,
        SupportsCache = true,
        ShouldUseCache = function() return not AddOnTable.State.BankOpen end,
        -- intended to be set in Bank.lua
        BagOverview_Initialize = nil,
        BagFilterGetFunction = AddOnTable.BlizzAPI.GetBankBagSlotFlag,
        BagFilterSetFunction = AddOnTable.BlizzAPI.SetBankBagSlotFlag,
    },
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
AddOnTable.ContainerIdOptionsIndexMap = {}