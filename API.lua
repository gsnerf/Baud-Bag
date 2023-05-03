local _
local AddOnName, AddOnTable = ...

AddOnTable.BlizzAPI = {
    GetInventorySlotInfo = GetInventorySlotInfo,
    GetItemInfo = GetItemInfo,
    GetDetailedItemLevelInfo = GetDetailedItemLevelInfo,
    ---returns the number of watched tokens or the maximum number of watched tokens in old API
    ---@return integer
    --GetNumWatchedTokens = function() return BackpackTokenFrame:GetNumWatchedTokens() end,
    -- this is necessary until TokenFrame was rewritten to be able to handle an arbitrary number of tokens
    GetNumWatchedTokens = function() return 5 end,
    GetIgnoreCleanupFlag = function() return Enum.BagSlotFlags.DisableAutoSort end,
    GetJunkFlag = function() return Enum.BagSlotFlags.PriorityJunk end,
    -- not yet available in WotLK
    CanContainerUseFilterMenu = ContainerFrame_CanContainerUseFilterMenu and ContainerFrame_CanContainerUseFilterMenu or function() return false end,
    -- introduced somewhere around BfA but removed in DF
    IsContainerItemAnUpgrade = IsContainerItemAnUpgrade and IsContainerItemAnUpgrade or function() return false end,
    IsInventoryItemLocked = IsInventoryItemLocked,
    GetInventoryItemTexture = GetInventoryItemTexture,
    GetInventoryItemQuality = GetInventoryItemQuality,
    GetInventoryItemLink = GetInventoryItemLink,
    CursorUpdate = CursorUpdate,
    CursorHasItem = CursorHasItem,
    ResetCursor = ResetCursor,
    PickupBagFromSlot = PickupBagFromSlot,
    PutItemInBag = PutItemInBag,
    -- introduced with warlords of draenor
    IsReagentBankUnlocked = IsReagentBankUnlocked and IsReagentBankUnlocked or function() return false end,
    GetReagentBankCost = GetReagentBankCost and GetReagentBankCost or function() return 0 end,
}

local API = AddOnTable.BlizzAPI

-- this is the API as introduced with Dragonflight (and mostly backported to wotlk classic)
if C_Container ~= nil then
    API.ContainerIDToInventoryID = C_Container.ContainerIDToInventoryID
    API.GetContainerNumSlots = C_Container.GetContainerNumSlots
    API.GetContainerNumFreeSlots = C_Container.GetContainerNumFreeSlots
    API.GetContainerFreeSlots = C_Container.GetContainerFreeSlots
    ---wrapper for the regular GetContainerItemInfo so we can support the addon in multiple interface levels
    ---@param containerId number ID of the container the item is located in
    ---@param slotIndex number ID of the slot in the container the item is located in
    ---@return { iconFileID: number, stackCount: number, isLocked: boolean, quality: Enum.ItemQuality?, isReadable: boolean, hasLoot: boolean, hyperlink: string, isFiltered: boolean, hasNoValue: boolean, itemID: number, isBound: boolean }|nil
    API.GetContainerItemInfo = C_Container.GetContainerItemInfo
    API.GetContainerItemQuestInfo = C_Container.GetContainerItemQuestInfo
    API.GetBackpackAutosortDisabled = C_Container.GetBackpackAutosortDisabled
    API.GetBankAutosortDisabled = C_Container.GetBankAutosortDisabled
    API.GetContainerItemID = C_Container.GetContainerItemID
    API.GetContainerItemLink = C_Container.GetContainerItemLink
    API.IsBattlePayItem = C_Container.IsBattlePayItem
    API.PickupContainerItem = C_Container.PickupContainerItem
    API.SetBackpackAutosortDisabled = C_Container.SetBackpackAutosortDisabled
    API.SetBankAutosortDisabled = C_Container.SetBankAutosortDisabled
    API.SortBags = C_Container.SortBags
    API.SortBankBags = C_Container.SortBankBags
    API.SortReagentBankBags = C_Container.SortReagentBankBags
    API.SplitContainerItem = C_Container.SplitContainerItem
    API.UseContainerItem = C_Container.UseContainerItem
    API.GetBagSlotFlag = C_Container.GetBagSlotFlag
    API.SetBagSlotFlag = C_Container.SetBagSlotFlag
    -- it is NOT a typo, that the BankBagSlot references the same method as the BagSlots!
    API.GetBankBagSlotFlag = C_Container.GetBagSlotFlag
    API.SetBankBagSlotFlag = C_Container.SetBagSlotFlag
else
    -- this is the API as currently seen in vanilla
    API.ContainerIDToInventoryID = ContainerIDToInventoryID
    API.GetContainerNumSlots = GetContainerNumSlots
    API.GetContainerNumFreeSlots = GetContainerNumFreeSlots
    API.GetContainerFreeSlots = GetContainerFreeSlots
    ---wrapper for the regular GetContainerItemInfo so we can support the addon in multiple interface levels
    ---@param containerId number ID of the container the item is located in
    ---@param slotIndex number ID of the slot in the container the item is located in
    ---@return { iconFileID: number, stackCount: number, isLocked: boolean, quality: Enum.ItemQuality?, isReadable: boolean, hasLoot: boolean, hyperlink: string, isFiltered: boolean, hasNoValue: boolean, itemID: number, isBound: boolean }|nil
    API.GetContainerItemInfo = function(containerId, slotIndex)
        local texture, count, locked, quality, isReadable, lootable, link, isFiltered, hasNoValue, itemID, isBound = GetContainerItemInfo(containerId, slotIndex)
        return {
            iconFileID = texture,
            stackCount = count,
            isLocked = locked,
            quality = quality,
            isReadable = isReadable,
            hasLoot = lootable,
            hyperlink = link,
            isFiltered = isFiltered,
            hasNoValue = hasNoValue,
            itemID = itemID,
            isBound = isBound,
        }
    end
    --- returns information about quest related information from an item
    ---@param containerID number ID of the container 
    ---@param slotIndex number index of the slot in the container
    ---@return {isQuestItem: boolean, questID: number?, isActive: boolean }
    API.GetContainerItemQuestInfo = function(containerID, slotIndex)
        local isQuestItem, questID, isActive = GetContainerItemQuestInfo(containerID, slotIndex)
        return {
            isQuestItem = isQuestItem,
            questID = questID,
            isActive = isActive
        }
    end
    API.GetBackpackAutosortDisabled = GetBackpackAutosortDisabled
    API.GetBankAutosortDisabled = GetBankAutosortDisabled
    API.GetContainerItemID = GetContainerItemID
    API.GetContainerItemLink = GetContainerItemLink
    API.IsBattlePayItem = IsBattlePayItem
    API.PickupContainerItem = PickupContainerItem
    API.SetBackpackAutosortDisabled = SetBackpackAutosortDisabled
    API.SetBankAutosortDisabled = SetBankAutosortDisabled
    API.SortBags = SortBags
    API.SortBankBags = SortBankBags
    API.SortReagentBankBags = SortReagentBankBags
    API.SplitContainerItem = SplitContainerItem
    API.UseContainerItem = UseContainerItem
    API.GetDetailedItemLevelInfo = GetDetailedItemLevelInfo
    ---returns the number of watched tokens or the maximum number of watched tokens in old API
    ---@return integer
    API.GetNumWatchedTokens = function() return MAX_WATCHED_TOKENS end
    API.GetIgnoreCleanupFlag = function() return LE_BAG_FILTER_FLAG_IGNORE_CLEANUP end
    API.GetJunkFlag = function() return LE_BAG_FILTER_FLAG_JUNK end
    API.GetBagSlotFlag = GetBagSlotFlag
    API.SetBagSlotFlag = SetBagSlotFlag
    API.GetBankBagSlotFlag = GetBankBagSlotFlag
    API.SetBankBagSlotFlag = SetBankBagSlotFlag
    
end

local localEnumerateBagGearFilters = function()
    return ipairs({
        2, --Enum.BagSlotFlags.PriorityEquipment (1),
        3, --Enum.BagSlotFlags.PriorityConsumables (4),
        4, --Enum.BagSlotFlags.PriorityTradeGoods (8),
        5, --Enum.BagSlotFlags.PriorityJunk (16),
        --seemingly does not exist before DF: Enum.BagSlotFlags.PriorityQuestItems (32)
    })
end
API.EnumerateBagGearFilters = ContainerFrameUtil_EnumerateBagGearFilters and ContainerFrameUtil_EnumerateBagGearFilters or localEnumerateBagGearFilters

-- this 
API.SupportsContainerSorting = function()
    return GetExpansionLevel() >= 6
end

API.IsNewItem = C_NewItems and C_NewItems.IsNewItem or function() return false end

if (API.IsBattlePayItem == nil) then
    API.IsBattlePayItem = function() return false end
end

AddOnTable.BlizzConstants = {
    REAGENTBANK_CONTAINER = -3, -- REAGENTBANK_CONTAINER (from WoD onwards)
    KEYRING_CONTAINER = -2, -- KEYRING_CONTAINER (only in BC? and WotLK)
    BANK_CONTAINER = -1, -- BANK_CONTAINER
    BACKPACK_CONTAINER = 0, -- BACKPACK_CONTAINER
    BACKPACK_CONTAINER_NUM = 4, -- NUM_BAG_SLOTS
    BACKPACK_REAGENT_BAG_NUM = 0, -- NUM_REAGENTBAG_SLOTS,
    BACKPACK_TOTAL_BAGS_NUM = 4, -- == NUM_BAG_SLOTS + NUM_REAGENTBAG_SLOTS
    BACKPACK_FIRST_CONTAINER = 0, -- == BACKPACK_CONTAINER
    BACKPACK_LAST_BAG_CONTAINER = 4, -- == NUM_BAG_SLOTS
    BACKPACK_FIRST_REAGENT_CONTAINER = nil, -- == doesn't exist here
    BACKPACK_LAST_CONTAINER = 4, -- == BACKPACK_CONTAINER + NUM_TOTAL_EQUIPPED_BAG_SLOTS ( == NUM_BAG_SLOTS + NUM_REAGENTBAG_SLOTS)
    BACKPACK_BASE_SIZE = 16, -- == local copy from ContainerFrame local variable
    BANK_CONTAINER_NUM = 7, -- == NUM_BANKBAGSLOTS
    BANK_FIRST_CONTAINER = 5, -- == NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1
    BANK_LAST_CONTAINER = 11, -- == NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1 + NUM_BANKBAGSLOTS
    BANK_SLOTS_NUM = NUM_BANKGENERIC_SLOTS,
    BAG_FILTER_ASSIGNED_TO = BAG_FILTER_ASSIGNED_TO, -- localized "Assigned To:"
    BAG_FILTER_LABELS = BAG_FILTER_LABELS, -- list of localized filter names, like "Consumables", "Trade Goods", etc.
    BAG_ITEM_QUALITY_COLORS = BAG_ITEM_QUALITY_COLORS, -- list of quality colors, index is quality id
}

if (GetExpansionLevel() >= 9) then
    AddOnTable.BlizzConstants.BACKPACK_REAGENT_BAG_NUM = 1 -- NUM_REAGENTBAG_SLOTS,
    AddOnTable.BlizzConstants.BACKPACK_TOTAL_BAGS_NUM = 5 -- == NUM_BAG_SLOTS + NUM_REAGENTBAG_SLOTS
    AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER = 5 -- == NUM_BAG_SLOTS + 1
    AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER = 5 -- == BACKPACK_CONTAINER + NUM_TOTAL_EQUIPPED_BAG_SLOTS ( == NUM_BAG_SLOTS + NUM_REAGENTBAG_SLOTS)
    AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER = 6 -- == NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1
    AddOnTable.BlizzConstants.BANK_LAST_CONTAINER = 12 -- == NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1 + NUM_BANKBAGSLOTS
end

if C_CurrencyInfo ~= nil and C_CurrencyInfo.GetBackpackCurrencyInfo ~= nil then
    AddOnTable.BlizzAPI.GetBackpackCurrencyInfo = C_CurrencyInfo.GetBackpackCurrencyInfo
else
    AddOnTable.BlizzAPI.GetBackpackCurrencyInfo = GetBackpackCurrencyInfo
end