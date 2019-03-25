BagButtonMixin = {}

function BagButtonMixin:GetItemContextMatchResult()
	return ItemButtonUtil.GetItemContextMatchResultForContainer( self:GetBagID() )
end

function BagButtonMixin:GetBagID()
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

function BagButtonMixin:GetInventorySlotID()
    --[[ for container related BagButtons
    return self:GetID()
    ]]
    --[[ for bank related BagButtons
    return BankButtonIDToInvSlotID( self:GetID(), true )
    ]]
    --[[ for reagent related BagButtons
    return ReagentBankButtonIDToInvSlotID( self:GetID() )
    ]]
end

function BagButtonMixin:UpdateTooltip()
    self:OnEnter()
end

function BagButtonMixin:Pickup()
	local inventoryID = self:GetInventorySlotID()
	PickupBagFromSlot( inventoryID )
end

function BagButtonMixin:PutItemInBag() 
	local inventoryID = self:GetInventorySlotID()
	local hadItem = PutItemInBag(inventoryID)
    
    local id = self:GetID()
    local translatedID = self:GetBagID()

	if ( not hadItem ) then
        ToggleBag( translatedID )
	end
end

function BagButtonMixin:OnLoad()
	self.isBag = 1
    self:RegisterEvent( "BAG_UPDATE_DELAYED" )
    self:RegisterEvent( "INVENTORY_SEARCH_UPDATE" )
	self:RegisterForDrag( "LeftButton" )
    self:RegisterForClicks( "LeftButtonUp", "RightButtonUp" )

    ItemAnim_OnLoad( self )
    PaperDollItemSlotButton_OnLoad( self )
end

function BagButtonMixin:OnEvent( event, ... )
    ItemAnim_OnEvent( self, event, ... )
	if ( event == "BAG_UPDATE_DELAYED" ) then
		PaperDollItemSlotButton_Update( self )
	elseif ( event == "INVENTORY_SEARCH_UPDATE" ) then
        self:SetMatchesSearch( not IsContainerFiltered( self:GetBagID() ) )
	else
		PaperDollItemSlotButton_OnEvent( self, event, ... )
	end
end

function BagButtonMixin:OnShow()
    PaperDollItemSlotButton_OnShow(self, true)
end

function BagButtonMixin:OnHide()
    PaperDollItemSlotButton_OnHide(self)
end

function BagButtonMixin:OnEnter()
	GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )

	local hasItem, hasCooldown, repairCost, speciesID, level, breedQuality, maxHealth, power, speed, name = GameTooltip:SetInventoryItem( "player", self:GetInventorySlotID() )
	if ( speciesID and speciesID > 0 ) then
		BattlePetToolTip_Show( speciesID, level, breedQuality, maxHealth, power, speed, name )
		CursorUpdate( self )
		return
	end

    if ( not IsInventoryItemProfessionBag( "player", self:GetInventorySlotID() ) ) then
        for i = LE_BAG_FILTER_FLAG_EQUIPMENT, NUM_LE_BAG_FILTER_FLAGS do
            if ( GetBankBagSlotFlag( self:GetID(), i ) ) then
                GameTooltip:AddLine( BAG_FILTER_ASSIGNED_TO:format( BAG_FILTER_LABELS[i] ) )
                break
            end
        end
    end

	if ( not hasItem ) then
        GameTooltip:SetText( self.tooltipText )
	end

	GameTooltip:Show()
	CursorUpdate( self )
end

function BagButtonMixin:OnLeave()
    GameTooltip_Hide()
    ResetCursor()
end

function BagButtonMixin:OnClick( button )
    if ( IsModifiedClick( "PICKUPITEM" ) ) then
        self:Pickup()
    else if ( IsModifiedClick( "OPENALLBAGS" ) ) then
        if ( GetInventoryItemTexture("player", self:GetID()) ) then
			ToggleAllBags();
		end
    else
        self:PutItemInBag()
    end
end

function BagButtonMixin:OnDragStart()
    self:Pickup()
end

function BagButtonMixin:OnReceiveDrag()
    self:PutItemInBag()
end