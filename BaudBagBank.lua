local _;
local Prefix = "BaudBag";

--[[
    This method creates the buttons in the banks BagsFrame (frame that pops out and shows the available bags).
  ]]
function BaudBagBankBags_Initialize()
    local BagSlot, Texture;
    local BBContainer2 = _G[Prefix.."Container2_1BagsFrame"];

    -- create BagSlots for regular bags
    for Bag = 1, NUM_BANKBAGSLOTS do
		-- the slot name before "BankBagX" has to be 10 chars long or else this will HARDCRASH
		BagSlot = CreateFrame("Button", "BaudBBankBag"..Bag, BBContainer2, "BankItemButtonBagTemplate");
		BagSlot:SetID(Bag);
		BagSlot.Bag = Bag + 4;
		BagSlot:SetPoint("TOPLEFT",		8 + mod(Bag - 1, 2) * 39, -8 - floor((Bag - 1) / 2) * 39);
		BagSlot:HookScript("OnEnter",	BaudBag_BagSlot_OnEnter);
        BagSlot:HookScript("OnUpdate",	BaudBag_BagSlot_OnUpdate);
		BagSlot:HookScript("OnLeave",	BaudBag_BagSlot_OnLeave);
      
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
    GameTooltip:SetText("Reagent Bank");
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