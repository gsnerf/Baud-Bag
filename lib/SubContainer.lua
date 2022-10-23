local AddOnName, AddOnTable = ...
local _

local Prototype = {
    BagSet = nil,
    ContainerId = nil,
    Name = "",
    StartColumn = 0,
    FreeSlots = 0,
    HighlightSlots = false,
    Frame = nil,
    Items = nil,
    BagButton = nil,
    FilterType = nil,
    
    -- theese values might be better of in an own object, we'll see
    Size = 0,
    AvailableItemButtons = 0
}

function Prototype:GetID()
    return self.ContainerId
end

function Prototype:GetFrame()
    return self.Frame
end

function Prototype:GetSize()
    local isBankBag = self.BagSet.Id == BagSetType.Bank.Id
    local useCache = isBankBag and not AddOnTable.State.BankOpen
    if useCache and (self.ContainerId ~= -3) then
        local bagCache = AddOnTable.Cache:GetBagCache(self.ContainerId)
        return bagCache.Size
    else
        return AddOnTable.BlizzAPI.GetContainerNumSlots(self.ContainerId)
    end
end

function Prototype:IsOpen()
    -- TODO: is self.Frame:IsShown() really necessary here?
    local parent = self.Frame:GetParent()
    return self.Frame:IsShown() and parent:IsShown() and not parent.Closing
end

function Prototype:GetItemButtonTemplate()
    -- TODO: this should propably be already known when creating the SubContainer, so better move somewhere earlier!
    
    if (self.ContainerId == REAGENTBANK_CONTAINER) then
        return "ReagentBankItemButtonGenericTemplate"
    elseif (self.BagSet.Id == BagSetType.Bank.Id) then
        return "BankItemButtonGenericTemplate"
    else
        return "ContainerFrameItemButtonTemplate"
    end
end

function Prototype:Rebuild()
    local newSize = self:GetSize()
    local currentSize = self.Size
    local availableItemButtons = self.AvailableItemButtons
    local bagCache = AddOnTable.Cache:GetBagCache(self.ContainerId)
    BaudBag_DebugMsg("BagCreation", "Rebuilding subcontainer content (containerId, currentSize, newSize, availableItemButtons)", self.ContainerId, currentSize, newSize, availableItemButtons)
    
    -- create missing slots if necessary
    if (availableItemButtons < newSize) then
        local templateToUse = self:GetItemButtonTemplate()
        for newSlot = availableItemButtons + 1, newSize do
            local button = AddOnTable:CreateItemButton(self, newSlot, templateToUse)
            self.Items[newSlot] = button

            -- hook for plugins
            AddOnTable:ItemSlot_Created(self.BagSet, self.Frame:GetParent():GetID(), self.ContainerId, slot, button)
        end
        availableItemButtons = newSize
    end

    -- handle excessive slots when necessary
    if (newSize < availableItemButtons) then
        for excessSlot = newSize + 1, availableItemButtons do
            local excessItemButton = self.Items[excessSlot]
            excessItemButton:Hide()

            if (bagCache) then
                bagCache[excessSlot] = nil
            end
        end
    end

    -- remember the new values
    self.Size = newSize
    self.AvailableItemButtons = availableItemButtons
    if (bagCache) then
        bagCache.Size = newSize
    end

    -- now update content
    self:UpdateSlotContents()
end

function Prototype:UpdateSlotContents()
    local showColor = BBConfig.RarityColor
    local rarityIntensity = BBConfig.RarityIntensity
    local isBankBag = self.BagSet.Id == BagSetType.Bank.Id
    local bagCache = AddOnTable.Cache:GetBagCache(self.ContainerId)
    local useCache = isBankBag and not AddOnTable.State.BankOpen
    
    -- reinit values that might be outdated
    self.FreeSlots = 0

    BaudBag_DebugMsg("Bags", "Updating SubBag (ID, Size, isBagContainer, isBankOpen)", self.ContainerId, self.Size, not isBankBag, AddOnTable.State.BankOpen)

    for slot = 1, self.Size do
        local itemObject = self.Items[slot]
        local link, newCacheEntry = itemObject:UpdateContent(useCache, bagCache[slot])
        itemObject:UpdateCustomRarity(showColor, rarityIntensity)
        itemObject:ShowHighlight(self.HighlightSlots)

        if (isBankBag and not useCache) then
            bagCache[slot] = newCacheEntry
        end

        if not link then
            self.FreeSlots = self.FreeSlots + 1
        end

        AddOnTable:ItemSlot_Updated(self.BagSet, self.Frame:GetParent():GetID(), self.ContainerId, slot, itemObject)
    end

    self:UpdateItemOverlays()
end

-- returns the adapted col and row values
function Prototype:UpdateSlotPositions(container, background, col, row, maxCols, slotLevel)
    local slot, itemObject
    local buttonWidth = background <= 3 and 42 or 39
    local buttonHeight = background <= 3 and -41 or -39

    for slot = 1, self.Size do
        itemOject = self.Items[slot]
        col = col + 1
        if (col > maxCols) then
            col = 1
            row = row + 1
        end
        local x = (col-1) * buttonWidth
        local y = (row-1) * buttonHeight
        itemOject:UpdatePosition(container, x, y, slotLevel)
    end
    return col, row
end

--[[ This only does something when the container is open (so the items are actually visible) ]]
function Prototype:UpdateItemOverlays()
    if self:IsOpen() then
        BaudBag_DebugMsg("Bags", "Updating Items of Bag (ContainerId, container name)", self.ContainerId, self.Name)
        for Slot = 1, self.Size do
            local itemSlotObject = self.Items[Slot]
            local containerItemInfo = AddOnTable.BlizzAPI.GetContainerItemInfo(self.ContainerId, itemSlotObject:GetID())
            local texture = containerItemInfo and containerItemInfo.iconFileID
            itemSlotObject:UpdateCooldown(texture)
            itemSlotObject:UpdateQuestOverlay(self.ContainerId)
        end
    end
end

local function UpdateBackpackHighlight(subContainer)
    local open = subContainer:IsOpen()
    -- needed in this case???
    subContainer.Frame:GetParent().UnlockInfo:Hide()

    if (subContainer.ContainerId == BACKPACK_CONTAINER) then
        if (open) then
            MainMenuBarBackpackButton.SlotHighlightTexture:Show()
        else
            MainMenuBarBackpackButton.SlotHighlightTexture:Hide()
        end
    else
        local bagId = subContainer.ContainerId -1
        if (open) then
            _G["CharacterBag"..bagId.."Slot"].SlotHighlightTexture:Show()
            AddOnTable["Sets"][1].BagButtons[bagId].SlotHighlightTexture:Show()
        else
            _G["CharacterBag"..bagId.."Slot"].SlotHighlightTexture:Hide()
            AddOnTable["Sets"][1].BagButtons[bagId].SlotHighlightTexture:Hide()
        end
    end
end

local function UpdateBankBagHighlight(subContainer)
    local open = subContainer:IsOpen()
    local parent = subContainer.Frame:GetParent()
    local unlockInfo = parent.UnlockInfo
    local depositButton = parent.DepositButton
    local highlight = nil

    unlockInfo:Hide()

    if (subContainer.ContainerId == REAGENTBANK_CONTAINER) then
        if (open)   then
            _G["BBReagentsBag"].SlotHighlightTexture:Show()
        else
            _G["BBReagentsBag"].SlotHighlightTexture:Hide()
        end
        if (not IsReagentBankUnlocked()) then
            unlockInfo:Show()
            depositButton:Disable()
            MoneyFrame_Update( unlockInfo.CostMoneyFrame, GetReagentBankCost() )
        else
            unlockInfo:Hide()
            depositButton:Enable()
        end
        return
    end

    if (subContainer.ContainerId ~= BANK_CONTAINER) then
        local button = AddOnTable["Sets"][2].BagButtons[subContainer.ContainerId-4]
        if (open) then
            button.SlotHighlightTexture:Show()
        else
            button.SlotHighlightTexture:Hide()
        end
    end
end

function Prototype:UpdateOpenBagHighlight()
    if (self.BagSet.Id == BagSetType.Backpack.Id) then
        UpdateBackpackHighlight(self)
    elseif (self.BagSet.Id == BagSetType.Bank.Id) then
        UpdateBankBagHighlight(self)
    end
end

function Prototype:SetSlotHighlighting(shouldHighlight)
    self.HighlightSlots = shouldHighlight
    self:UpdateSlotContents()
end

function Prototype:GetSlotInfo()
    BaudBag_DebugMsg("Bags", "Counting free slots for container (id)", self.ContainerId)
    local useCache = AddOnTable.Cache:UsesCache(self.ContainerId)

    if useCache then
        local cache = AddOnTable.Cache:GetBagCache(self.ContainerId)

        -- if we don't have a hit in the cache make sure to return values that make sense
        local link = cache.BagLink
        if not BaudBag_IsBankDefaultContainer(self.ContainerId) and (not link or (GetItemFamily(link) ~= 0)) then
            return 0, 0
        end

        local free = 0
        for slot = 1, cache.Size do
            if not cache[slot]then
                free = free + 1
            end
        end
        return free, cache.Size
    else
        local freeSlots, _ = AddOnTable.BlizzAPI.GetContainerNumFreeSlots(self.ContainerId)
        local overallSlots = AddOnTable.BlizzAPI.GetContainerNumSlots(self.ContainerId)
        return freeSlots, overallSlots
    end
end

function Prototype:GetFilterType()
    if (not self.FilterType) then
        local funcToExec

        if (self.BagSet.Id == BagSetType.Backpack.Id) then
            funcToExec = GetBagSlotFlag
        end
        if (self.BagSet.Id == BagSetType.Bank.Id) then
            funcToExec = GetBankBagSlotFlag
        end

        for i = LE_BAG_FILTER_FLAG_EQUIPMENT, NUM_LE_BAG_FILTER_FLAGS do
            if (funcToExec(self.ContainerId, i)) then
                self.FilterType = i
            end
        end
    end

    return self.FilterType
end

function Prototype:SetFilterType(type, value)
    if (self.BagSet.Id == BagSetType.Backpack.Id) then
        SetBagSlotFlag(self.ContainerId, type, value)
    end
    if (self.BagSet.Id == BagSetType.Bank.Id) then
        SetBankBagSlotFlag(self.ContainerId, type, value)
    end
    self.FilterType = nil
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateSubContainer(bagSetType, containerId)
    local subContainer = _G.setmetatable({}, Metatable)
    -- TODO this is a really nasty workaround... I don't like it AT ALL... but I don't see a good way right now :(
    local templateName = "BaudBagSubBagTemplate"
    if (BaudBag_IsBankDefaultContainer(containerId)) then
        templateName = nil
    end
    subContainer.Name = AddOnName.."SubBag"..containerId
    subContainer.Frame = CreateFrame("Frame", subContainer.Name, nil, templateName)
    subContainer.Frame.BagSet = bagSetType.Id
    subContainer.BagSet = bagSetType
    subContainer.ContainerId = containerId
    subContainer.Items = {}
    return subContainer
end

local function EventUpdateFunction(self, event, ...)
    -- only update if the event is for the current bag!
    local idOfBagToUpdate = ...
    if (self.ContainerId ~= idOfBagToUpdate) then
        return
    end
    BaudBag_DebugMsg("ItemHandle", "Event fired for subBag, Params[Event, ID]", event, self.ContainerId)
    self:Update(event, ...)
end

local Events = {
    BAG_UPDATE,
    BAG_UPDATE_COOLDOWN = EventUpdateFunction,
    BAG_CLOSED,
    ITEM_LOCK_CHANGED = EventUpdateFunction,
    UPDATE_INVENTORY_ALERTS = EventUpdateFunction
}

-- TODO: don't know if this mixup of object orientation and wow function handly really works like that
function Prototype:OnLoad(self, event, ...)

end

-- TODO: don't know if this mixup of object orientation and wow function handly really works like that
function Prototype:OnEvent(self, event, ...)
    if not self:GetParent():IsShown() or (self:GetID() >= 5) and not AddOnTable.State.BankOpen then
        return
    end
    Events[event](self, event, ...)
end