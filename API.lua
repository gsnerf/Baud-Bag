local _
local AddOnName, AddOnTable = ...

if C_Container ~= nil then

    AddOnTable.BlizzAPI = {
        ContainerIDToInventoryID = C_Container.ContainerIDToInventoryID,
        GetContainerNumSlots = C_Container.GetContainerNumSlots,
        GetContainerNumFreeSlots = C_Container.GetContainerNumFreeSlots,
        GetContainerFreeSlots = C_Container.GetContainerFreeSlots,
        GetInventorySlotInfo = GetInventorySlotInfo,
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
        UseContainerItem = C_Container.UseContainerItem,
        IsNewItem = C_NewItems.IsNewItem,
        GetItemInfo = GetItemInfo,
        ---returns the number of watched tokens or the maximum number of watched tokens in old API
        ---@return integer
        GetNumWatchedTokens = function() return BackpackTokenFrame:GetNumWatchedTokens() end,
        EnumerateBagGearFilters = ContainerFrameUtil_EnumerateBagGearFilters,
        GetJunkFlag = function() return Enum.BagSlotFlags.PriorityJunk end,
        GetBagSlotFlag = C_Container.GetBagSlotFlag,
        GetBankBagSlotFlag = C_Container.GetBankBagSlotFlag
    }

else

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
        GetItemInfo = GetItemInfo,
        ---returns the number of watched tokens or the maximum number of watched tokens in old API
        ---@return integer
        GetNumWatchedTokens = function() return MAX_WATCHED_TOKENS end,
        EnumerateBagGearFilters = function()
            return ipairs({
                2, --Enum.BagSlotFlags.PriorityEquipment (1),
                3, --Enum.BagSlotFlags.PriorityConsumables (4),
                4, --Enum.BagSlotFlags.PriorityTradeGoods (8),
                5, --Enum.BagSlotFlags.PriorityJunk (16),
                --seemingly does not exist before DF: Enum.BagSlotFlags.PriorityQuestItems (32)
            })
        end,
        GetJunkFlag = function() return 5 end,
        GetBagSlotFlag = GetBagSlotFlag,
        GetBankBagSlotFlag = GetBankBagSlotFlag
    }

end