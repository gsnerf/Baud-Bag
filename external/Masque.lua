local AddOnName, AddOnTable = ...
local Masque

local function ItemSlotCreated(self, bagSetType, containerId, subContainerId, slotId, button)
    local buttonData = {
        -- FloatingBG = {...},
        Icon = button.icon,
        Cooldown = button.Cooldown,
        -- Flash = button.flash,
        Pushed = button:GetPushedTexture(),
        Normal = button:GetNormalTexture(),
        -- Disabled = {...},
        -- Checked = {...},
        Border = button.IconBorder,
        -- AutoCastable = {...},
        Highlight = button:GetHighlightTexture(),
        -- HotKey = {...},
        Count = button.Count,
        -- Name = {...},
        -- Duration = {...},
        -- Shine = {...},
    }
    local group = Masque:Group('BaudBag', bagSetType.Name.." Container "..containerId)
    group:AddButton(button, buttonData)
end

local function BagSlotCreated(self, bagSetType, bagId, button)
    local highlightTexture = button:GetHighlightTexture()
    if (button.HighlightFrame ~= nil) then
        highlightTexture = button.HighlightFrame.HighlightTexture
    end
    local buttonData = {
        -- FloatingBG = {...},
        Icon = button.icon,
        Cooldown = button.Cooldown,
        -- Flash = button.flash,
        Pushed = button:GetPushedTexture(),
        Normal = button:GetNormalTexture(),
        -- Disabled = {...},
        Checked = button:GetCheckedTexture(),
        Border = button.IconBorder,
        -- AutoCastable = {...},
        Highlight = highlightTexture,
        -- HotKey = {...},
        Count = button.Count,
        -- Name = {...},
        -- Duration = {...},
        -- Shine = {...},
    }

    local group = Masque:Group('BaudBag', bagSetType.Name.." Bag Buttons")
    group:AddButton(button, buttonData)
end

local function ContainerUpdated(self, bagSetType, containerId)
    Masque:Group('BaudBag', bagSetType.Name.." Container "..containerId):ReSkin()
end

if IsAddOnLoaded("Masque") then
    Masque = LibStub("Masque", true)
    hooksecurefunc(BaudBag, "ItemSlot_Created", ItemSlotCreated)
    hooksecurefunc(BaudBag, "BagSlot_Created", BagSlotCreated)
    hooksecurefunc(BaudBag, "Container_Updated", ContainerUpdated)
end