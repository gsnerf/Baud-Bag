-- Author      : gsnerf
-- Create Date : 11/11/2010 6:16:49 PM

-- some locally needed variables
local Localized	= BaudBagLocalized;
local SliderBars, CheckButtons;

function BaudBagSetCfgPreReq(Bars, Buttons)
	SliderBars		= Bars;
	CheckButtons	= Buttons;
end

function BaudBagRestoreCfg()
  BaudBag_DebugMsg("Restoring BaudBag_Cfg structure:");
  
  if (type(BaudBag_Cfg) ~= "table") then
		BaudBag_DebugMsg("- basic BaudBag_Cfg damaged or missing, creating now");
		BaudBag_Cfg = {};
	end
	
  for BagSet = 1, 2 do
		if (type(BaudBag_Cfg[BagSet]) ~= "table") then
			BaudBag_DebugMsg("- BaudBag_Cfg for BagSet "..BagSet.." damaged or missing, creating now");
			BaudBag_Cfg[BagSet] = {};
		end
		
    if (type(BaudBag_Cfg[BagSet].Enabled) ~= "boolean") then
			BaudBag_DebugMsg("- enabled state for BagSet "..BagSet.." damaged or missing, creating now");
			BaudBag_Cfg[BagSet].Enabled = true;
    end
    
    if (type(BaudBag_Cfg[BagSet].Joined) ~= "table") then
			BaudBag_DebugMsg("- joins for BagSet "..BagSet.." damaged or missing, creating now");
			BaudBag_Cfg[BagSet].Joined = {};
    end
    
    if (type(BaudBag_Cfg[BagSet].ShowBags) ~= "boolean") then
			BaudBag_DebugMsg("- show information for BagSet "..BagSet.." damaged or missing, creating now");
			BaudBag_Cfg[BagSet].ShowBags = ((BagSet == 2) and true or false);
		end
    
    local Container = 0;
    BaudBagForEachBag(BagSet, function(Bag, Index)
    
      if (Bag == -2) and (BaudBag_Cfg[BagSet].Joined[Index] == nil) then
				BaudBag_DebugMsg("- BagSet["..BagSet.."], Bag["..Bag.."] joined status damaged or missing, creating now");
        BaudBag_Cfg[BagSet].Joined[Index] = false;
      end
      
      if (Container == 0) or (BaudBag_Cfg[BagSet].Joined[Index] == false) then
        Container = Container + 1;
        
        if (type(BaudBag_Cfg[BagSet][Container]) ~= "table") then
					BaudBag_DebugMsg("- BagSet["..BagSet.."], Bag["..Bag.."], Container["..Container.."] container data damaged or missing, creating now");
          if (Container == 1) or (Bag==-2) then
            BaudBag_Cfg[BagSet][Container] = {};
          else
            BaudBag_Cfg[BagSet][Container] = CopyTable(BaudBag_Cfg[BagSet][Container-1]);
          end
        end
        
        if not BaudBag_Cfg[BagSet][Container].Name then
					BaudBag_DebugMsg("- BagSet["..BagSet.."], Bag["..Bag.."], Container["..Container.."] container name missing, creating now");
          --With the key ring, there isn't enough room for the player name aswell
          BaudBag_Cfg[BagSet][Container].Name = (Bag==-2) and Localized.KeyRing or UnitName("player")..Localized.Of..((BagSet==1)and Localized.Inventory or Localized.BankBox);
        end
        
        if (type(BaudBag_Cfg[BagSet][Container].Background) ~= "number") then
					BaudBag_DebugMsg("- BagSet["..BagSet.."], Bag["..Bag.."], Container["..Container.."] container background damaged or missing, creating now");
					if (BagSet == 2) then
						-- bank containers have "blizz bank" default
						BaudBag_Cfg[BagSet][Container].Background = 2
					else
						-- default containers only separate for default bag and keyring (-2 == keyring)
						BaudBag_Cfg[BagSet][Container].Background = (Bag == -2) and 3 or 1;
					end
        end
        
        for Key, Value in ipairs(SliderBars)do
          if (type(BaudBag_Cfg[BagSet][Container][Value.SavedVar]) ~= "number") then
						BaudBag_DebugMsg("- BagSet["..BagSet.."], Bag["..Bag.."], Container["..Container.."] Slider["..Value.SavedVar.."] data damaged or missing, creating now");
            BaudBag_Cfg[BagSet][Container][Value.SavedVar] = (Bag==-2) and (Value.SavedVar=="Columns") and 4 or Value.Default[BagSet];
          end
        end
        
        for Key, Value in ipairs(CheckButtons)do
          if (type(BaudBag_Cfg[BagSet][Container][Value.SavedVar]) ~= "boolean") then
						BaudBag_DebugMsg("- BagSet["..BagSet.."], Bag["..Bag.."], Container["..Container.."] CheckBox["..Value.SavedVar.."] data damaged or missing, creating now");
            BaudBag_Cfg[BagSet][Container][Value.SavedVar] = Value.Default;
          end
        end
      end
    end);
  end

  --BaudUpdateJoinedBags();
  --BaudBagUpdateBagFrames();
  --BaudBagOptionsUpdate();
  
  return CopyTable(BaudBag_Cfg);
end

function BaudBagSaveCfg(Config)
	BaudBag_Cfg = CopyTable(Config);
end