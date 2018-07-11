local _

if IsAddOnLoaded("CaerdonWardrobe") then
    CaerdonWardrobe:RegisterBagAddon();
end

local function ItemSlotUpdated(self, bagSet, containerId, subContainerId, slotId, button)
    if not IsAddOnLoaded("CaerdonWardrobe") then
        return
    end

    local itemId = GetContainerItemID(subContainerId, slotId)
    if itemId then
        local options = {
            showMogIcon=true,
            showBindStatus=true,
            showSellables=true
        }

        CaerdonWardrobe:ProcessItem(itemId, subContainerId, slotId, button, options)
    else
        CaerdonWardrobe:ProcessItem(nil, subContainerId, slotId, button, nil)
    end 
end

hooksecurefunc(BaudBag, "ItemSlot_Updated", ItemSlotUpdated)