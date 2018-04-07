local AddOnName, AddOnTable = ...
local Localized = BaudBagLocalized
local _

local DropDownContainer, DropDownBagSet

--[[ Referenced in BaudBagContainerDropDown in BaudBag.xml ]]
function BaudBagContainerDropDown_OnLoad(self, event, ...)
    UIDropDownMenu_Initialize(self, BaudBagContainerDropDown_Initialize, "MENU")
end

function BaudBagContainerDropDown_Show(self, event, ...)
    local Container = self:GetParent()
    DropDownContainer = Container:GetID()
    DropDownBagSet = Container.BagSet
    ToggleDropDownMenu(1, nil, BaudBagContainerDropDown, self:GetName(), 0, 0)
end

--[[ 
    This initializes the drop down menus for each container.
    Beware that the bank box won't exist yet when this is initialized at first.
  ]]
  function BaudBagContainerDropDown_Initialize(dropDown, level, menuList)
    BaudBag_DebugMsg("MenuDropDown", "initializing with (level, menuList, DropDownBagSet, DropDownContainer)", level, menuList, DropDownBagSet, DropDownContainer)
    local header = { isTitle = true, notCheckable = true }
    local info = {  }
    
    -- category bag specifics
    header.text = Localized.MenuCatSpecific
    UIDropDownMenu_AddButton(header)

    -- bag locking/unlocking
    info.text = not (DropDownBagSet and AddOnTable.Config[DropDownBagSet][DropDownContainer].Locked) and Localized.LockPosition or Localized.UnlockPosition
    info.func = ToggleContainerLock
    UIDropDownMenu_AddButton(info)

    -- cleanup button first regular
    if (DropDownBagSet == 1) then
        info.text = BAG_CLEANUP_BAGS
        info.func = SortBags
        UIDropDownMenu_AddButton(info)
    elseif (DropDownContainer and BaudBagFrame.BankOpen) then
        if(_G["BaudBagContainer"..DropDownBagSet.."_"..DropDownContainer].Bags[1]:GetID() == -3) then
            info.text = BAG_CLEANUP_REAGENT_BANK
            info.func = SortReagentBankBags
        else
            info.text = BAG_CLEANUP_BANK
            info.func = SortBankBags
        end
        UIDropDownMenu_AddButton(info)
    end

    -- category general
    header.text = Localized.MenuCatGeneral
    UIDropDownMenu_AddButton(header)

    -- 'show bank' option
    -- we only want to show this option on the backpack when the bank is not currently shown
    if (DropDownBagSet ~= 2) and _G[AddOnName.."Container2_1"] and not _G[AddOnName.."Container2_1"]:IsShown()then
        info.text = Localized.ShowBank
        info.func = BaudBagToggleBank
        UIDropDownMenu_AddButton(info)
    end

    -- open the options
    info.text = Localized.Options
    info.func = ShowContainerOptions
    UIDropDownMenu_AddButton(info)

    -- increase backpack size
    local needToShow = not (IsAccountSecured() and GetContainerNumSlots(1) > BACKPACK_BASE_SIZE)
    if (needToShow) then
        info.text = BACKPACK_AUTHENTICATOR_INCREASE_SIZE
        info.func = BaudBag_AddSlotsClick
        UIDropDownMenu_AddButton(info)
    end
end

function ToggleContainerLock(self)
    BaudBag_DebugMsg("MenuDropDown", "toggeling container lock (DropDownBagSet, DropDownContainer, currentConfig)", DropDownBagSet, DropDownContainer, AddOnTable.Config[DropDownBagSet][DropDownContainer].Locked)
    AddOnTable.Config[DropDownBagSet][DropDownContainer].Locked = not AddOnTable.Config[DropDownBagSet][DropDownContainer].Locked
end

function ShowContainerOptions(self)
    BaudBagOptionsSelectContainer(DropDownBagSet, DropDownContainer)
    -- working around what seems to be a bug in blizzards code, preventing this to work on the first try..
    InterfaceOptionsFrame_OpenToCategory("Baud Bag")
    InterfaceOptionsFrame_OpenToCategory("Baud Bag")
end

-- new backpack slots stuff
function BaudBag_AddSlotsClick()
    StaticPopup_Show("BACKPACK_INCREASE_SIZE")
    ContainerFrame_SetBackpackForceExtended(true)
end