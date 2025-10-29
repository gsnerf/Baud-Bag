---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local Localized = AddOnTable.Localized

--[[
    This enum is pre-filled with the default values that are _always_ available.
    It can be extended with more depending on feature availability (for example keyring or warband bank)
]]
---@enum BagSetType this contains all bag set types supported by this flavor
BagSetType = {
    ---@class BagSetTypeClass
    Backpack = {
        Id = 1,
        Name = Localized.Inventory,
        TypeName = "Backpack",
        IsSupported = function() return true end,
        IsSubContainerOf = function(containerId)
            local isBackpackContainer = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER <= containerId and containerId <= AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER
            return isBackpackContainer
        end,
        ContainerIterationOrder = {},
        Init = function()
            for bag = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
                table.insert(BagSetType.Backpack.ContainerIterationOrder, bag)
            end
            for id = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
                AddOnTable.ContainerIdOptionsIndexMap[id] = id + 1
            end
        end,
        -- backpack + number of additional bags
        NumberOfContainers = 1 + AddOnTable.BlizzConstants.BACKPACK_TOTAL_BAGS_NUM,
        DefaultConfig = {
            Columns = 8,
            Scale = 100,
            GetNameAddition = function(bagId)
                local isReagentBag = AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER ~= nil and AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER <= bagId and bagId <= AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER
                if (isReagentBag) then
                    return Localized.ReagentBag
                else
                    return Localized.Inventory
                end
            end,
            RequiresFreshConfig = function(bagId)
                local isReagentBag = AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER ~= nil and AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER <= bagId and bagId <= AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER
                return isReagentBag
            end,
            Theme = "BlizzInventoryDragonflight"
        },
        ApplyConfigRestorationSpecificalities = function(configObject)
            -- make sure the reagent bag is NOT joined by default!
            if (configObject[BagSetType.Backpack.Id].Joined[6] == nil) then
                AddOnTable.Functions.DebugMessage("Config", "- reagent bag join for BagSet "..BagSetType.Backpack.Id.." damaged or missing, creating now")
                configObject[BagSetType.Backpack.Id].Joined[6] = false;
            end
        end,
        CanContainerBeJoined = function(subContainerId) return subContainerId ~= AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER end,
        LinkedSet = function() return nil end,
        GetContainerTemplate = function(containerId) return "BaudBagContainerTemplate" end,
        GetItemButtonTemplate = function(containerId) return "ContainerFrameItemButtonTemplate" end,
        GetSize = function(containerId) return AddOnTable.BlizzAPI.GetContainerNumSlots(containerId) end,
        SupportsCache = false,
        ShouldUseCache = function() return false end,
        -- intended to be set in Backpack.lua
        BagOverview_Initialize = nil,
        UpdateOpenBagHighlight = function(subContainer)
            local open = subContainer:IsOpen()
            if (subContainer.ContainerId == AddOnTable.BlizzConstants.BACKPACK_CONTAINER) then
                if (MainMenuBarBackpackButton.SlotHighlightTexture) then
                    if (open) then
                        MainMenuBarBackpackButton.SlotHighlightTexture:Show()
                    else
                        MainMenuBarBackpackButton.SlotHighlightTexture:Hide()
                    end
                else
                    MainMenuBarBackpackButton:SetChecked(open)
                end
            else
                local backpackSet = AddOnTable.Sets[BagSetType.Backpack.Id]
                local bagId = subContainer.ContainerId -1
                local mainMenuBarButton = _G["CharacterBag"..bagId.."Slot"]
                local baudBagBagButton = backpackSet.BagButtons[bagId]

                if (subContainer.ContainerId == 5) then
                    bagId = subContainer.ContainerId - (AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER + AddOnTable.BlizzConstants.BACKPACK_CONTAINER_NUM + 1)
                    mainMenuBarButton = _G["CharacterReagentBag"..bagId.."Slot"]
                    baudBagBagButton = backpackSet.ReagentBagButtons[bagId]
                end
                
                if (open) then
                    if (mainMenuBarButton.SlotHighlightTexture) then
                        mainMenuBarButton.SlotHighlightTexture:Show()
                    else
                        mainMenuBarButton:SetChecked(true)
                    end
                    baudBagBagButton.SlotHighlightTexture:Show()
                else
                    if (mainMenuBarButton.SlotHighlightTexture) then
                        mainMenuBarButton.SlotHighlightTexture:Hide()
                    else
                        mainMenuBarButton:SetChecked(false)
                    end
                    baudBagBagButton.SlotHighlightTexture:Hide()
                end
            end
        end,
        BagFilterGetFunction = AddOnTable.BlizzAPI.GetBagSlotFlag,
        BagFilterSetFunction = AddOnTable.BlizzAPI.SetBagSlotFlag,
        CanInteractWithBags = function() return true end,
        OnItemButtonCustomEnter = function(self)
            if (ContainerFrameItemButton_OnUpdate ~= nil) then
                ContainerFrameItemButton_OnUpdate(self)
            elseif (ContainerFrameItemButton_OnEnter ~= nil) then
                ContainerFrameItemButton_OnEnter(self)
            else
                self:OnUpdate()
            end
        end,
        FilterData = {
            GetFilterType = function(container)
                if (container.ContainerId ~= AddOnTable.BlizzConstants.BACKPACK_CONTAINER) then
                    container:GetFilterType()
                end
                return nil
            end,
            SetFilterType = function(container, type, value)
                if (container.ContainerId ~= AddOnTable.BlizzConstants.BACKPACK_CONTAINER) then
                    container:SetFilterType(type, value)
                end
            end,
            GetCleanupIgnore = function(container)
                local containerId = container.ContainerId
                if (containerId == AddOnTable.BlizzConstants.BACKPACK_CONTAINER) then
                    return AddOnTable.BlizzAPI.GetBackpackAutosortDisabled()
                end
                return AddOnTable.BlizzAPI.GetBagSlotFlag(containerId, AddOnTable.BlizzAPI.GetIgnoreCleanupFlag())
            end,
            SetCleanupIgnore = function(container, value)
                local containerId = container.ContainerId
                if (containerId == AddOnTable.BlizzConstants.BACKPACK_CONTAINER) then
                    AddOnTable.BlizzAPI.SetBackpackAutosortDisabled(value)
                else
                    AddOnTable.BlizzAPI.SetBagSlotFlag(containerId, AddOnTable.BlizzAPI.GetIgnoreCleanupFlag(), value)
                end
            end,
        },
        CustomCloseAllFunction = function() end,
        GetSpecialBagTexture = function(subContainerId)
            if (subContainerId == AddOnTable.BlizzConstants.BACKPACK_CONTAINER) then
                return "Interface\\Buttons\\Button-Backpack-Up"
            else
                return nil
            end
        end,
    },
}

--[[
    This will seem unnecessary at first glance, but it ensures a specific order for iterating over all existing BagSetTypes.
    At the moment this is necessary at least for the tab list in the options as long as BagSetType itself is a "map" type table instead of an "array" type table.
  ]]
BagSetTypeArray = { BagSetType.Backpack }

-- Definition
---@enum ContainerType
ContainerType = {
    Joined,
    Tabbed
}

--[[ this is a really dump way to access the config to get the joined state... ]]
AddOnTable.ContainerIdOptionsIndexMap = {}