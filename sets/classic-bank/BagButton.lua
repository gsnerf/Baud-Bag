---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

BaudBag_Bank_BagButtonMixin = {}

function BaudBag_Bank_BagButtonMixin:Initialize()
    BaudBag_BagButtonMixin.Initialize(self)
end

function BaudBag_Bank_BagButtonMixin:UpdateContent()
    if (AddOnTable.State.BankOpen) then
        BaudBag_BagButtonMixin.UpdateContent(self)
    else
        local bagCache = AddOnTable.Cache:GetBagCache(self.SubContainerId)
        self:SetItem(bagCache.BagLink)
    end
end

function BaudBag_Bank_BagButtonMixin:GetBagID()
    return self:GetID() + AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER
end

function BaudBag_Bank_BagButtonMixin:GetInventorySlot()
    --[[ for reagent related BagButtons ]]
    if (self.SubContainerId == REAGENTBANK_CONTAINER) then
        return ReagentBankButtonIDToInvSlotID( self:GetID() )
    end

    --[[ for bank related BagButtons ]]
    return BankButtonIDToInvSlotID( self:GetID(), 1 )
end

function BaudBag_Bank_BagButtonMixin:UpdateTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")

    local bagCache = AddOnTable.Cache:GetBagCache(self.SubContainerId)
    if (bagCache.BagLink) then
        AddOnTable.Functions.DebugMessage("Tooltip", "[BagButton:UpdateTooltip] Showing cached item info [bagId, cacheEntry]", self.SubContainerId, bagCache.BagLink)
        AddOnTable.Functions.ShowLinkTooltip(self, bagCache.BagLink)
    end

    GameTooltip:Show()
    BaudBagModifyBagTooltip(self.SubContainerId)
    AddOnTable.BlizzAPI.CursorUpdate(self)
end



function AddOnTable:CreateBankBagButton(bagIndex, parentFrame)
    -- Attention:
    -- "PaperDollFrame" calls GetInventorySlotInfo on the button created here
    -- For this to work the name bas to be "BagXSlot" with 9 random chars before that
    -- TODO: check if this is actually needed or if we can somehow break the connection to that!
    local bagSetType = BagSetType.Bank
    local subContainerId = AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER + bagIndex
    local name = "BBBagSet"..bagSetType.Id.."Bag"..bagIndex.."Slot"

    return AddOnTable:CreateBagButton("BaudBag_Bank_BagButton", bagSetType, subContainerId, bagIndex, parentFrame, name)
end