---@class AddonNamespace
local AddOnTable = select(2, ...)
local Localized = AddOnTable.Localized
local _

local Prefix = "BaudBag"
local LastBagID = AddOnTable.BlizzConstants.ACCOUNT_BANK_LAST_SUB_CONTAINER

local BagsSearched = {}

function BaudBagSearchFrame_ShowFrame(parentContainer, scale, themeId)
    local SearchFrame	= BaudBagSearchFrame
    local Backdrop		= SearchFrame.Backdrop
    local EditBox		= SearchFrame.EditBox
	
    -- remember the element the search frame is attached to
    SearchFrame.AttachedTo = parentContainer:GetName()
    SearchFrame:SetParent(parentContainer)
	
    local theme = AddOnTable.Themes[themeId]
    theme.SearchFrame:UpdateBackground(parentContainer, SearchFrame, Backdrop)
    theme.SearchFrame:UpdatePositions(parentContainer, SearchFrame, Backdrop)

    -- adjust the scaling according to the calling container
    SearchFrame:SetScale(scale)
	
    -- finally show it
    SearchFrame:Show()
    EditBox:SetFocus()
end

local function searchBagsForItem(searchTarget)
    -- check search text for validity
    if (false) then
        -- TODO!!!a
        return
    end
	
    -- go through all bags to find the open ones
    local SubBag, Open, Link, Name, Texture
    local Status, Result
    local bagCache, slotCache
    for _,SubBagObject in pairs(AddOnTable.SubBags) do
        SubBag = SubBagObject.Frame
        Open	= SubBag:IsShown()and SubBag:GetParent():IsShown() and not SubBag:GetParent().Closing
        bagCache = AddOnTable.Cache:GetBagCache(SubBag:GetID())

        -- if the bag is open go through its items and compare the itemname
        if (Open) then
            AddOnTable.Functions.DebugMessage("Search", "Bag is open, going through items (BagID)", Bag)
            BagsSearched[SubBagObject.ContainerId] = true

            for _, ItemButton in pairs(SubBagObject.Items) do
                slotCache = bagCache and bagCache[ItemButton.SlotIndex] or nil

                if AddOnTable.Sets[SubBag.BagSet].Type.ShouldUseCache() then
                    Link = slotCache and slotCache.Link or nil
                else
                    Link = AddOnTable.BlizzAPI.GetContainerItemLink(SubBag:GetID(), ItemButton.SlotIndex)
                end

                -- get the name for that link
                if Link then
                    -- debug message
                    local printableLink = gsub(Link, "\124", "\124\124")
                    AddOnTable.Functions.DebugMessage("Search", "Found a link (link)", printableLink)
                    _, _, Name = LinkUtil.ExtractLink(Link)
                    AddOnTable.Functions.DebugMessage("Search", "extracted name from link", Name)
                end

                -- add transparency if search active but not a result
                Texture = ItemButton
                if (Link and compareString ~= "") then
                    AddOnTable.Functions.DebugMessage("Search", "Searching (searchString, itemName)", searchTarget, Name)

                    -- first run string search and go through results later (because of error handling)
                    Status, Result = pcall(string.find, string.lower(Name), string.lower(searchTarget))

                    -- find was run successfull: act depending on result
                    if (Status) then
                        --if (string.find(string.lower(Name), string.lower(target)) == nil) then
                        if (Result == nil) then
                            AddOnTable.Functions.DebugMessage("Search", "Itemname does not match")
                            Texture:SetAlpha(0.2)
                        else
                            AddOnTable.Functions.DebugMessage("Search", "Item seems to match")
                            Texture:SetAlpha(1)
                        end
                        -- find failed, create debug message
                    else
                        AddOnTable.Functions.DebugMessage("Search", "current search creates problem (result)", Result)
                        return
                    end
                else
                    Texture:SetAlpha(1)
                end
            end
        end
    end
end

function BaudBagSearchFrameEditBox_OnTextChanged(self, isUserInput)
    AddOnTable.Functions.DebugMessage("Search", "Changed search phrase, searching open bags")
    local compareString = self:GetText()
    searchBagsForItem(compareString)
end

local function RemoveSearchHighlights()
    local SubBagObject
    for Bag,Searched in  pairs(BagsSearched) do
        if (Searched) then
            SubBagObject = AddOnTable.SubBags[Bag]
            for _,ItemButton in pairs(SubBagObject.Items) do
                ItemButton:SetAlpha(1)
            end
            BagsSearched[Bag] = false
        end
    end
end

--[[
if the SearchFrame is hidden the search text and any existing search markers needs to be cleared
]]--
function BaudBagSearchFrame_OnHide(self, event, ...)
    self.EditBox:SetText("")
    self.AttachedTo = nil
    RemoveSearchHighlights()
end

function BaudBagSearchFrame_CheckClose(caller)
    AddOnTable.Functions.DebugMessage("Search", "Checking if searchframe needs to be closed:")
    if (BaudBagSearchFrame:IsVisible()) then
        AddOnTable.Functions.DebugMessage("Search", "(sourceName, attachedTo)", caller:GetName(), BaudBagSearchFrame.AttachedTo)
        local isSelf		= (caller:GetName() == BaudBagSearchFrame:GetName())
        local isAttached	= (caller:GetName() == BaudBagSearchFrame.AttachedTo)
        local isClosed		= _G[BaudBagSearchFrame.AttachedTo].Closing or (not _G[BaudBagSearchFrame.AttachedTo]:IsVisible())
		
        AddOnTable.Functions.DebugMessage("Search", "isSelf, isAttached, isClosed", isSelf, isAttached, isClosed)
        if (isSelf or (isAttached and isClosed)) then
            BaudBagSearchFrame:Hide()
        end
    end
end
