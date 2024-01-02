local AddOnName, AddOnTable = ...
local _


BaudBagSelectionPopoutEntryMixin = CreateFromMixins(SelectionPopoutEntryMixin)

function BaudBagSelectionPopoutEntryMixin:OnLoad()
	SelectionPopoutEntryMixin.OnLoad(self)

	self.SelectionDetails.SelectionName:SetPoint("RIGHT")
end

function BaudBagSelectionPopoutEntryMixin:ClearNewFlag()
	self.selectionData.isNew = false
	self.parentButton:UpdatePopout()
end

function BaudBagSelectionPopoutEntryMixin:OnEnter()
	SelectionPopoutEntryMixin.OnEnter(self)

	if not self.isSelected then
		self.HighlightBGTex:SetAlpha(0.15)

		self.SelectionDetails.SelectionName:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
	end
end

function BaudBagSelectionPopoutEntryMixin:OnLeave()
	SelectionPopoutEntryMixin.OnLeave(self)

	if not self.isSelected then
		self.HighlightBGTex:SetAlpha(0)
		self.SelectionDetails:UpdateFontColors(self.selectionData, self.isSelected, self.popoutHasAFailedReq)
	end
end

BaudBagSelectionPopoutDetailsMixin = {}

function BaudBagSelectionPopoutDetailsMixin:GetTooltipText()
	local name, lockedText
	if (self.SelectionName:IsShown() and self.SelectionName:IsTruncated()) or self.lockedText or self.name=="Charger" then
		name = self.name
	end
	if self.lockedText then
		lockedText = BARBERSHOP_CUSTOMIZATION_SOURCE_FORMAT:format(self.lockedText)
	end
	return name, lockedText
end

function BaudBagSelectionPopoutDetailsMixin:AdjustWidth(multipleColumns, defaultWidth)
	local width = defaultWidth

	if self.SelectionName:IsShown() then
		if multipleColumns then
			width = 108
		end
	else
		if multipleColumns then
			width = 42
		end
	end

	if self:GetParent().popoutHasALockedChoice then
		width = width + CHAR_CUSTOMIZE_LOCK_WIDTH
	end
	self:SetWidth(Round(width))
end

local function GetNormalSelectionTextFontColor(selectionData, isSelected)
	if isSelected then
		return NORMAL_FONT_COLOR
	else
		return DISABLED_FONT_COLOR
	end
end

local eligibleChoiceColor = CreateColor(.808, 0.808, 0.808)
local ineligibleChoiceColor = CreateColor(.337, 0.337, 0.337)

local function GetFailedReqSelectionTextFontColor(selectionData, isSelected)
	if isSelected then
		return NORMAL_FONT_COLOR
	elseif selectionData.ineligibleChoice then
		return ineligibleChoiceColor
	else
		return eligibleChoiceColor
	end
end

function BaudBagSelectionPopoutDetailsMixin:GetFontColors(selectionData, isSelected, hasAFailedReq)
	if self.selectable then
		local fontColorFunction = hasAFailedReq and GetFailedReqSelectionTextFontColor or GetNormalSelectionTextFontColor
		local fontColor = fontColorFunction(selectionData, isSelected)
		local showAsNew = (selectionData.isNew and self.selectable)
		if showAsNew then
			return fontColor
		else
			return fontColor
		end
	else
		return NORMAL_FONT_COLOR
	end
end

function BaudBagSelectionPopoutDetailsMixin:UpdateFontColors(selectionData, isSelected, hasAFailedReq)
	local nameColor = self:GetFontColors(selectionData, isSelected, hasAFailedReq);
	self.SelectionName:SetTextColor(nameColor:GetRGB())
end

function BaudBagSelectionPopoutDetailsMixin:SetShowAsNew(showAsNew)
	if showAsNew then

		self.NewGlow:SetPoint("RIGHT", self.SelectionText, "LEFT", 5, -2)
		self.NewGlow:Show()
	else
		self.NewGlow:Hide()
	end
end

function BaudBagSelectionPopoutDetailsMixin:UpdateText(selectionData, isSelected, hasAFailedReq)
    local nameColor = self:GetFontColors(selectionData, isSelected, hasAFailedReq)
	self.SelectionName:SetTextColor(nameColor:GetRGB())

	if selectionData.name ~= "" then
		self.SelectionName:Show()
		self.SelectionName:SetWidth(0)
		self.SelectionName:SetText(selectionData.name)
	else
		self.SelectionName:Hide()
	end

	local showAsNew = (self.selectable and selectionData.isNew)
	self:SetShowAsNew(showAsNew)
end

function BaudBagSelectionPopoutDetailsMixin:SetupDetails(selectionData, index, isSelected, hasAFailedReq, hasALockedChoice)
	if not index then
		self.SelectionName:SetText(CHARACTER_CUSTOMIZE_POPOUT_UNSELECTED_OPTION)
		self.SelectionName:Show()
		self.SelectionName:SetWidth(0)
		self.SelectionName:SetPoint("LEFT", self, "LEFT", 0, 0)
		self:SetShowAsNew(false)
		return
	end
	self.name = selectionData.name
	self.index = index
	self.lockedText = selectionData.isLocked and selectionData.lockedText
    self.SelectionName:SetPoint("LEFT", self, "LEFT", 0, 0)

	self.LockIcon:SetShown(selectionData.isLocked)
	if self.selectable then
		if selectionData.isLocked then
			self.SelectionName:SetPoint("RIGHT", -CHAR_CUSTOMIZE_LOCK_WIDTH, 0)
		else
			self.SelectionName:SetPoint("RIGHT", 0, 0)
		end
	end

	self:UpdateText(selectionData, isSelected, hasAFailedReq)
end