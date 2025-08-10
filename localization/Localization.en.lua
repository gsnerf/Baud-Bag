---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

--[[
    Many thanks to the community that provided translations for the many different languages.
    Contributors to the translations of this addon have been:
    - Isler (chinese and french translations)
    - Thurmal (german)
    - talkswind (korean)
    - StingerSoft (russian)

    If you contributed in the past and are missing here: please get in contanct with me!
]]

-- make sure this file stays UTF-8!
AddOnTable["Localized"] = {
    LockPosition = "Lock Position",
    UnlockPosition = "Unlock Position",
    ShowBank = "Show Bank",
    Options = "Options",
    Free = " Free",
    Offline = " (Offline)",
    AutoOpen = "Auto Open",
    AutoOpenTooltip = "When enabled, automaticaly opens this bag at the mailbox, vendor, or bank (if possible).",
    AutoClose = "Auto Close",
    AutoCloseTooltip = "When enabled, automatically closes this bag when leaving mailbox, vendor or bank. (Only if Auto Open is active!)",
    BlankOnTop = "Blank on top",
    BlankOnTopTooltip = "When enabled, any leftover blank space will be put on the top, instead of the bottom.",
    RarityColoring = "Rarity Coloring",
    RarityColoringTooltip = "When enabled, the borders of items will be colored according to their rarity (green, blue, etc).",
    RarityIntensity = "Rarity Color Intensity - %g",
    RarityIntensityTooltip = "Set the intensity of the rarity color",
    ShowNewItems = "New Items Highlight",
    ShowNewItemsTooltip = "When enabled, the borders of items will flash to highlight the new item until hovered with the mouse.",
    Columns = "Columns - %d",
    ColumnsTooltip = "Width of the container in slots.",
    Scale = "Scale - %d%%",
    ScaleTooltip = "Scale of the container.",
    AddMessage = "Baud Bag: AddOn loaded. Type /baudbag or /bb for options.",
    CheckTooltip = "Joined bags",
    Enabled = "Enabled",
    EnabledTooltip = "Enable or disable BaudBag for this bag set.",
    EnabledLinkedSet = "This bag set is linked with bag set '%s'. Changing one will also change the other.",
    CloseAll = "Close all",
    CloseAllTooltip = "Close all bags of this set when the first container (bank or backpack) is closed.",
    SellJunk = "Sell Junk",
    SellJunkTooltip = "Automatically sell all junk in the bag when visiting a merchant.",
    KeyRing = "Key Ring",
    Of = "'s ",
    Inventory = "Inventory",
    ReagentBag = "Reagents",
    BankBox = "Bank Box",
    ReagentBankBox = "Reagent Bank",
    BlizInventory = "Bliz Inventory",
    BlizBank = "Bliz Bank",
    BlizKeyring = "Bliz Keyring",
    Transparent = "Transparent",
    Transparent2 = "Transparent ElvUI",
    Solid = "Solid",
    BagSet = "Bag Set",
    ContainerName = "Container Name:",
    Background = "Background",
    FeatureFrameName = "BaudBag Options",
    FeatureFrameTooltip = "BaudBag Options",
    SearchBagTooltip = "Search Items",
    MenuCatSpecific = "Container Specifics",
    MenuCatGeneral = "General",
    TooltipScanReagent = "Crafting Reagent",
    OptionsGroupGlobal = "Basic Settings",
    OptionsGroupContainer = "Container Settings",
    UseMasque = "Enable Masque Support",
    UseMasqueTooltip = "This will tell Baud Bag to register item buttons with masque, so it can skin those buttons.",
    UseMasqueUnavailable = "Masque not found",
    UseMasqueReloadPopupText = "You seem to have enabled or disabled Masque support within Baud Bag. For changes to take effect you will need to reload your ui. Do you want to do that now?",
    UseMasqueReloadPopupAccept = "yes",
    UseMasqueReloadPopupDecline = "no",
    ShowItemLevel = "Show item level",
    ShowItemLevelTooltip = "Shows item levels on equipable items (small yellow number on the top)",
    EnableFadeAnimation = "Enable container fade animation",
    EnableFadeAnimationTooltip = "Controls wether the containers have a fade in/out animation uppon opening/closing",
    OptionsResetAllPositions = "Reset all container positions",
    OptionsResetAllPositionsTooltip = "Mainly helpful if you moved a container off screen by accident. If you only want to reset the position for a specific container, use the option further down instead!",
    OptionsResetContainerPosition = "Reset container position",
    OptionsResetContainerPositionTooltip = "Use this if you dragged the selected container of screen by accident.",
    AccountBank = "Warband Bank",
    ShowAccountBank = "Show Warband Bank",
}
