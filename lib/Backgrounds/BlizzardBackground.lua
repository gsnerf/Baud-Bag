local AddOnName, AddOnTable = ...
local _

local Prototype = {
    Id = nil,
    Name = nil,
    File = nil,
    --[[  sub tables have to be reassigned on init or ALL new elements will have the SAME tables for access... ]]
    Insets = nil
}

function Prototype:Update(containerFrame, backdrop, shiftName)
    local containerConfig = BBConfig[containerFrame.BagSet][containerFrame:GetID()]

    local cols = containerConfig.Columns
    if (containerFrame.Slots < cols) then
        cols = containerFrame.Slots
    end
    local startColumn = 0
    local blanks = cols - mod(containerFrame.Slots - 1, cols) - 1
    local blanksOnTop = containerConfig.BlankTop and (blanks ~= 0)

    local top = self.Insets.Top
    local bottom = self.Insets.Bottom
    if blanksOnTop then
        startColumn = blanks
    else
        top = top + 18
    end

    
    local Parent = backdrop.Textures:GetName()
    local Texture

    -- initialize texture helper
    local helper = AddOnTable:GetTextureHelper()
    helper.Parent = backdrop.Textures
    helper.Parent:SetFrameLevel(containerFrame:GetFrameLevel())
    helper.Width, helper.Height = 256, 512
    helper.File = self.File
    helper.DefaultLayer = "ARTWORK"

    -- --------------------------
    -- create new textures now
    -- --------------------------
    self:CreateBorderTextures(helper, blanksOnTop, Parent)
    self:FillBlanks(helper, blanks, blanksOnTop, Parent, containerFrame)
    self:CreateSlotBackgrounds(helper, containerFrame, cols, startColumn)
    self:ImproveCornerGaps(helper, containerFrame, Parent, blanks, blanksOnTop, cols)
    if (containerFrame:GetID() == 1) then
        local bottomOffset = self:AddBottomInfoBar(helper, containerFrame, bottom, Parent)
        bottom = bottom + bottomOffset
    end
    self:UpdateBagPicture(containerFrame, Parent, backdrop)
    self:AdjustPositioning(helper, containerFrame, backdrop, shiftName)

    return self.Insets.Left, self.Insets.Right, top, bottom
end

function Prototype:CreateBorderTextures(helper, blanksOnTop, parentName)
    -- transparent circle top left
    local texture = helper:GetTexturePiece("TopLeft", 65, 116, 1, 49)
    texture:SetPoint("TOPLEFT", -7, 4)

    -- right end of header + transparent piece for close button (with or without blank part on the bottom)
    texture = helper:GetTexturePiece("TopRight", 223, 252, 5, blanksOnTop and 30 or 49)
    texture:SetPoint("TOPRIGHT")

    -- bottom left round corner
    texture = helper:GetTexturePiece("BottomLeft", 72, 79, 169, 177)
    texture:SetPoint("BOTTOMLEFT")

    -- bottom right round corner
    texture = helper:GetTexturePiece("BottomRight", 247, 252, 172, 177)
    texture:SetPoint("BOTTOMRIGHT")

    -- container header (contains name, with or without blank part on the bottom)
    texture = helper:GetTexturePiece("Top", 117, 222, 5, blanksOnTop and 30 or 49)
    texture:SetPoint("TOP")
    texture:SetPoint("RIGHT", parentName.."TopRight", "LEFT")
    texture:SetPoint("LEFT", parentName.."TopLeft", "RIGHT")

    -- left border
    texture = helper:GetTexturePiece("Left", 72, 76, 182, 432)
    texture:SetPoint("LEFT")
    texture:SetPoint("BOTTOM", parentName.."BottomLeft", "TOP")
    texture:SetPoint("TOP", parentName.."TopLeft", "BOTTOM")

    -- right border
    texture = helper:GetTexturePiece("Right", 248, 252, 182, 432)
    texture:SetPoint("RIGHT")
    texture:SetPoint("BOTTOM", parentName.."BottomRight", "TOP")
    texture:SetPoint("TOP", parentName.."TopRight", "BOTTOM")

    -- bottom border
    texture = helper:GetTexturePiece("Bottom", 80, 246, 173, 177, nil, nil, "OVERLAY")
    texture:SetPoint("BOTTOM")
    texture:SetPoint("LEFT", parentName.."BottomLeft", "RIGHT")
    texture:SetPoint("RIGHT", parentName.."BottomRight", "LEFT")
end

function Prototype:FillBlanks(helper, blanks, blanksOnTop, parentName, containerFrame)
    if (blanks <= 0) then
        self:HideObject(parentName.."BlankFill")
        self:HideObject(parentName.."BlankFillEdge")
        self:HideObject(parentName.."BlankFillLeft")
        return
    end

    local width = blanks * 42
    local texture = nil
    if blanksOnTop then
        texture = helper:GetTexturePiece("BlankFillEdge", 116, 223, 31, 34)
        texture:SetPoint("TOPLEFT", parentName.."Top", "BOTTOMLEFT")
        texture:SetPoint("RIGHT", containerFrame, "LEFT", width, 0)

        texture = helper:GetTexturePiece("BlankFillLeft", 72, 116, 142, 162)
        texture:SetPoint("TOPRIGHT", parentName.."TopLeft", "BOTTOMRIGHT", 0, 3)
        texture:SetPoint("BOTTOM", containerFrame, "TOP", 0, -42)

        -- Since the texture in already stretched about double in height, try to keep the ratio
        local texWidth = (width / 2 > 107) and 107 or (width / 2)
        texture = helper:GetTexturePiece("BlankFill", 223 - texWidth, 223, 35, 49)
        texture:SetPoint("TOPRIGHT", parentName.."BlankFillEdge", "BOTTOMRIGHT")
        texture:SetPoint("BOTTOMLEFT", parentName.."BlankFillLeft", "BOTTOMRIGHT")
    else
        texture = helper:GetTexturePiece("BlankFillEdge", 245, 248, 30, 49)
        texture:SetPoint("BOTTOM", containerFrame, "BOTTOM", 0, -5)
        texture:SetPoint("RIGHT", parentName.."Right", "LEFT")
        texture:SetHeight(42)

        -- Avoids the texture becomming too compressed if the space is infact small
        local texWidth = (width > 132) and 132 or width
        texture = helper:GetTexturePiece("BlankFill", 245 - texWidth, 244, 30, 49)
        texture:SetPoint("BOTTOMRIGHT", parentName.."BlankFillEdge", "BOTTOMLEFT")
        texture:SetPoint("TOPRIGHT", parentName.."BlankFillEdge", "TOPLEFT")
        texture:SetPoint("LEFT", containerFrame, "RIGHT", -width, 0)
        self:HideObject(parentName.."BlankFillLeft")
    end
end

--[[ Width of one slot is 42, Height of one slot is 41 ]]
function Prototype:CreateSlotBackgrounds(helper, containerFrame, numberOfColumns, currentColumn)
    local row = 1
    local offsetX, offsetY = -2, -2
    for slot = 1, containerFrame.Slots do
        currentColumn = currentColumn + 1
        if (currentColumn > numberOfColumns) then
            currentColumn = 1
            row = row + 1
        end
        local texture = helper:GetTexturePiece("Slot"..slot, 118, 164, 213, 258, nil, nil, "BORDER")
        texture:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", (currentColumn - 1) * 42 + offsetX - 3, (row - 1) * -41 + 2 - offsetY)
    end
    
    -- adapt to increased container size
    if (containerFrame.Slots > (helper.Parent.Slots or -1)) then
        helper.Parent.Slots = containerFrame.Slots
    else
        -- Hide extra slot textures
        for slot = (containerFrame.Slots + 1), helper.Parent.Slots do
            _G[helper.Parent:GetName().."Slot"..slot]:Hide()
        end
    end
end

function Prototype:ImproveCornerGaps(helper, containerFrame, parentName, blanks, blanksOnTop, numberOfColumns)
    self:HideObject(parentName.."Corner")
    if (blanks > 0) then
        local slot = blanksOnTop and (numberOfColumns + 1) or (containerFrame.Slots - numberOfColumns)
        BaudBag_DebugMsg("BagBackgrounds", "There are blanks to show (affectedSlot, BlankTop, Container.Slots, Cols)", slot, blanksOnTop, containerFrame.Slots, numberOfColumns)
        if (slot >= 1) or (slot <= containerFrame.Slots) then
            if not blanksOnTop then
                local texture = helper:GetTexturePiece("Corner", 154, 164, 248, 258, nil, nil, "OVERLAY")
                texture:SetPoint("BOTTOMRIGHT", parentName.."Slot"..slot)
            else
                local texture = helper:GetTexturePiece("Corner", 118, 128, 213, 223, nil, nil, "OVERLAY")
                texture:SetPoint("TOPLEFT", parentName.."Slot"..slot)
            end
        end
    end
end

--[[ this returns the bottom offset to add to the bottom variable ]]
function Prototype:AddBottomInfoBar(helper, containerFrame, bottom, parentName)
    if (BackpackTokenFrame_IsShown() == 1 and containerFrame:GetName() == "BaudBagContainer1_1") then
        self:RenderMoneyFrameBackground(helper, containerFrame, parentName, false)
        BaudBagTokenFrame_RenderBackgrounds(containerFrame, parentName)
        return 43
    else
        -- make sure the window gets big enough and the correct texture is chosen
        self:RenderMoneyFrameBackground(helper, containerFrame, parentName)
        return 21
    end
end

function Prototype:RenderMoneyFrameBackground(helper, containerFrame, parentName, renderMoneyFrameOnly)
    renderMoneyFrameOnly = renderMoneyFrameOnly or true

    helper.Parent = _G[parentName]
    helper.File = "Interface\\ContainerFrame\\UI-BackpackBackground.blp";
    helper.Width, helper.Height = 256, 256;

    local targetHeight = containerFrame.MoneyFrame:GetHeight()
    local moneyFrameName = containerFrame.MoneyFrame:GetName()

    -- left part of ONLY the yellow border
    local texture = helper:GetTexturePiece("MoneyLineLeft", 80,84, 228,246, nil, targetHeight);
    texture:SetPoint("LEFT", parentName.."Left", "RIGHT");
    texture:SetPoint("TOP", moneyFrameName, "TOP", 0, 0);

    -- right part of ONLY the yellow border
    texture = helper:GetTexturePiece("MoneyLineRight", 240,244, 228,246, nil, targetHeight);
    texture:SetPoint("RIGHT", parentName.."Right", "LEFT");
    texture:SetPoint("TOP", moneyFrameName, "TOP", 0, 0);

    -- center part of ONLY the yellow border
    texture = helper:GetTexturePiece("MoneyLineCenter", 85,239, 228,246, nil, targetHeight);
    texture:SetPoint("LEFT", parentName.."MoneyLineLeft", "RIGHT");
    texture:SetPoint("RIGHT", parentName.."MoneyLineRight", "LEFT");
end

function Prototype:UpdateBagPicture(containerFrame, parentName, backdrop)
    local texture = _G[parentName.."Bag"]
    if not texture then
        texture = backdrop.Textures:CreateTexture(parentName.."Bag")
        texture:SetWidth(40)
        texture:SetHeight(40)
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", parentName.."TopLeft", "TOPLEFT", 3, -3)
        texture:SetDrawLayer("BACKGROUND")
    end
    
    local icon
    local bagID = containerFrame.Bags[1]:GetID()
    local bagCache = BaudBagGetBagCache(bagID)
    if (bagID <= 0) then
        icon = BaudBagIcons[bagID]
    elseif (containerFrame.BagSet == 2) and not BaudBagFrame.BankOpen and bagCache.BagLink then
        icon = GetItemIcon(bagCache.BagLink)
    else
        icon = GetInventoryItemTexture("player", ContainerIDToInventoryID(bagID))
    end
    
    SetPortraitToTexture(texture, icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    backdrop:SetBackdrop(nil)
end

function Prototype:AdjustPositioning(helper, containerFrame, backdrop, shiftName)
    containerFrame.Name:SetPoint("TOPLEFT", backdrop, "TOPLEFT", (45 + shiftName), -7)
    containerFrame.CloseButton:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", 3, 3)
    helper.Parent:Show()
    if (containerFrame:GetID() == 1) then
        if (BackpackTokenFrame_IsShown() == 1 and containerFrame:GetName() == "BaudBagContainer1_1") then
            containerFrame.TokenFrame:SetPoint("BOTTOMLEFT",  backdrop, "BOTTOMLEFT", 0, 6)
            containerFrame.TokenFrame:SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", 0, 6)
            containerFrame.MoneyFrame:SetPoint("BOTTOMRIGHT", containerFrame.TokenFrame, "TOPRIGHT", 0, -1)
            containerFrame.FreeSlots:SetPoint("BOTTOMLEFT",   containerFrame.TokenFrame, "TOPLEFT", 0, 4)
        else
            containerFrame.FreeSlots:SetPoint("BOTTOMLEFT",   backdrop, "BOTTOMLEFT", 12, 7)
            containerFrame.MoneyFrame:SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", 0, 3)
        end
    end
end

function Prototype:HideObject(Object)
    Object = _G[Object];
    if not Object then
        return;
    end
    Object:Hide();
end

local Metatable = { __index = Prototype }

function AddOnTable:CreateBlizzardBackground(id, name, file)
    local background = _G.setmetatable({}, Metatable)
    background.Id = id
    background.Name = name
    background.Insets = { Left = 10, Right = 10, Top = 25, Bottom = 7 }
    background.File = file
    
    AddOnTable["Backgrounds"][id] = background
    return bagSet
end