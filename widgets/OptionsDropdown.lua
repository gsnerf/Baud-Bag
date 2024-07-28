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
    -- nothing to be done, this happens automatically here
end