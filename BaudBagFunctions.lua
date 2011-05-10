﻿-- Author      : gsnerf
-- Create Date : 11/14/2010 11:52:55 PM

local BaudBag_DebugCfg = {
	{ Name = "Config", Active = false},
	{ Name = "Options", Active = false},
	{ Name = "Token", Active = false},
	{ Name = "Bags", Active = false},
	{ Name = "Bank", Active = false},
	{ Name = "Search", Active = false},
	{ Name = "Bag Hover", Active = false},
	{ Name = "Bag Opening", Active = false}
};

function BaudBag_DebugMsg(type, msg)
	if (BaudBag_DebugCfg[type].Active) then
		DEFAULT_CHAT_FRAME:AddMessage(GetTime().." BaudBag ("..BaudBag_DebugCfg[type].Name.."): "..msg);
	end
end


--[[
	This function takes a set of bags and a function, and then applies the function to each bag of the set.
	The function gets the parameters: 1. Bag, 2. Index
]]--
function BaudBagForEachBag(BagSet, Func)
--[[
	BagsSet Indices:
		 1 == inventory;   2 == bank
	Bag Indices:
		-4 == tokens bag; -2 == keyring;          -1 == bank
		 0 == backpack;  1-4 == inventory bags; 5-11 == bank bags
]]--
  if (BagSet==1) then
		-- regular bags
    for Bag = 1, 5 do
      Func(Bag - 1, Bag);
    end
    -- keyring
    Func(-2, 6);
  else
		-- bank
    Func(-1, 1);
    -- bank bags
    for Bag = 1, NUM_BANKBAGSLOTS do
      Func(Bag + 4, Bag + 1);
    end
  end
end


function BaudBagCopyTable(Value)
	-- end of possible recursion
  if (type(Value) ~= "table") then
    return Value;
  end
  -- create target table
  local Table = {};
  -- copy all entries of the source table
  table.foreach(Value, function(k,v) Table[k] = BaudBagCopyTable(v) end);
  return Table;
end


function ShowHyperlink(Owner, Link)
  local ItemString = strmatch(Link or "","(item[%d:%-]+)");
  if not ItemString then
    return;
  end
  if(Owner:GetRight() >= (GetScreenWidth() / 2))then
    GameTooltip:SetOwner(Owner, "ANCHOR_LEFT");
  else
    GameTooltip:SetOwner(Owner, "ANCHOR_RIGHT");
  end
  GameTooltip:SetHyperlink(ItemString);
  return true;
end

function BaudBag_InitTexturePiece(Texture, File, Width, Height, MinX, MaxX, MinY, MaxY, Layer)
  Texture:ClearAllPoints();
  -- Texture:SetTexture(1.0, 0, 0, 1);
  Texture:SetTexture(File);
  Texture:SetTexCoord(MinX / Width, (MaxX + 1) / Width, MinY / Height, (MaxY + 1) / Height);
  Texture:SetWidth(MaxX - MinX + 1);
  Texture:SetHeight(MaxY - MinY + 1);
  Texture:SetDrawLayer(Layer);
  Texture:Show();
end