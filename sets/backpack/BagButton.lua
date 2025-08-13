---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

BaudBag_Backpack_BagButtonMixin = {}

function BaudBag_Backpack_BagButtonMixin:Initialize()
    local slotPrefix = self.SubContainerId <= AddOnTable.BlizzConstants.BACKPACK_CONTAINER_NUM and "Bag" or "ReagentBag"
    local id, textureName = AddOnTable.BlizzAPI.GetInventorySlotInfo(slotPrefix..self.BagIndex.."Slot")
    self:SetID(id)

    BaudBag_BagButtonMixin.Initialize(self)
end

function BaudBag_Backpack_BagButtonMixin:GetBagID()
    if ( self:GetID() == 0 ) then
        return 0
    end

    -- TODO: this seems like a global... do something special with the wrapper?
    return (self:GetID() - CharacterBag0Slot:GetID()) + 1
end

function BaudBag_Backpack_BagButtonMixin:GetInventorySlot()
    return self:GetID()
end

function BaudBag_Backpack_BagButtonMixin:UpdateTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")

    AddOnTable.Functions.DebugMessage("Tooltip", "[BackpackBagButton:UpdateTooltip] bag belongs to inventory, updating with inventory item logic for [bagId]", self.SubContainerId)
    GameTooltip:SetInventoryItem("player", self:GetID())

    if AddOnTable.BlizzAPI.CanContainerUseFilterMenu( self.SubContainerId ) then
        for i, flag in AddOnTable.BlizzAPI.EnumerateBagGearFilters() do
            if AddOnTable.BlizzAPI.GetBagSlotFlag(self.SubContainerId, flag) then
                GameTooltip:AddLine(AddOnTable.BlizzConstants.BAG_FILTER_ASSIGNED_TO:format(AddOnTable.BlizzConstants.BAG_FILTER_LABELS[flag]));
                break;
            end
        end
    end

    GameTooltip:Show()
    BaudBagModifyBagTooltip(self.SubContainerId)
    AddOnTable.BlizzAPI.CursorUpdate(self)
end

local bagButtonRelatedEvents = {
    "MERCHANT_UPDATE",
    "PLAYERBANKSLOTS_CHANGED",
    "ITEM_LOCK_CHANGED",
    "CURSOR_CHANGED",
    "UPDATE_INVENTORY_ALERTS",
    "AZERITE_ITEM_POWER_LEVEL_CHANGED",
    "AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED",
    "BAG_CONTAINER_UPDATE",
}
function BaudBag_Backpack_BagButtonMixin:OnShow()
    FrameUtil.RegisterFrameForEvents(self, bagButtonRelatedEvents)
    self:UpdateContent()
end

function BaudBag_Backpack_BagButtonMixin:OnHide()
    FrameUtil.UnregisterFrameForEvents(self, bagButtonRelatedEvents)
end

function AddOnTable:CreateBackpackBagButton(bagIndex, parentFrame)
    local bagSetType = BagSetType.Backpack
    local subContainerId = bagIndex + 1

    return AddOnTable:CreateBagButton("BaudBag_Backpack_BagButton", bagSetType, subContainerId, bagIndex, parentFrame)
end

function AddOnTable:CreateReagentBagButton(bagIndex, parentFrame)
    local bagSetType = BagSetType.Backpack
    local subContainerId = bagIndex + AddOnTable.BlizzConstants.BACKPACK_CONTAINER_NUM + 1
    local name = "BBBagSet1ReagentBag"..bagIndex.."Slot"

    return AddOnTable:CreateBagButton("BaudBag_Backpack_BagButton", bagSetType, subContainerId, bagIndex, parentFrame, name)
end