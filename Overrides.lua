-- addon defaults
local AddOnName, AddOnTable = ...
local Localized = AddOnTable.Localized
local _

--[[ backpack specific original functions ]]--
local orig_OpenBackpack = OpenBackpack
OpenBackpack = function() 
    AddOnTable.Functions.DebugMessage("BagOpening", "[OpenBackpack] called!")
    if (not BBConfig or not BBConfig[1].Enabled) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenBackpack] somethings not right, sending to blizz-bags!")
        return orig_OpenBackpack()
    end

    OpenBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER)
end

local orig_CloseBackpack = CloseBackpack
CloseBackpack = function()
    AddOnTable.Functions.DebugMessage("BagOpening", "[CloseBackpack] called!")
    if (not BBConfig or not BBConfig[1].Enabled) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[CloseBackpack] somethings not right, sending to blizz-bags!")
        return orig_CloseBackpack()
    end

    CloseBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER)
end

local orig_ToggleBackpack = ToggleBackpack
ToggleBackpack = function()
    AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleBackpack] called")
    -- make sure original is called when BaudBag is disabled for the backpack
    if (not BBConfig or not BBConfig[1].Enabled) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleBackpack] BaudBag disabled for inventory calling original UI")
        return orig_ToggleBackpack()
    end
	
    if not AddOnTable.BagsReady then
        return
    end
	
    ToggleBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER)
end


local orig_ToggleBag = ToggleBag
ToggleBag = function(id)
    -- decide if the current bag needs to be opened by baudbag or blizzard
    if (id > AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER) then
        if BBConfig and (BBConfig[2].Enabled == false) then
            return orig_ToggleBag(id)
        end
        if not AddOnTable.BagsReady then
            return
        end
        --The close button thing allows the original blizzard bags to be closed if they're still open
    elseif (BBConfig[1].Enabled == false) then-- or self and (strsub(self:GetName(),-11) == "CloseButton") then
        return orig_ToggleBag(id)
    end

    AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleBag] toggeling bag (ID)", id)
	
    local Container = _G[AddOnName.."SubBag"..id]
    if not Container then
        return orig_ToggleBag(id)
    end
    Container = Container:GetParent()

    if Container:IsShown() then
        AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleBag] container open, closing (name)", Container:GetName())
        Container:Hide()
    else
        AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleBag] container closed, opening (name)", Container:GetName())
        Container:Show()
        -- If there are tokens watched then show the bar
        if ( id == AddOnTable.BlizzConstants.BACKPACK_CONTAINER and BackpackTokenFrame_Update ) then
            BackpackTokenFrame_Update()
            --ManageBackpackTokenFrame()
        end
    end
end


local orig_OpenAllBags = OpenAllBags
OpenAllBags = function(frame)
    AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] called from (frame)", ((frame ~= nil) and frame:GetName() or "[none]"))
    
    -- call default bags if the addon is disabled for regular bags
    if (not BBConfig or not BBConfig[1].Enabled) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] sent to original frames")
        return orig_OpenAllBags(frame)
    end

    -- also cancel if bags can't be viewed at the moment (CAN this actually happen?)
    if not AddOnTable.BagsReady then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] bags not ready")
        return
    end

    -- failsafe check as opening mail or merchant seems to instantly call OpenAllBags instead of the bags registering for the events...
    if (frame ~= nil and (frame:GetName() == "MailFrame" or frame:GetName() == "MerchantFrame")) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] found merchant or mail call, stopping now!")
        return
    end

    -- last but not least: the auction house is doing strange stuff lately, so if the call is originating from auction house and the bags where auto opened, ignore the call
    if (frame ~=nil and frame:GetName() == "AuctionHouseFrame" and BBConfig[1][1].AutoOpen) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] found auction house call on auto opened bags, stopping now!")
        return
    end

    local Container
    for Bag = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] analyzing bag (ID)", Bag)
        Container = _G[AddOnName.."SubBag"..Bag]:GetParent()
        if (AddOnTable.BlizzAPI.GetContainerNumSlots(Bag) > 0) and not Container:IsShown()then
            AddOnTable.Functions.DebugMessage("BagOpening", "[OpenAllBags] showing bag")
            Container:Show()
        end
    end
end

local orig_CloseAllBags = CloseAllBags
CloseAllBags = function(frame)
    AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] (sourceName)", ((frame ~= nil) and frame:GetName() or "[none]"))

        -- call default bags if the addon is disabled for regular bags
        if (not BBConfig or not BBConfig[1].Enabled) then
            AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] sent to original frames")
            return orig_CloseAllBags(frame)
        end

    -- failsafe check as opening mail or merchant seems to instantly call OpenAllBags instead of the bags registering for the events...
    if (frame ~= nil and (frame:GetName() == "MailFrame" or frame:GetName() == "MerchantFrame")) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] found merchant or mail call, stopping now!")
        return
    end

    -- last but not least: the auction house is doing strange stuff lately, so if the call is originating from auction house and the bags where auto opened, ignore the call
    if (frame ~=nil and frame:GetName() == "AuctionHouseFrame" and BBConfig[1][1].AutoOpen) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] found auction house call on auto opened bags, stopping now!")
        return
    end

    for Bag = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
        AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] analyzing bag (id)", Bag)
        local Container = _G[AddOnName.."SubBag"..Bag]:GetParent()
        if (AddOnTable.BlizzAPI.GetContainerNumSlots(Bag) > 0) and Container:IsShown() then
            AddOnTable.Functions.DebugMessage("BagOpening", "[CloseAllBags] hiding  bag")
            Container:Hide()
        end
    end
end
   
local function IsBagShown(BagId)
    local SubContainer = AddOnTable["SubBags"][BagId]
    AddOnTable.Functions.DebugMessage("BagOpening", "Got SubContainer", SubContainer)
    return SubContainer:IsOpen()
end

local orig_IsBagOpen = IsBagOpen
-- IsBagOpen = function(BagID)
function BaudBag_IsBagOpen(BagId)
    -- fallback
    if (not BBConfig or not BaudBag_BagHandledByBaudBag(BagId)) then
        AddOnTable.Functions.DebugMessage("BagOpening", "BaudBag is not responsible for this bag, calling default ui")
        return orig_IsBagOpen(BagId)
    end
    
    local open = IsBagShown(BagId)
    AddOnTable.Functions.DebugMessage("BagOpening", "[IsBagOpen] (BagId, open)", BagId, open)
    return open
end
IsBagOpen = BaudBag_IsBagOpen

--[[ this usually only applies to inventory bags ]]--
local orig_ToggleAllBags = ToggleAllBags
ToggleAllBags = function()
    AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleAllBags] called")

    if (not BBConfig or not BBConfig[1].Enabled) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleAllBags] no config found or addon deactivated for inventory, calling original")
        return orig_ToggleAllBags()
    end

    AddOnTable.Functions.DebugMessage("BagOpening", "[ToggleAllBags] BaudBag bags are active, close & open")

    local bagsOpen = 0
    local totalBags = 0

    -- first find out if everything is open or only a part of everything
    for i = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
        if (AddOnTable.BlizzAPI.GetContainerNumSlots(i) > 0 ) then
            totalBags = totalBags + 1
        end
        if ( BaudBag_IsBagOpen(i) ) then
            bagsOpen = bagsOpen +1
        end
    end

    -- now correctly open all of them
    if (bagsOpen < totalBags) then
        for i = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
            OpenBag(i)
        end
    else
        for i = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
            CloseBag(i)
        end
    end
end

local orig_OpenBag = OpenBag
OpenBag = function(id)
    AddOnTable.Functions.DebugMessage("BagOpening", "[OpenBag] called on bag (id)", id)
	
    -- if there is no baud bag config we most likely do not work correctly => send to original bag frames
    if (not BBConfig or not BaudBag_BagHandledByBaudBag(id)) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[OpenBag] no config or bag not handled by BaudBag, calling original")
        return orig_OpenBag(id)
    end

    -- if (not IsBagOpen(id)) then
    if (not BaudBag_IsBagOpen(id)) then
        local Container = _G[AddOnName.."SubBag"..id]:GetParent()
        Container:Show()
    end
end

local orig_CloseBag = CloseBag
CloseBag = function(id)
    AddOnTable.Functions.DebugMessage("BagOpening", "[CloseBag] called on bag (id)", id)
    if (not BBConfig or not BaudBag_BagHandledByBaudBag(id)) then
        AddOnTable.Functions.DebugMessage("BagOpening", "[CloseBag] no config or bag not handled by BaudBag, calling original")
        return orig_CloseBag(id)
    end

    -- if (IsBagOpen(id)) then
    if (BaudBag_IsBagOpen(id)) then
        local Container = _G[AddOnName.."SubBag"..id]:GetParent()
        Container:Hide()
    end
end



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