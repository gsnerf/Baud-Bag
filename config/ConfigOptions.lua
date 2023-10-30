local AddOnName, AddOnTable = ...
local _

local Localized = AddOnTable.Localized

---@class CheckButtonConfig
---@field Text string the description text for the option, as shown in the settings window
---@field TooltipText string additional description that will be shown when hovering with the mouse over an option entry
---@field SavedVar string the ID of the option as used in the configuration object
---@field Default boolean the default value to be used if no value has been configured yet
---@field DependsOn string? the ID of another option entry that needs to be enabled for this option to be used
---@field CanBeSet boolean? this defines if the option can be changed currently, it is expected to be filled dynamically on addon load based on some condition (like addon xyz is available)
---@field UnavailableText string? description that is shown on hovering over an entry that is not available due to CanBeSet == false

---@class SliderConfig
---@field Text string the description text for the option as shwon in the settings window
---@field TooltipText string additional description that will be shown when hovering with the mouse over an option entry
---@field Low number|string the minimal valid value this option can have
---@field High number|string the maximum valid value this option can have
---@field Step number the increase between two valid values of this option
---@field SavedVar string the ID of the option as used in the configuration object
---@field Default number|number[] the default value to be used if no value has been configured yet, when used on container options this is supposed to be an array containing the defaults for each bag set type
---@field DependsOn string? the ID of another option entry that needs to be enabled for this option to be used

---@class ConfigOptionSection
---@field CheckButtons CheckButtonConfig[] boolean type configurations
---@field SliderBars SliderConfig[] number type configurations with a given range

---This holds all of the more generalized configuration options
---@class ConfigOptions
---@field Global ConfigOptionSection general configuration options that configure the addon in it's entirety
---@field Container ConfigOptionSection configuration options that control the behavior of single containers
AddOnTable.ConfigOptions = {
    Global = {
        CheckButtons = {
            {Text=Localized.ShowNewItems,        SavedVar="ShowNewItems",        Default=true,  TooltipText=Localized.ShowNewItemsTooltip,        DependsOn=nil, CanBeSet=true,                      UnavailableText = "" },
            {Text=Localized.SellJunk,            SavedVar="SellJunk",            Default=false, TooltipText=Localized.SellJunkTooltip,            DependsOn=nil, CanBeSet=true,                      UnavailableText = "" },
            {Text=Localized.UseMasque,           SavedVar="UseMasque",           Default=false, TooltipText=Localized.UseMasqueTooltp,            DependsOn=nil, CanBeSet=IsAddOnLoaded("Masque"),   UnavailableText = Localized.UseMasqueUnavailable},
            {Text=Localized.RarityColoring,      SavedVar="RarityColor",         Default=true,  TooltipText=Localized.RarityColoringTooltip,      DependsOn=nil, CanBeSet=true,                      UnavailableText = "" },
            {Text=Localized.ShowItemLevel,       SavedVar="ShowItemLevel",       Default=false, TooltipText=Localized.ShowItemLevelTooltip,       DependsOn=nil, CanBeSet=true,                      UnavailableText = "" },
            {Text=Localized.EnableFadeAnimation, SavedVar="EnableFadeAnimation", Default=false, TooltipText=Localized.EnableFadeAnimationTooltip, DependsOn=nil, CanBeSet=true,                      UnavailableText = "" },
        },
        SliderBars = {
            { Text=Localized.RarityIntensity, Low=0.5, High=2.5, Step=0.1, SavedVar="RarityIntensity", Default=1, TooltipText=Localized.RarityIntensityTooltip, DependsOn="RarityColor" },
        }
    },
    Container = {
        CheckButtons = {
            {Text=Localized.AutoOpen,       SavedVar="AutoOpen",     Default=false, TooltipText=Localized.AutoOpenTooltip,          DependsOn=nil},
            {Text=Localized.AutoClose,      SavedVar="AutoClose",    Default=true,  TooltipText=Localized.AutoCloseTooltip,         DependsOn="AutoOpen"},
            {Text=Localized.BlankOnTop,     SavedVar="BlankTop",     Default=false, TooltipText=Localized.BlankOnTopTooltip,        DependsOn=nil},
        },
        SliderBars = {
            {Text=Localized.Columns,	Low="2",	High="40",		Step=1,		SavedVar="Columns",		Default={8,14,4},		TooltipText = Localized.ColumnsTooltip },
            {Text=Localized.Scale,		Low="50%",	High="200%",	Step=1,		SavedVar="Scale",		Default={100,100,100},	TooltipText = Localized.ScaleTooltip }
        }
    }
}

