-- Author      : gsnerf
-- Create Date : 11/11/2010 6:16:49 PM

local _;

-- some locally needed variables
local Localized	= BaudBagLocalized;
local SliderBars, GlobalCheckButtons, ContainerCheckButtons;
BBConfig = {};

function BaudBagSetCfgPreReq(Bars, GlobalButtons, ContainerButtons)
    SliderBars            = Bars;
    GlobalCheckButtons    = GlobalButtons;
    ContainerCheckButtons = ContainerButtons;
end

function BaudBagRestoreCfg()
    BaudBag_DebugMsg("Config", "Restoring BBConfig structure:");
	
    -- cofig base
    if (type(BaudBag_Cfg) ~= "table") then
        BaudBag_DebugMsg("Config", "- basic BBConfig damaged or missing, creating now");
        BaudBag_Cfg = {};
    end
    BBConfig = BaudBag_Cfg;

    -- global options first
    for Key, Value in ipairs(GlobalCheckButtons) do
        if (type(BBConfig[Value.SavedVar]) ~= "boolean") then
            BaudBag_DebugMsg("Config", "- Global CheckBox["..Value.SavedVar.."] data damaged or missing, creating now");
            BBConfig[Value.SavedVar] = Value.Default;
        end
    end

    for BagSet = 1, 2 do
        if (type(BBConfig[BagSet]) ~= "table") then
            BaudBag_DebugMsg("Config", "- BBConfig for BagSet "..BagSet.." damaged or missing, creating now");
            BBConfig[BagSet] = {};
        end
		
        if (type(BBConfig[BagSet].Enabled) ~= "boolean") then
            BaudBag_DebugMsg("Config", "- enabled state for BagSet "..BagSet.." damaged or missing, creating now");
            BBConfig[BagSet].Enabled = true;
        end

        if (type(BBConfig[BagSet].CloseAll) ~= "boolean") then
            BaudBag_DebugMsg("Config", "- close all state for BagSet "..BagSet.." damaged or missing, creating now");
            BBConfig[BagSet].CloseAll = true;
        end

        if (type(BBConfig[BagSet].Joined) ~= "table") then
            BaudBag_DebugMsg("Config", "- joins for BagSet "..BagSet.." damaged or missing, creating now");
            BBConfig[BagSet].Joined = {};
        end

        -- make sure the reagent bank is NOT joined by default!
        if (BagSet == 2 and BBConfig[2].Joined[9] == nil) then
            BaudBag_DebugMsg("Config", "- reagent bank join for BagSet "..BagSet.." damaged or missing, creating now");
            BBConfig[BagSet].Joined[9] = false;
        end

        if (type(BBConfig[BagSet].ShowBags) ~= "boolean") then
            BaudBag_DebugMsg("Config", "- show information for BagSet "..BagSet.." damaged or missing, creating now");
            BBConfig[BagSet].ShowBags = ((BagSet == 2) and true or false);
        end

        local Container = 0;
        BaudBagForEachBag(BagSet, function(Bag, Index)

            -- keyring cache, not needed anymore???
            --if (Bag == -2) and (BBConfig[BagSet].Joined[Index] == nil) then
            --    BaudBag_DebugMsg("Config", "- BagSet["..BagSet.."], Bag["..Bag.."] joined status damaged or missing, creating now");
            --    BBConfig[BagSet].Joined[Index] = false;
            --end

            if (Container == 0) or (BBConfig[BagSet].Joined[Index] == false) then
                Container = Container + 1;

                if (type(BBConfig[BagSet][Container]) ~= "table") then
                    BaudBag_DebugMsg("Config", "- BagSet["..BagSet.."], Bag["..Bag.."], Container["..Container.."] container data damaged or missing, creating now");
                    if (Container == 1) or (Bag==-3) then
                        BBConfig[BagSet][Container] = {};
                    else
                        BBConfig[BagSet][Container] = BaudBagCopyTable(BBConfig[BagSet][Container-1]);
                    end
                end

                if not BBConfig[BagSet][Container].Name then
                    BaudBag_DebugMsg("Config", "- BagSet["..BagSet.."], Bag["..Bag.."], Container["..Container.."] container name missing, creating now");
                    --With the key ring, there isn't enough room for the player name aswell
                    BBConfig[BagSet][Container].Name = UnitName("player")..Localized.Of..((BagSet==1)and Localized.Inventory or Localized.BankBox);
                    if (Bag == REAGENTBANK_CONTAINER) then
                        BBConfig[BagSet][Container].Name = UnitName("player")..Localized.Of..Localized.ReagentBankBox;
                    end
                end

                if (type(BBConfig[BagSet][Container].Background) ~= "number") then
                    BaudBag_DebugMsg("Config", "- BagSet["..BagSet.."], Bag["..Bag.."], Container["..Container.."] container background damaged or missing, creating now");
                    if (BagSet == 2) then
                        -- bank containers have "blizz bank" default
                        BBConfig[BagSet][Container].Background = 2;
                    else
                        -- default contains have "blizz inventory" default
                        BBConfig[BagSet][Container].Background = 1;
                    end
                end

                for Key, Value in ipairs(SliderBars) do
                    if (type(BBConfig[BagSet][Container][Value.SavedVar]) ~= "number") then
                        BaudBag_DebugMsg("Config", "- BagSet["..BagSet.."], Bag["..Bag.."], Container["..Container.."] Slider["..Value.SavedVar.."] data damaged or missing, creating now");
                        BBConfig[BagSet][Container][Value.SavedVar] = Value.Default[BagSet];
                    end
                end

                for Key, Value in ipairs(ContainerCheckButtons)do
                    if (type(BBConfig[BagSet][Container][Value.SavedVar]) ~= "boolean") then
                        BaudBag_DebugMsg("Config", "- BagSet["..BagSet.."], Bag["..Bag.."], Container["..Container.."] CheckBox["..Value.SavedVar.."] data damaged or missing, creating now");
                        BBConfig[BagSet][Container][Value.SavedVar] = Value.Default;
                    end
                end
            end
        end);
    end
end

function ConvertOldConfig()
    -- take over old sell junk data
    if (type(BBConfig[1]) == "table" and type(BBConfig[1].SellJunk) == "boolean") then
        BaudBag_DebugMsg("Config", "- sell junk state is now global, converting old value from bag set 1");
        BBConfig.SellJunk = BBConfig[1].SellJunk;
        BBConfig[1].SellJunk = nil;
        BBConfig[2].SellJunk = nil;
    end

    -- take over old new items highlight data
    if (type(BBConfig[1]) == "table" and type(BBConfig[1][1]) == "table" and type(BBConfig[1][1].ShowNewItems) == "boolean") then
        BaudBag_DebugMsg("Config", "- show new items state is now global, converting old value from first bagpack container");
        BBConfig.ShowNewItems = BBConfig[1][1].ShowNewItems;
        for BagSet = 1, 2 do
            local Container = 0;
            BaudBagForEachBag(BagSet, function(Bag, Index)
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
    BaudBag_DebugMsg("Config", "Saving configuration");
    BaudBag_Cfg = BaudBagCopyTable(BBConfig);
    ReloadConfigDependant();
end

function ReloadConfigDependant()
    BaudBag_DebugMsg("Config", "Reloading configuration depending objects");
    BaudUpdateJoinedBags();
    BaudBagUpdateBagFrames();
    BaudBagOptionsUpdate();
end