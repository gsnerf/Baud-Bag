local _
local Prefix = "BaudBag"
--[[

    The cache can be accessed through BaudBag_Cache.
    It has the following structure (values are initial and may be overwritten):
	
    BaudBag_Cache = {
        "Void" = {}
        "Bank" = {
            -1 = { Size = NUM_BANKGENERIC_SLOTS }
            5 = { Size  = 0 }
        }
    }
]]

--[[ EXPERIMENTAL

BBCache = {}

function BBCache:initialize()
    BaudBag_DebugMsg("Cache", "[initialize] initializing BaudBag_Cache with object methods")
    setmetatable(BaudBag_Cache, self)
    self.__index = self
end

function BBCache:test()
     BaudBag_DebugMsg("Cache", "[test] TEST")
end

function BBCache:getBankBag(bagId)
    
end ]]

--[[ 
This function initializes the cache if it does not already exist.
Needs to be called in ADDON_LOADED event!
]]
function BaudBagInitCache()
    BaudBag_DebugMsg("Cache", "initalizing cache")

    -- init cache as a whole
    if (type(BaudBag_Cache) ~= "table") then
        BaudBag_DebugMsg("Cache", "no cache found, creating new one")
        BaudBag_Cache = {}
    end

    ---- init cache for bankbox (not the additional bags in the bank)
    --if (type(BaudBag_Cache[-1]) ~= "table") then
    --	BaudBag_DebugMsg("Cache", "no bank cache found, creating new one")
    --	BaudBag_Cache[-1] = {Size = NUM_BANKGENERIC_SLOTS}
    --end

    -- init bank cache
    if (type(BaudBag_Cache.Bank) ~= "table") then
        -- wrapper for everything bank specific
        BaudBag_Cache.Bank = {}
        -- the bank box (not the additional bags in the bank)
        BaudBag_Cache.Bank[-1] = {Size = NUM_BANKGENERIC_SLOTS}
    end
	
    -- init void cache
    if (type(BaudBag_Cache.Void) ~= "table") then
        BaudBag_Cache.Void = {}
    end
end


--[[ 
This returns a boolean value wether the data of the chosen bag is cached or not.
At the moment only: bag == bankbag
]]
function BaudBagUseCache(Bag)
    local useCache = (BBConfig[2].Enabled and ((Bag < 0) or (Bag >= 5)) and (not BaudBagFrame.BankOpen))
    BaudBag_DebugMsg("Cache", "[UseCache] Bag: "..Bag..", Enabled: "..(BBConfig[2].Enabled and "true" or "false")..", bank open: "..(BaudBagFrame.BankOpen and "true" or "false"), useCache)
    return useCache
end

--[[
Access to a (bank) bags cache content. It is expected that all calls are valid
so this method makes sure to return a valid cache object.
]]
function BaudBagGetBagCache(Bag)
    -- make sure the requested cache is initialized.
    --if (BaudBagUseCache(Bag) and type(BaudBag_Cache.Bank[Bag]) ~= "table") then
    if (type(BaudBag_Cache.Bank[Bag]) ~= "table") then
        BaudBag_DebugMsg("Cache", "[GetBagCache] Bag: "..Bag..", cache entry type: "..type(BaudBag_Cache.Bank[Bag]), BaudBag_Cache.Bank)
        BaudBag_Cache.Bank[Bag] = {Size = 0}
    end
    return BaudBag_Cache.Bank[Bag]
end

function BaudBagGetVoidCache()
    return BaudBag_Cache.Void
end


--[[ ####################################### ToolTip stuff ####################################### ]]

--[[ Show the ToolTip for a cached item ]]
function BaudBagShowCachedTooltip(self, event, ...)
    local bagId = (self.isBag) and self.Bag or self:GetParent():GetID()
    local slotId = (not self.isBag) and self:GetID() or nil

    if (not BaudBagUseCache(bagId)) then
        return
    end
    
    -- show tooltip for a bag
    local bagCache = BaudBagGetBagCache(bagId)
    if self.isBag then
        if (not bagCache) then
            BaudBag_DebugMsg("Tooltip", "[ShowCachedTooltip] Could not show cache for bag as there is no cache entry [bagId]", bagId)
            return
        end
        
        BaudBag_DebugMsg("Tooltip", "[ShowCachedTooltip] Showing cache for bag [bagId, cacheEntry]", bagId, bagCache)
        ShowHyperlink(self, bagCache.BagLink)
        return
    end

    -- show tooltip for an item inside a bag
    local slotCache = bagCache[slotId]
    if not slotCache then
        BaudBag_DebugMsg("Tooltip", "[ShowCachedTooltip] Cannot show cache for item because there is no cache entry [bagId, slotId]", bagId, slotId)
        return
    end
    BaudBag_DebugMsg("Tooltip", "[ShowCachedTooltip] Showing cached item info [bagId, slotId, cachEntry]", bagId, slotId, slotCache)
    ShowHyperlink(self, slotCache.Link)
end

--[[ hook cached tooltip to item enter events ]]
hooksecurefunc("ContainerFrameItemButton_OnEnter", BaudBagShowCachedTooltip)
hooksecurefunc("BankFrameItemButton_OnEnter", BaudBagShowCachedTooltip)
