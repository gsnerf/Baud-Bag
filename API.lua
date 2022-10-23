local _
local AddOnName, AddOnTable = ...

AddOnTable.BlizzAPI = {
    ContainerIDToInventoryID = ContainerIDToInventoryID,
    GetContainerNumSlots = GetContainerNumSlots,
    GetContainerNumFreeSlots = GetContainerNumFreeSlots,
    GetContainerFreeSlots = GetContainerFreeSlots,
    GetInventorySlotInfo = GetInventorySlotInfo,
    ---wrapper for the regular GetContainerItemInfo so we can support the addon in multiple interface levels
    ---@param containerId number ID of the container the item is located in
    ---@param slotIndex number ID of the slot in the container the item is located in
    ---@return { iconFileID: number, stackCount: number, isLocked: boolean, quality: Enum.ItemQuality?, isReadable: boolean, hasLoot: boolean, hyperlink: string, isFiltered: boolean, hasNoValue: boolean, itemID: number, isBound: boolean }|nil
    GetContainerItemInfo = function(containerId, slotIndex)
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
    end,
    --- returns information about quest related information from an item
    ---@param containerID number ID of the container 
    ---@param slotIndex number index of the slot in the container
    ---@return {isQuestItem: boolean, questID: number?, isActive: boolean }
    GetContainerItemQuestInfo = function(containerID, slotIndex)
        local isQuestItem, questID, isActive = GetContainerItemQuestInfo(containerID, slotIndex)
        return {
            isQuestItem = isQuestItem,
            questID = questID,
            isActive = isActive
        }
    end,
    GetBackpackAutosortDisabled = GetBackpackAutosortDisabled,
    GetBankAutosortDisabled = GetBankAutosortDisabled,
    GetContainerItemID = GetContainerItemID,
    GetContainerItemLink = GetContainerItemLink,
    IsBattlePayItem = IsBattlePayItem,
    PickupContainerItem = PickupContainerItem,
    SetBackpackAutosortDisabled = SetBackpackAutosortDisabled,
    SetBankAutosortDisabled = SetBankAutosortDisabled,
    SortBankBags = SortBankBags,
    SortReagentBankBags = SortReagentBankBags,
    SplitContainerItem = SplitContainerItem,
    UseContainerItem = UseContainerItem,
    IsNewItem = C_NewItems.IsNewItem,
    GetItemInfo = GetItemInfo
}
