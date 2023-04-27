-- addon defaults
local AddOnName, AddOnTable = ...
local Localized = AddOnTable.Localized
local _

--[[ single bag stuff ]]--

local function openBag(id)
    AddOnTable.Functions.DebugMessage("BagTrigger", "[OpenBag] called for bag with id "..id)
    if (not BBConfig or not AddOnTable.Functions.BagHandledByBaudBag(id)) then
        return
    end

    local Container = _G[AddOnName.."SubBag"..id]:GetParent()
    Container:Show()
end
hooksecurefunc("OpenBag", openBag)

local function closeBag(id)
    AddOnTable.Functions.DebugMessage("BagTrigger", "[CloseBag] called for bag with id "..id)

    if (not BBConfig or not AddOnTable.Functions.BagHandledByBaudBag(id)) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[CloseBag] no config or bag not handled by BaudBag, calling original")
        return
    end

    local Container = _G[AddOnName.."SubBag"..id]:GetParent()
    Container:Hide()
end
hooksecurefunc("CloseBag", closeBag)

local function toggleBag(id)
    AddOnTable.Functions.DebugMessage("BagTrigger", "[ToggleBag] called for bag with id "..id)

    -- decide if the current bag needs to be opened by baudbag or blizzard
    if not AddOnTable.Functions.BagHandledByBaudBag(id) or not AddOnTable.BagsReady then
        return
    end
    
    AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleBag] toggeling bag (ID)", id)
	
    local Container = _G[AddOnName.."SubBag"..id]
    if not Container then
        return
    end
    Container = Container:GetParent()

    if Container:IsShown() then
        AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleBag] container open, closing (name)", Container:GetName())
        Container:Hide()
    else
        AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleBag] container closed, opening (name)", Container:GetName())
        Container:Show()
    end
end
hooksecurefunc("ToggleBag", toggleBag)

--[[ BagSlot stuff ]]

local pre_BagSlotButton_OnClick = BagSlotButton_OnClick
BagSlotButton_OnClick = function(self, event, ...)

    if (not BBConfig or not BBConfig[1].Enabled) then
        return pre_BagSlotButton_OnClick(self, event, ...)
    end

    if not PutItemInBag(self:GetID()) then
        ToggleBag(self:GetID() - CharacterBag0Slot:GetID() + 1)
    end
end

--self is hooked to be able to replace the original bank box with this one
local orig_BankFrame_OnEvent = BankFrame_OnEvent
BankFrame_OnEvent = function(self, event, ...)
    if BBConfig and(BBConfig[2].Enabled == false) then
        return orig_BankFrame_OnEvent(self, event, ...)
    end
end