local _
local AddOnName, AddOnTable = ...

AddOnTable.BlizzAPI = {
    ContainerIDToInventoryID = ContainerIDToInventoryID,
    GetContainerNumSlots = GetContainerNumSlots,
    GetContainerNumFreeSlots = GetContainerNumFreeSlots,
    GetContainerFreeSlots = GetContainerFreeSlots,
    GetInventorySlotInfo = GetInventorySlotInfo,
    GetContainerItemInfo = GetContainerItemInfo,
    GetContainerItemQuestInfo = GetContainerItemQuestInfo,
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
    UseContainerItem = UseContainerItem
}
