---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

-- make sure this file stays UTF-8!
if (GetLocale() == "zhCN") then
    local L = AddOnTable.Localized
    L.StandardBag = "容器"
    L.LockPosition = "锁定窗口"
    L.UnlockPosition = "解锁窗口"
    L.ShowBank = "显示银行"
    L.Options = "选项"
    L.Free = " 剩余"
    L.Offline = " (离线银行)"
    L.AutoOpen = "自动开启"
    L.AutoOpenTooltip = "勾选后，在交易,使用邮箱和银行时自动打开背包(如果可用)"
    L.BlankOnTop = "顶部留空"
    L.BlankOnTopTooltip = "勾选后，剩余的未使用空间上升到整合背包顶部(开启背包整合后生效)"
    L.RarityColoring = "质量边框"
    L.RarityColoringTooltip = "勾选后，物品图标的边框按品质着色(开启背包整合后生效)"
    L.Columns = "每行列数 - %d"
    L.ColumnsTooltip = "每行显示的背包格数."
    L.Scale = "缩放 - %d%%"
    L.ScaleTooltip = "缩放整合背包."
    L.AddMessage = "Baud Bag: 已载入. 输入 /baudbag 打开设置窗口."
    L.CheckTooltip = "启用的背包"
    L.Enabled = "启用整合功能"
    L.EnabledTooltip = "启用或禁用整合功能"
    L.KeyRing = "钥匙链"
    L.Of = " 的"
    L.Inventory = "背包"
    L.BankBox = "银行"
    L.ReagentBankBox = "银行"
    L.BlizInventory = "暴雪背包风格"
    L.BlizBank = "暴雪银行风格"
    L.BlizKeyring = "暴雪钥匙链风格"
    L.Transparent = "水晶风格"
    L.Transparent2 = "水晶风格 ElvUI"
    L.Solid = "Solid风格"
    L.BagSet = "背包设定"
    L.ContainerName = "背包名称:"
    L.Background = "风格设定"
    L.FeatureFrameName = "背包设定"
    L.FeatureFrameTooltip = "设定背包整合的各种参数"
end