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
        local slotPrefix = self.SubContainerId <= AddOnTable.BlizzConstants.BACKPACK_CONTAINER_NUM and "Bag" or "ReagentBag"
        local id, textureName = AddOnTable.BlizzAPI.GetInventorySlotInfo(slotPrefix..self.BagIndex.."Slot")
        self:SetID(id)
    end

    self:UpdateContent()
end

function BaudBag_BagButtonMixin:UpdateContent()
    if (self.IsInventoryContainer or AddOnTable.State.BankOpen) then
        local inventorySlotId = self:GetInventorySlot()
        local textureName = AddOnTable.BlizzAPI.GetInventoryItemTexture("player", inventorySlotId)
        local quality = AddOnTable.BlizzAPI.GetInventoryItemQuality("player", inventorySlotId)
        local itemLink = AddOnTable.BlizzAPI.GetInventoryItemLink("player", inventorySlotId)

        self.Icon:SetTexture(textureName)
        self.Icon:SetDesaturated(AddOnTable.BlizzAPI.IsInventoryItemLocked(inventorySlotId))
        self:SetQuality(quality)
    else
        local bagCache = AddOnTable.Cache:GetBagCache(self.SubContainerId)
        self:SetItem(bagCache.BagLink)
    end
end

function BaudBag_BagButtonMixin:SetQuality(quality)
    local qualityColor = AddOnTable.BlizzConstants.BAG_ITEM_QUALITY_COLORS[quality]
    if (qualityColor) then
        self.Border:SetVertexColor(qualityColor.r, qualityColor.g, qualityColor.b)
    else
        self.Border:SetVertexColor(1, 1, 1)
    end
end

function BaudBag_BagButtonMixin:SetItem(item)
	self.item = item;

	if not item then
		return true
	end

	local _, itemLink, itemQuality, _, _, _, _, _, _, itemIcon = AddOnTable.BlizzAPI.GetItemInfo(item)

	self.itemLink = itemLink
	if self.itemLink == nil then
		self.pendingInfo = { item = self.item, itemLocation = self.itemLocation }
		self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
		self:Reset()
		return true
	end

	self.pendingItem = nil;
	self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")

	self.Icon:SetTexture(itemIcon)
	self:SetQuality(itemQuality)
	return true;
end

function BaudBag_BagButtonMixin:Reset()
	self:SetTexture()
	self:SetQuality()
end

--[[function BaudBag_BagButtonMixin:GetItemContextMatchResult()
	return ItemButtonUtil.GetItemContextMatchResultForContainer( self:GetBagID() )
end]]

function BaudBag_BagButtonMixin:GetBagID()
    if ( self.IsInventoryContainer ) then
        if ( self:GetID() == 0 ) then
            return 0
        end

        -- TODO: this seems like a global... do something special with the wrapper?
        return (self:GetID() - CharacterBag0Slot:GetID()) + 1
    end

    if (self.IsBankContainer) then
        return self:GetID() + AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER
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
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")

    if (self.IsInventoryContainer) then
        AddOnTable.Functions.DebugMessage("Tooltip", "[BagButton:UpdateTooltip] bag belongs to inventory, updating with inventory item logic for [bagId]", self.SubContainerId)
        GameTooltip:SetInventoryItem("player", self:GetID())

        if AddOnTable.BlizzAPI.CanContainerUseFilterMenu( self.SubContainerId ) then
            for i, flag in AddOnTable.BlizzAPI.EnumerateBagGearFilters() do
                if AddOnTable.BlizzAPI.GetBagSlotFlag(self.SubContainerId, flag) then
                    GameTooltip:AddLine(AddOnTable.BlizzConstants.BAG_FILTER_ASSIGNED_TO:format(AddOnTable.BlizzConstants.BAG_FILTER_LABELS[flag]));
                    break;
                end
            end
        end
    end

    if (self.IsBankContainer) then
        local bagCache = AddOnTable.Cache:GetBagCache(self.SubContainerId)
        if (bagCache.BagLink) then
            AddOnTable.Functions.DebugMessage("Tooltip", "[BagButton:UpdateTooltip] Showing cached item info [bagId, cacheEntry]", self.SubContainerId, bagCache.BagLink)
            AddOnTable.Functions.ShowLinkTooltip(self, bagCache.BagLink)
        end
    end

    GameTooltip:Show()
    BaudBagModifyBagTooltip(self.SubContainerId)
    AddOnTable.BlizzAPI.CursorUpdate(self)
end

function BaudBag_BagButtonMixin:Pickup()
	local inventoryID = self:GetInventorySlot()
	AddOnTable.BlizzAPI.PickupBagFromSlot( inventoryID )
end

function BaudBag_BagButtonMixin:PutItemInBag()
    local hadItem = AddOnTable.BlizzAPI.CursorHasItem()
	local inventoryID = self:GetInventorySlot()
	AddOnTable.BlizzAPI.PutItemInBag(inventoryID)

    local translatedID = self:GetBagID()

	if ( not hadItem ) then
        -- TODO this is basically a global, also move to API?
        -- TODO this is somehow behaving strangely in bags... (not in bank though)
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

    if ( event == "BAG_CONTAINER_UPDATE" ) then
        self:UpdateContent()
    end

    if event == "GET_ITEM_INFO_RECEIVED" then
        if not self.pendingInfo then
			return;
		end

        self:SetItem(self.pendingInfo.item)
    end
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
function BaudBag_BagButtonMixin:OnShow()
    if (self.IsInventoryContainer) then
        FrameUtil.RegisterFrameForEvents(self, bagButtonRelatedEvents)

        self:UpdateContent()
    end
end

function BaudBag_BagButtonMixin:OnHide()
    if (self.IsInventoryContainer) then
        FrameUtil.UnregisterFrameForEvents(self, bagButtonRelatedEvents)
    end
end

--[[ if the mouse hovers over the bag slot item the slots belonging to this bag should be shown after a certain time (atm 350ms or 0.35s) ]]
function BaudBag_BagButtonMixin:OnEnter()
    AddOnTable.Functions.DebugMessage("BagHover", "Mouse is hovering above item, initializing highlight")
    self.HighlightBag		= true
    self.HighlightBagOn		= false
    self.HighlightBagCount	= GetTime() + 0.35

    self:UpdateTooltip()
end

--[[ determine if and how long the mouse was hovering and change bag according ]]
function BaudBag_BagButtonMixin:OnUpdate()
    if (self.HighlightBag and (not self.HighlightBagOn) and GetTime() >= self.HighlightBagCount) then
        AddOnTable.Functions.DebugMessage("BagHover", "showing item (itemName)", self:GetName())
        self.HighlightBagOn	= true
        AddOnTable["SubBags"][self.SubContainerId]:SetSlotHighlighting(true)
    end
    AddOnTable:BagSlot_Updated(self.BagSetType, self.SubContainerId, self.Frame)
end

--[[ if the mouse was removed cancel all actions ]]
function BaudBag_BagButtonMixin:OnLeave()
    GameTooltip_Hide()
    AddOnTable.BlizzAPI.ResetCursor()

    AddOnTable.Functions.DebugMessage("BagHover", "Mouse not hovering above item anymore")
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
        if ( AddOnTable.BlizzAPI.GetInventoryItemTexture("player", self:GetID()) ) then
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

function AddOnTable:CreateBackpackBagButton(bagIndex, parentFrame)
    local bagSetType = BagSetType.Backpack
    local subContainerId = bagIndex + 1
    local name = "BBBagSet"..bagSetType.Id.."Bag"..bagIndex.."Slot"

    local bagButton = CreateFrame("Button", name, parentFrame, "BaudBag_BagButton")
    bagButton.BagSetType = bagSetType
    bagButton.BagIndex = bagIndex
    bagButton.Bag = subContainerId
    bagButton.SubContainerId = subContainerId
    bagButton:SetFrameStrata("HIGH")
    bagButton:Initialize()

    AddOnTable:BagSlot_Created(bagSetType, subContainerId, bagButton)

    return bagButton
end

function AddOnTable:CreateReagentBagButton(bagIndex, parentFrame)
    local subContainerId = bagIndex + AddOnTable.BlizzConstants.BACKPACK_CONTAINER_NUM + 1
    local name = "BBBagSet1ReagentBag"..bagIndex.."Slot"

    local bagButton = CreateFrame("Button", name, parentFrame, "BaudBag_BagButton")
    bagButton.BagSetType = BagSetType.Backpack
    bagButton.BagIndex = bagIndex
    bagButton.Bag = subContainerId
    bagButton.SubContainerId = subContainerId
    bagButton:SetFrameStrata("HIGH")
    bagButton:Initialize()

    AddOnTable:BagSlot_Created(bagButton.BagSetType, subContainerId, bagButton)

    return bagButton
end

function AddOnTable:CreateBankBagButton(bagIndex, parentFrame)
    -- Attention:
    -- "PaperDollFrame" calls GetInventorySlotInfo on the button created here
    -- For this to work the name bas to be "BagXSlot" with 9 random chars before that
    -- TODO: check if this is actually needed or if we can somehow break the connection to that!
    local bagSetType = BagSetType.Bank
    local subContainerId = AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER + bagIndex
    local name = "BBBagSet"..bagSetType.Id.."Bag"..bagIndex.."Slot"

    local bagButton = CreateFrame("Button", name, parentFrame, "BaudBag_BagButton")
    bagButton.BagSetType = bagSetType
    bagButton.BagIndex = bagIndex
    bagButton.Bag = subContainerId
    bagButton.SubContainerId = subContainerId
    --bagButton:SetFrameStrata("HIGH")
    bagButton:Initialize()

    AddOnTable:BagSlot_Created(bagSetType, subContainerId, bagButton)

    return bagButton
end

function AddOnTable:BagSlot_Created(bagSetType, bag, button)
    -- just an empty hook for other addons
end

function AddOnTable:BagSlot_Updated(bagSetType, bag, button)
    -- just an empty hook for other addons
end