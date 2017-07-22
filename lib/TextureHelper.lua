local AddOnName, AddOnTable = ...
local _

local Prototype = {
    File,
    Parent,
    Width,
    Height,
    DefaultLayer = "BACKGROUND"
}

--- Creates a new Texture inside the current value of Parent.
-- The image is read from the currently set File which has the currently set Width and Height.
-- Those values are needed to calculate the correct relative values for left/right/top/bottom.
-- @param Name Value to use for creating the new texture
-- @param MinX The left most pixel of the texture image
-- @param MaxX The right most pixel of the texture image
-- @param MinY The top most pixel of the texture image
-- @param MaxY The bottom most pixel of the texture image
-- @param[opt=MaxX - MinX + 1] Width The target width
-- @param[opt=MaxY - MinY + 1] Height The target height
-- @param[opt="BACKGROUND"] Layer The layer to write the texture to
function Prototype:GetTexturePiece(Name, MinX, MaxX, MinY, MaxY, Width, Height, Layer)
    -- handle optional parameters
    Layer = Layer or self.DefaultLayer
    Width = Width or (MaxX - MinX + 1)
    Height = Height or (MaxY - MinY + 1)

    local Texture = _G[self.Parent:GetName()..Name]
    if not Texture then
        Texture = self.Parent:CreateTexture(self.Parent:GetName()..Name)
    end

    Texture:ClearAllPoints()
    Texture:SetTexture(self.File)
    Texture:SetTexCoord(MinX / self.Width, (MaxX + 1) / self.Width, MinY / self.Height, (MaxY + 1) / self.Height)
    Texture:SetWidth(Width)
    Texture:SetHeight(Height)
    Texture:SetDrawLayer(Layer)
    Texture:Show()
    
    return Texture
end

local Metatable = { __index = Prototype }

function AddOnTable:GetTextureHelper()
    if AddOnTable.TextureHelper == nil then
        AddOnTable.TextureHelper = _G.setmetatable({}, Metatable)
    end

    return AddOnTable.TextureHelper
end