local _
local AddOnName, AddOnTable = ...

AddOnTable.BlizzAPI = {
    ContainerIDToInventoryID = C_Container.ContainerIDToInventoryID,
    GetContainerNumSlots = C_Container.GetContainerNumSlots,
    GetContainerNumFreeSlots = C_Container.GetContainerNumFreeSlots,
    GetContainerFreeSlots = C_Container.GetContainerFreeSlots,
    GetInventorySlotInfo = C_Container.GetInventorySlotInfo,
    ---wrapper for the regular GetContainerItemInfo so we can support the addon in multiple interface levels
    ---@param containerId number ID of the container the item is located in
    ---@param slotIndex number ID of the slot in the container the item is located in
    ---@return { iconFileID: number, stackCount: number, isLocked: boolean, quality: Enum.ItemQuality?, isReadable: boolean, hasLoot: boolean, hyperlink: string, isFiltered: boolean, hasNoValue: boolean, itemID: number, isBound: boolean }|nil
    GetContainerItemInfo = C_Container.GetContainerItemInfo,
    GetContainerItemQuestInfo = C_Container.GetContainerItemQuestInfo,
    GetBackpackAutosortDisabled = C_Container.GetBackpackAutosortDisabled,
    GetBankAutosortDisabled = C_Container.GetBankAutosortDisabled,
    GetContainerItemID = C_Container.GetContainerItemID,
    GetContainerItemLink = C_Container.GetContainerItemLink,
    IsBattlePayItem = C_Container.IsBattlePayItem,
    PickupContainerItem = C_Container.PickupContainerItem,
    SetBackpackAutosortDisabled = C_Container.SetBackpackAutosortDisabled,
    SetBankAutosortDisabled = C_Container.SetBankAutosortDisabled,
    SortBags = C_Container.SortBags,
    SortBankBags = C_Container.SortBankBags,
    SortReagentBankBags = C_Container.SortReagentBankBags,
    SplitContainerItem = C_Container.SplitContainerItem,
    UseContainerItem = C_Container.UseContainerItem
}
