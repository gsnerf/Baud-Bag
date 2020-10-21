local AddOnName, AddOnTable = ...
local _

local Prototype = {
    BagSetType = nil,
    SubContainerId = nil,
    Frame = nil
}

function Prototype:ApplyBaseSkin()

end

local Metatable = { __index = Prototype }

local function BagSlot_UpdateTooltip(self, event, ...)
    local bagId = (self.isBag) and self.Bag or self:GetParent():GetID()
    if (not BagSetType.Bank.IsSubContainerOf(bagId)) then
        BaudBag_DebugMsg("Tooltip", "[BagButton:UpdateTooltip] bagId does not support cache, passing on to BagSlotButton_OnEnter [bagId]", bagId)
        BagSlotButton_OnEnter(self)
        return
    end

    local bagCache = AddOnTable.Cache:GetBagCache(bagId)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    BaudBag_DebugMsg("Tooltip", "[BagButton:UpdateTooltip] Showing cached item info [bagId, cacheEntry]", bagId, bagCache.BagLink)
    ShowHyperlink(self, bagCache.BagLink)
    GameTooltip:Show()
    BaudBagModifyBagTooltip(bagId)
    CursorUpdate(self)
end

--[[ if the mouse hovers over the bag slot item the slots belonging to this bag should be shown after a certain time (atm 350ms or 0.35s) ]]
local function BagSlot_OnEnter(self, event, ...)
    BaudBag_DebugMsg("BagHover", "Mouse is hovering above item")
    self.HighlightBag		= true
    self.HighlightBagOn		= false
    self.HighlightBagCount	= GetTime() + 0.35

    BagSlot_UpdateTooltip(self, event, ...)
end

--[[ determine if and how long the mouse was hovering and change bag according ]]
local function BagSlot_OnUpdate(self, event, ...)
    if (self.HighlightBag and (not self.HighlightBagOn) and GetTime() >= self.HighlightBagCount) then
        BaudBag_DebugMsg("BagHover", "showing item (itemName)", self:GetName())
        self.HighlightBagOn	= true
        AddOnTable["SubBags"][self.Bag]:SetSlotHighlighting(true)
    end
    AddOnTable:BagSlot_Updated(self.BagSetType, self.SubContainerId, self.Frame)
end

--[[ if the mouse was removed cancel all actions ]]
local function BagSlot_OnLeave(self, event, ...)
    BaudBag_DebugMsg("BagHover", "Mouse not hovering above item anymore")
    self.HighlightBag		= false
	
    if (self.HighlightBagOn) then
        self.HighlightBagOn	= false
        AddOnTable["SubBags"][self.Bag]:SetSlotHighlighting(false)
    end
	
end

function AddOnTable:CreateBagButton(bagSetType, bagIndex, subContainerId, parentFrame, buttonTemplate)
    -- Attention:
    -- "PaperDollFrame" calls GetInventorySlotInfo on the button created here
    -- For this to work the name bas to be "BagXSlot" with 9 random chars before that
    -- TODO: check if this is actually needed or if we can somehow break the connection to that!
    local name = "BBBagSet"..bagSetType.Id.."Bag"..bagIndex.."Slot"
    
    local bagButton = _G.setmetatable({}, Metatable)
    bagButton.BagSetType = bagSetType
    bagButton.SubContainerId = subContainerId
    bagButton.Frame	= CreateFrame("ItemButton", name, parentFrame, buttonTemplate)
    bagButton.Frame:SetFrameStrata("HIGH")
    bagButton.Frame:SetScript("OnEnter",   BagSlot_OnEnter)
    bagButton.Frame:HookScript("OnUpdate",  BagSlot_OnUpdate)
    bagButton.Frame:HookScript("OnLeave",   BagSlot_OnLeave)
    bagButton.Frame.HighlightBag = false
    bagButton.Frame.UpdateTooltip = BagSlot_UpdateTooltip
    bagButton.Frame.Bag = subContainerId
    bagButton.Frame.BagSetType = bagSetType

    AddOnTable:BagSlot_Created(bagSetType, subContainerId, bagButton.Frame)

    return bagButton
end
