---@class AddonNamespace
local AddOnTable = select(2, ...)
local Localized = AddOnTable.Localized
local _

local EventFuncs = {}
    
function BaudBag_RegisterBackpackEvents(self)
    for Key, Value in pairs(EventFuncs)do
        self:RegisterEvent(Key)
    end
end

function BaudBag_OnBackpackEvent(self, event, ...)
    if EventFuncs[event] then
        EventFuncs[event](self, event, ...)
    end
end


local function BackpackBagOverview_Initialize()
    -- create BagSlots for the bag overview in the inventory (frame that pops out and only shows the available bags)
    AddOnTable.Functions.DebugMessage("Bags", "Creating bag slot buttons.")
    local backpackSet = AddOnTable.Sets[BagSetType.Backpack.Id]
    local BBContainer1 = _G["BaudBagContainer1_1BagsFrame"]

    -- this is one container less, as the backpack itself doesn't get a button
    for backpackBagButton = 0, AddOnTable.BlizzConstants.BACKPACK_CONTAINER_NUM - 1 do
        local bagButton = AddOnTable:CreateBackpackBagButton(backpackBagButton, BBContainer1)
        bagButton:SetPoint("TOPLEFT", 8, -8 - backpackBagButton * bagButton:GetHeight())
        backpackSet.BagButtons[backpackBagButton] = bagButton
	end

    if (GetExpansionLevel() >= 9) then
        for reagentBagButton = 0, AddOnTable.BlizzConstants.BACKPACK_REAGENT_BAG_NUM - 1 do
            local bagButton = AddOnTable:CreateReagentBagButton(reagentBagButton, BBContainer1)
            bagButton:SetPoint("TOPLEFT", 8, -8 - (#backpackSet.BagButtons + 1 + reagentBagButton) * bagButton:GetHeight())
            backpackSet.ReagentBagButtons[reagentBagButton] = bagButton
        end
    end

    local firstBackpackBagButton = backpackSet.BagButtons[0]
    BBContainer1:SetWidth(15 + firstBackpackBagButton:GetWidth())
    BBContainer1:SetHeight(15 + AddOnTable.BlizzConstants.BACKPACK_TOTAL_BAGS_NUM * firstBackpackBagButton:GetHeight())
end
BagSetType.Backpack.BagOverview_Initialize = BackpackBagOverview_Initialize


if PlayerInteractionFrameManager ~= nil then
    local function HandleMerchantShow()
        AddOnTable.Functions.DebugMessage("Junk", "MerchandFrame was shown checking if we need to sell junk")
        if (BBConfig.SellJunk and BBConfig[1].Enabled and MerchantFrame:IsShown()) then
            AddOnTable.Functions.DebugMessage("Junk", "junk selling active and merchant frame is shown, identifiyng junk now")
            AddOnTable.Sets[BagSetType.Backpack.Id]:ForEachBag(
                function(Bag, _)
                    for Slot = 1, AddOnTable.BlizzAPI.GetContainerNumSlots(Bag) do
                        local containerItemInfo = AddOnTable.BlizzAPI.GetContainerItemInfo(Bag, Slot)
                        if (containerItemInfo and containerItemInfo.quality and containerItemInfo.quality == 0) then
                            AddOnTable.Functions.DebugMessage("Junk", "Found junk (Container, Slot)", Bag, Slot)
                            --[[
                                TODO: additionally check if this is something that can be collected for transmog and optionally skip that
                                - transmog stuff was introduced with legion
                                - transmog base info can be retrieved from C_TransmogCollection.GetItemInfo through itemID/link/name
                                - if it is already collected can be found from C_TransmogCollection.GetAppearanceSourceInfo and C_TransmogCollection.PlayerCanCollectSource
                            ]]
                            AddOnTable.BlizzAPI.UseContainerItem(Bag, Slot)
                        end
                    end
                end
            )
        end
    end

    local Func = function(self, event, ...)
        local type = ...

        if type == Enum.PlayerInteractionType.Merchant then
            if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
                HandleMerchantShow()
            end
        end
    end
    EventFuncs.PLAYER_INTERACTION_MANAGER_FRAME_SHOW = Func
    EventFuncs.PLAYER_INTERACTION_MANAGER_FRAME_HIDE = Func
end

--[[ this method ensures that the bank bags are either placed as childs under UIParent or BaudBag ]]
function AddOnTable:UpdateBagParents()
    local newParent = ContainerFrameContainer
    if AddOnTable.Functions.BagHandledByBaudBag(AddOnTable.BlizzConstants.BACKPACK_CONTAINER) then
        newParent = BaudBag_OriginalBagsHideFrame
    end

    if (ContainerFrameCombinedBags) then
        ContainerFrameCombinedBags:SetParent(newParent)
    end
    for i = AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER, AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER do
        _G["ContainerFrame"..(i + 1)]:SetParent(newParent)
    end
end