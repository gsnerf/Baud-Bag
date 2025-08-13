---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local Prefix = "BaudBag"
local INV_ID_BAG_FIRST = AddOnTable.BlizzAPI.ContainerIDToInventoryID(AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER + 1)
local INV_ID_BAG_LAST = AddOnTable.BlizzAPI.ContainerIDToInventoryID(AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER)

-- Adds container name when mousing over bags, aswell as simulating offline bank item mouse over
hooksecurefunc(GameTooltip, "SetInventoryItem", function (Data, Unit, InvID)
    if (Unit ~= "player") then
        AddOnTable.Functions.DebugMessage("Tooltip", "SetInventoryItem called with unit '"..Unit.."' which cannot be handled")
        return
    end

    if (InvID >= INV_ID_BAG_FIRST) and (InvID <= INV_ID_BAG_LAST) then
        AddOnTable.Functions.DebugMessage("Tooltip", "Showing tooltip for bags in overview...")
        if BBConfig and (BBConfig[1].Enabled==false) then
            return
        end
        AddOnTable.Functions.DebugMessage("Tooltip", "... success!")
        BaudBagModifyBagTooltip(InvID - INV_ID_BAG_FIRST + 1)
    end
    
end)

-- this was supposed to show the backpack hover in something similar as the rest, but it just doesn't work (has no line for "soulbound" etc.)
MainMenuBarBackpackButton:HookScript("OnEnter", function(...)
    if BBConfig and (BBConfig[1].Enabled ~= false) then
        BaudBagModifyBagTooltip(0)
    end
end)

-- this adapts an existing tooltip to show the name of the container in the first subline (instead of i.e. soulbound)
function BaudBagModifyBagTooltip(BagID)
    AddOnTable.Functions.DebugMessage("Tooltip", "ModifyBagTooltip called for BagID"..BagID)
    if not GameTooltip:IsShown() then
        AddOnTable.Functions.DebugMessage("Tooltip", "Returning pre-maturely 1")
        return;
    end

    local Container = _G[Prefix.."SubBag"..BagID]:GetParent()
    Container = BBConfig[Container.BagSet][Container:GetID()].Name

    if not Container or not strfind(Container, "%S") then
        AddOnTable.Functions.DebugMessage("Tooltip", "Returning pre-maturely 2")
        return
    end  

    local Current, Next
    for Line = GameTooltip:NumLines(), 3, -1 do
        Current, Next = _G["GameTooltipTextLeft"..Line], _G["GameTooltipTextLeft"..(Line - 1)]
        Current:SetTextColor(Next:GetTextColor())
    end

    if Next then
        Next:SetText(Container)
        Next:SetTextColor(1,0.82,0)
    end

    GameTooltip:Show()
    GameTooltip:AppendText("")
end
