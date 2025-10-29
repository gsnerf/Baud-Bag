---@class AddonNamespace
local AddOnTable = select(2, ...)
local Localized = AddOnTable.Localized
local _

local SimpleTheme = {}

function SimpleTheme:Update(containerFrame, backdrop, shiftName)
    backdrop.Textures:Hide()
    backdrop:SetBackdrop(self.Backdrop)
    local color = self.BackdropColor
    if (color ~= nil) then
        backdrop:SetBackdropColor(color.Red, color.Green, color.Blue, color.Alpha)
    end

    containerFrame.Name:SetPoint("TOPLEFT", (2 + shiftName), 18)
    containerFrame.CloseButton:SetPoint("TOPRIGHT", 8, 28)

    local Bottom = self.Insets.Bottom
    if (containerFrame.showInfoBar == true) then
        if (containerFrame.TokenFrame.shouldShow == 1 and containerFrame:GetName() == "BaudBagContainer1_1") then
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

local function initSimpleBackground(id, name, insets, backdrop, color, itemButtonBackground, itemButtonWidthOffset, itemButtonHeightOffset)
    local background = CreateFromMixins(SimpleTheme)
    background.Id = id
    background.Name = name
    background.Insets = insets
    background.Backdrop = backdrop
    background.BackdropColor = color

    AddOnTable:RegisterTheme({
        Id = id,
        ContainerBackground = background,
        ItemButton = {
            ShowBackground = itemButtonBackground ~= nil,
            BackgroundImage = itemButtonBackground,
            WidthOffset = itemButtonWidthOffset,
            HeightOffset = itemButtonHeightOffset
        },
        BorderOffset = {
            X = 2,
            Y = 2
        }
    })
end

initSimpleBackground(
    "Transparent",
    Localized.Transparent,
    { Left = 8, Right = 8, Top = 28, Bottom = 8 }, -- Bottom + X if container is first container
    {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    },
    { Red = 0.0, Green = 0.0, Blue = 0.0, Alpha = 1 },
    nil,
    39,
    -39
)

initSimpleBackground(
    "Solid",
    Localized.Solid,
    { Left = 16, Right = 16, Top = 36, Bottom = 16 }, -- Bottom + X if container is first container
    {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 8, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    },
    { Red = 0.1, Green = 0.1, Blue = 0.1, Alpha = 1 },
    nil,
    39,
    -39
)

initSimpleBackground(
    "ElvUI",
    Localized.Transparent2,
    { Left = 8, Right = 8, Top = 28, Bottom = 8 }, -- Bottom + X if container is first container
    {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = 14, edgeSize = 14,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    },
    { Red = 0.0, Green = 0.0, Blue = 0.0, Alpha = 0.6 },
    nil,
    39,
    -39
)