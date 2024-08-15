BaudBagOptionsDropdownMixin = {}

function BaudBagOptionsDropdownMixin:SetDefaultText(defaultText)
    self.Dropdown:SetDefaultText(defaultText)
end

function BaudBagOptionsDropdownMixin:Setup(menuEntriesList, isSelectedFunc, valueChangedCallback)
    local menunEntriesGenerator = function(owner, rootDescription)
        for Key, Value in pairs(menuEntriesList) do
            rootDescription:CreateRadio(Value, isSelectedFunc, valueChangedCallback, Key);
        end
    end
    self.Dropdown:SetupMenu(menunEntriesGenerator)
end

function BaudBagOptionsDropdownMixin:UpdateSelection(newIndex)
    -- this is basically only needed because the drop down needs to handle selections of multiple things that are switched behind its ass...
    self.Dropdown:SignalUpdate()
end