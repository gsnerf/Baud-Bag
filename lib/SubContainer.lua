local AddOnName, AddOnTable = ...
local _

local Prototype = {
    BagSet = nil,
    ContainerId = nil,
    Name = "",
    StartColumn = 0,
    Size = 0,
    FreeSlots = 0,
    HighlightSlots = false,
    Frame = nil,
    Items = nil,
    BagButton = nil
}

function Prototype:GetID()
    return self.ContainerId
end

function Prototype:GetFrame()
    return self.Frame
end

function Prototype:IsOpen()
    -- TODO: is self.Frame:IsShown() really necessary here?
    local parent = self.Frame:GetParent()
    return self.Frame:IsShown() and parent:IsShown() and not parent.Closing;
end

function Prototype:Render()
    -- TODO
end

function Prototype:CreateMissingSlots()
    local frame = self.Frame
    if (frame.size > (frame.maxSlots or 0)) then
        for slot = (frame.maxSlots or 0) + 1, frame.size do
            -- determine type of template for item button
            local template
            if (self.ContainerId == BANK_CONTAINER) then
                template = "BankItemButtonGenericTemplate"
            elseif (self.ContainerId == REAGENTBANK_CONTAINER) then
                template = "ReagentBankItemButtonGenericTemplate"
            else
                template = "ContainerFrameItemButtonTemplate"
            end

            local button = AddOnTable:CreateItemButton(self, slot, template)
            self.Items[slot] = button
            
            AddOnTable:ItemSlot_Created(self.BagSet, frame:GetParent():GetID(), self.ContainerId, slot, button.Frame)
        end
        frame.maxSlots = frame.size
    end
end

function Prototype:UpdateSlotContents()
    local showColor = BBConfig[self.BagSet.Id][self.Frame:GetParent():GetID()].RarityColor
    local isBankBag = self.BagSet.Id == BagSetType.Bank.Id
    local bagCache = BaudBagGetBagCache(self.ContainerId)
    local useCache = isBankBag and not BaudBagFrame.BankOpen
    
    -- reinit values that might be outdated
    self.FreeSlots = 0
    if useCache then
        self.Size = bagCache.Size
    else
        self.Size = GetContainerNumSlots(self.ContainerId)
    end

    BaudBag_DebugMsg("Bags", "Updating SubBag (ID, Size, isBagContainer, isBankOpen)", self.ContainerId, self.Size, not isBankBag, BaudBagFrame.BankOpen)

    for slot = 1, self.Size do
        local itemObject = self.Items[slot]
        local link, newCacheEntry = itemObject:UpdateContent(useCache, bagCache[slot])

        if (isBankBag and not useCache) then
            bagCache[slot] = newCacheEntry
        end

        if not link then
            self.FreeSlots = self.FreeSlots + 1
        end

        -- add rarity coloring
        itemObject:UpdateCustomRarity(showColor)

        -- highlight the slots to show the connection to the bag
        if (self.HighlightSlots) then
            itemObject:ShowHighlight()
        end

        AddOnTable:ItemSlot_Updated(self.BagSet, self.Frame:GetParent():GetID(), self.ContainerId, slot, itemObject.Frame)
    end
end

-- returns the adapted col and row values
function Prototype:UpdateSlotPositions(container, background, col, row, maxCols, slotLevel)
    local frame = self.Frame
    local slot, itemObject
    local buttonWidth = background <= 3 and 42 or 39
    local buttonHeight = background <= 3 and -41 or -39

    for slot = 1, frame.maxSlots do
        itemOject = self.Items[slot]
        if (slot <= frame.size) then
            col = col + 1
            if (col > maxCols) then
                col = 1
                row = row + 1
            end
            local x = (col-1) * buttonWidth
            local y = (row-1) * buttonHeight
            itemOject:UpdatePosition(container, x, y, slotLevel)
        else
            itemOject.Frame:Hide()
        end
    end
    return col, row
end

--[[ This only does something when the container is open (so the items are actually visible) ]]
function Prototype:UpdateItemOverlays()
    if self:IsOpen() then
        BaudBag_DebugMsg("Bags", "Updating Items of Bag (ContainerId)", self.ContainerId)
        local itemButton, questTexture
        local frame = self.Frame
        for Slot = 1, GetContainerNumSlots(self.ContainerId) do
            local itemSlotObject = self.Items[Slot]
            ContainerFrame_UpdateCooldown(self.ContainerId, itemSlotObject.Frame)
            itemSlotObject:UpdateQuestOverlay(self.ContainerId)
        end
    end
end

local function UpdateBackpackHighlight(subContainer)
    local open = subContainer:IsOpen()
    -- needed in this case???
    subContainer.Frame:GetParent().UnlockInfo:Hide()

    if (subContainer.ContainerId == BACKPACK_CONTAINER) then
        MainMenuBarBackpackButton:SetChecked(open)
    else
        local bagId = subContainer.ContainerId -1
        _G["CharacterBag"..bagId.."Slot"]:SetChecked(open)
        AddOnTable["Sets"][1].BagButtons[bagId].Frame:SetChecked(open)
    end
end

local function UpdateBankBagHighlight(subContainer)
    local highlight = _G["BaudBBankBag"..(subContainer.ContainerId-4).."HighlightFrameTexture"]
    local open = subContainer:IsOpen()
    local parent = subContainer.Frame:GetParent()
    local unlockInfo = parent.UnlockInfo
    local depositButton = parent.DepositButton

    unlockInfo:Hide()

    if (subContainer.ContainerId == REAGENTBANK_CONTAINER) then
        highlight = _G["BBReagentsBagHighlightFrameTexture"]

        if (not IsReagentBankUnlocked()) then
            unlockInfo:Show()
            depositButton:Disable()
            MoneyFrame_Update( unlockInfo.CostMoneyFrame, GetReagentBankCost() )
        else
            unlockInfo:Hide()
            depositButton:Enable()
        end
    end

    if (subContainer.ContainerId ~= BANK_CONTAINER) then
        if open then
            highlight:Show()
        else
            highlight:Hide()
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
    local useCache = BaudBagUseCache(self.ContainerId)

    if useCache then
        local cache = BaudBagGetBagCache(self.ContainerId)

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
        local freeSlots, _ = GetContainerNumFreeSlots(self.ContainerId)
        local overallSlots = GetContainerNumSlots(self.ContainerId)
        return freeSlots, overallSlots
    end
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
    local idOfBagToUpdate = ...;
    if (self.ContainerId ~= idOfBagToUpdate) then
        return;
    end
    BaudBag_DebugMsg("ItemHandle", "Event fired for subBag, Params[Event, ID]", event, self.ContainerId);
    self:Update(event, ...);
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
    if not self:GetParent():IsShown() or (self:GetID() >= 5) and not BaudBagFrame.BankOpen then
        return;
    end
    Events[event](self, event, ...);
end