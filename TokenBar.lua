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
MAX_WATCHED_TOKENS_ORIG = MAX_WATCHED_TOKENS
MAX_WATCHED_TOKENS_BAUD_BAG = 5


local function calculateScaleFix(TokenFrame)
    local scale = TokenFrame:GetEffectiveScale()
    local scaleFix = 5 - math.ceil(scale / 0.2)
    BaudBag_DebugMsg("Token", "Applying scale fix (scale, scaleFix)", scale, scaleFix)
    return scaleFix
end

local TokenFrame_Update = function()
    BaudBag_DebugMsg("Token", "Update was called on TokenFrame")
    -- make sure the old is called when BaudBag is disabled for the backpack
    if (BBConfig and BBConfig[1].Enabled == false) then
        --BaudBag_DebugMsg("Token", "BaudBag disabled for Backpack, calling original!")
        --MAX_WATCHED_TOKENS = MAX_WATCHED_TOKENS_ORIG
        --return pre_BackpackTokenFrame_Update()
        BaudBag_DebugMsg("Token", "BaudBag disabled for Backpack, skipping!")
        return
    end
	
    -- get the token frame and reset to default values (will be updated below)
    local TokenFrame = _G["BaudBagContainer1_1TokenFrame"]
    TokenFrame.shouldShow = 0
    TokenFrame.numWatchedTokens = 0

    -- do whatever the original does but for our own frame
    --MAX_WATCHED_TOKENS = MAX_WATCHED_TOKENS_BAUD_BAG -- this HAS to be done to allow more than 3 selections in the management window
    local watchButton
    local digits, countSize
    local usedWidth = 0
    local digitWidth = 8 + calculateScaleFix(TokenFrame)
    for i=1, MAX_WATCHED_TOKENS do
        local currencyInfo = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
        watchButton = TokenFrame["Token"..i]

        -- Update watched tokens
        if ( currencyInfo ) then
            BaudBag_DebugMsg("Token", "Update: Token "..i.." found")
			
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
            BaudBag_DebugMsg("Token", "number of digits in currency '"..currencyInfo.name.."': "..digits)
            countSize = digits * digitWidth + math.floor(6 / digits)
            watchButton.Quantity:SetWidth(countSize)
            -- 12 (icon width) + 1 (space between quantity & icon) + quantity width + 5 (space to the left)
            watchButton:SetWidth(18 + countSize)

            -- recalc used width now
            usedWidth = usedWidth + watchButton:GetWidth()
            BaudBag_DebugMsg("Token", "used width after currency '"..currencyInfo.name.."': "..usedWidth.." space available: "..TokenFrame:GetWidth())
			
            -- make only visible if there is enough space 
            watchButton:Hide()
            if (usedWidth < TokenFrame:GetWidth()) then
                watchButton:Show()
                watchButton.currencyType = currencyInfo.currencyTypesID
                watchButton.amount = currencyInfo.quantity
                TokenFrame.shouldShow = 1
                TokenFrame.numWatchedTokens = i
            end
        else
            BaudBag_DebugMsg("Token", "Update: Token "..i.." NOT found")
            watchButton:Hide()
            watchButton.currencyType = nil
            watchButton.amount = 0
            if ( i == 1 ) then
                BaudBag_DebugMsg("Token", "Update: Token 1 => hiding backpack")
                TokenFrame.shouldShow = 0
            end
        end
    end
end
hooksecurefunc("BackpackTokenFrame_Update", TokenFrame_Update)


local pre_GetNumWatchedTokens = GetNumWatchedTokens
GetNumWatchedTokens = function()
    -- make sure the old is called when baudbag is disabled for the bagpack
    if (BBConfig and BBConfig[1].Enabled == false) then
        BaudBag_DebugMsg("Token", "BaudBag disabled for Backpack, calling original!")
        return pre_GetNumWatchedTokens()
    end
	
    local TokenFrame = _G["BaudBagContainer1_1TokenFrame"]
	
    if (not TokenFrame.numWatchedTokens) then
        -- No count yet so get it 
        BackpackTokenFrame_Update() 
    end
    return TokenFrame.numWatchedTokens or 0
end

local pre_BackpackTokenFrame_IsShown = BackpackTokenFrame_IsShown
BackpackTokenFrame_IsShown = function()
    BaudBag_DebugMsg("Token", "IsShown was called on BaudBagTokenFrame")
    -- make sure the old is called when BaudBag is disabled for the backpack
    if (BBConfig and BBConfig[1].Enabled == false) then
        BaudBag_DebugMsg("Token", "BaudBag disabled for Backpack, calling original!")
        return pre_BackpackTokenFrame_IsShown()
    end

    return _G["BaudBagContainer1_1TokenFrame"].shouldShow 
end


local ManageTokenFrame = function(backpack)
    BaudBag_DebugMsg("Token", "Manage was called on TokenFrame")
    if (BBConfig and BBConfig[1].Enabled == false) then
        BaudBag_DebugMsg("Token", "BaudBag disabled for Backpack, ignoring!")
        return
    end
	
    -- get references to all frames needed for the management
    local TokenFrame = _G["BaudBagContainer1_1TokenFrame"]
    local Backpack   = _G["BaudBagContainer1_1"]

    if (BackpackTokenFrame_IsShown() == 1) and (not TokenFrame:IsShown()) then
        BaudBag_DebugMsg("Token", "Manage: TokenFrame visible, update settings")
        TokenFrame:Show()
        BaudBagUpdateContainer(Backpack)
    elseif (BackpackTokenFrame_IsShown() ~= 1 and TokenFrame:IsShown()) then
        BaudBag_DebugMsg("Token", "Manage: TokenFrame NOT visible, hide it")
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
    BaudBag_DebugMsg("Token", "Showing Token Frame for Container (Name, ID)'", container:GetName(), container:GetID())
    
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