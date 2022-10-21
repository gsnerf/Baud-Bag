local _
local AddOnName, AddOnTable = ...

BaudBag_BagButtonMixin = {
    --[[
        the BagButton frame is supposed to contain:
        - BagSetType = BagSetType.Bank/BagSetType.Backpack
        - IsBankContainer = true/false
        - IsInventoryContainer = true/false
        - SubContainerId = <wow bag id>
        - Bag = SubContainerId
        - isBag = 1 [originally from ItemButton?]
    ]]
}

function BaudBag_BagButtonMixin:Initialize()
    self.IsBankContainer = self.BagSetType == BagSetType.Bank
    self.IsInventoryContainer = self.BagSetType == BagSetType.Backpack

    if (self.IsInventoryContainer) then
        PaperDollItemSlotButton_OnLoad( self )
        -- as the PaperDollItemSlotButton_OnLoad method called just now overwrites the UpdateTooltip function, we have to reset it here...
        self.UpdateTooltip = BaudBag_BagButtonMixin.UpdateTooltip
    elseif (self.IsBankContainer) then
        local bagCache = AddOnTable.Cache:GetBagCache(self.SubContainerId)
        self:SetItem(bagCache.BagLink)
    end
end

function BaudBag_BagButtonMixin:GetItemContextMatchResult()
	return ItemButtonUtil.GetItemContextMatchResultForContainer( self:GetBagID() )
end

function BaudBag_BagButtonMixin:GetBagID()
    if ( self.IsInventoryContainer ) then
        if ( self:GetID() == 0 ) then
            return 0
        end

        return (self:GetID() - CharacterBag0Slot:GetID()) + 1
    end

    if (self.IsBankContainer) then
        return self:GetID() + NUM_BAG_SLOTS
    end
end

function BaudBag_BagButtonMixin:GetInventorySlot()
    if (self.IsInventoryContainer) then
        return self:GetID()
    end

    if (self.IsBankContainer) then
        
        --[[ for reagent related BagButtons ]]
        if (self.SubContainerId == REAGENTBANK_CONTAINER) then
            return ReagentBankButtonIDToInvSlotID( self:GetID() )
        end
    
        --[[ for bank related BagButtons ]]
        return BankButtonIDToInvSlotID( self:GetID(), 1 )
    end
end

function BaudBag_BagButtonMixin:UpdateTooltip()
    if (self.IsInventoryContainer) then
        BaudBag_DebugMsg("Tooltip", "[BagButton:UpdateTooltip] bag belongs to inventory, forwarding to BagSlotButton_OnEnter [bagId]", self.SubContainerId)
        BagSlotButton_OnEnter(self)
        return
    end

    local bagCache = AddOnTable.Cache:GetBagCache(self.SubContainerId)
    if (bagCache.BagLink) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        BaudBag_DebugMsg("Tooltip", "[BagButton:UpdateTooltip] Showing cached item info [bagId, cacheEntry]", self.SubContainerId, bagCache.BagLink)
        AddOnTable.Functions.ShowLinkTooltip(self, bagCache.BagLink)
        GameTooltip:Show()
        BaudBagModifyBagTooltip(self.SubContainerId)
        CursorUpdate(self)
    end
end

function BaudBag_BagButtonMixin:Pickup()
	local inventoryID = self:GetInventorySlot()
	PickupBagFromSlot( inventoryID )
end

function BaudBag_BagButtonMixin:PutItemInBag()
    local hadItem = CursorHasItem()
	local inventoryID = self:GetInventorySlot()
	PutItemInBag(inventoryID)

    local translatedID = self:GetBagID()

	if ( not hadItem ) then
        ToggleBag( translatedID )
	end
end

function BaudBag_BagButtonMixin:OnLoad()
    self:RegisterEvent( "BAG_UPDATE_DELAYED" )
    self:RegisterEvent( "INVENTORY_SEARCH_UPDATE" )
    self:RegisterEvent( "ITEM_PUSH" )
	self:RegisterForDrag( "LeftButton" )
    self:RegisterForClicks( "LeftButtonUp", "RightButtonUp" )
end

function BaudBag_BagButtonMixin:OnEvent( event, ... )
    if ( event == "ITEM_PUSH" ) then
		local bagSlot, iconFileID = ...
		local id = self:GetID()
		if ( id == bagSlot ) then
			self.animIcon:SetTexture(iconFileID)
			self.flyin:Play(true)
		end
	end
end

function BaudBag_BagButtonMixin:OnShow()
    if (self.IsInventoryContainer) then
        PaperDollItemSlotButton_OnShow(self, true)
    end
end

function BaudBag_BagButtonMixin:OnHide()
    if (self.IsInventoryContainer) then
        PaperDollItemSlotButton_OnHide(self)
    end
end

--[[ if the mouse hovers over the bag slot item the slots belonging to this bag should be shown after a certain time (atm 350ms or 0.35s) ]]
function BaudBag_BagButtonMixin:OnEnter()
    BaudBag_DebugMsg("BagHover", "Mouse is hovering above item, initializing highlight")
    self.HighlightBag		= true
    self.HighlightBagOn		= false
    self.HighlightBagCount	= GetTime() + 0.35

    self:UpdateTooltip()
end

--[[ determine if and how long the mouse was hovering and change bag according ]]
function BaudBag_BagButtonMixin:OnUpdate()
    if (self.HighlightBag and (not self.HighlightBagOn) and GetTime() >= self.HighlightBagCount) then
        BaudBag_DebugMsg("BagHover", "showing item (itemName)", self:GetName())
        self.HighlightBagOn	= true
        AddOnTable["SubBags"][self.SubContainerId]:SetSlotHighlighting(true)
    end
    AddOnTable:BagSlot_Updated(self.BagSetType, self.SubContainerId, self.Frame)
end

--[[ if the mouse was removed cancel all actions ]]
function BaudBag_BagButtonMixin:OnLeave()
    GameTooltip_Hide()
    ResetCursor()

    BaudBag_DebugMsg("BagHover", "Mouse not hovering above item anymore")
    self.HighlightBag		= false
	
    if (self.HighlightBagOn) then
        self.HighlightBagOn	= false
        AddOnTable["SubBags"][self.SubContainerId]:SetSlotHighlighting(false)
    end
end

function BaudBag_BagButtonMixin:OnClick( button )
    if ( IsModifiedClick( "PICKUPITEM" ) ) then
        -- TODO: this might only be allowed when this is called from bank items
        self:Pickup()
    elseif ( IsModifiedClick( "OPENALLBAGS" ) ) then
        if ( GetInventoryItemTexture("player", self:GetID()) ) then
			ToggleAllBags()
		end
    else
        self:PutItemInBag()
    end
end

function BaudBag_BagButtonMixin:OnDragStart()
    self:Pickup()
end

function BaudBag_BagButtonMixin:OnReceiveDrag()
    self:PutItemInBag()
end

function AddOnTable:CreateBagButton(bagSetType, bagIndex, subContainerId, parentFrame)
    -- Attention:
    -- "PaperDollFrame" calls GetInventorySlotInfo on the button created here
    -- For this to work the name bas to be "BagXSlot" with 9 random chars before that
    -- TODO: check if this is actually needed or if we can somehow break the connection to that!
    local name = "BBBagSet"..bagSetType.Id.."Bag"..bagIndex.."Slot"
    
    local bagButton = CreateFrame("ItemButton", name, parentFrame, "BaudBag_BagButton")
    bagButton.BagSetType = bagSetType
    bagButton.Bag = subContainerId
    bagButton.SubContainerId = subContainerId
    bagButton:SetFrameStrata("HIGH")
    bagButton:Initialize()
    
    -- initialize size
    if (bagSetType == BagSetType.Backpack) then
        bagButton:SetSize(30, 30)
        bagButton.IconBorder:SetSize(30, 30)
        _G[bagButton:GetName().."NormalTexture"]:SetWidth(50)
        _G[bagButton:GetName().."NormalTexture"]:SetHeight(50)
    end
    
    AddOnTable:BagSlot_Created(bagSetType, subContainerId, bagButton)

    return bagButton
end

function AddOnTable:BagSlot_Created(bagSetType, bag, button)
    -- just an empty hook for other addons
end

function AddOnTable:BagSlot_Updated(bagSetType, bag, button)
    -- just an empty hook for other addons
end