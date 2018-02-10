local AddOnName, AddOnTable = ...
local _
local Localized	= BaudBagLocalized;

function AddOnTable:RegisterDefaultBackgrounds()
    -- blizzard backgrounds
    AddOnTable:CreateBlizzardBackground(
        1, Localized.BlizInventory,
        "Interface\\ContainerFrame\\UI-Bag-Components"
    )

    AddOnTable:CreateBlizzardBackground(
        2, Localized.BlizBank,
        "Interface\\ContainerFrame\\UI-Bag-Components-Bank"
    )

    AddOnTable:CreateBlizzardBackground(
        3, Localized.BlizKeyring,
        "Interface\\ContainerFrame\\UI-Bag-Components-Keyring"
    )

    -- additional backgrounds
    AddOnTable:CreateSimpleBackground(
        4, Localized.Transparent,
        { Left = 8, Right = 8, Top = 28, Bottom = 8 }, -- Bottom + X if container is first container
        {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        },
        { Red = 0.0, Green = 0.0, Blue = 0.0, Alpha = 1 }
    )

    AddOnTable:CreateSimpleBackground(
        5, Localized.Solid,
        { Left = 16, Right = 16, Top = 36, Bottom = 16 }, -- Bottom + X if container is first container
        {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 8, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        },
        { Red = 0.1, Green = 0.1, Blue = 0.1, Alpha = 1 }
    )

    AddOnTable:CreateSimpleBackground(
        6, Localized.Transparent2,
        { Left = 8, Right = 8, Top = 28, Bottom = 8 }, -- Bottom + X if container is first container
        {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            tile = true, tileSize = 14, edgeSize = 14,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        },
        { Red = 0.0, Green = 0.0, Blue = 0.0, Alpha = 0.6 }
    )
end