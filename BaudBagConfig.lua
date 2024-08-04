local AddOnName, AddOnTable = ...
local _

-- some locally needed variables
local Localized	= AddOnTable.Localized
BBConfig = {}
-- TODO: somehow changes of BBConfig are not getting stored in AddOnTable.Config, propably something to do with resetting BBConfig at later points...

---@class ContainerConfig
---@field Columns integer the number of columns to render in a container
---@field Scale integer the scale in percentage to use for defining the size
---@field AutoOpen boolean whether to automatically open the container when going to a merchant, post, bank or whatever
---@field AutoClose boolean whether to automatically close the container if it has been opened automatically before
---@field BlankTop boolean wheter to show "blank" items (when number of items / columns != 0) on the top or bottom of the container

---@class BagSetConfig
---@field Enabled boolean whether to cover this bag set with baud bag or leave it to stock UI
---@field CloseAll boolean whether to close all containers when the first one in the set has been closed
---@field Joined table<integer,boolean?> for each container defines if it is joined with the previous one or not, if the value is nil it cannot be joined!
---@field ShowBags boolean 
---@field [integer] ContainerConfig the configuration for the container with ID == value

---@class Config
---@field ShowNewItems boolean whether to highlight new items in the bags or not
---@field SellJunk boolean whether to automatically sell junk or not
---@field UseMasque boolean whether to integrate with the Masque skinning addon or not
---@field RarityColor boolean whether to show a rarity border around items
---@field ShowItemLevel boolean whether to show an item level on top of an item or not
---@field EnableFadeAnimation boolean whether to show a fading animation when opening/closing a container or not
---@field RarityIntensity number the intensity of the rarity border to use
---@field [integer] BagSetConfig the configuration of bag set with ID == value

AddOnTable.Config = BBConfig

--- helper method to minify the code, checks the given variable and possibly returns a default value
---@param toCheck table|boolean|number|string a variable to check
---@param compareWith type a type definition to check the variable against
---@param default table|boolean|number|string a default value to apply if the type of toCheck doesn't match
---@param log string any string to put into the log
---@return table|boolean|number|string checkResult toCheck if type matches or default value if it doesn't
local function checkValue(toCheck, compareWith, default, log)
    -- default check if applied, return default value
    if (type(toCheck) ~= compareWith) then
        AddOnTable.Functions.DebugMessage("Config", log);
        return default;
    end

    -- check did not match, return original value
    return toCheck;
end

function RestoreConfigToObject(configObject)
    configObject = checkValue(configObject, "table", {}, "- basic config object damaged or missing, creating now")

    -- global options first
    for _, buttonConfig in ipairs(AddOnTable.ConfigOptions.Global.CheckButtons) do
        configObject[buttonConfig.SavedVar] = checkValue(configObject[buttonConfig.SavedVar], "boolean", buttonConfig.Default, "- Global CheckBox["..buttonConfig.SavedVar.."] data damaged or missing, creating now")
    end
    for _, sliderConfig in ipairs(AddOnTable.ConfigOptions.Global.SliderBars) do
        configObject[sliderConfig.SavedVar] = checkValue(configObject[sliderConfig.SavedVar], "number", sliderConfig.Default, "- Global Slider["..sliderConfig.SavedVar.."] data damaged or missing, creating now")
    end

    -- bag set configs now
    for _, bagSetType in pairs(BagSetType) do
        local bagSetID = bagSetType.Id
        configObject[bagSetID]          = checkValue(configObject[bagSetID],          "table",   {},   "- BBConfig for BagSet "..bagSetID.." damaged or missing, creating now")
		configObject[bagSetID].Enabled  = checkValue(configObject[bagSetID].Enabled,  "boolean", true, "- enabled state for BagSet "..bagSetID.." damaged or missing, creating now")
        configObject[bagSetID].CloseAll = checkValue(configObject[bagSetID].CloseAll, "boolean", true, "- close all state for BagSet "..bagSetID.." damaged or missing, creating now")
        configObject[bagSetID].Joined   = checkValue(configObject[bagSetID].Joined,   "table",   {},   "- joins for BagSet "..bagSetID.." damaged or missing, creating now")
        configObject[bagSetID].ShowBags = checkValue(configObject[bagSetID].ShowBags, "boolean", (bagSetID == 2), "- show information for BagSet "..bagSetID.." damaged or missing, creating now")

        -- make sure the reagent bank is NOT joined by default!
        if (bagSetID == BagSetType.Bank.Id and configObject[2].Joined[9] == nil) then
            AddOnTable.Functions.DebugMessage("Config", "- reagent bank join for BagSet "..bagSetID.." damaged or missing, creating now")
            configObject[bagSetID].Joined[9] = false
        end

        -- make sure the reagent bag is NOT joined by default!
        if (bagSetID == BagSetType.Backpack.Id and configObject[1].Joined[6] == nil) then
            AddOnTable.Functions.DebugMessage("Config", "- reagent bag join for BagSet "..bagSetID.." damaged or missing, creating now")
            configObject[bagSetID].Joined[6] = false;
        end

        local containerID = 0
        AddOnTable.Functions.ForEachBag(bagSetID, function(bagID, index)

            if (containerID == 0) or (configObject[bagSetID].Joined[index] == false) then
                containerID = containerID + 1;
                
                local isBackpack = containerID == 1
                local isReagentBank = bagID == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER
                local isReagentBag = AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER ~= nil and AddOnTable.BlizzConstants.BACKPACK_FIRST_REAGENT_CONTAINER <= bagID and bagID <= AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER
                local isKeyring = bagID == AddOnTable.BlizzConstants.KEYRING_CONTAINER

                if (type(configObject[bagSetID][containerID]) ~= "table") then
                    AddOnTable.Functions.DebugMessage("Config", "- BagSet["..bagSetID.."], Bag["..bagID.."], Container["..containerID.."] container data damaged or missing, creating now")
                    if isBackpack or isReagentBank or isReagentBag or isKeyring then
                        configObject[bagSetID][containerID] = {}
                    else
                        configObject[bagSetID][containerID] = AddOnTable.Functions.CopyTable(configObject[bagSetID][containerID-1])
                    end
                end

                if not configObject[bagSetID][containerID].Name then
                    AddOnTable.Functions.DebugMessage("Config", "- BagSet["..bagSetID.."], Bag["..bagID.."], Container["..containerID.."] container name missing, creating now")
                    local nameAddition = Localized.BankBox
                    if (bagSetID == 1) then
                        if ( isReagentBag ) then
                            nameAddition = Localized.ReagentBag
                        else
                            nameAddition = Localized.Inventory
                        end
                    end

                    if ( isReagentBank ) then
                        nameAddition = Localized.ReagentBankBox
                    end

                    if (bagSetID == 3) then
                        nameAddition = Localized.KeyRing
                    end
                    
                    configObject[bagSetID][containerID].Name = UnitName("player")..Localized.Of..nameAddition
                end

                if (type(configObject[bagSetID][containerID].Background) ~= "number") then
                    AddOnTable.Functions.DebugMessage("Config", "- BagSet["..bagSetID.."], Bag["..bagID.."], Container["..containerID.."] container background damaged or missing, creating now")
                    if (bagSetID == 2) then
                        -- bank containers have "blizz bank" default
                        configObject[bagSetID][containerID].Background = 2
                    elseif (bagSetID == 3) then
                        -- keyring containers have "blizz keyring" default
                        configObject[bagSetID][containerID].Background = 3
                    else
                        -- default contains have "blizz inventory" default
                        configObject[bagSetID][containerID].Background = 1
                    end
                end

                for _, sliderConfig in ipairs(AddOnTable.ConfigOptions.Container.SliderBars) do
                    configObject[bagSetID][containerID][sliderConfig.SavedVar] = checkValue(configObject[bagSetID][containerID][sliderConfig.SavedVar], "number", sliderConfig.Default[bagSetID], "- BagSet["..bagSetID.."], Bag["..bagID.."], Container["..containerID.."] Slider["..sliderConfig.SavedVar.."] data damaged or missing, creating now")
                end

                for _, buttonConfig in ipairs(AddOnTable.ConfigOptions.Container.CheckButtons) do
                    configObject[bagSetID][containerID][buttonConfig.SavedVar] = checkValue(configObject[bagSetID][containerID][buttonConfig.SavedVar], "boolean", buttonConfig.Default, "- BagSet["..bagSetID.."], Bag["..bagID.."], Container["..containerID.."] CheckBox["..buttonConfig.SavedVar.."] data damaged or missing, creating now")
                end
            end
        end)
    end

    return configObject
end

function BaudBagRestoreCfg()
    AddOnTable.Functions.DebugMessage("Config", "Restoring BBConfig structure:");
	
    -- cofig base
    BaudBag_Cfg = RestoreConfigToObject(BaudBag_Cfg)
    BBConfig = BaudBag_Cfg

    AddOnTable.Config = BBConfig
    AddOnTable:Configuration_Loaded()
end

function ConvertOldConfig()
    -- take over old sell junk data
    if (type(BBConfig[1]) == "table" and type(BBConfig[1].SellJunk) == "boolean") then
        AddOnTable.Functions.DebugMessage("Config", "- sell junk state is now global, converting old value from bag set 1");
        BBConfig.SellJunk = BBConfig[1].SellJunk;
        BBConfig[1].SellJunk = nil;
        BBConfig[2].SellJunk = nil;
    end

    -- take over old new items highlight data
    if (type(BBConfig[1]) == "table" and type(BBConfig[1][1]) == "table" and type(BBConfig[1][1].ShowNewItems) == "boolean") then
        AddOnTable.Functions.DebugMessage("Config", "- show new items state is now global, converting old value from first bagpack container");
        BBConfig.ShowNewItems = BBConfig[1][1].ShowNewItems;
        for BagSet = 1, 2 do
            local Container = 0;
            AddOnTable.Functions.ForEachBag(BagSet, function(Bag, Index)
                if (Container == 0) or (BBConfig[BagSet].Joined[Index] == false) then
                    Container = Container + 1;
                    if (type(BBConfig[BagSet][Container].ShowNewItems) == "boolean") then
                        BBConfig[BagSet][Container].ShowNewItems = nil;
                    end
                end
            end);
        end
    end
end

function BaudBagSaveCfg()
    AddOnTable.Functions.DebugMessage("Config", "Saving configuration");
    BaudBag_Cfg = AddOnTable.Functions.CopyTable(BBConfig);
    ReloadConfigDependant();
    AddOnTable:Configuration_Updated()
end

function ReloadConfigDependant()
    AddOnTable.Functions.DebugMessage("Config", "Reloading configuration depending objects");
    BaudUpdateJoinedBags();
    BaudBagUpdateBagFrames();
end

--[[--------------------------------------------------------------------------------
------------------------ config specific hooks for binding -------------------------
----------------------------------------------------------------------------------]]

function AddOnTable:Configuration_Loaded()
    -- just an empty hook for other addons or extensions
end

function AddOnTable:Configuration_Updated()
    -- just an empty hook for other addons or extensions
end