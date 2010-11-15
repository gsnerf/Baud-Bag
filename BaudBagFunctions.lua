-- Author      : gsnerf
-- Create Date : 11/14/2010 11:52:55 PM

local BaudBag_Debug = true;

function BaudBag_DebugMsg(msg)
  if BaudBag_Debug then
    DEFAULT_CHAT_FRAME:AddMessage(msg);
  end
end

--[[
	This function takes a set of bags and a function, and then applies the function to each bag of the set.
	The function gets the parameters: 1. Bag, 2. Index
]]--
function BaudBagForEachBag(BagSet, Func)
--[[
	BagsSet Indices:
		1 == inventory; 2 == bank
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