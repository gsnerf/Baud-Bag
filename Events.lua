local AddOnName, AddOnTable = ...
local _

AddOnTable["Events"] = {}

AddOnTable.Functions.RegisterEvents = function(self)
    for Key, _ in pairs(AddOnTable.Events) do
        self:RegisterEvent(Key)
    end
end

AddOnTable.Functions.OnEvent = function(self, event, ...)
    if AddOnTable.Events[event] then
        AddOnTable.Events[event](self, event, ...)
    end
end