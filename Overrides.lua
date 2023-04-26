-- addon defaults
local AddOnName, AddOnTable = ...
local Localized = AddOnTable.Localized
local _

--[[ helpers ]]
   
local function isBagShown(BagId)
    local SubContainer = AddOnTable["SubBags"][BagId]
    AddOnTable.Functions.DebugMessage("BagOpening", "Got SubContainer", SubContainer)
    return SubContainer:IsOpen()
end

function BaudBag_IsBagOpen(BagId)
    if (not BBConfig or not BaudBag_BagHandledByBaudBag(BagId)) then
        AddOnTable.Functions.DebugMessage("BagOpening", "BaudBag is not responsible for this bag, calling default ui")
        return false
    end

    local open = isBagShown(BagId)
    AddOnTable.Functions.DebugMessage("BagOpening", "[IsBagOpen] (BagId, open)", BagId, open)
    return open
end

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

--[[ "all" bag stuff ]]--

local function openAllBags(triggerSourceFrame, forceUpdate)
    AddOnTable.Functions.DebugMessage("BagTrigger", "[OpenAllBags] called from frame", ((triggerSourceFrame ~= nil) and triggerSourceFrame:GetName() or "[none]"))
    
    -- call default bags if the addon is disabled for regular bags
    if (not BBConfig or not BBConfig[1].Enabled) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] bags not enabled, skipping")
        return
    end

    -- also cancel if bags can't be viewed at the moment (CAN this actually happen?)
    if not AddOnTable.BagsReady then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] bags not ready")
        return
    end

    -- failsafe check as opening mail or merchant seems to instantly call OpenAllBags instead of the bags registering for the events...
    if (triggerSourceFrame ~= nil and (triggerSourceFrame:GetName() == "MailFrame" or triggerSourceFrame:GetName() == "MerchantFrame")) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] found merchant or mail call, stopping now!")
        return
    end

    -- last but not least: the auction house is doing strange stuff lately, so if the call is originating from auction house and the bags where auto opened, ignore the call
    if (triggerSourceFrame ~=nil and triggerSourceFrame:GetName() == "AuctionHouseFrame" and BBConfig[1][1].AutoOpen) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] found auction house call on auto opened bags, stopping now!")
        return
    end

    local Container
    for Bag = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] analyzing bag (ID)", Bag)
        Container = _G[AddOnName.."SubBag"..Bag]:GetParent()
        if (AddOnTable.BlizzAPI.GetContainerNumSlots(Bag) > 0) then
            AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] showing bag")
            Container:Show()
        end
    end
end
--hooksecurefunc("OpenAllBags", openAllBags)

local function closeAllBags(triggerSourceFrame, forceUpdate)
    AddOnTable.Functions.DebugMessage("BagTrigger", "[CloseAllBags] (sourceName)", ((triggerSourceFrame ~= nil) and triggerSourceFrame:GetName() or "[none]"))

        -- call default bags if the addon is disabled for regular bags
        if (not BBConfig or not BBConfig[1].Enabled) then
            AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] bags disabled, skipping")
            return
        end

    -- failsafe check as opening mail or merchant seems to instantly call OpenAllBags instead of the bags registering for the events...
    if (triggerSourceFrame ~= nil and (triggerSourceFrame:GetName() == "MailFrame" or triggerSourceFrame:GetName() == "MerchantFrame")) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] found merchant or mail call, stopping now!")
        return
    end

    -- last but not least: the auction house is doing strange stuff lately, so if the call is originating from auction house and the bags where auto opened, ignore the call
    if (triggerSourceFrame ~=nil and triggerSourceFrame:GetName() == "AuctionHouseFrame" and BBConfig[1][1].AutoOpen) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] found auction house call on auto opened bags, stopping now!")
        return
    end

    for Bag = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
        AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] analyzing bag (id)", Bag)
        local Container = _G[AddOnName.."SubBag"..Bag]:GetParent()
        if (AddOnTable.BlizzAPI.GetContainerNumSlots(Bag) > 0) then
            AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] hiding  bag")
            Container:Hide()
        end
    end
end
--hooksecurefunc("CloseAllBags", closeAllBags)

local function toggleAllBags()
    AddOnTable.Functions.DebugMessage("BagTrigger", "[ToggleAllBags] called")

    if (not BBConfig or not BBConfig[1].Enabled) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleAllBags] no config found or addon deactivated for inventory, calling original")
        return
    end

    AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleAllBags] BaudBag bags are active, close & open")

    local bagsOpen = 0
    local totalBags = 0

    -- first find out if everything is open or only a part of everything
    for i = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
        if (AddOnTable.BlizzAPI.GetContainerNumSlots(i) > 0 ) then
            totalBags = totalBags + 1
        end
        if ( isBagShown(i) ) then
            bagsOpen = bagsOpen +1
        end
    end

    -- now correctly open all of them
    if (bagsOpen < totalBags) then
        for i = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
            openBag(i)
        end
    else
        for i = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
            closeBag(i)
        end
    end
end
-- hooksecurefunc("ToggleAllBags", toggleAllBags)

--[[ Backpack stuff ]]

local function openBackpack()
    AddOnTable.Functions.DebugMessage("BagTrigger", "[OpenBackpack] called")
    if (not BBConfig or not BBConfig[1].Enabled) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenBackpack] bags apparently not enabled, skipping")
        return
    end

    openBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER)
end
--hooksecurefunc("OpenBackpack", openBackpack)

local function closeBackpack()
    AddOnTable.Functions.DebugMessage("BagTrigger", "[CloseBackpack] called")
    if (not BBConfig or not BBConfig[1].Enabled) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[CloseBackpack] bags apparently not enabled, skipping")
        return
    end

    closeBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER)
end
--hooksecurefunc("CloseBackpack", closeBackpack)

local function toggleBackpack()
    AddOnTable.Functions.DebugMessage("BagTrigger", "[ToggleBackpack] called")
    if (not BBConfig or not BBConfig[1].Enabled) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleBackpack] bags apparently not enabled, skipping")
        return
    end

    if not AddOnTable.BagsReady then
        return
    end

    toggleBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER)
end
--hooksecurefunc("ToggleBackpack", toggleBackpack)


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