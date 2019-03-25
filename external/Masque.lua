local AddOnName, AddOnTable = ...
local Localized = BaudBagLocalized
local Masque
local useMasque = false
local staticPopupName = "BaudBag_Masque_Reload"

--[[--------------------------------------------------------------------------------
--------------- internal methods to handle communication with masque ---------------
----------------------------------------------------------------------------------]]
local function RegisterItemButton(groupName, button)
    local buttonData = {
        Icon = button.icon,
        Cooldown = button.Cooldown,
        Pushed = button:GetPushedTexture(),
        Normal = button:GetNormalTexture(),
        Border = button.IconBorder,
        Highlight = button.SlotHighlightTexture,
        Count = button.Count,
    }
    Masque:Group('BaudBag', groupName):AddButton(button, buttonData)
end

local function RegisterBagButton(groupName, button)
    local highlightTexture = button:GetHighlightTexture()
    if (button.HighlightFrame ~= nil) then
        highlightTexture = button.HighlightFrame.HighlightTexture
    end
    local buttonData = {
        Icon = button.icon,
        Cooldown = button.Cooldown,
        Pushed = button:GetPushedTexture(),
        Normal = button:GetNormalTexture(),
        Checked = button.SlotHighlightTexture,
        Border = button.IconBorder,
        Highlight = highlightTexture,
        Count = button.Count,
    }
    Masque:Group('BaudBag', groupName):AddButton(button, buttonData)
end

--[[--------------------------------------------------------------------------------
------------------------- methods hook to internal events --------------------------
----------------------------------------------------------------------------------]]
local function ItemSlotCreated(self, bagSetType, containerId, subContainerId, slotId, button)
    if (useMasque) then
        local groupName = bagSetType.Name.." Container "..containerId
        RegisterItemButton(groupName, button)
    end
end

local function BagSlotCreated(self, bagSetType, bagId, button)
    if (useMasque) then
        local groupName = bagSetType.Name.." Bag Buttons"
        RegisterBagButton(groupName, button)
    end
end

local function ContainerUpdated(self, bagSetType, containerId)
    if (useMasque) then
        Masque:Group('BaudBag', bagSetType.Name.." Container "..containerId):ReSkin()
    end
end

local function BagSlotUpdated(self, bagSetType, bagId, button)
    if (useMasque) then
        --Masque:Group('BaudBag', bagSetType.Name.." Bag Buttons"):ReSkin()
    end
end

local function UpdateRegistration(self)
    if (AddOnTable.Config.UseMasque ~= useMasque) then
        StaticPopup_Show(staticPopupName)
    end
end

if IsAddOnLoaded("Masque") then
    Masque = LibStub("Masque")

    StaticPopupDialogs[staticPopupName] = {
        text = Localized.UseMasqueReloadPopupText,
        button1 = Localized.UseMasqueReloadPopupAccept,
        button2 = Localized.UseMasqueReloadPopupDecline,
        OnAccept = function()
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }

    hooksecurefunc(BaudBag, "Configuration_Loaded", function(self) useMasque = AddOnTable.Config.UseMasque end )
    hooksecurefunc(BaudBag, "Configuration_Updated", UpdateRegistration)
    hooksecurefunc(BaudBag, "ItemSlot_Created", ItemSlotCreated)
    hooksecurefunc(BaudBag, "BagSlot_Created", BagSlotCreated)
    hooksecurefunc(BaudBag, "BagSlot_Updated", BagSlotUpdated)
    hooksecurefunc(BaudBag, "Container_Updated", ContainerUpdated)
end