local AddOnName, AddOnTable = ...
local _

---@class SubContainer
local Prototype = {
    ---@type BagSetTypeClass
    BagSet = nil,
    ---@type integer
    ContainerId = nil,
    ---@type string
    Name = "",
    ---@type integer
    StartColumn = 0,
    ---@type integer
    FreeSlots = 0,
    ---@type boolean
    HighlightSlots = false,
    ---@type Frame
    Frame = nil,
    ---@type BBItemButton[]
    Items = nil,
    ---@type BagButton TODO: never used???
    BagButton = nil,
    ---@type Enum.BagSlotFlags
    FilterType = nil,
    
    -- these values might be better of in an own object, we'll see
    Size = 0,
    AvailableItemButtons = 0
}

function Prototype:GetID()
    return self.ContainerId
end

function Prototype:GetFrame()
    return self.Frame
end

function Prototype:IsOpen()
    -- TODO: is self.Frame:IsShown() really necessary here?
    -- possible answer: apparently there _can_ be a timing issue when calling GetParent() on load that _might_ be prevented by checking IsShown() first
    ---@class Frame
    local parent = self.Frame:GetParent()
    return self.Frame:IsShown() and parent:IsShown() and not parent.Closing
end

function Prototype:Rebuild()
    local newSize = self.BagSet.GetSize(self.ContainerId)
    local currentSize = self.Size
    local availableItemButtons = self.AvailableItemButtons
    local bagCache = AddOnTable.Cache:GetBagCache(self.ContainerId)
    AddOnTable.Functions.DebugMessage("BagCreation", "Rebuilding subcontainer content (containerId, currentSize, newSize, availableItemButtons)", self.ContainerId, currentSize, newSize, availableItemButtons)
    
    -- create missing slots if necessary
    if (availableItemButtons < newSize) then
        local templateToUse = self.BagSet.GetItemButtonTemplate(self.ContainerId)
        for newSlot = availableItemButtons + 1, newSize do
            local button = AddOnTable:CreateItemButton(self, newSlot, templateToUse)
            self.Items[newSlot] = button

            -- hook for plugins
            AddOnTable:ItemSlot_Created(self.BagSet, self.Frame:GetParent():GetID(), self.ContainerId, newSlot, button)
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
    local setSupportsCache = self.BagSet.SupportsCache
    local bagCache = AddOnTable.Cache:GetBagCache(self.ContainerId)
    local useCache = setSupportsCache and self.BagSet.ShouldUseCache()
    
    -- reinit values that might be outdated
    self.FreeSlots = 0

    AddOnTable.Functions.DebugMessage("Temp", "Updating SubBag (ID, Size, isBagContainer, isBankOpen)", self.ContainerId, self.Size, not setSupportsCache, AddOnTable.State.BankOpen)

    for slot = 1, self.Size do
        local itemObject = self.Items[slot]
        local link, newCacheEntry = itemObject:UpdateContent(useCache, bagCache[slot])
        itemObject:UpdateCustomRarity(showColor, rarityIntensity)
        itemObject:ShowHighlight(self.HighlightSlots)

        if (setSupportsCache and not useCache) then
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
    local buttonWidth = background <= 3 and 42 or 39
    local buttonHeight = background <= 3 and -41 or -39

    for slot = 1, self.Size do
        local itemObject = self.Items[slot]
        col = col + 1
        if (col > maxCols) then
            col = 1
            row = row + 1
        end
        local x = (col-1) * buttonWidth
        local y = (row-1) * buttonHeight
        itemObject:UpdatePosition(container, x, y, slotLevel)
    end
    return col, row
end

--[[ This only does something when the container is open (so the items are actually visible) ]]
function Prototype:UpdateItemOverlays()
    if self:IsOpen() then
        AddOnTable.Functions.DebugMessage("Bags", "Updating Items of Bag (ContainerId, container name)", self.ContainerId, self.Name)
        if not AddOnTable.Functions.IsInventory(self.ContainerId) then
            return
        end
        for Slot = 1, self.Size do
            local itemSlotObject = self.Items[Slot]
            local containerItemInfo = AddOnTable.BlizzAPI.GetContainerItemInfo(self.ContainerId, itemSlotObject:GetID())
            if (ContainerFrame_UpdateCooldown ~= nil) then
                ContainerFrame_UpdateCooldown(self.ContainerId, itemSlotObject)
            else
                local texture = containerItemInfo and containerItemInfo.iconFileID
                itemSlotObject:UpdateCooldown(texture)
            end
            itemSlotObject:UpdateQuestOverlay(self.ContainerId, containerItemInfo and containerItemInfo.hyperlink)
            itemSlotObject:UpdateItemOverlay(containerItemInfo and containerItemInfo.itemID)
        end
    end
end

local function UpdateBackpackHighlight(subContainer)
    local open = subContainer:IsOpen()
    if (subContainer.ContainerId == AddOnTable.BlizzConstants.BACKPACK_CONTAINER) then
        if (MainMenuBarBackpackButton.SlotHighlightTexture) then
            if (open) then
                MainMenuBarBackpackButton.SlotHighlightTexture:Show()
            else
                MainMenuBarBackpackButton.SlotHighlightTexture:Hide()
            end
        else
            MainMenuBarBackpackButton:SetChecked(open)
        end
    else
        local backpackSet = AddOnTable.Sets[BagSetType.Backpack.Id]
        local bagId = subContainer.ContainerId -1
        local mainMenuBarButton = _G["CharacterBag"..bagId.."Slot"]
        local baudBagBagButton = backpackSet.BagButtons[bagId]

        if (subContainer.ContainerId == 5) then
            bagId = subContainer.ContainerId - (AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER + AddOnTable.BlizzConstants.BACKPACK_CONTAINER_NUM + 1)
            mainMenuBarButton = _G["CharacterReagentBag"..bagId.."Slot"]
            baudBagBagButton = backpackSet.ReagentBagButtons[bagId]
        end
        
        if (open) then
            if (mainMenuBarButton.SlotHighlightTexture) then
                mainMenuBarButton.SlotHighlightTexture:Show()
            else
                mainMenuBarButton:SetChecked(true)
            end
            baudBagBagButton.SlotHighlightTexture:Show()
        else
            if (mainMenuBarButton.SlotHighlightTexture) then
                mainMenuBarButton.SlotHighlightTexture:Hide()
            else
                mainMenuBarButton:SetChecked(false)
            end
            baudBagBagButton.SlotHighlightTexture:Hide()
        end
    end
end

local function UpdateBankBagHighlight(subContainer)
    local open = subContainer:IsOpen()
    
    if (subContainer.ContainerId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER) then
        if (open) then
            _G["BBReagentsBag"].SlotHighlightTexture:Show()
        else
            _G["BBReagentsBag"].SlotHighlightTexture:Hide()
        end
        return
    end

    if (subContainer.ContainerId ~= AddOnTable.BlizzConstants.BANK_CONTAINER) then
        local button = AddOnTable.Sets[BagSetType.Bank.Id].BagButtons[subContainer.ContainerId - AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER]
        if (button) then
            if (open) then
                button.SlotHighlightTexture:Show()
            else
                button.SlotHighlightTexture:Hide()
            end
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
    AddOnTable.Functions.DebugMessage("Bags", "Counting free slots for container (id)", self.ContainerId)
    local useCache = AddOnTable.Cache:UsesCache(self.ContainerId)

    if useCache then
        local cache = AddOnTable.Cache:GetBagCache(self.ContainerId)

        -- if we don't have a hit in the cache make sure to return values that make sense
        local link = cache.BagLink
        if not AddOnTable.Functions.IsDefaultContainer(self.ContainerId) and (not link or (GetItemFamily(link) ~= 0)) then
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
            funcToExec = AddOnTable.BlizzAPI.GetBagSlotFlag
        end
        if (self.BagSet.Id == BagSetType.Bank.Id) then
            funcToExec = AddOnTable.BlizzAPI.GetBankBagSlotFlag
        end

        if (funcToExec) then
            for _, flag in  AddOnTable.BlizzAPI.EnumerateBagGearFilters() do
                if (funcToExec(self.ContainerId, flag)) then
                    self.FilterType = flag
                end
            end
        end
    end

    return self.FilterType
end

function Prototype:SetFilterType(type, value)
    if (self.BagSet.Id == BagSetType.Backpack.Id) then
        AddOnTable.BlizzAPI.SetBagSlotFlag(self.ContainerId, type, value)
    end
    if (self.BagSet.Id == BagSetType.Bank.Id) then
        AddOnTable.BlizzAPI.SetBankBagSlotFlag(self.ContainerId, type, value)
    end
    self.FilterType = nil
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateSubContainer(bagSetType, containerId)
    local subContainer = _G.setmetatable({}, Metatable)
    -- TODO this is a really nasty workaround... I don't like it AT ALL... but I don't see a good way right now :(
    local templateName = "BaudBagSubBagTemplate"
    if (AddOnTable.Functions.IsDefaultContainer(containerId)) then
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
    AddOnTable.Functions.DebugMessage("ItemHandle", "Event fired for subBag, Params[Event, ID]", event, self.ContainerId)
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
    if not self:GetParent():IsShown() or (self:GetID() >= 6) and not AddOnTable.State.BankOpen then
        return
    end
    Events[event](self, event, ...)
end