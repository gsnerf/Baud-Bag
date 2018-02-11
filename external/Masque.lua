local AddOnName, AddOnTable = ...
local Masque

if IsAddOnLoaded("Masque") then
    Masque = LibStub("Masque", true)
end

local function ItemSlotCreated(self, bagID, slotID, button)
    if not IsAddOnLoaded("Masque") or button == nil then
        return
    end

    --[[
    local buttonData = {
        -- FloatingBG = {...},
        Icon = _G[button:GetName().."IconTexture"],
        Cooldown = _G[button:GetName().."Cooldown"],
        Flash = button.flash,
        -- Pushed = {...},
        Normal = _G[button:GetName().."NormalTexture"],
        -- Disabled = {...},
        -- Checked = {...},
        Border = button.iconBorder,
        -- AutoCastable = {...},
        -- Highlight = {...},
        -- HotKey = {...},
        Count = _G[button:GetName().."Count"]
        -- Name = {...},
        -- Duration = {...},
        -- Shine = {...},
    }]]
    local group = Masque:Group('BaudBag')
    --group:AddButton(button, buttonData)
    group:AddButton(button)

end

hooksecurefunc(BaudBag, "ItemSlot_Created", ItemSlotCreated)