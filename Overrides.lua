-- addon defaults
---@class AddonNamespace
local AddOnTable = select(2, ...)
local AddOnName = select(1, ...)
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

local function closeBag(id)
    AddOnTable.Functions.DebugMessage("BagTrigger", "[CloseBag] called for bag with id "..id)

    local Container = _G[AddOnName.."SubBag"..id]:GetParent()
    Container:Hide()
end

local function openBackpack()
    openBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER)
end

local function closeBackpack()
    closeBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER)
end

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

--[[
    This needs to cover the case that the original bags are combined and the backpack was originally open and should be closed.
    Default ToggleBackpack_Combined is only calling OpenBackpack but hiding the frame itself ]]
local function toggleCombinedBackpackClose()
    closeBackpack()
end

--[[ BagSlot stuff ]]

--[[ TODO: check if this can be a hook now ]]
local pre_BagSlotButton_OnClick = BagSlotButton_OnClick
local function custom_BagSlotButton_OnClick(self, event, ...)

    if (not BBConfig or not BBConfig[1].Enabled) then
        return pre_BagSlotButton_OnClick(self, event, ...)
    end

    if not PutItemInBag(self:GetID()) then
        ToggleBag(self:GetID() - CharacterBag0Slot:GetID() + 1)
    end
end

local function OpenAllBags()
    for i = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
        openBag(i)
    end
    
    if AddOnTable.Sets[BagSetType.Bank.Id].Containers[1].Frame:IsShown() then
        for i = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER,  AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
            openBag(i)
        end
    end
end

local function CloseAllBags()
    for i = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
        closeBag(i)
    end
    
    if AddOnTable.Sets[BagSetType.Bank.Id].Containers[1].Frame:IsShown() then
        for i = AddOnTable.BlizzConstants.BANK_FIRST_CONTAINER,  AddOnTable.BlizzConstants.BANK_LAST_CONTAINER do
            closeBag(i)
        end
    end
end

--[[ Classic specific stuff ]]
--[[
    This is necessary, as the orriginal ToggleBackpack only calls ToggleBag if the bag was closed before.
    If it was open, it instead manually iterates over all container frames and closes them directly via frame:Hide().

    Seems dump at first glance, but probably is an "optimized" way of closing bags, as _every_ other close/toggle/open iterates over all container frames, so calling close 5x would iterate over all 13 containers 5 times.
    If someone from the blizz team should read this: There is no reason to hold the container frames dynamic this way. It just complicates things and serves no valuable purpose.
    The number of frames are fixed, the content of the frame not freed on close, so here isn't even memory usage limitation at work. Just revert to the retail way please!
]]
local function handleBackpackClosing()
    local backpackOpen = IsBagOpen(Enum.BagIndex.Backpack)
    AddOnTable.Functions.DebugMessage("BagTrigger", "[handleBackpackClosing] backpack toggled with state "..(backpackOpen and "open" or "closed"))
    if (not backpackOpen) then
        toggleBag(Enum.BagIndex.Backpack)
    end
end


AddOnTable.ApplyOverrides = function()
    hooksecurefunc("OpenBag", openBag)
    hooksecurefunc("CloseBag", closeBag)
    hooksecurefunc("OpenBackpack", openBackpack)
    hooksecurefunc("CloseBackpack", closeBackpack)
    hooksecurefunc("ToggleBag", toggleBag)

    if (ContainerFrameCombinedBags) then
        hooksecurefunc(ContainerFrameCombinedBags, "Hide", toggleCombinedBackpackClose)
    end

    BagSlotButton_OnClick = custom_BagSlotButton_OnClick

    EventRegistry:RegisterCallback("ContainerFrame.OpenAllBags", OpenAllBags)
    EventRegistry:RegisterCallback("ContainerFrame.CloseAllBags", CloseAllBags)

    if (GetExpansionLevel() < 9) then
        hooksecurefunc("ToggleBackpack", handleBackpackClosing)
    end
end