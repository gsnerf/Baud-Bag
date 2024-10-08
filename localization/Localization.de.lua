---@class AddonNamespace
local AddOnTable = select(2, ...)
local _

-- make sure this file stays UTF-8!
if (GetLocale() == "deDE") then
    local L = AddOnTable.Localized
    L.LockPosition = "Fenster fixieren"
    L.UnlockPosition = "Fenster freigeben"
    L.ShowBank = "Bank anzeigen"
    L.Options = "Optionen"
    L.Free = " frei"
    L.Offline = " (Offline)"
    L.AutoOpen = "Automatisch Öffnen"
    L.AutoOpenTooltip = "Öffnet die gewählte Tasche automatisch wenn Post abgeholt wird, ein Verkäufer oder (wenn möglich) die Bank besucht wird."
    L.AutoClose = "Automatisch Schließen"
    L.AutoCloseTooltip = "Schließt die gewählte Tasche automatisch wenn das Post-, Verkaufs- oder Bankfenster geschlossen wird. (Nur wenn Automatisch Öffnen gewählt ist!)"
    L.BlankOnTop = "Leerplätze oben"
    L.BlankOnTopTooltip = "Nicht von Taschenplätzen belegter Platz im Fenster wird oben angezeigt anstatt unten."
    L.RarityColoring = "Seltenheitseinfärbung"
    L.RarityColoringTooltip = "Der Rand von Gegenständen wird entsprechend der Seltenheit eingefärbt (grün, blau, etc)."
    L.RarityIntensity = "Intensität - %g"
    L.RarityIntensityTooltip = "Verändert die Iintensität der Seltenheitsfärbung. (1 ist Normal)"
    L.ShowNewItems = "Hervorhebung für neue Items"
    L.ShowNewItemsTooltip = "Items welche neu im Inventar sind werden durch einen pulsierenden Rand hervorgehoben."
    L.Columns = "Spalten - %d"
    L.ColumnsTooltip = "Anzahl der angezeigten Taschenplätze (Spalten) pro Zeile in der gewählten Tasche."
    L.Scale = "Skalierung - %d%%"
    L.ScaleTooltip = "Skalierung des Fensters."
    L.AddMessage = "Baud Bag: AddOn geladen. Tippe /baudbag oder /bb in den Chat um die Optionen aufzurufen."
    L.CheckTooltip = "Taschen zusammenfassen"
    L.Enabled = "Aktiviert"
    L.EnabledTooltip = "Aktiviere oder Deaktiviere BaudBag für diesen Taschen-Typ."
    L.CloseAll = "Alle schließen"
    L.CloseAllTooltip = "Schließt alle Taschen des Sets wenn der erste Container (Rucksack/Bank) geschlossen wird."
    L.SellJunk = "Unrat verkaufen"
    L.SellJunkTooltip = "Verkauft automatisch alle unnützen items wenn ein Händler besucht wird."
    L.KeyRing = "Schlüsselbund"
    L.Of = "s "
    L.Inventory = "Inventar"
    L.ReagentBag = "Reagenzien"
    L.BankBox = "Bankfach"
    L.ReagentBankBox = "Materiallager"
    L.BlizInventory = "Bliz Inventar"
    L.BlizBank = "Bliz Bank"
    L.BlizKeyring = "Bliz Schlüsselbund"
    L.Transparent = "Transparent"
    L.Transparent2 = "Transparent ElvUI"
    L.Solid = "Fest"
    L.BagSet = "Taschen-Typ"
    L.ContainerName = "Taschen-Name"
    L.Background = "Hintergrund"
    L.FeatureFrameName = "BaudBag Optionen"
    L.FeatureFrameTooltip = "BaudBag Optionen"
    L.SearchBagTooltip = "Taschen durchsuchen"
    L.MenuCatSpecific = "Taschenspezifisches"
    L.MenuCatGeneral = "Allgemeines"
    L.TooltipScanReagent = "Handwerksmaterial"
    L.OptionsGroupGlobal = "Allgemeines"
    L.OptionsGroupContainer = "Taschen-Typ spezifisches"
    L.UseMasque = "Unterstützung für Masque aktivieren"
    L.UseMasqueTooltip = "Bei Aktivierung werden die Gegenstands-Buttons in den taschen bei Masque registriert, so dass man darüber das Aussehen verändern kann."
    L.UseMasqueUnavailable = "Masque wurde nicht gefunden"
    L.UseMasqueReloadPopupText = "Scheinbar hast du die Einstellungen für die Masque Unterstützung verändert. Damit die Änderungen wirksam werden muss das UI neugeladen werden, möchtest du das jetzt tun?"
    L.UseMasqueReloadPopupAccept = "ja"
    L.UseMasqueReloadPopupDecline = "nein"
    L.ShowItemLevel = "Itemlevel anzeigen"
    L.ShowItemLevelTooltip = "Zeigt das Itemlevel auf Ausrüstungsgegenständen (die gelbe Zahl oben)"
    L.EnableFadeAnimation = "Aktiviere Ein-/Ausblende animationen"
    L.EnableFadeAnimationTooltip = "Aktiviert eine Animation zum sanften Einblenden oder Ausblenden der Taschen beim Öffnen und Schließen"
    L.OptionsResetAllPositions = "Alle Container zentrieren"
    L.OptionsResetAllPositionsTooltip = "Nützlich um Container wieder ins Bild zu holen die ausserhalb des sichtbaren Bildschirmbereichs gelandet sind."
    L.OptionsResetContainerPosition = "Container zentrieren"
    L.OptionsResetContainerPositionTooltip = "Verwende dies um einen aus dem Bildschirmbreich geschobenen Container in die Mitte des Bildschirms zu versetzen."
    L.AccountBank = "Kriegsmeutenbank"
end