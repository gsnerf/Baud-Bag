local AddOnName, AddOnTable = ...
local Localized = AddOnTable.Localized
local _

local DropDownContainer, DropDownBagSet

--[[ please mind, that this is a COPY of a local variable from FrameXML\ContainerFrame.lua... hold it in sync, because constants are (seemingly) evil... ]]
local BACKPACK_BASE_SIZE = 16;

--[[ Referenced in BaudBagContainerDropDown in BaudBag.xml ]]
function BaudBagContainerDropDown_OnLoad(self, event, ...)
    UIDropDownMenu_Initialize(self, BaudBagContainerDropDown_Initialize, "MENU")
end

function BaudBagContainerDropDown_Show(self, event, ...)
    local Container = self:GetParent()
    DropDownContainer = Container:GetID()
    DropDownBagSet = Container.BagSet
    local containerMenu = AddOnTable.Sets[Container.BagSet].Containers[Container:GetID()].Menu
    containerMenu:SetPoint("BOTTOM", self, "TOP")
    containerMenu:Toggle()
    ToggleDropDownMenu(1, nil, BaudBagContainerDropDown, self:GetName(), 0, 0)
end

--[[ 
    This initializes the drop down menus for each container.
    Beware that the bank box won't exist yet when this is initialized at first.
  ]]
  function BaudBagContainerDropDown_Initialize(dropDown, level, menuList)
    AddOnTable.Functions.DebugMessage("MenuDropDown", "initializing with (level, menuList, DropDownBagSet, DropDownContainer)", level, menuList, DropDownBagSet, DropDownContainer)
    local header = { isTitle = true, notCheckable = true }
    local entry = UIDropDownMenu_CreateInfo();

    -- category bag specifics
    header.text = Localized.MenuCatSpecific
    UIDropDownMenu_AddButton(header)

    -- bag locking/unlocking
    entry.text = not (DropDownBagSet and AddOnTable.Config[DropDownBagSet][DropDownContainer].Locked) and Localized.LockPosition or Localized.UnlockPosition
    entry.func = ToggleContainerLock
    UIDropDownMenu_AddButton(entry)

    if (AddOnTable.BlizzAPI.SupportsContainerSorting()) then
        -- cleanup ignore
        if (DropDownContainer) then
            local containerObject = AddOnTable.Sets[DropDownBagSet].Containers[DropDownContainer]
            entry.text = BAG_FILTER_IGNORE
            entry.checked = containerObject:GetCleanupIgnore()
            entry.func = function(_, _, _, value) containerObject:SetCleanupIgnore(not value) end
            UIDropDownMenu_AddButton(entry)
        end

        -- cleanup button first regular
        if (DropDownBagSet == 1) then
            entry.text = BAG_CLEANUP_BAGS
            entry.func = AddOnTable.BlizzAPI.SortBags
            entry.checked = false
            UIDropDownMenu_AddButton(entry)
        elseif (DropDownContainer and AddOnTable.State.BankOpen) then
            if(_G["BaudBagContainer"..DropDownBagSet.."_"..DropDownContainer].Bags[1]:GetID() == -3) then
                entry.text = BAG_CLEANUP_REAGENT_BANK
                entry.func = AddOnTable.BlizzAPI.SortReagentBankBags
            else
                entry.text = BAG_CLEANUP_BANK
                entry.func = AddOnTable.BlizzAPI.SortBankBags
            end
            UIDropDownMenu_AddButton(entry)
        end

        if (DropDownBagSet ~= nil and DropDownContainer ~= nil) then
            AddFilterOptions(DropDownBagSet, DropDownContainer, header)
        end
    end
    
    -- category general
    header.text = Localized.MenuCatGeneral
    UIDropDownMenu_AddButton(header)

    -- 'show bank' option
    -- we only want to show this option on the backpack when the bank is not currently shown
    if (DropDownBagSet ~= 2) and _G[AddOnName.."Container2_1"] and not _G[AddOnName.."Container2_1"]:IsShown()then
        entry.text = Localized.ShowBank
        entry.func = BaudBagToggleBank
        UIDropDownMenu_AddButton(entry)
    end

    -- open the options
    entry.text = Localized.Options
    entry.func = ShowContainerOptions
    UIDropDownMenu_AddButton(entry)

    -- increase backpack size
    local needToShow = not (IsAccountSecured() and AddOnTable.BlizzAPI.GetContainerNumSlots(AddOnTable.BlizzConstants.BACKPACK_CONTAINER) > AddOnTable.BlizzConstants.BACKPACK_BASE_SIZE)
    if (needToShow) then
        entry.text = BACKPACK_AUTHENTICATOR_INCREASE_SIZE
        entry.func = BaudBag_AddSlotsClick
        UIDropDownMenu_AddButton(entry)
    end
end

function AddFilterOptions(bagSetId, containerId, header)
    
    local containerObject = AddOnTable.Sets[bagSetId].Containers[containerId]
    local frame = containerObject.Frame
    
    local numberOfSubContainers = table.getn(containerObject.SubContainers)
    local firstSubContainerId = containerObject.SubContainers[1].ContainerId
    if (numberOfSubContainers == 1 and
        (
            firstSubContainerId == BACKPACK_CONTAINER
            or
            firstSubContainerId == BANK_CONTAINER
            or
            firstSubContainerId == REAGENTBANK_CONTAINER
            or
            IsInventoryItemProfessionBag("player", AddOnTable.BlizzAPI.ContainerIDToInventoryID(firstSubContainerId))
        )
    ) then
        -- the backpack, bank or reagent bank themselves cannot have filters!
        return
    end

    header.text = BAG_FILTER_ASSIGN_TO
    UIDropDownMenu_AddButton(header)
    
    local toggleFilter = function(_, type, _, value)
        value = not value
        containerObject:SetFilterType(type, value)
        if (value) then
            -- todo: optionally show some kind of visualization
            --frame.FilterIcon.Icon:SetAtlas(BAG_FILTER_ICONS[i])
            --frame.FilterIcon:Show()
        else
            -- todo: hide optional visualization again
            --frame.FilterIcon:Hide()
        end
    end

    local info = UIDropDownMenu_CreateInfo()
    for _, flag in AddOnTable.BlizzAPI.EnumerateBagGearFilters() do
        info.text = BAG_FILTER_LABELS[flag]
        info.func = toggleFilter
        info.arg1 = flag
        info.checked = containerObject:GetFilterType() == flag
        UIDropDownMenu_AddButton(info)
    end
end

function ToggleContainerLock(self)
    AddOnTable.Functions.DebugMessage("MenuDropDown", "toggeling container lock (DropDownBagSet, DropDownContainer, currentConfig)", DropDownBagSet, DropDownContainer, AddOnTable.Config[DropDownBagSet][DropDownContainer].Locked)
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
end