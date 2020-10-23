local AddOnName, AddOnTable = ...
local _

local Prototype = {
    Name = nil,
    SlotIndex = nil,
    Quality = nil,
    Parent = nil,
    BorderFrame = nil,
    QuestOverlay = nil
}

function Prototype:UpdateContent(useCache, slotCache)
    local texture, count, locked, quality, isReadable, link, isFiltered, hasNoValue, itemID
    local name, isNewItem, isBattlePayItem
    local cacheEntry = nil
    
    -- initialize with default values before possibly overriding later
    locked = false
    quality = Enum.ItemQuality.Poor
    isNewItemm = false
    isBattlePayItem = false
    isReadable = false

    if not useCache then
        texture, count, locked, quality, isReadable, _, link, isFiltered, hasNoValue, itemID = GetContainerItemInfo(self.Parent.ContainerId, self.SlotIndex)
        
        if link then
            cacheEntry = { Link = link, Count = count }
            name = GetItemInfo(link)
            isNewItem = C_NewItems.IsNewItem(self.Parent.ContainerId, self.SlotIndex)
            isBattlePayItem = IsBattlePayItem(self.Parent.ContainerId, self.SlotIndex)
        end
    elseif slotCache then
        self.hasItem = nil
        link = slotCache.Link
        count = slotCache.Count or 0

        if link then
            -- regular items ... 
            if (strmatch(link, "|Hitem:")) then
                name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(link)
            -- ... or a caged battle pet ...
            elseif (strmatch(link, "|Hbattlepet:")) then
                local _, speciesID, _, qualityString = strsplit(":", link)
                name, texture = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
                quality = tonumber(qualityString)
            -- ... we don't know about everything else
            end
            
            self.hasItem = 1
            isNewItem = C_NewItems.IsNewItem(self.Parent.ContainerId, self.SlotIndex)
            isBattlePayItem = IsBattlePayItem(self.Parent.ContainerId, self.SlotIndex)

            -- how to find out if an item is filtered by search here or not?
        end


    end
    
    SetItemButtonTexture(self, texture)
    --SetItemButtonQuality(self, quality, itemID)
    SetItemButtonCount(self, count)
    SetItemButtonDesaturated(self, locked)
    
    self.Quality = quality
    self:UpdateNewAndBattlepayoverlays(isNewItem, isBattlePayItem)
    self:UpdateItemOverlay(itemID)
    self.readable = isReadable
    if (self.JunkIcon) then
        self.JunkIcon:SetShown(quality == Enum.ItemQuality.Poor and not hasNoValue and MerchantFrame:IsShown())
    end

    -- in case this is a container button we try to use the regular upgrade system (this might be even extended by addons like pawn)
    if self.UpgradeIcon then
        ContainerFrameItemButton_UpdateItemUpgradeIcon(self)
    end

    return link, cacheEntry
end

--[[
    Updates the position of this ItemButton slot.
    TODO: is this really necessary?
    -> Shouldn't this be done relative to the other slots instead of absolutely inside the container?
]]
function Prototype:UpdatePosition(container, x, y, slotLevel)
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)
    self:SetFrameLevel(slotLevel)
    self:Show()
end

--[[ Updates the rarity for this on basis of the current items quality ]]
function Prototype:UpdateCustomRarity(showColor, intensity)
    local quality = self.Quality

    if quality and (quality > 1) and showColor then
        -- use alternative rarity coloring
        if (quality == Enum.ItemQuality.Uncommon) then
            self.IconBorder:SetVertexColor(0.1,   1,   0, 0.5 * intensity)
        elseif (quality == Enum.ItemQuality.Rare) then
            self.IconBorder:SetVertexColor(  0, 0.4, 0.8, 0.8 * intensity)
        elseif (quality == Enum.ItemQuality.Epic) then
            self.IconBorder:SetVertexColor(0.6, 0.2, 0.9, 0.5 * intensity)
        else
            -- we have no alternative colors for this rarity, just use the default ones
            self.IconBorder:SetVertexColor(GetItemQualityColor(quality))
        end
        self.IconBorder:Show()
    else
        self.IconBorder:Hide()
    end
end

function Prototype:UpdateQuestOverlay(containerId)
    local questTexture = _G[self.Name.."IconQuestTexture"]

    if (questTexture) then
        local width, height = self.icon:GetSize()
        local newWidth = width * 3/4
        local newHeight = height * 3/4
        questTexture:SetSize(newWidth, newHeight)
        questTexture:ClearAllPoints()
        questTexture:SetPoint("CENTER", self.icon, "CENTER", -newWidth/3, 0)
        
        local isQuestItem, questId, isActive = GetContainerItemQuestInfo(containerId, self.SlotIndex)
        local isQuestRelated = questId ~= nil or isQuestItem

        if ( isQuestRelated ) then
            self.IconBorder:SetVertexColor(1, 0.9, 0.4, 0.9)
            self.IconBorder:Show()
            if (not isActive) then
                questTexture:Show()
            end
        end

        if ( not questId or isActive ) then
            questTexture:Hide()
        end
    end
end

function Prototype:UpdateItemOverlay(itemID)
        if itemID and C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(itemID) then
            self.IconOverlay:SetAtlas([[AzeriteIconFrame]]);
            self.IconOverlay:Show();
        else
            self.IconOverlay:Hide();
        end
end

function Prototype:UpdateNewAndBattlepayoverlays(isNewItem, isBattlePayItem)
    local battlepayItemTexture = self.BattlepayItemTexture
    local newItemTexture = self.NewItemTexture
    local flash = self.flashAnim
    local newItemAnim = self.newitemglowAnim

    if (not newItemTexture or not battlepayItemTexture) then
        return
    end

    if (BBConfig.ShowNewItems and isNewItem) then
        
        if (isBattlePayItem) then
            newItemTexture:Hide()
            battlepayItemTexture:Show()
        else
            if (quality and NEW_ITEM_ATLAS_BY_QUALITY[quality]) then
                newItemTexture:SetAtlas(NEW_ITEM_ATLAS_BY_QUALITY[quality])
            else
                newItemTexture:SetAtlas("bags-glow-white")
            end
            battlepayItemTexture:Hide()
            newItemTexture:Show()
        end
        if (not flash:IsPlaying() and not newItemAnim:IsPlaying()) then
            flash:Play()
            newItemAnim:Play()
        end
    else
        battlepayItemTexture:Hide()
        newItemTexture:Hide()
        if (flash:IsPlaying() or newItemAnim:IsPlaying()) then
            flash:Stop()
            newItemAnim:Stop()
        end
    end
end

function Prototype:UpdateTooltipInternal(subContainerId)
    if ( self == GameTooltip:GetOwner() ) then
        if (GetContainerItemInfo(subContainerId, self:GetID())) then
            self.UpdateTooltip(self)
        else
            GameTooltip:Hide()
        end
    end
end

function Prototype:UpdateTooltip()
    BaudBag_DebugMsg("Tooltip", "[ItemButton:UpdateTooltip] Updating tooltip for item button "..self:GetName())
    if (self.Parent.BagSet.Id == BagSetType.Bank.Id) then
        BaudBag_DebugMsg("Tooltip", "[ItemButton:UpdateTooltip] This button is part of the bank bags... reading from cache")
        local bagId = (self.isBag) and self.Bag or self:GetParent():GetID()
        local slotId = (not self.isBag) and self:GetID() or nil
        self:UpdateTooltipFromCache(bagId, slotId)
    else
        ContainerFrameItemButton_OnUpdate(self)
    end
end

function Prototype:UpdateTooltipFromCache(bagId, slotId)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    local bagCache = AddOnTable.Cache:GetBagCache(bagId)
    local slotCache = bagCache[slotId]
    if not slotCache then
        BaudBag_DebugMsg("Tooltip", "[ItemButton:UpdateTooltipFromCache] Cannot show cache for item because there is no cache entry [bagId, slotId]", bagId, slotId)
        GameTooltip:Hide()
        return
    end
    BaudBag_DebugMsg("Tooltip", "[ItemButton:UpdateTooltipFromCache] Showing cached item info [bagId, slotId, cachEntry]", bagId, slotId, slotCache.Link)
    AddOnTable.Functions.ShowLinkTooltip(self, slotCache.Link)
    GameTooltip:Show()
    CursorUpdate(self)
end

function Prototype:ShowHighlight(enabled)
    local texture = _G[self.Name.."Border"]
    texture:SetVertexColor(0.5, 0.5, 0, 1)
    if (enabled) then
        texture:Show()
    else
        texture:Hide()
    end
    --self.NewItemTexture:Show()
end

function Prototype:ApplyBaseSkin()
    self.IconBorder:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
    self.IconBorder:SetSize(70, 70)
    self.IconBorder:SetBlendMode("ADD")

    self.BorderFrame:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
    self.BorderFrame:SetPoint("CENTER")
    self.BorderFrame:SetBlendMode("ADD")
    self.BorderFrame:SetAlpha(0.8)
    self.BorderFrame:SetSize(70, 70)

    if (self.QuestOverlay) then
        self.QuestOverlay:SetAtlas("QuestNormal", false)
    end
end

function AddOnTable:CreateItemButton(subContainer, slotIndex, buttonTemplate)
    local name = subContainer.Name.."Item"..slotIndex

    local itemButton = CreateFrame("ItemButton", name, subContainer.Frame, buttonTemplate)
    itemButton:SetID(slotIndex)
    itemButton = Mixin(itemButton, Prototype)
    
    itemButton.Name = name
    itemButton.SlotIndex = slotIndex
    itemButton.Parent = subContainer
    itemButton.BorderFrame = itemButton:CreateTexture(itemButton.Name.."Border", "OVERLAY")
    itemButton.BorderFrame:Hide()
    itemButton:SetScript("OnEnter", itemButton.UpdateTooltip)
    
    itemButton.QuestOverlay = _G[itemButton.Name.."IconQuestTexture"]
    
    itemButton:ApplyBaseSkin()
    
    return itemButton
end


function AddOnTable:ItemSlot_Created(bagSet, containerId, subContainerId, slotId, button)
    -- just an empty hook for other addons
end

function AddOnTable:ItemSlot_Updated(bagSet, containerId, subContainerId, slotId, button)
    -- just an empty hook for other addons
end