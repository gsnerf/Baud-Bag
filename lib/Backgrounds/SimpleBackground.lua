local AddOnName, AddOnTable = ...
local _

local Prototype = {
    Id = nil,
    Name = nil,
    --[[  sub tables have to be reassigned on init or ALL new elements will have the SAME tables for access... ]]
    Insets = nil,
    Backdrop = nil,
    BackdropColor = nil
}

function Prototype:Update(containerFrame, backdrop, shiftName)
    backdrop.Textures:Hide()
    backdrop:SetBackdrop(self.Backdrop)
    local color = self.BackdropColor
    if (color ~= nil) then
        backdrop:SetBackdropColor(color.Red, color.Green, color.Blue, color.Alpha)
    end

    containerFrame.Name:SetPoint("TOPLEFT", (2 + shiftName), 18)
    containerFrame.CloseButton:SetPoint("TOPRIGHT", 8, 28)

    local Bottom = self.Insets.Bottom
    if (containerFrame:GetID() == 1) then
        if (BackpackTokenFrame_IsShown() == 1  and containerFrame:GetName() == "BaudBagContainer1_1") then
            containerFrame.FreeSlots:SetPoint("BOTTOMLEFT",   2, -17)
            containerFrame.MoneyFrame:SetPoint("BOTTOMRIGHT", 8, -18)
            containerFrame.TokenFrame:SetPoint("BOTTOMLEFT",  8, -36)
            containerFrame.TokenFrame:SetPoint("BOTTOMRIGHT", 8, -36)
            Bottom = Bottom + 36
        else
            containerFrame.FreeSlots:SetPoint("BOTTOMLEFT",   2, -17)
            containerFrame.MoneyFrame:SetPoint("BOTTOMRIGHT", 8, -18)
            Bottom = Bottom + 18
        end
    end

    return self.Insets.Left, self.Insets.Right, self.Insets.Top, Bottom
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateSimpleBackground(id, name, insets, backdrop, color)
    local background = _G.setmetatable({}, Metatable)
    background.Id = id
    background.Name = name
    background.Insets = insets
    background.Backdrop = backdrop
    background.BackdropColor = color
    
    AddOnTable["Backgrounds"][id] = background
    return bagSet
end
