-- Author      : gsnerf
-- Create Date : 8/14/2013 12:20:35 PM

--[[

	The cache can be accessed through BaudBag_Cache. It has the following structure:
	BaudBag_Cache = {
		"VoidStorage" = {}
		"Bank" = {
			-1 = { Size = NUM_BANKGENERIC_SLOTS }
		}
	}
]]

--[[ 
    This function initializes the cache if it does not already exist.
    Needs to be called in ADDON_LOADED event!
  ]]
function BaudBagInitCache()
	BaudBag_DebugMsg("Cache", "initalizing cache");

	-- init cache as a whole
	if (type(BaudBag_Cache) ~= "table") then
		BaudBag_DebugMsg("Cache", "no cache found, creating new one");
		BaudBag_Cache = {};
	end

	-- init cache for bankbox (not the additional bags in the bank)
	if (type(BaudBag_Cache[-1]) ~= "table") then
		BaudBag_DebugMsg("Cache", "no bank cache found, creating new one");
		BaudBag_Cache[-1] = {Size = NUM_BANKGENERIC_SLOTS};
	end
end


--[[ 
	This returns a boolean value wether the data of the chosen bag is cached or not.
	At the moment only: bag == bankbag
  ]]
function BaudBagUseCache(Bag)
	return (((Bag==-1) or (Bag >= 5)) and not BankOpen);
end

--[[
    Access to a (bank) bags cache content. It is expected that all calls are valid
    so this method makes sure to return a valid cache object.
  ]]
function BaudBagGetBagCache(Bag)
	-- make sure the requested cache is initialized.
	if (type(BaudBag_Cache[Bag]) ~= "table") then
		BaudBag_Cache[Bag] = {Size = 0};
	end
	return BaudBag_Cache[Bag];
end



--[[ ####################################### ToolTip stuff ####################################### ]]

--[[ Show the ToolTip for a cached item ]]
function BaudBagShowCachedTooltip(self, event, ...)

	-- failsafe if the current item is not a bank item or BB is turned of for the bank
	if BBConfig and (BBConfig[2].Enabled == false) and not (self and (strsub(self:GetName(), 1, 9) == Prefix.."Bank")) then
		return;
	end

	-- show tooltip for a bag
	local Bag, Slot;
	if self.isBag then
		Bag = self:GetID();
		if BaudBagUseCache(Bag) then
			if not GameTooltip:GetItem()then
				ShowHyperlink(self, BaudBagGetBagCache(Bag).BagLink);
			end
			BaudBagModifyBagTooltip(Bag);
		end
		return;
	end

	-- show tooltip for an item inside a bag
	Bag, Slot = self:GetParent():GetID(), self:GetID();
	if not BaudBagUseCache(Bag) or GameTooltip:IsShown() or not BaudBagGetBagCache(Bag)[Slot] then
		return;
	end
	ShowHyperlink(self, BaudBagGetBagCache(Bag)[Slot].Link);
end

--[[ hook cached tooltip to item enter events ]]
hooksecurefunc("ContainerFrameItemButton_OnEnter", BaudBagShowCachedTooltip);
hooksecurefunc("BankFrameItemButton_OnEnter", BaudBagShowCachedTooltip);
