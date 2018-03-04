local AddOnName, AddOnTable = ...
local _
local Prefix = "BaudBag"
local Localized = BaudBagLocalized;

local EventFuncs = {
    BANKFRAME_CLOSED = function(self, event, ...)
        BaudBag_DebugMsg("Bank", "Event BANKFRAME_CLOSED fired");
        BaudBagFrame.BankOpen = false;
        BaudBagBankSlotPurchaseButton:Disable();
        if _G[Prefix.."Container2_1"].AutoOpened then
            _G[Prefix.."Container2_1"]:Hide();
        else
            --Add offline again to bag name
            local numberOfContainers = table.getn(AddOnTable.Sets[2].Containers)
            for ContNum = 1, numberOfContainers do
                AddOnTable.Sets[2].Containers[ContNum]:UpdateName()
            end
        end
        BaudBagAutoOpenSet(1, true);
    end,
}

local Func = function(self, event, ...)
    BaudBag_DebugMsg("Bank", "Event fired", event)
    
	-- set bank open marker if it was opend
    if (event == "BANKFRAME_OPENED") then
        BaudBagFrame.BankOpen = true
    end
    
    -- everything coming now is only needed if the bank is visible
    local bankVisible = BBConfig[2].Enabled and (event == "BANKFRAME_OPENED")
    BaudBagBankBags_UpdateContent(bankVisible)
    if not bankVisible then
        return
    end
    BaudBagAutoOpenSet(1)
    BaudBagAutoOpenSet(2)
end
EventFuncs.BANKFRAME_OPENED = Func
EventFuncs.PLAYERBANKBAGSLOTS_CHANGED = Func

--[[ This updates the visual of the given reagent bank item ]]
Func = function(self, event, ...)
    local slot = ...;
    BaudBag_DebugMsg("BankReagent", "Updating Slot", slot);

    -- first basic update
    local Button = _G["BaudBagSubBag-3Item"..(slot)];
    BankFrameItemButton_Update(Button);

    ---- now update custom rarity colloring
    local bagCache = BaudBagGetBagCache(REAGENTBANK_CONTAINER);
    local Link = GetContainerItemLink(REAGENTBANK_CONTAINER, slot);
    local Quality = nil;

    -- even though we are in "online" there might be no item on this slot!
    if Link then
        _, _, Quality, _, _, _, _, _, _, _ = GetItemInfo(Link);
        --isNewItem       = C_NewItems.IsNewItem(REAGENTBANK_CONTAINER, slot);
        --isBattlePayItem = IsBattlePayItem(REAGENTBANK_CONTAINER, slot);
        bagCache[slot]  = {Link = Link, Count = select(2, GetContainerItemInfo(REAGENTBANK_CONTAINER, slot))};
    else
        bagCache[slot] = nil;
    end
    
    local subBagObject = AddOnTable["SubBags"][-3]
    local rarityColor = BBConfig[2][subBagObject.Frame:GetParent():GetID()].RarityColor
    subBagObject.Items[slot]:UpdateContent(false)
    subBagObject.Items[slot]:UpdateCustomRarity(rarityColor)
end
EventFuncs.PLAYERREAGENTBANKSLOTS_CHANGED = Func;

Func = function(self, event, ...)
    _G["BaudBagSubBag-3"]:GetParent().UnlockInfo:Hide();
	_G["BaudBagSubBag-3"]:GetParent().DepositButton:Enable();
end
EventFuncs.REAGENTBANK_PURCHASED = Func;

function BaudBag_RegisterBankEvents(self)
    for Key, Value in pairs(EventFuncs)do
        self:RegisterEvent(Key)
    end
end

function BaudBag_OnBankEvent(self, event, ...)
    if EventFuncs[event] then
        EventFuncs[event](self, event, ...)
    end
end

--[[
    This method creates the buttons in the banks BagsFrame (frame that pops out and shows the available bags).
  ]]
function BaudBagBankBags_Initialize()
    local BagSlot, Texture;
    local bankSet = AddOnTable["Sets"][2]
    local BBContainer2 = _G[Prefix.."Container2_1BagsFrame"];

    -- create BagSlots for regular bags
    for Bag = 1, NUM_BANKBAGSLOTS do
        local buttonIndex = Bag
        local subContainerId = Bag + 4
        local bagButton = AddOnTable:CreateBagButton(bankSet.Type, buttonIndex, subContainerId, BBContainer2, "BankItemButtonBagTemplate")
        bagButton.Frame:SetID(buttonIndex)
        bagButton.Frame:SetPoint("TOPLEFT", 8 + mod(Bag - 1, 2) * 39, -8 - floor((Bag - 1) / 2) * 39)
        bankSet.BagButtons[Bag] = bagButton

        -- get cache for the current bank bag
        -- if there is a bag create icon with correct texture etc
        local bagCache = BaudBagGetBagCache(Bag + 4);
        if (bagCache.BagLink) then
            Texture = GetItemIcon(bagCache.BagLink);
            SetItemButtonCount(BagSlot, bagCache.BagCount or 0);
        else
            Texture = select(2, GetInventorySlotInfo("Bag"..Bag));
        end
        SetItemButtonTexture(BagSlot, Texture);
    end

    -- create BagSlot for reagent bank!
    BagSlot = CreateFrame("Button", "BBReagentsBag", BBContainer2, "ReagentBankSlotTemplate");
    BagSlot:SetID(-3);
    BagSlot.Bag = -3;
    BagSlot:SetPoint("TOPLEFT", 8 + mod(NUM_BANKBAGSLOTS, 2) * 39, -8 - floor(NUM_BANKBAGSLOTS / 2) * 39);
    BagSlot:HookScript("OnEnter",	BaudBag_BagSlot_OnEnter);
    BagSlot:HookScript("OnUpdate",	BaudBag_BagSlot_OnUpdate);
    BagSlot:HookScript("OnLeave",	BaudBag_BagSlot_OnLeave);

    BBContainer2:SetWidth(91);
    --Height changes depending if there is a purchase button
    BBContainer2.Height = 13 + ceil(NUM_BANKBAGSLOTS / 2) * 39;
    BaudBagBankBags_Update();
    
end


--[[
    This analyses the bought bags and updates the bag slot view
    (the little window that pops out the main bank container and shows the bought bags) 
    alongside the "bag slot buy" button 
  ]]
function BaudBagBankBags_Update()
    local Purchase = BaudBagBankSlotPurchaseFrame;
    local Slots, Full = GetNumBankSlots();
    local ReagentsBought = IsReagentBankUnlocked();
    local BagSlot;
    local bankSet = AddOnTable["Sets"][2]

    BaudBag_DebugMsg("Bank", "BankBags: updating");
    
    for Bag = 1, NUM_BANKBAGSLOTS do
        BagSlot = bankSet.BagButtons[Bag].Frame
        
        if (Bag <= Slots) then
            SetItemButtonTextureVertexColor(BagSlot, 1.0, 1.0, 1.0);
            BagSlot.tooltipText = BANK_BAG;
        else
            SetItemButtonTextureVertexColor(BagSlot, 1.0, 0.1, 0.1);
            BagSlot.tooltipText = BANK_BAG_PURCHASE;
        end
    end
    -- TODO similarily check if reagent bank is already bought and change vertex color accordingly!
    
    local BBContainer2 = _G[Prefix.."Container2_1BagsFrame"];
    
    if Full then
        BaudBag_DebugMsg("Bank", "BankBags: all bags bought hiding purchase button");
        Purchase:Hide();
        BBContainer2:SetHeight(BBContainer2.Height);
        return;
    end
    
    local Cost = GetBankSlotCost(Slots);
    BaudBag_DebugMsg("Bank", "BankBags: buyable bag slots left, currentCost = "..Cost);
    
    -- This line allows the confirmation box to show the cost
    BankFrame.nextSlotCost = Cost;
    
    if (GetMoney() >= Cost) then
        -- SetMoneyFrameColor(Purchase:GetName().."MoneyFrame", 1.0, 1.0, 1.0);
        SetMoneyFrameColor(Purchase:GetName().."MoneyFrame");
    else
        SetMoneyFrameColor(Purchase:GetName().."MoneyFrame", "red");
    end
    MoneyFrame_Update(Purchase:GetName().."MoneyFrame", Cost);
    
    Purchase:Show();
    BBContainer2:SetHeight(BBContainer2.Height + 40);
end

function BaudBagBankBags_UpdateContent(bankVisible)
    
    -- make sure the player can buy new bankslots
    BaudBagBankSlotPurchaseButton:Enable()

    local BankItemButtonPrefix        = Prefix.."SubBag"..BANK_CONTAINER.."Item"
    local ReagentBankItemButtonPrefix = Prefix.."SubBag"..REAGENTBANK_CONTAINER.."Item"

    for Index = 1, NUM_BANKGENERIC_SLOTS do
        BankFrameItemButton_Update(_G[BankItemButtonPrefix..Index])
    end
    for Index = 1, NUM_BANKBAGSLOTS do
        local bankBagButton = AddOnTable["Sets"][2].BagButtons[Index].Frame
        BankFrameItemButton_Update(bankBagButton)
    end
    for Index = 1, GetContainerNumSlots(REAGENTBANK_CONTAINER) do
        BankFrameItemButton_Update(_G[ReagentBankItemButtonPrefix..Index])
    end
    BaudBagBankBags_Update()
    BaudBag_DebugMsg("Bank", "Recording bank bag info.")
    for Bag = 1, NUM_BANKBAGSLOTS do
        BaudBagGetBagCache(Bag + 4).BagLink  = GetInventoryItemLink("player", 67 + Bag)
        BaudBagGetBagCache(Bag + 4).BagCount = GetInventoryItemCount("player", 67 + Bag)
    end

    if not bankVisible then
        BaudBag_DebugMsg("Bank", "Bankframe does not really seem to be open or event was not BANKFRAME_OPENED. Stepping over actually opening the Bankframes")
        return
    end

    local BBContainer2_1 = _G[Prefix.."Container2_1"]
    if BBContainer2_1:IsShown() then
        -- TODO we need direct access to the Container Object here in the future!
        BaudBagUpdateContainer(BBContainer2_1)
        BaudBagUpdateFreeSlots(BBContainer2_1)
    else
        BBContainer2_1.AutoOpened = true
        BBContainer2_1:Show()
    end
end



--[[ this prepares the visual style of the reagent bag slot ]]
function ReagentBankSlotButton_OnLoad(self, event, ...)
    -- for the time beeing we use the texture of manastorms duplicator for the reagent bank button
    local _, _, _, _, _, _, _, _, _, texture, _ = GetItemInfo(118938);
    BaudBag_DebugMsg("BankReagent", "[SlotButton_OnLoad] Updating texture of reagent bank slot");
    SetItemButtonTexture(self, texture);
end

function ReagentBankSlotButton_OnEvent(self, event, ...)
    BaudBag_DebugMsg("BankReagent", "[SlotButton_OnEvent] called event "..event);
end

function ReagentBankSlotButton_OnEnter(self, event, ...)
    BaudBag_DebugMsg("BankReagent", "[SlotButton_OnEnter] Hovering over bank slot, showing tooltip");
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(REAGENT_BANK);
end

function ReagentBankSlotButton_OnClick(self, event, ...)
    BaudBag_DebugMsg("BankReagent", "[SlotButton_OnClick] trying to show reagent bank");
    -- trying to determine container for reagent bank
    local RBankContainer = _G[Prefix.."SubBag-3"]:GetParent();
    if (RBankContainer:IsShown()) then
        RBankContainer:Hide();
    else
        RBankContainer:Show();
    end
end




function BaudBagToggleBank(self)
    if _G[Prefix.."Container2_1"]:IsShown() then
        _G[Prefix.."Container2_1"]:Hide();
        BaudBagAutoOpenSet(2, true);
    else
        _G[Prefix.."Container2_1"]:Show();
        BaudBagAutoOpenSet(2, false);
    end
end