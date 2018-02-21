local AddOnName, AddOnTable = ...
local Masque

if IsAddOnLoaded("Masque") then
    Masque = LibStub("Masque", true)
end

local function ItemSlotCreated(self, bagID, slotID, button)
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
    local group = Masque:Group('BaudBag')
    group:AddButton(button, buttonData)
    --group:AddButton(button)

end

hooksecurefunc(BaudBag, "ItemSlot_Created", ItemSlotCreated)