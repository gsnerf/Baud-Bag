local _;
local Prefix = "BaudBag";


--[[ This analyses the bought bags and updates the bag slot view
     (the little window that pops out the main bank container and shows the bought bags) 
     alongside the "bag slot buy" button ]]--
function BaudBagBankBags_Update()
    local Purchase = BaudBagBankSlotPurchaseFrame;
    local Slots, Full = GetNumBankSlots();
    local ReagentsBought = IsReagentBankUnlocked();
    local BagSlot;
  
    BaudBag_DebugMsg("Bank", "BankBags: updating");
    
    for Bag = 1, NUM_BANKBAGSLOTS do
        BagSlot = _G["BaudBBankBag"..Bag];
        
        if (Bag <= Slots) then
            SetItemButtonTextureVertexColor(BagSlot, 1.0, 1.0, 1.0);
            BagSlot.tooltipText = BANK_BAG;
        else
            SetItemButtonTextureVertexColor(BagSlot, 1.0, 0.1, 0.1);
            BagSlot.tooltipText = BANK_BAG_PURCHASE;
        end
    end
    
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



--[[ this prepares the visual style of the reagent bag slot ]]
function ReagentBankSlotButton_OnLoad(self, event, ...)
    -- for the time beeing we use the texture of manastorms duplicator for the reagent bank button
    local _, _, _, _, _, _, _, _, _, texture, _ = GetItemInfo(118938);
    BaudBag_DebugMsg("Bank", "[ReagentBankSlotButton_OnLoad] Updating texture of reagent bank slot");
    SetItemButtonTexture(self, texture);
end

function ReagentBankSlotButton_OnEvent(self, event, ...)
    BaudBag_DebugMsg("Bank", "[ReagentBankSlotButton_OnEvent] TEST");
end

function ReagentBankSlotButton_OnEnter(self, event, ...)
    BaudBag_DebugMsg("Bank", "[ReagentBankSlotButton_OnEnter] Hovering over bank slot, showing tooltip");
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Reagent Bank");
end

function ReagentBankSlotButton_OnClick(self, event, ...)
end