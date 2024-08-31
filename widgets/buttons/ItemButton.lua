---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

---@class BBItemButton
local Prototype = {
    ---@type string frame name for referencing from global space
    Name = nil,
    ---@type integer index inside the sub container, to be used for API calls
    SlotIndex = nil,
    ---@type Enum.ItemQuality cached quality string, used for overlay handling
    Quality = nil,
    ---@type SubContainer reference to the parent container for easier API call handling
    Parent = nil,
    ---@type Texture
    BorderFrame = nil,
    ---@type Texture|nil
    QuestOverlay = nil
}

function Prototype:UpdateContent(useCache, slotCache)
    local isNewItem, isBattlePayItem
    local cacheEntry = nil
    local containerItemInfo = {}

    if not useCache then
        containerItemInfo = AddOnTable.BlizzAPI.GetContainerItemInfo(self.Parent.ContainerId, self.SlotIndex)
        if containerItemInfo == nil then
            containerItemInfo = {}
        end
        
        if containerItemInfo.hyperlink then
            cacheEntry = { Link = containerItemInfo.hyperlink, Count = containerItemInfo.stackCount }
            isNewItem = AddOnTable.BlizzAPI.IsNewItem(self.Parent.ContainerId, self.SlotIndex)
            isBattlePayItem = AddOnTable.BlizzAPI.IsBattlePayItem(self.Parent.ContainerId, self.SlotIndex)
        end
    elseif slotCache then
        self.hasItem = nil
        containerItemInfo.hyperlink = slotCache.Link
        containerItemInfo.stackCount = slotCache.Count or 0

        if containerItemInfo.hyperlink then
            -- regular items ... 
            local texture, quality
            if (LinkUtil.IsLinkType(containerItemInfo.hyperlink, "item")) then
                _, _, quality, _, _, _, _, _, _, texture = AddOnTable.BlizzAPI.GetItemInfo(containerItemInfo.hyperlink)
                -- ... or a caged battle pet ...
            elseif (LinkUtil.IsLinkType(containerItemInfo.hyperlink, "battlepet")) then
                local _, speciesID, _, qualityString = strsplit(":", containerItemInfo.hyperlink)
                _, texture = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
                quality = tonumber(qualityString)
                -- ... we don't know about everything else
            end
            containerItemInfo.quality = quality
            containerItemInfo.iconFileID = texture

            self.hasItem = 1
            isNewItem = AddOnTable.BlizzAPI.IsNewItem(self.Parent.ContainerId, self.SlotIndex)
            isBattlePayItem = AddOnTable.BlizzAPI.IsBattlePayItem(self.Parent.ContainerId, self.SlotIndex)

            -- how to find out if an item is filtered by search here or not?
        end

    end
    
    if SetItemButtonTexture ~= nil then
        SetItemButtonTexture(self, containerItemInfo.iconFileID)
    else
        self:SetItemButtonTexture(containerItemInfo.iconFileID)
    end
    --SetItemButtonQuality(self, containerItemInfo.quality, containerItemInfo.iconFileID)
    SetItemButtonCount(self, containerItemInfo.stackCount)
    SetItemButtonDesaturated(self, containerItemInfo.isLocked)
    local itemLevelText = ""
    if (containerItemInfo.hyperlink ~= nil and BBConfig.ShowItemLevel) then
        local _, _, _, _, _, itemType, itemSubType, _, itemEquipLoc = AddOnTable.BlizzAPI.GetItemInfo(containerItemInfo.hyperlink)
        local effectiveItemLevel, _, _ = AddOnTable.BlizzAPI.GetDetailedItemLevelInfo(containerItemInfo.hyperlink)
        if effectiveItemLevel ~= nil and itemEquipLoc ~= "" and itemEquipLoc ~= INVTYPE_NON_EQUIP then
            itemLevelText = effectiveItemLevel
        end
    end
    
    if (itemLevelText ~= "") then
        self.ItemLevel:SetText(itemLevelText)
        self.ItemLevel:Show()
    else
        self.ItemLevel:Hide()
    end
    
    self.Quality = containerItemInfo.quality
    self:UpdateNewAndBattlepayoverlays(isNewItem, isBattlePayItem)
    self:UpdateItemOverlay(containerItemInfo.itemID)
    self:UpdateQuestOverlay(self.Parent.ContainerId, containerItemInfo.hyperlink)
    self.readable = containerItemInfo.isReadable
    if (self.JunkIcon) then
        self.JunkIcon:SetShown(containerItemInfo.quality == Enum.ItemQuality.Poor and not containerItemInfo.hasNoValue and MerchantFrame:IsShown())
    end

    if self.UpgradeIcon then
        self:UpdateItemUpgradeIcon()
    end
    
    return containerItemInfo.hyperlink, cacheEntry
end

function Prototype:UpdateItemUpgradeIcon()

    local isUpgrade = false

    -- first lets check if pawn is available and if so use that as a source
    if PawnIsContainerItemAnUpgrade then
        isUpgrade = PawnIsContainerItemAnUpgrade (self:GetParent():GetID(), self:GetID())
    -- now for regular wow upgrade information... while the UpgradeIcon texture itself still exists in DF, it doesn't seem to be used anymore, so this is mainly for classic(ish) versions
    elseif AddOnTable.BlizzAPI.IsContainerItemAnUpgrade then
        -- in case this is a container button we try to use the regular upgrade system (this might be even extended by addons like pawn)
        isUpgrade = AddOnTable.BlizzAPI.IsContainerItemAnUpgrade(self:GetParent():GetID(), self:GetID())
    end

    if ( isUpgrade == nil) then -- nil means not all the data was available to determine if this is an upgrade.
        self.UpgradeIcon:SetShown(false);
    else
        self.UpgradeIcon:SetShown(isUpgrade);
    end
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
            self.IconBorder:SetVertexColor(0.1,   1,   0, math.min(0.5 * intensity, 1))
        elseif (quality == Enum.ItemQuality.Rare) then
            self.IconBorder:SetVertexColor(  0, 0.4, 0.8, math.min(0.8 * intensity, 1))
        elseif (quality == Enum.ItemQuality.Epic) then
            self.IconBorder:SetVertexColor(0.6, 0.2, 0.9, math.min(0.5 * intensity, 1))
        else
            -- we have no alternative colors for this rarity, just use the default ones
            local color = BAG_ITEM_QUALITY_COLORS[quality]
            self.IconBorder:SetVertexColor( color.r, color.g, color.b, color.a )
        end
        self.IconBorder:Show()
    else
        self.IconBorder:Hide()
    end
end

function Prototype:UpdateQuestOverlay(containerId, itemlink)
    -- can only use this after DF launch and when/if classic ever gets an interface code update :(
    local questTexture = self.QuestOverlay

    if (questTexture) then
        local width, height = self.icon:GetSize()
        local newWidth = width * 3/4
        local newHeight = height * 3/4
        questTexture:SetSize(newWidth, newHeight)
        questTexture:ClearAllPoints()
        questTexture:SetPoint("CENTER", self.icon, "CENTER", -newWidth/3, 0)

        local questInfo = AddOnTable.BlizzAPI.GetContainerItemQuestInfo(containerId, self.SlotIndex)
        local isQuestRelated = questInfo.questID ~= nil or questInfo.isQuestItem

        --[[if ( not isQuestRelated ) then
            if (itemlink) then
                local _, _, _, _, _, itemType, itemSubType, _, _, _, _, classID, subclassID = AddOnTable.BlizzAPI.GetItemInfo(itemlink)
                isQuestRelated = itemType == "Quest" or itemSubType == "Quest"
            end
        end]]

        if ( isQuestRelated ) then
            self.IconBorder:SetVertexColor(1, 0.9, 0.4, 0.9)
            self.IconBorder:Show()
            if (not questInfo.isActive) then
                questTexture:Show()
            end
        end

        if ( not isQuestRelated or questInfo.isActive ) then
            questTexture:Hide()
        end
    end
end

function Prototype:UpdateItemOverlay(itemID)
    if (SetItemButtonOverlay) then
        if (itemID ~= nil) then
            SetItemButtonOverlay(self, itemID, self.Quality)
        else
            ClearItemButtonOverlay(self)
        end
    else
        self.IconOverlay:Hide()
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
            if (self.Quality and NEW_ITEM_ATLAS_BY_QUALITY[self.Quality]) then
                newItemTexture:SetAtlas(NEW_ITEM_ATLAS_BY_QUALITY[self.Quality])
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

function Prototype:OnCustomEnter()
    local bagSetId = self.Parent.BagSet.Id
    if (bagSetId == BagSetType.Bank.Id) then
        local bagId = self:GetParent():GetID()
        local slotId = self:GetID()
        AddOnTable.Functions.DebugMessage("Tooltip", "[ItemButton:UpdateTooltip] This button is part of the bank bags... reading from cache")
        self:UpdateTooltipFromCache(bagId, slotId)
    elseif (bagSetId == BagSetType.Backpack.Id) then
        if (ContainerFrameItemButton_OnUpdate ~= nil) then
            ContainerFrameItemButton_OnUpdate(self)
        elseif (ContainerFrameItemButton_OnEnter ~= nil) then
            ContainerFrameItemButton_OnEnter(self)
        else
            self:OnUpdate()
        end
    end
end

function Prototype:UpdateTooltipFromCache(bagId, slotId)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    local bagCache = AddOnTable.Cache:GetBagCache(bagId)
    local slotCache = bagCache[slotId]
    if not slotCache then
        AddOnTable.Functions.DebugMessage("Tooltip", "[ItemButton:UpdateTooltipFromCache] Cannot show cache for item because there is no cache entry [bagId, slotId]", bagId, slotId)
        GameTooltip:Hide()
        return
    end
    AddOnTable.Functions.DebugMessage("Tooltip", "[ItemButton:UpdateTooltipFromCache] Showing cached item info [bagId, slotId, cachEntry]", bagId, slotId, slotCache.Link)
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

    self.ItemLevel:SetPoint("TOP")

    if (self.QuestOverlay) then
        self.QuestOverlay:SetAtlas("QuestNormal", false)
    end
end

function AddOnTable:CreateItemButton(subContainer, slotIndex, buttonTemplate)
    local name = subContainer.Name.."Item"..slotIndex

    local itemButton
    if (GetExpansionLevel() > 7) then
        itemButton = CreateFrame("ItemButton", name, subContainer.Frame, buttonTemplate)
    else
        itemButton = CreateFrame("Button", name, subContainer.Frame, buttonTemplate)
    end
    itemButton:SetID(slotIndex)
    itemButton = Mixin(itemButton, Prototype)
    
    itemButton.Name = name
    itemButton.SlotIndex = slotIndex
    itemButton.Parent = subContainer
    itemButton.BorderFrame = itemButton:CreateTexture(itemButton.Name.."Border", "OVERLAY")
    itemButton.BorderFrame:Hide()
    itemButton:SetScript("OnEnter", itemButton.OnCustomEnter)
    itemButton.emptyBackgroundTexture = nil
    itemButton.emptyBackgroundAtlas = nil
    itemButton.ItemLevel = itemButton:CreateFontString(nil, "OVERLAY", "NumberFontNormalYellow")
    itemButton.ItemLevel:Hide()
    
    itemButton.QuestOverlay = itemButton.IconQuestTexture
    if (itemButton.QuestOverlay == nil) then
        itemButton.QuestOverlay = _G[itemButton.Name.."IconQuestTexture"]
    end
    
    if itemButton.UpgradeIcon then
        itemButton.UpgradeIcon:ClearAllPoints()
        itemButton.UpgradeIcon:SetPoint("BOTTOMLEFT")
    end

    -- this is an override for the bank items which manually call UpdateTooltip
    if (itemButton.UpdateTooltip) then
        itemButton.UpdateTooltip = itemButton.OnCustomEnter
    end
    
    itemButton:ApplyBaseSkin()
    
    return itemButton
end

---@param bagSet BagSetTypeClass
---@param containerId integer ID of the baud bag container containing the subContainerId (bagId)
---@param subContainerId integer ID representing the actual bag as known to WoW
---@param slotId integer the numeric index/ID of the slot in the wow bag the button is here fore
---@param button ItemButton the item button of the respective bagSet specific template
function AddOnTable:ItemSlot_Created(bagSet, containerId, subContainerId, slotId, button)
    -- just an empty hook for other addons
end

function AddOnTable:ItemSlot_Updated(bagSet, containerId, subContainerId, slotId, button)
    -- just an empty hook for other addons
end