local AddOnName, AddOnTable = ...
local Localized = AddOnTable.Localized
local _

local Prefix = "BaudBag"
local LastBagID = AddOnTable.BlizzConstants.BANK_LAST_CONTAINER

local BagsSearched = {}

function BaudBagSearchFrame_ShowFrame(ParentContainer, Scale, Background)
    local SearchFrame	= BaudBagSearchFrame
    local Backdrop		= SearchFrame.Backdrop
    local EditBox		= SearchFrame.EditBox
    local BagSearchHeightOffset = 0
    local BagSearchHeight		= 20
	
    -- remember the element the search frame is attached to
    SearchFrame.AttachedTo = ParentContainer:GetName()
    SearchFrame:SetParent(ParentContainer)
	
    -- draw the background depending on the containers background
    Backdrop:SetFrameLevel(SearchFrame:GetFrameLevel());
    local Left, Right, Top, Bottom
	
    -- these are the default blizz-frames
    if (Background <= 3) then

        Left, Right, Top, Bottom	= 10, 10, 25, 7
        BagSearchHeightOffset		= 22
        local Parent = Backdrop.Textures:GetName()
        local Texture
		
        -- initialize texture helper
        local helper = AddOnTable:GetTextureHelper()
        helper.Parent = Backdrop.Textures
        helper.Parent:SetFrameLevel(ParentContainer:GetFrameLevel())
        helper.Width, helper.Height = 256, 512
        helper.File = "Interface\\ContainerFrame\\UI-Bag-Components"
        if (Background == 2) then
            helper.File = helper.File.."-Bank"
        elseif(Background == 3)then
            helper.File = helper.File.."-Keyring"
        end
        helper.DefaultLayer = "ARTWORK"


        -- --------------------------
        -- create new textures now
        -- --------------------------
        -- BORDERS FIRST
        -- transparent circle top left
        Texture = helper:GetTexturePiece("Left", 106, 117, 5, 30)
        Texture:SetPoint("TOPLEFT")

        -- right end of header + transparent piece for close button (with or without blank part on the bottom)
        Texture = helper:GetTexturePiece("Right", 223, 252, 5, 30)
        Texture:SetPoint("TOPRIGHT")

        -- container header (contains name, with or without blank part on the bottom)
        Texture = helper:GetTexturePiece("Center", 117, 222, 5, 30)
        Texture:SetPoint("TOP")
        Texture:SetPoint("RIGHT", Parent.."Right", "LEFT")
        Texture:SetPoint("LEFT", Parent.."Left", "RIGHT")

        -- fix positions of some elements
        SearchFrame.CloseButton:SetPoint("TOPRIGHT",Backdrop,"TOPRIGHT",3,3)
        SearchFrame.EditBox:SetPoint("TOPLEFT", -1, 18)
		
        -- make sure the backdrop of "else" is removed and the texture is actually shown
        Backdrop:SetBackdrop(nil)
        helper.Parent:Show()
    else
        Left, Right, Top, Bottom = 8, 8, 8, 8
        BagSearchHeightOffset = 32
        BagSearchHeight	= 12
        Backdrop.Textures:Hide()
        SearchFrame.CloseButton:SetPoint("TOPRIGHT", 9, 10)
        SearchFrame.EditBox:SetPoint("TOPLEFT", -1, 0)
		
        if (Background == 5) then
            -- "solid"
            Backdrop:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 8, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 }
            })
            Left, Right, Top, Bottom = Left+8, Right+8, Top+8, Bottom+8
            BagSearchHeightOffset = BagSearchHeightOffset + 8
            Backdrop:SetBackdropColor(0.1, 0.1, 0.1, 1)
        elseif (Background == 6) then
            -- "transparent2"
            Backdrop:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                tile = true, tileSize = 14, edgeSize = 14,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            Backdrop:SetBackdropColor(0.0, 0.0, 0.0, 0.6)
        else
            -- "transparent"
            Backdrop:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 14, edgeSize = 14,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            Backdrop:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
        end
    end
	
    -- correct the sizes depending on the frame backdrop
    Backdrop:ClearAllPoints()
    Backdrop:SetPoint("TOPLEFT", -Left, Top)
    Backdrop:SetPoint("BOTTOMRIGHT", Right, -Bottom)
    SearchFrame:SetHitRectInsets(-Left, -Right, -Top, -Bottom)
	
    -- position the frame above the calling container
    SearchFrame:ClearAllPoints()
    SearchFrame:SetPoint("BOTTOMLEFT", ParentContainer, "TOPLEFT", 0, BagSearchHeightOffset)
    SearchFrame:SetPoint("RIGHT", ParentContainer, "RIGHT")
    SearchFrame:SetHeight(BagSearchHeight)
	
    -- make sure the frame lies on the same lvl as the calling container
    SearchFrame:SetFrameLevel(ParentContainer:GetFrameLevel())
    Backdrop:SetFrameLevel(SearchFrame:GetFrameLevel())
    SearchFrame.CloseButton:SetFrameLevel(SearchFrame:GetFrameLevel()+1)
    SearchFrame.EditBox:SetFrameLevel(SearchFrame:GetFrameLevel()+1)
	
    -- adjust the scaling according to the calling container
    SearchFrame:SetScale(Scale)
	
    -- finally show it
    SearchFrame:Show()
    EditBox:SetFocus()
end

local function isSupportedBag(bagId)
    if (bagId == AddOnTable.BlizzConstants.KEYRING_CONTAINER) then
        return false
    end

    if (bagId == AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER and not AddOnTable.State.ReagentBankSupported) then
        return false
    end
    
    return true
end

function BaudBagSearchFrameEditBox_OnTextChanged(self, isUserInput)
    AddOnTable.Functions.DebugMessage("Search", "Changed search phrase, searching open bags")
    local compareString = self:GetText()
	
    -- check search text for validity
    if (false) then
        -- TODO!!!a
        return
    end
	
    -- go through all bags to find the open ones
    local SubBagObject, SubBag, Frame, Open, ItemButton, Link, Name, Texture
    local Status, Result
    local bagCache, slotCache
    for Bag = AddOnTable.BlizzConstants.REAGENTBANK_CONTAINER, LastBagID do
        if isSupportedBag(Bag) then
            SubBagObject = AddOnTable.SubBags[Bag]
            SubBag = SubBagObject.Frame
            Open	= SubBag:IsShown()and SubBag:GetParent():IsShown() and not SubBag:GetParent().Closing
            bagCache = AddOnTable.Cache:GetBagCache(SubBag:GetID())

            -- if the bag is open go through its items and compare the itemname
            if (Open) then
                AddOnTable.Functions.DebugMessage("Search", "Bag is open, going through items (BagID)", Bag)
                BagsSearched[Bag] = true

                for Slot = 1, SubBagObject.BagSet.GetSize(Bag) do
                    ItemButton = _G[SubBag:GetName().."Item"..Slot]
                    slotCache = bagCache and bagCache[Slot] or nil

                    -- get item link according to the type of bag
                    if (SubBag.BagSet ~= 2) or AddOnTable.State.BankOpen then
                        Link = AddOnTable.BlizzAPI.GetContainerItemLink(SubBag:GetID(), Slot)
                    elseif slotCache then
                        Link = slotCache.Link
                    end

                    -- get the name for that link
                    if Link then
                        -- debug message
                        local printableLink = gsub(Link, "\124", "\124\124")
                        AddOnTable.Functions.DebugMessage("Search", "Found a link (link)", printableLink)

                        -- we can have different types of links, usually it is an item...
                        if (strmatch(Link, "|Hitem:")) then
                            Name, _, _, _, _, _, _, _, _, _ = AddOnTable.BlizzAPI.GetItemInfo(Link)

                            -- ... or a cages battle pet ...
                        elseif (strmatch(Link, "|Hbattlepet:")) then
                            local _, speciesID, _, _, _, _, _, battlePetID = strsplit(":", Link)
                            Name, _, _, _, _, _, _, _, _, _= C_PetJournal.GetPetInfoBySpeciesID(speciesID)

                            -- ... we don't know about everything else
                        else
                            Name = "Unknown"
                        end
                    end

                    -- add transparency if search active but not a result
                    Texture = ItemButton
                    if (Link and compareString ~= "") then
                        AddOnTable.Functions.DebugMessage("Search", "Searching (searchString, itemName)", compareString, Name)

                        -- first run string search and go through results later (because of error handling)
                        Status, Result = pcall(string.find, string.lower(Name), string.lower(compareString))

                        -- find was run successfull: act depending on result
                        if (Status) then
                            --if (string.find(string.lower(Name), string.lower(compareString)) == nil) then
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
end

local function RemoveSearchHighlights()
    local SubBagObject, SubBag, Frame, Open, ItemButton, Link, Name, Texture
    for Bag = -3, LastBagID do
        if not (Bag == -2) then
            if (BagsSearched[Bag]) then
                SubBagObject = AddOnTable.SubBags[Bag]
                SubBag = SubBagObject.Frame
                for Slot = 1, SubBagObject.BagSet.GetSize(Bag) do
                    ItemButton = _G[SubBag:GetName().."Item"..Slot]
                    ItemButton:SetAlpha(1)
                end
                BagsSearched[Bag] = false
            end
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