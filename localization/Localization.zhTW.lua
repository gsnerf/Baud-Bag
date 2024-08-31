---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

-- make sure this file stays UTF-8!
if (GetLocale() == "zhTW") then
    local L = AddOnTable.Localized
    L.LockPosition = "鎖定窗口"
    L.UnlockPosition = "解鎖窗口"
    L.ShowBank = "顯示銀行"
    L.Options = "選項"
    L.Free = " 剩餘"
    L.Offline = " (離線銀行)"
    L.AutoOpen = "自動開啟"
    L.AutoOpenTooltip = "勾選後，在交易,使用郵箱和銀行時自動打開背包(如果可用)"
    L.BlankOnTop = "頂部留空"
    L.BlankOnTopTooltip = "勾選後，剩餘的未使用空間上升到整合背包頂部(開啟背包整合後生效)"
    L.RarityColoring = "品質邊框"
    L.RarityColoringTooltip = "勾選後，物品圖示的邊框按品質著色(開啟背包整合後生效)"
    L.Columns = "每行列數 - %d"
    L.ColumnsTooltip = "每行顯示的背包格數."
    L.Scale = "縮放 - %d%%"
    L.ScaleTooltip = "縮放整合背包."
    L.AddMessage = "Baud Bag: 已載入. 輸入 /baudbag 打開設置視窗."
    L.CheckTooltip = "啟用的背包"
    L.Enabled = "啟用整合功能"
    L.EnabledTooltip = "啟用或禁用整合功能"
    L.KeyRing = "鑰匙鏈"
    L.Of = " 的"
    L.Inventory = "背包"
    L.BankBox = "銀行"
    L.ReagentBankBox = "銀行"
    L.BlizInventory = "暴雪背包風格"
    L.BlizBank = "暴雪銀行風格"
    L.BlizKeyring = "暴雪鑰匙鏈風格"
    L.Transparent = "水晶風格"
    L.Transparent2 = "水晶風格 ElvUI"
    L.Solid = "Solid風格"
    L.BagSet = "背包設定"
    L.ContainerName = "背包名稱:"
    L.Background = "風格設定"
    L.FeatureFrameName = "背包設定"
    L.FeatureFrameTooltip = "設定背包整合的各種參數"
end