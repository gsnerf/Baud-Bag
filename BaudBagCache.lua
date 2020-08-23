--[[
    The cache can be accessed through AddOnTable.Cache and is persisted through the saved variable BaudBag_Cache.
    It has the following structure (values are initial and may be overwritten):
    
    BaudBag_Cache = {
        "Void" = {}
        "Bank" = {
            -1 = { Size = NUM_BANKGENERIC_SLOTS }
            5 = { Size  = 0 }
        }
    }
]]
local AddOnName, AddOnTable = ...
local _
local initialized = false

local function DebugMsg(message, ...)
    BaudBag_DebugMsg("Cache", message, ...)
end

local CacheMixin = {}

--[[ 
    This returns a boolean value wether the data of the chosen bag is cached or not.
    At the moment only: bag == bankbag
]]
function CacheMixin:UsesCache(Bag)
    local usesCache = (BBConfig[2].Enabled and ((Bag < 0) or (Bag >= 5)) and (not BaudBagFrame.BankOpen))
    DebugMsg("[UseCache] Bag: "..Bag..", Enabled: "..(BBConfig[2].Enabled and "true" or "false")..", bank open: "..(BaudBagFrame.BankOpen and "true" or "false"), usesCache)
    return usesCache
end


--[[
    Access to a (bank) bags cache content. It is expected that all calls are valid
    so this method makes sure to return a valid cache object.
]]
function CacheMixin:GetBagCache(bag)
    -- make sure the requested cache is initialized.
    --if (self:UsesCache(bag) and type(self.Bank[bag]) ~= "table") then
    if (type(self.Bank[bag]) ~= "table") then
        DebugMsg("[GetBagCache] Bag: "..bag..", cache entry type: "..type(self.Bank[bag]), self.Bank)
        self.Bank[bag] = {Size = 0}
    end
    return self.Bank[bag]
end


--[[
    This function initializes the cache if it does not already exist. Needs to be called in ADDON_LOADED event!
]]
function AddOnTable:InitCache()
    -- this method is currently called twice (because of ... reasons ...)
    if initialized then
        return
    end

    DebugMsg("initalizing cache")

    -- we might have a saved cache
    if (type(BaudBag_Cache) ~= "table") then
        DebugMsg("no cache found, creating new one")
        BaudBag_Cache = {}
    end
    BaudBag_Cache = Mixin(BaudBag_Cache, CacheMixin)
    AddOnTable.Cache = BaudBag_Cache

    -- init bank cache
    if (type(BaudBag_Cache.Bank) ~= "table") then
        DebugMsg("bank cache missing or broken, creating new one")
        -- wrapper for everything bank specific
        BaudBag_Cache.Bank = {}
        -- the bank box (not the additional bags in the bank)
        BaudBag_Cache.Bank[-1] = { Size = NUM_BANKGENERIC_SLOTS }
    end
	
    -- init void cache
    if (type(BaudBag_Cache.Void) ~= "table") then
        DebugMsg("void cache missing or broken, creating new one")
        BaudBag_Cache.Void = {}
    end

    initialized = true
end

function BaudBagGetVoidCache()
    return BaudBag_Cache.Void
end


--[[ ####################################### ToolTip stuff ####################################### ]]

--[[ Show the ToolTip for a cached item ]]
function BaudBagShowCachedTooltip(self, event, ...)
    local bagId = (self.isBag) and self.Bag or self:GetParent():GetID()
    local slotId = (not self.isBag) and self:GetID() or nil

    if (not AddOnTable.Cache:UsesCache(bagId)) then
        return
    end
    
    -- show tooltip for a bag
    local bagCache = AddOnTable.Cache:GetBagCache(bagId)
    if self.isBag then
        if (not bagCache) then
            BaudBag_DebugMsg("Tooltip", "[ShowCachedTooltip] Could not show cache for bag as there is no cache entry [bagId]", bagId)
            return
        end
        
        BaudBag_DebugMsg("Tooltip", "[ShowCachedTooltip] Showing cache for bag [bagId, cacheEntry]", bagId, bagCache.BagLink)
        ShowHyperlink(self, bagCache.BagLink)
        BaudBagModifyBagTooltip(bagId)
        return
    end

    -- show tooltip for an item inside a bag
    local slotCache = bagCache[slotId]
    if not slotCache then
        BaudBag_DebugMsg("Tooltip", "[ShowCachedTooltip] Cannot show cache for item because there is no cache entry [bagId, slotId]", bagId, slotId)
        return
    end
    BaudBag_DebugMsg("Tooltip", "[ShowCachedTooltip] Showing cached item info [bagId, slotId, cachEntry]", bagId, slotId, slotCache.Link)
    ShowHyperlink(self, slotCache.Link)
end

function BaudBagUpdateCachedTooltip(tooltip, bagId, slotId)
    if (not AddOnTable.Cache:UsesCache(bagId)) then
        return
    end

    BaudBag_DebugMsg("Tooltip", "[UpdateCachedTooltip] Updating tooltip with cache for bagID: "..bagId.." and itemID: "..slotId)
    
    local bagCache = AddOnTable.Cache:GetBagCache(bagId)
    if (not bagCache) then
        BaudBag_DebugMsg("Tooltip", "[UpdateCachedTooltip] Could not show cache for bag as there is no cache entry [bagId]", bagId)
        return
    end

    local slotCache = bagCache[slotId]
    if not slotCache then
        BaudBag_DebugMsg("Tooltip", "[UpdateCachedTooltip] Cannot show cache for item because there is no cache entry [bagId, slotId]", bagId, slotId)
        return
    end

    local ItemString = strmatch(slotCache.Link or "","(item[%d:%-]+)")
    if not ItemString then
        return;
    end
    GameTooltip:SetHyperlink(ItemString)
end

--[[ hook cached tooltip to item enter events ]]
hooksecurefunc("BankFrameItemButton_OnEnter", BaudBagShowCachedTooltip)
hooksecurefunc(GameTooltip, "SetBagItem", BaudBagUpdateCachedTooltip)