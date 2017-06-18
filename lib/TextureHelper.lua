local AddOnName, AddOnTable = ...
local _

local Prototype = {
    File,
    Parent,
    Width,
    Height
}

function Prototype:GetTexturePiece(Name, MinX, MaxX, MinY, MaxY, Layer)
    local Texture = _G[self.Parent:GetName()..Name];
    if not Texture then
        Texture = self.Parent:CreateTexture(self.Parent:GetName()..Name);
    end
    Texture:ClearAllPoints();
    Texture:SetTexture(self.File);
    Texture:SetTexCoord(MinX / self.Width, (MaxX + 1) / self.Width, MinY / self.Height, (MaxY + 1) / self.Height);
    Texture:SetWidth(MaxX - MinX + 1);
    Texture:SetHeight(MaxY - MinY + 1);
    Texture:SetDrawLayer(Layer);
    Texture:Show();
    --  Texture:SetVertexColor(0.2,0.2,1);
    return Texture;
end

local Metatable = { __index = Prototype }

function AddOnTable:GetTextureHelper()
    if AddOnTable.TextureHelper == nil then
        AddOnTable.TextureHelper = _G.setmetatable({}, Metatable)
    end

    return AddOnTable.TextureHelper
end