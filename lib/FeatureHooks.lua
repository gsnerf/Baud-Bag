local AddOnName, AddOnTable = ...
local _

--[[--------------------------------------------------------------------------------
--------------------- hooks for dynamic extension of features ----------------------
----------------------------------------------------------------------------------]]

--[[ use this hook to extend any essential base types that the rest of the addon system will use, like BagSetType etc. ]]
function AddOnTable:ExtendBaseTypes()
    -- intentionally empty hook for feature extensions
end

--[[ so you added a new bag set type... now is the time to create the according bag set ]]
function AddOnTable:InitBagSets()
    -- intentionally empty hook for feature extensions
end

--[[ this hook will be called when all the essential data has been initialized, use this to initialize your stuff that depends on that essential data ]]
function AddOnTable:EssentialsLoaded()
    -- intentionally empty hook to allow usage of dynamic features
end