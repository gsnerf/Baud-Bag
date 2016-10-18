if IsAddOnLoaded("CaerdonWardrobe") then
    CaerdonWardrobe:RegisterBagAddon();
end

local function ItemSlotUpdated(self, bagID, slotID, button)
    if not IsAddOnLoaded("CaerdonWardrobe") then
        return
    end

    local itemID = GetContainerItemID(bagID, slotID)
    if itemID then
        local options = {
            showMogIcon=true,
            showBindStatus=true,
            showSellables=true
        }

        CaerdonWardrobe:ProcessItem(itemID, bagID, slotID, button, options)
    else
		CaerdonWardrobe:ProcessItem(nil, bagID, slotID, button, nil)
    end 
end

hooksecurefunc(BaudBag, "ItemSlot_Updated", ItemSlotUpdated)