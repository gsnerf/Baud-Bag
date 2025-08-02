---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

--[[--------------------------------------------------------------------------------
--------------------- hooks for dynamic extension of features ----------------------
----------------------------------------------------------------------------------]]

--[[ use this hook to extend any essential base types that the rest of the addon system will use, like BagSetType etc. ]]
function AddOnTable:ExtendBaseTypes()
    -- intentionally empty hook for feature extensions
end

--[[ this hook will be called when all the essential data has been initialized, use this to initialize your stuff that depends on that essential data ]]
function AddOnTable:EssentialsLoaded()
    -- intentionally empty hook to allow usage of dynamic features
end

--[[ use this hook to register events for your feature ]]
function AddOnTable:RegisterEvents(self)
    --intentionally empty hook to allow usage of dynamic features
end

---This hook will be called when the container manu is being created.
---@param menuGroup Frame use as parent when creating your CheckButton type entries
---@param addedButtons table add your created buttons here for them to be added to the actual menu after hook has been executed
function AddOnTable:ExtendContainerMenuWithGeneralEntriesForBackpack(menuGroup, addedButtons)
    -- intentionally empty hook to allow usage of dynamic features
end