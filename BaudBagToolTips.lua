local _;
local Prefix = "BaudBag";

-- Adds container name when mousing over bags, aswell as simulating offline bank item mouse over
hooksecurefunc(GameTooltip, "SetInventoryItem", function (Data, Unit, InvID)
    if (Unit ~= "player") then
        BaudBag_DebugMsg("Tooltip", "SetInventoryItem called with unit '"..Unit.."' which cannot be handled");
        return;
    end

    if (InvID >= 20) and (InvID <= 23) then
        BaudBag_DebugMsg("Tooltip", "Showing tooltip for bags in overview...");
        if BBConfig and (BBConfig[1].Enabled==false) then
            return;
        end
        BaudBag_DebugMsg("Tooltip", "... success!")
        BaudBagModifyBagTooltip(InvID - 19);
    elseif (InvID >= 68) and (InvID < 68 + NUM_BANKBAGSLOTS) then
        BaudBag_DebugMsg("Tooltip", "Showing tooltip for bank bags in overview...");
        if BBConfig and (BBConfig[2].Enabled == false) then
            return;
        end
        BaudBag_DebugMsg("Tooltip", "... success");
        BaudBagModifyBagTooltip(4 + InvID - 67);
    end
    
end);


MainMenuBarBackpackButton:HookScript("OnEnter", function(...)
    if BBConfig and (BBConfig[1].Enabled ~= false) then
        BaudBagModifyBagTooltip(0);
    end
end);

function BaudBagModifyBagTooltip(BagID)
    BaudBag_DebugMsg("Tooltip", "ModifyTooltip called for BagID"..BagID);
    if not GameTooltip:IsShown()then
        return;
    end

    local Container = _G[Prefix.."SubBag"..BagID]:GetParent();
    Container = BBConfig[Container.BagSet][Container:GetID()].Name;

    if not Container or not strfind(Container, "%S") then
        return;
    end  

    local Current, Next;
    for Line = GameTooltip:NumLines(), 3, -1 do
        Current, Next = _G["GameTooltipTextLeft"..Line], _G["GameTooltipTextLeft"..(Line - 1)];
        Current:SetTextColor(Next:GetTextColor());     
    end

    if Next then
        Next:SetText(Container);
        Next:SetTextColor(1,0.82,0);
    end

    GameTooltip:Show();
    GameTooltip:AppendText("");
end
