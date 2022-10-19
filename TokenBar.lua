--[[
	This handles mostly everything that has to do with the TokenFrame in the Backpack container.
	As the control of which tokens should be shown in the backpack is controlled by the default blizzard ui for tokens,
	its needed to first save and then overwrite the original functions, so that it can be decided here
	wether this AddOn needs to handle the token, or wether the original frames need to be called.
	The original frame has to be called in two cases:
	1. BaudBag is not enabled for the backpack
	2. The user disabled to show the frame in the options (TODO: not implemented yet!!!)

	Additionally to the self rendering in our bags (done in BaudBag.lua BaudBagUpdateBackground()) the max trackable tokens are raised to 5.
  ]]
local AddOnName, AddOnTable = ...
local _

local function calculateScaleFix(TokenFrame)
    local scale = TokenFrame:GetEffectiveScale()
    local scaleFix = 5 - math.ceil(scale / 0.2)
    AddOnTable.Functions.DebugMessage("Token", "Applying scale fix (scale, scaleFix)", scale, scaleFix)
    return scaleFix
end

-- this is being called (among others) when the currency selection in the token frame changes
local TokenFrame_Update = function()
    AddOnTable.Functions.DebugMessage("Token", "Update was called on TokenFrame")
    -- make sure the old is called when BaudBag is disabled for the backpack
    if (BBConfig and BBConfig[1].Enabled == false) then
        AddOnTable.Functions.DebugMessage("Token", "BaudBag disabled for Backpack, skipping!")
        return
    end
	
    -- get the token frame and reset to default values (will be updated below)
    local backpackContainer = _G["BaudBagContainer1_1"]
    backpackContainer.TokenFrame:Update()
end
hooksecurefunc("BackpackTokenFrame_Update", TokenFrame_Update)


-- this is being called (among others) when the currency selection in the token frame changes
local ManageTokenFrame = function(backpack)
    AddOnTable.Functions.DebugMessage("Token", "Manage was called on TokenFrame")
    if (BBConfig and BBConfig[1].Enabled == false) then
        AddOnTable.Functions.DebugMessage("Token", "BaudBag disabled for Backpack, ignoring!")
        return
    end
	
    -- get references to all frames needed for the management
    local TokenFrame = _G["BaudBagContainer1_1TokenFrame"]
    local Backpack   = _G["BaudBagContainer1_1"]

    if (TokenFrame.shouldShow == 1) and (not TokenFrame:IsShown()) then
        AddOnTable.Functions.DebugMessage("Token", "Manage: TokenFrame visible, update settings")
        TokenFrame:Show()
        BaudBagUpdateContainer(Backpack)
    elseif (TokenFrame.shouldShow ~= 1 and TokenFrame:IsShown()) then
        AddOnTable.Functions.DebugMessage("Token", "Manage: TokenFrame NOT visible, hide it")
        TokenFrame:Hide()
        BaudBagUpdateContainer(Backpack)
    end
end
hooksecurefunc("ManageBackpackTokenFrame", ManageTokenFrame)


BaudBagTokenMixin = {}

function BaudBagTokenMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetBackpackToken(self:GetID())
end

function BaudBagTokenMixin:OnLeave()
    GameTooltip:Hide()
end

function BaudBagTokenMixin:OnClick()
    if ( IsModifiedClick("CHATLINK") ) then
        HandleModifiedItemClick(C_CurrencyInfo.GetCurrencyLink(self.currencyType, self.amount))
    end
end

BaudBagTokenFrameMixin = {}

function BaudBagTokenFrameMixin:RenderBackground(texturesParentName)
    local container = self:GetParent()
    AddOnTable.Functions.DebugMessage("Token", "Showing Token Frame for Container (Name, ID)'", container:GetName(), container:GetID())
    
    -- init texture helper
    local helper = AddOnTable:GetTextureHelper()
    helper.Parent = _G[texturesParentName]
    helper.File = "Interface\\ContainerFrame\\UI-Backpack-TokenFrame.blp"
    helper.Width, helper.Height = 256, 32

    local TargetHeight =  self:GetHeight()

    Texture = helper:GetTexturePiece("TokensFillLeft", 7,13, 6,24, nil, TargetHeight)
    Texture:SetPoint("LEFT", texturesParentName.."Left", "RIGHT")
    Texture:SetPoint("BOTTOM", texturesParentName.."Bottom", "TOP", 0, 0)

    Texture = helper:GetTexturePiece("TokensFillRight", 165,171, 6,24, nil, TargetHeight)
    Texture:SetPoint("RIGHT", texturesParentName.."Right", "LEFT")
    Texture:SetPoint("BOTTOM", texturesParentName.."Bottom", "TOP", 0, 0)

    Texture = helper:GetTexturePiece("TokensFillCenter", 14,164, 6,24, nil, TargetHeight)
    Texture:SetPoint("LEFT", texturesParentName.."TokensFillLeft", "RIGHT")
    Texture:SetPoint("RIGHT", texturesParentName.."TokensFillRight", "LEFT")
end

function BaudBagTokenFrameMixin:Update()
    -- init runtime variables
    self.shouldShow = 0
    self.numWatchedTokens = 0

        -- do whatever the original does but for our own frame
    local watchButton
    local digits, countSize
    local usedWidth = 0
    local digitWidth = 8 + calculateScaleFix(self)
    for i=1, MAX_WATCHED_TOKENS do
        local currencyInfo = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
        watchButton = self["Token"..i]

        -- Update watched tokens
        if ( currencyInfo ) then
            AddOnTable.Functions.DebugMessage("Token", "Update: Token "..i.." found")
			
            -- set icon
            watchButton.Icon:SetTexture(currencyInfo.iconFileID)
			
            -- and quantity
            if ( currencyInfo.quantity <= 99999 ) then
                watchButton.Quantity:SetText(currencyInfo.quantity)
            else
                watchButton.Quantity:SetText("*")
            end
			
            -- update width based on text to show
            digits = string.len(tostring(currencyInfo.quantity))
            AddOnTable.Functions.DebugMessage("Token", "number of digits in currency '"..currencyInfo.name.."': "..digits)
            countSize = digits * digitWidth + math.floor(6 / digits)
            watchButton.Quantity:SetWidth(countSize)
            -- 12 (icon width) + 1 (space between quantity & icon) + quantity width + 5 (space to the left)
            watchButton:SetWidth(18 + countSize)

            -- recalc used width now
            usedWidth = usedWidth + watchButton:GetWidth()
            AddOnTable.Functions.DebugMessage("Token", "used width after currency '"..currencyInfo.name.."': "..usedWidth.." space available: "..self:GetWidth())
			
            -- make only visible if there is enough space 
            watchButton:Hide()
            if (usedWidth < self:GetWidth()) then
                watchButton:Show()
                watchButton.currencyType = currencyInfo.currencyTypesID
                watchButton.amount = currencyInfo.quantity
                self.shouldShow = 1
                self.numWatchedTokens = i
            end
        else
            AddOnTable.Functions.DebugMessage("Token", "Update: Token "..i.." NOT found")
            watchButton:Hide()
            watchButton.currencyType = nil
            watchButton.amount = 0
            if ( i == 1 ) then
                AddOnTable.Functions.DebugMessage("Token", "Update: Token 1 => hiding backpack")
                self.shouldShow = 0
            end
        end
    end
end