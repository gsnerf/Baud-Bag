---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local Localized	= AddOnTable.Localized

---@class Theme
---@field Id string
---@field ContainerBackground ThemeBackground
---@field ItemButton ThemeItemButton

---@class ThemeBackground
---@field Id integer
---@field Name string
---@field Insets backdropInsets

---@class ThemeItemButton
---@field ShowBackground boolean
---@field BackgroundImage string|nil

---@type Theme[]
AddOnTable.Themes = {}

---@param theme Theme id should be a unique string
function AddOnTable:RegisterTheme(theme)
    AddOnTable.Themes[theme.Id] = theme
end