---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

-- make sure this file stays UTF-8!
if (GetLocale() == "ruRU") then
    local L = AddOnTable.Localized
    L.LockPosition = "Заблокировать положение"
    L.UnlockPosition = "Разблокировать положение"
    L.ShowBank = "Показать банк"
    L.Options = "Настройки"
    L.Free = " Свободно"
    L.Offline = " (Оффлайн)"
    L.AutoOpen = "Авто открытие"
    L.AutoOpenTooltip = "Когда включено, автоматически открывает эту сумку (если возможно)."
    L.BlankOnTop = "Пустые сверху"
    L.BlankOnTopTooltip = "Когда включен, любые пустые ячейки будет отсортированы сверху, а не снизу."
    L.RarityColoring = "Окрасить согласно качеству"
    L.RarityColoringTooltip = "Когда включено, окрашивает границы ячеек вещей согласно их качеству (зеленые, синие, и т.п.)."
    L.Columns = "Колонки - %d"
    L.ColumnsTooltip = "Количество колонок по ширине."
    L.Scale = "Масштаб - %d%%"
    L.ScaleTooltip = "Масштаб ячейки."
    L.AddMessage = "Baud Bag: Аддон загружен. введите /baudbag для открытия настроек."
    L.CheckTooltip = "Присоединить сумку"
    L.Enabled = "Включить"
    L.EnabledTooltip = "Включить или отключить BaudBag."
    L.KeyRing = "Связка ключей"
    L.Of = " "
    L.Inventory = "Инвентарь"
    L.BankBox = "Банк"
    L.ReagentBankBox = "Банк"
    L.BlizInventory = "Bliz инвентарь"
    L.BlizBank = "Bliz банк"
    L.BlizKeyring = "Bliz ключи"
    L.Transparent = "Прозрачный"
    L.Transparent2 = "Прозрачный ElvUI"
    L.Solid = "Непрозрачный"
    L.BagSet = "Набор сумок"
    L.ContainerName = "Название:"
    L.Background = "Фон"
    L.FeatureFrameName = "BaudBag настройки"
    L.FeatureFrameTooltip = "BaudBag настройки"
end