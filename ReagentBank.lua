local AddOnName, AddOnTable = ...
local _
local Funcs = AddOnTable.Functions
local Events = AddOnTable.Events

AddOnTable.State.ReagentBankSupported = true

--[[ This updates the visual of the given reagent bank item ]]
Func = function(self, event, ...)
    local slot = ...
    Funcs.DebugMessage("BankReagent", "Updating Slot", slot)

    local bagCache = AddOnTable.Cache:GetBagCache(REAGENTBANK_CONTAINER)
    local subBagObject = AddOnTable["SubBags"][-3]
    local rarityColor = BBConfig[2].RarityColor

    local _, newCacheEntry  = subBagObject.Items[slot]:UpdateContent(false)
    bagCache[slot] = newCacheEntry
    subBagObject.Items[slot]:UpdateCustomRarity(rarityColor)
end
Events.PLAYERREAGENTBANKSLOTS_CHANGED = Func

Func = function(self, event, ...)
    _G["BaudBagSubBag-3"]:GetParent().UnlockInfo:Hide()
	_G["BaudBagSubBag-3"]:GetParent().DepositButton:Enable()
end
Events.REAGENTBANK_PURCHASED = Func

local function ReagentBankBagInitialize(self, BagContainer)
    -- create BagSlot for reagent bank!
    BagSlot = CreateFrame("ItemButton", "BBReagentsBag", BagContainer, "ReagentBankSlotTemplate")
    BagSlot:SetID(-3)
    BagSlot.Bag = -3
    BagSlot:SetPoint("TOPLEFT", 8 + mod(NUM_BANKBAGSLOTS, 2) * 39, -8 - floor(NUM_BANKBAGSLOTS / 2) * 39)
    BagSlot:HookScript("OnEnter",	BaudBag_BagSlot_OnEnter)
    BagSlot:HookScript("OnUpdate",	BaudBag_BagSlot_OnUpdate)
    BagSlot:HookScript("OnLeave",	BaudBag_BagSlot_OnLeave)
end
hooksecurefunc(AddOnTable, "BankBags_Inititalize", ReagentBankBagInitialize)

local function ReagentBankBagUpdate(self)
    local ReagentsBought = IsReagentBankUnlocked()
    local bankSet = AddOnTable["Sets"][2]

    if (not ReagentsBought) then
        BagSlot = bankSet.BagButtons[REAGENTBANK_CONTAINER]
        SetItemButtonTextureVertexColor(BagSlot, 1.0, 0.1, 0.1)
    end
end
hooksecurefunc(AddOnTable, "BankBags_Update", ReagentBankBagUpdate)

local function ReagentBankBagUpdateContent(self, bankVisible)
    AddOnTable.SubBags[REAGENTBANK_CONTAINER]:UpdateSlotContents()
end
hooksecurefunc(AddOnTable, "BankBags_UpdateContent", ReagentBankBagUpdateContent)

--[[ this prepares the visual style of the reagent bag slot ]]
function ReagentBankSlotButton_OnLoad(self, event, ...)
    -- for the time beeing we use the texture of manastorms duplicator for the reagent bank button
    local texture = C_Item.GetItemIconByID(118938)
    Funcs.DebugMessage("BankReagent", "[SlotButton_OnLoad] Updating texture of reagent bank slot")
    SetItemButtonTexture(self, texture)
end

function ReagentBankSlotButton_OnEvent(self, event, ...)
    Funcs.DebugMessage("BankReagent", "[SlotButton_OnEvent] called event "..event)
end

function ReagentBankSlotButton_OnEnter(self, event, ...)
    Funcs.DebugMessage("BankReagent", "[SlotButton_OnEnter] Hovering over bank slot, showing tooltip")
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(REAGENT_BANK)
end

function ReagentBankSlotButton_OnClick(self, event, ...)
    Funcs.DebugMessage("BankReagent", "[SlotButton_OnClick] trying to show reagent bank")
    -- trying to determine container for reagent bank
    local RBankContainer = _G["BaudBagSubBag-3"]:GetParent()
    if (RBankContainer:IsShown()) then
        RBankContainer:Hide()
    else
        RBankContainer:Show()
    end
end

function BBReagentBank_UnlockInfo_Show(self, event, ...)
    if(not IsReagentBankUnlocked()) then		
		self:Show();
		MoneyFrame_Update( self.CostMoneyFrame, GetReagentBankCost());
	else
		self:Hide();
	end
end