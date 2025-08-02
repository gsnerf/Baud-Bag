--[[
    The cache can be accessed through AddOnTable.Cache and is persisted through the saved variable BaudBag_Cache.
    It has the following structure (values are initial and may be overwritten):
    
    BaudBag_Cache = {
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

---@class SlotCache
---@field Link string item link
---@field Count integer number of items in the stack

---@class BagCache
---@field Size integer number of item slots in the bag
---@field TabData TabData|nil optional data for warband banks
---@field BagLink string optional item link for the bag (usually bank bags)
---@field BagCount integer number of items in the bag stack (that doesn't really make sense, does it?)

---@class Cache
local CacheMixin = {}

--[[ 
    This returns a boolean value wether the data of the chosen bag is cached or not.
    At the moment only: bag == bankbag
]]
function CacheMixin:UsesCache(Bag)
    for _, bagSetType in pairs(BagSetType) do
        if bagSetType.IsSubContainerOf(Bag) then
            return bagSetType.SupportsCache and bagSetType.ShouldUseCache(Bag)
        end
    end
    -- fallback
    local usesCache = (BBConfig[2].Enabled and ((Bag < AddOnTable.BlizzConstants.BACKPACK_FIRST_CONTAINER) or (AddOnTable.BlizzConstants.BACKPACK_LAST_CONTAINER < Bag)) and (not AddOnTable.State.BankOpen))
    DebugMsg("[UseCache] Bag: "..Bag..", Enabled: "..(BBConfig[2].Enabled and "true" or "false")..", bank open: "..(AddOnTable.State.BankOpen and "true" or "false"), usesCache)
    return usesCache
end


--[[
    Access to a (bank) bags cache content. It is expected that all calls are valid
    so this method makes sure to return a valid cache object.
]]
function CacheMixin:GetBagCache(bag)
    local bagSetType = AddOnTable.Functions.GetBagSetTypeForBag(bag)

    if bagSetType == nil or not bagSetType.SupportsCache then return end

    -- make sure the requested cache is initialized.
    DebugMsg("[GetBagCache] Bag: "..bag..", cache entry type: "..type(self[bagSetType.TypeName][bag]), self[bagSetType.TypeName])
    if (type(self[bagSetType.TypeName][bag]) ~= "table") then
        self[bagSetType.TypeName][bag] = {Size = 0}
    end
    
    return self[bagSetType.TypeName][bag]
end

---@param bagSetType BagSetTypeClass
local function initCacheForBagSetType(bagSetType)
    if (type(BaudBag_Cache[bagSetType.TypeName]) ~= "table") then
        DebugMsg("cache for bag set '"..bagSetType.TypeName.."' missing or broken, creating new one")
        -- wrapper for everything bank specific
        BaudBag_Cache[bagSetType.TypeName] = {}
    end
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

    -- init caches for all bagsets that support it
    for _, bagSetType in pairs(BagSetType) do
        if (bagSetType.SupportsCache) then
            initCacheForBagSetType(bagSetType)
        end
    end

    initialized = true
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