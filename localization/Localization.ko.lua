---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

-- make sure this file stays UTF-8!
if (GetLocale() == "koKR") then
    local L = AddOnTable.Localized
    L.LockPosition = "위치 잠금"
    L.UnlockPosition = "위치 풀음"
    L.ShowBank = "은행 보이기"
    L.Options = "옵션"
    L.Free = "빈 칸"
    L.Offline = " (오프라인)"
    L.AutoOpen = "자동 열기"
    L.AutoOpenTooltip = "활성화시, (가능하다면)우편함, 상점, 혹은 은행에서 이 가방을 자동으로 엽니다."
    L.BlankOnTop = "상단 비움"
    L.BlankOnTopTooltip = "활성화시, 하단 대신에 상단에 약간의 나머지 빈공간을 집어 넣습니다."
    L.RarityColoring = "등급 색 입히기"
    L.RarityColoringTooltip = "활성화시, 아이템의 테두리는 그것의 등급(녹색, 청색 등등..)에 걸맞게 색이 입혀집니다."
    L.Columns = "행 - %d"
    L.ColumnsTooltip = "가방의 너비를 칸으로 조절합니다."
    L.Scale = "크기 비율 - %d%%"
    L.ScaleTooltip = "보관함의 크기 비율을 설정합니다."
    L.AddMessage = "Baud Bag: 애드온을 불러들였습니다. 옵션을 위해서는 /baudbag을 입력하십시요."
    L.CheckTooltip = "가방을 합칩니다."
    L.Enabled = "활성화"
    L.EnabledTooltip = "이 가방 세트에 대해 BaudBag을 활성화 혹은 비활성화합니다."
    L.KeyRing = "열쇠 고리"
    L.Of = "'의 "
    L.Inventory = "소지품"
    L.BankBox = "은행 박스"
    L.ReagentBankBox = "은행 박스"
    L.BlizInventory = "블리즈 소지품"
    L.BlizBank = "블리즈 은행"
    L.BlizKeyring = "블리즈 열쇠고리"
    L.Transparent = "반투명한"
    L.Transparent2 = "반투명한 ElvUI"
    L.Solid = "바탕 무늬 없는"
    L.BagSet = "가방 세트"
    L.ContainerName = "보관함 이름:"
    L.Background = "배경"
    L.FeatureFrameName = "BaudBag 옵션"
    L.FeatureFrameTooltip = "BaudBag 옵션입니다."
end