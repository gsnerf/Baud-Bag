---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local Funcs = AddOnTable.Functions
local Events = AddOnTable.Events

AddOnTable.State.ReagentBankSupported = true

--[[ This updates the visual of the given reagent bank item ]]
Func = function(self, event, ...)
    local slot = ...
    Funcs.DebugMessage("BankReagent", "Updating Slot", slot)

    if not AddOnTable.State.BankOpen then return end

    local showColor = BBConfig.RarityColor
    local rarityIntensity = BBConfig.RarityIntensity

    local bagCache = AddOnTable.Cache:GetBagCache(AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER)
    local subBagObject = AddOnTable["SubBags"][AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER]
    --local rarityColor = BBConfig[2].RarityColor
    local finishItemButtonUpdateCallback = function(itemButton, link, newCacheEntry)
        bagCache[slot] = newCacheEntry
    end

    subBagObject.Items[slot]:SetRarityOptions(showColor, rarityIntensity)
    subBagObject.Items[slot]:UpdateContentFromLiveData(finishItemButtonUpdateCallback)
end
Events.PLAYERREAGENTBANKSLOTS_CHANGED = Func

Func = function(self, event, ...)
    _G["BaudBagSubBag-3"]:GetParent().UnlockInfo:Hide()
	_G["BaudBagSubBag-3"]:GetParent().DepositButton:Enable()
end
Events.REAGENTBANK_PURCHASED = Func

local function ReagentBankBagInitialize(self, BagContainer)
    -- create BagSlot for reagent bank!
    local BagSlot = CreateFrame("ItemButton", "BBReagentsBag", BagContainer, "ReagentBankSlotTemplate")
    BagSlot:SetID(AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER)
    BagSlot.Bag = AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER
    BagSlot:SetPoint("TOPLEFT", 8 + mod(NUM_BANKBAGSLOTS, 2) * 39, -8 - floor(NUM_BANKBAGSLOTS / 2) * 39)
    BagSlot:HookScript("OnEnter",	BaudBag_BagSlot_OnEnter)
    BagSlot:HookScript("OnUpdate",	BaudBag_BagSlot_OnUpdate)
    BagSlot:HookScript("OnLeave",	BaudBag_BagSlot_OnLeave)
    AddOnTable.Sets[BagSetType.Bank.Id].BagButtons[AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER] = BagSlot
end
hooksecurefunc(AddOnTable, "BankBags_Inititalize", ReagentBankBagInitialize)

local function ReagentBankBagUpdate(self)
    local bankSet = AddOnTable.Sets[BagSetType.Bank.Id]

    local reagentBank = bankSet.SubContainers[AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER]
    local reagentBankContainer = reagentBank.Frame:GetParent()

    local unlockInfo = reagentBankContainer.UnlockInfo
    local depositButton = reagentBankContainer.DepositButton

    if (not AddOnTable.BlizzAPI.IsReagentBankUnlocked()) then
        local bagSlot = bankSet.BagButtons[AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER]
        bagSlot.IconBorder:SetVertexColor(1.0, 0.1, 0.1)
        unlockInfo:Show()
        depositButton:Disable()
        MoneyFrame_Update( unlockInfo.CostMoneyFrame, AddOnTable.BlizzAPI.GetReagentBankCost() )
    else
        unlockInfo:Hide()
        depositButton:Enable()
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

BaudBagReagentBankUnlockMixin = {}

function BaudBagReagentBankUnlockMixin:OnLoad()
    BaudBagContainerUnlockMixin.OnLoad(self)
    self.Title:SetText(REAGENT_BANK)
    self.Text:SetText(REAGENTBANK_PURCHASE_TEXT)
    self.PurchaseButton:SetAttribute("clickbutton", ReagentBankFrameUnlockInfoPurchaseButton)
end

function BaudBagReagentBankUnlockMixin:Refresh()
    -- TODO: global api access
    MoneyFrame_Update( self.CostMoneyFrame, GetReagentBankCost())
end