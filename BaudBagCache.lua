--[[
    The cache can be accessed through AddOnTable.Cache and is persisted through the saved variable BaudBag_Cache.
    It has the following structure (values are initial and may be overwritten):
    
    BaudBag_Cache = {
        "Void" = {}
        "Bank" = {
            -1 = { Size = NUM_BANKGENERIC_SLOTS }
            6 = { Size  = 0 }
        }
    }
]]
---@class AddonNamespace
local AddOnTable = select(2, ...)
local _
local initialized = false

local function DebugMsg(message, ...)
    AddOnTable.Functions.DebugMessage("Cache", message, ...)
end

local CacheMixin = {}

--[[ 
    This returns a boolean value wether the data of the chosen bag is cached or not.
    At the moment only: bag == bankbag
]]
function CacheMixin:UsesCache(Bag)
    local usesCache = (BBConfig[2].Enabled and ((Bag < AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER) or (AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER < Bag)) and (not AddOnTable.State.BankOpen))
    DebugMsg("[UseCache] Bag: "..Bag..", Enabled: "..(BBConfig[2].Enabled and "true" or "false")..", bank open: "..(AddOnTable.State.BankOpen and "true" or "false"), usesCache)
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

function BaudBagUpdateCachedTooltip(tooltip, bagId, slotId)
    if (bagId == nil or not AddOnTable.Cache:UsesCache(bagId)) then
        return
    end

    AddOnTable.Functions.DebugMessage("Tooltip", "[UpdateCachedTooltip] Updating tooltip with cache for bagID: "..bagId.." and itemID: "..slotId)
    
    local bagCache = AddOnTable.Cache:GetBagCache(bagId)
    if (not bagCache) then
        AddOnTable.Functions.DebugMessage("Tooltip", "[UpdateCachedTooltip] Could not show cache for bag as there is no cache entry [bagId]", bagId)
        return
    end

    local slotCache = bagCache[slotId]
    if not slotCache then
        AddOnTable.Functions.DebugMessage("Tooltip", "[UpdateCachedTooltip] Cannot show cache for item because there is no cache entry [bagId, slotId]", bagId, slotId)
        return
    end
end

--[[ hook cached tooltip to item enter events ]]
hooksecurefunc(GameTooltip, "SetBagItem", BaudBagUpdateCachedTooltip)