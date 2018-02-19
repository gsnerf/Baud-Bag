local AddOnName, AddOnTable = ...
local _

local Prototype = {
    Name = nil,
    SlotIndex = nil,
    Quality = nil,
    Parent = nil,
    Frame = nil
}

function Prototype:UpdateContent(useCache, slotCache)
    local name, count, link, quality, texture, isNewItem, isBattlePayItem
    local cacheEntry = nil

    if not useCache then
        -- the two params after link are: isFiltered (grayed out by search), hasNoValue (can't be selled)
        _, count, _, quality, _, _, link, _, _, _ = GetContainerItemInfo(self.Parent.ContainerId, self.SlotIndex)
        
        if link then
            cacheEntry = { Link = link, Count = count }
            name = GetItemInfo(link)
            isNewItem = C_NewItems.IsNewItem(self.Parent.ContainerId, self.SlotIndex)
            isBattlePayItem = IsBattlePayItem(self.Parent.ContainerId, self.SlotIndex)
        end
    elseif slotCache then
        self.Frame.hasItem = nil
        link = slotCache.Link

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
            
            self.Frame.hasItem = 1
            isNewItem = C_NewItems.IsNewItem(self.Parent.ContainerId, self.SlotIndex)
            isBattlePayItem = IsBattlePayItem(self.Parent.ContainerId, self.SlotIndex)
        end

        SetItemButtonTexture(self.Frame, texture)
        SetItemButtonCount(self.Frame, slotCache.Count or 0)
    end

    self.Quality = quality

    if (self.Frame.BattlepayItemTexture) then
        if (isBattlePayItem) then
            self.Frame.BattlepayItemTexture:Show()
        else
            self.Frame.BattlepayItemTexture:Hide()
        end
    end

    return link, cacheEntry
end

--[[
    Updates the position of this ItemButton slot.
    TODO: is this really necessary?
    -> Shouldn't this be done relative to the other slots instead of absolutely inside the container?
]]
function Prototype:UpdatePosition(container, x, y, slotLevel)
    self.Frame:ClearAllPoints()
    self.Frame:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)
    self.Frame:SetFrameLevel(slotLevel)
    self.Frame:Show()
end

--[[ Updates the rarity for this on basis of the current items quality ]]
function Prototype:UpdateRarity(showColor)
    local quality = self.Quality
    local texture = _G[self.Name.."Border"]

    if quality and (quality > 1) and showColor then
        -- default with set option
        -- texture:SetVertexColor(GetItemQualityColor(Quality))
        -- alternative rarity coloring
        if (quality ~=2) and (quality ~= 3) and (quality ~= 4) then
            texture:SetVertexColor(GetItemQualityColor(quality))
        elseif (quality == 2) then        --uncommon
            texture:SetVertexColor(0.1,   1,   0, 0.5)
        elseif (quality == 3) then        --rare
            texture:SetVertexColor(  0, 0.4, 0.8, 0.8)
        elseif (quality == 4) then        --epic
            texture:SetVertexColor(0.6, 0.2, 0.9, 0.5)
        end
        texture:Show();
    else
        texture:Hide();
    end
end

function Prototype:UpdateQuestOverlay(containerId)
    local questTexture = _G[self.Name.."IconQuestTexture"]

    if (questTexture) then
        local isQuestItem, questId, isActive = GetContainerItemQuestInfo(containerId, self.SlotIndex)
        if ( questId and not isActive ) then
            questTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
            questTexture:Show()
        elseif ( questId or isQuestItem ) then
            questTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER)
            questTexture:Show()
        else
            questTexture:Hide()
        end
    end
end

function Prototype:ShowHighlight()
    local texture = _G[self.Name.."Border"]
    texture:SetVertexColor(0.5, 0.5, 0, 1)
    texture:Show()
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateItemButton(subContainer, slotIndex, buttonTemplate)
    local itemButton = _G.setmetatable({}, Metatable)

    itemButton.Name = subContainer.Name.."Item"..slotIndex
    itemButton.SlotIndex = slotIndex
    itemButton.Parent = subContainer
    itemButton.Frame = CreateFrame("Button", itemButton.Name, subContainer.Frame, buttonTemplate)
    itemButton.Frame:SetID(slotIndex)

    local texture = itemButton.Frame:CreateTexture(itemButton.Name.."Border", "OVERLAY")
    texture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    texture:SetPoint("CENTER")
    texture:SetBlendMode("ADD")
    texture:SetAlpha(0.8)
    texture:SetHeight(70)
    texture:SetWidth(70)
    texture:Hide()
    
    return itemButton
end


function AddOnTable:ItemSlot_Created(bagId, slotId, button)
    -- just an empty hook for other addons
end

function AddOnTable:ItemSlot_Updated(bagId, slotId, button)
    -- just an empty hook for other addons
end