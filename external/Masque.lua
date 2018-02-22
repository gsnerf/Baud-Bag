local AddOnName, AddOnTable = ...
local Masque

if IsAddOnLoaded("Masque") then
    Masque = LibStub("Masque", true)
end

local function ItemSlotCreated(self, bagSet, containerId, subContainerId, slotId, button)
    if not IsAddOnLoaded("Masque") or button == nil then
        return
    end

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
    local group = Masque:Group('BaudBag', bagSet.Name.." Container "..containerId)
    group:AddButton(button, buttonData)
end

local function ContainerUpdated(self, bagSet, containerId)
    if not IsAddOnLoaded("Masque") then
        return
    end

    Masque:Group('BaudBag', bagSet.Name.." Container "..containerId):ReSkin()
end

hooksecurefunc(BaudBag, "ItemSlot_Created", ItemSlotCreated)
hooksecurefunc(BaudBag, "Container_Updated", ContainerUpdated)