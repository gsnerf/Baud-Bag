local AddOnName, AddOnTable = ...
local _

local Prototype = {
    BagSetType = nil,
    Bag = nil,
    Frame = nil
}

local Metatable = { __index = Prototype }

--[[ if the mouse hovers over the bag slot item the slots belonging to this bag should be shown after a certain time (atm 350ms or 0.35s) ]]
local function BagSlot_OnEnter(self, event, ...)
    BaudBag_DebugMsg("BagHover", "Mouse is hovering above item")
    self.HighlightBag		= true
    self.HighlightBagOn		= false
    self.HighlightBagCount	= GetTime() + 0.35
end

--[[ determine if and how long the mouse was hovering and change bag according ]]
local function BagSlot_OnUpdate(self, event, ...)
    if (self.HighlightBag and (not self.HighlightBagOn) and GetTime() >= self.HighlightBagCount) then
        BaudBag_DebugMsg("BagHover", "showing item (itemName)", self:GetName())
        self.HighlightBagOn	= true
        AddOnTable["SubBags"][self.Bag]:SetSlotHighlighting(true)
    end
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

function AddOnTable:CreateBagButton(bagSetType, bagId, bagIndex, parentFrame, buttonTemplate, namePrefix)
    local bagButton = _G.setmetatable({}, Metatable)

    bagButton.BagSetType = bagSetType
    bagButton.Bag = bagId

    bagButton.Frame	= CreateFrame("CheckButton", namePrefix..(bagIndex - 1).."Slot", parentFrame, buttonTemplate)
    bagButton.Frame:SetPoint("TOPLEFT", 8, -8 - (bagIndex - 1) * 30)
    bagButton.Frame:SetFrameStrata("HIGH")
    bagButton.Frame:HookScript("OnEnter",   BagSlot_OnEnter)
    bagButton.Frame:HookScript("OnUpdate",  BagSlot_OnUpdate)
    bagButton.Frame:HookScript("OnLeave",   BagSlot_OnLeave)
    bagButton.Frame.HighlightBag = false
    bagButton.Frame.Bag = bagId
    -- bagButton.Frame:SetID(bagIndex)

    AddOnTable:BagSlot_Created(bagSetType, bag, bagButton.Frame)

    return bagButton
end


function AddOnTable:BagSlot_Created(bagSetType, bag, button)
    -- just an empty hook for other addons
end

function AddOnTable:BagSlot_Updated(bagSetType, bag, button)
    -- just an empty hook for other addons
end