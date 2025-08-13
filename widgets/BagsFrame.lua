---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

BaudBagBagsFrameMixin = {}

-- this just makes sure the bags will be visible at the correct layer position when opened
function BaudBagBagsFrameMixin:OnShow(event, ...)
    --[[local isBags = self:GetName() == "BaudBagContainer1_1BagsFrame"
    local isBank = self:GetName() == "BaudBagContainer2_1BagsFrame"
    local Level = self:GetFrameLevel() + 1
    AddOnTable.Functions.DebugMessage("Bank", "BaudBagBagsFrame is shown, correcting frame layer lvls of childs (frame, targetLevel)", self:GetName(), Level)
    -- Adjust frame level because of Blizzard's screw up
    if (isBags) then
        local backpackSet = AddOnTable.Sets[BagSetType.Backpack.Id]
        for Bag = 0, 3 do
            backpackSet.BagButtons[Bag]:SetFrameLevel(Level)
        end
        if (backpackSet.ReagentBagButtons[0]) then
            backpackSet.ReagentBagButtons[0]:SetFrameLevel(Level)
        end
    elseif (isBank) then
        local bagSet = AddOnTable.Sets[BagSetType.Bank.Id]
        for Bag = 1, NUM_BANKBAGSLOTS do
            bagSet.BagButtons[Bag]:SetFrameLevel(Level)
        end
        if (AddOnTable.State.ReagentBankSupported) then
            _G["BBReagentsBag"]:SetFrameLevel(Level)
        end
    end]]
    -- for the moment we leave the rest open and see if something breaks horribly, or if blizzard maybe fixed it's screw up
end