#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance Force

CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
SetTitleMatchMode, 2

; === Log-Initialisierung ===
logFilePath := InitLogging()

; === Fensterkennung für COC Emulator ===
TargetWin := "ahk_class CROSVM_1 ahk_exe crosvm.exe"

; === Bilddateien (Dynamisch aus Ordnern laden) ===
images := {}
image_groups := ["builder", "mauer", "gold", "elexier", "popup"]

images := LoadImagePaths(image_groups)




; === Statusvariable ===
MonitoringActive := false
runCounter := 0 ; Zählt die Durchläufe bis zum Upgrade-Zyklus
popupSearchState := "" ; Verhindert Log-Spam bei der Popup-Suche

; === Hotkeys ===
F2::ToggleScript()
F3::CheckImageGroupWithPopup("builder")
F4::CheckImageGroupWithPopup("mauer")
F5::CheckImageGroupWithPopup("gold")
F6::CheckImageGroupWithPopup("elexier")
F8::CheckImageGroupWithPopup("popup")

F9::
    MouseGetPos, xpos, ypos
    ToolTip, Maus-Position: %xpos%`, %ypos%
    SetTimer, RemoveToolTip, 2000
return

Esc::ExitAppWithKill()

; === Skript Start/Stopp mit F2 ===
ToggleScript() {
    global MonitoringActive
    MonitoringActive := !MonitoringActive

    RunWait, taskkill /F /IM "Attack.exe", , Hide
    Sleep, 300

    if (MonitoringActive) {
        Log("Script enabled.")
        ToolTip, ✅ Makro aktiviert
        SetTimer, StartRoutine, 1000
    } else {
        Log("Script disabled.")
        ToolTip, ❌ Makro gestoppt
        SetTimer, StartRoutine, Off
    }
    SetTimer, RemoveToolTip, 2000
}

; === Hauptablauf ===
StartRoutine:
    global runCounter
    Log("--- Starting new routine cycle ---")

    ; 1. IMMER zuerst auf initiales Popup warten und klicken
    if (popupSearchState != "waiting") {
        Log("Searching for popup...")
    }

    if !ImageFoundInGroup(images["popup"], x, y) {
        if (popupSearchState != "waiting") {
            popupSearchState := "waiting"
            Log("Popup not found. Quietly waiting for it to appear...")
        }
        return ; Beendet die Routine, wenn kein Popup gefunden wird
    }

    popupSearchState := "found" ; Zurücksetzen, da Popup gefunden wurde
    Log("Popup found and clicked.")
    xOffset := x + 10
    yOffset := y + 10
    Click, %xOffset%, %yOffset%
    Sleep, 500

    runCounter++ ; Zähler erhöhen
    Log("Run counter is now: " . runCounter)

    ; Wenn 6 Durchläufe abgeschlossen sind, führe den Upgrade-Zyklus aus
    if (runCounter >= 10) {
        Log("Run counter reached 6. Starting upgrade cycle.")
        runCounter := 0 ; Zähler zurücksetzen
        Log("Counter reset to 0.")

        ; 2. Einzelne, durchgehende Schleife für den Upgrade-Zyklus
        Loop {
            ; --- Builder suchen ---
            Log("Searching for a free builder...")
            Tolerance := GetTolerance("builder.png")
            if !WaitForImageClick(images["builder"], 30000, Tolerance) {
                Log("No free builder found within 30s. Breaking upgrade loop.")
                break ; Kein Builder gefunden, Schleife beenden
            }
            Log("Builder found and clicked.")
            Sleep, 300

            ; --- Maus nach unten bewegen ---
            MouseMove, 0, 200, 0, R
            Sleep, 300
            
            ; --- Mauer suchen (mit Scrollen) ---
            Log("Searching for a wall...")
            Tolerance := GetTolerance("mauer.png")
            ScrollAttempts := 0
            MauerFound := false
            Loop {
                if WaitForImageClick(images["mauer"], 400, Tolerance) {
                    MauerFound := true
                    Log("Wall found and clicked.")
                    break
                }
                if (ScrollAttempts >= 9) {
                    Log("No wall found after 9 scroll attempts.")
                    break
                }
                Loop, 3 {
                    Send, {WheelDown}
                    Sleep, 30
                }
                Sleep, 700 ; Angepasste Wartezeit
                ScrollAttempts++
            }

            if (!MauerFound) {
                Log("Breaking upgrade loop because no wall was found.")
                break ; Keine Mauer gefunden, Schleife beenden
            }

            ; --- Gold oder Elexier suchen ---
            Log("Searching for Gold or Elixir to upgrade...")
            goldAndElexier := images["gold"].Clone()
            for _, img in images["elexier"] {
                goldAndElexier.Push(img)
            }

            if !WaitForEitherClick(goldAndElexier, 5000) {
                Log("No Gold or Elixir button found. Breaking upgrade loop.")
                break ; Keine Ressourcen gefunden, Schleife beenden
            }
            else{
                Sleep, 500
                Click, 1300, 925
                Sleep, 400
            }
            Log("Resource found and clicked.")
            Log("Upgrade initiated. Looping back to find next builder.")
            
            ; Die Schleife beginnt von vorn (sucht wieder nach Builder)
        }
         Sleep, 1000
        ; Nach dem Upgrade-Versuch (erfolgreich oder nicht), zum Angriff übergehen
        Log("Upgrade cycle finished. Starting attack.")
        SetTimer, StartRoutine, Off ; Pausiere die Hauptroutine
        RunAngriff()
        WaitForPopupAndRestart() ; Warte auf Popup und starte dann neu
        return
    }
    Sleep, 8000
    ; 3. Angriff starten, wenn der Upgrade-Zyklus noch nicht dran ist
    Log("Starting attack.")
    SetTimer, StartRoutine, Off ; Pausiere die Hauptroutine
    RunAngriff()
    WaitForPopupAndRestart() ; Warte auf Popup und starte dann neu
    
return

WaitForPopupAndRestart() {
    global images, popupSearchState
    Log("Now waiting for the popup to restart the main loop...")
    Loop {
        if ImageFoundInGroup(images["popup"], x, y) {
            Log("Popup found. Restarting main routine.")
            popupSearchState := "" ; Reset state
            SetTimer, StartRoutine, 1000 ; Timer wieder aktivieren
            break
        }
        Sleep, 1000 ; Warte 1 Sekunde zwischen den Suchversuchen
    }
}

RunAngriff() {
    Log("Executing Attack.exe")
    Run, Attack.exe
    Sleep, 15000
    Log("Attack.exe should be finished.")
}

ImageFoundInGroup(images, ByRef x := "", ByRef y := "", tolerance := "*30") {
    for _, image in images {
        ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, %tolerance% %A_ScriptDir%\%image%
        if (!ErrorLevel) {
            x := foundX
            y := foundY
            return true
        }
    }
    return false
}

ImageFound(image, ByRef x := "", ByRef y := "", tolerance := "*30") {
    ImageSearch, x, y, 0, 0, A_ScreenWidth, A_ScreenHeight, %tolerance% %A_ScriptDir%\%image%
    return !ErrorLevel
}

WaitForImageClick(images, timeout, tolerance := "*30") {
    start := A_TickCount
    Loop {
        if ImageFoundInGroup(images, x, y, tolerance) {
            Sleep, 500
            Click, %x%, %y%
            Sleep, 500
            return true
        }
        if (A_TickCount - start > timeout)
            return false
        Sleep, 300
    }
}

WaitForEitherClick(images, timeout) {
    start := A_TickCount
    Loop {
        for _, img in images {
            Tolerance := GetTolerance(img)
            if ImageFound(img, x, y, Tolerance) {
                Sleep, 700 ; Kurze Verzögerung vor dem Klick
                Click, %x%, %y% ; Klick auf das gefundene Gold/Elexier Bild
                Sleep, 700
                return true
            }
        }
        if (A_TickCount - start > timeout)
            return false
        Sleep, 300
    }
}

GetTolerance(imageFile) {
    if InStr(imageFile, "mauer") {
        return "*130"
    }
    else if InStr(imageFile, "gold") || InStr(imageFile, "elexier") {
        return "*100"
    }
    else if InStr(imageFile, "builder") {
        return "*60"
    }
    else {
        return "*600"
    }
}



; === Bildsuche mit Fensterbezug (F3-F6) ===
CheckImageGroupWithPopup(groupName) {
    global images, TargetWin

    if !images.HasKey(groupName) {
        MsgBox, ⚠️ Bild-Gruppe '%groupName%' nicht definiert.
        return
    }

    if !WinExist(TargetWin) {
        MsgBox, ❌ Fenster nicht gefunden: Clash of Clans Emulator läuft nicht!
        return
    }

    WinGetPos, X, Y, W, H, %TargetWin%
    
    found := false
    for _, imageFile in images[groupName] {
        Tolerance := GetTolerance(imageFile)
        ImageSearch, FoundX, FoundY, X, Y, X+W, Y+H, %Tolerance% %A_ScriptDir%\%imageFile%
        
        if (ErrorLevel = 0) {
            ToolTip, ✅ %imageFile% gefunden bei %FoundX%, %FoundY%
            Gui, +AlwaysOnTop -Caption +ToolWindow
            Gui, Color, Red
            Gui, Add, Text, x0 y0 w80 h20 Center BackgroundTrans cWhite, ✔ Gefunden
            Gui, Show, x%FoundX% y%FoundY% w80 h20 NoActivate
            SetTimer, CloseTestGui, 2000
            found := true
            break ; Stop searching after first find in group
        }
    }

    if (!found) {
        ToolTip, ❌ Kein Bild aus Gruppe '%groupName%' gefunden.
    }
    SetTimer, RemoveToolTip, 3000
}

CloseTestGui:
    Gui, Destroy
    SetTimer, CloseTestGui, Off
return

RemoveToolTip:
    ToolTip
    SetTimer, RemoveToolTip, Off
return

; F7 hotkey to show help popup again
F7::
MsgBox, 64, COC Popup Monitor - Help, Script Hotkeys:`n`n• F2 - Start/Stop `n• F3 - Test Builder Images`n• F4 - Test Mauer Images`n• F5 - Test Gold Images`n• F6 - Test Elexier Images`n• F7 - Show this help`n• F8 - Test Popup Images`n• ESC - Exit script (kills COC macro)`n`nNotes:`n- Make sure "popup.png" is in script folder`n- Works on all monitors`n- COC macro gets killed when stopping/exiting
return

LoadImagePaths(groups) {
    local loaded_images := {}
    for _, groupName in groups
    {
        loaded_images[groupName] := []
        Loop, Files, %A_ScriptDir%\%groupName%\*.png
        {
            loaded_images[groupName].Push(groupName . Chr(92) . A_LoopFileName)
        }
    }
    return loaded_images
}

ExitAppWithKill() {
    Log("Exit hotkey pressed. Killing Attack.exe and exiting script.")
    RunWait, taskkill /F /IM "Attack.exe", , Hide
    ExitApp
}

; === Logging Funktionen ===
InitLogging() {
    logDir := A_ScriptDir . "\logs"
    if !FileExist(logDir)
        FileCreateDir, %logDir%
    
    FormatTime, time, , yyyy-MM-dd_HH-mm-ss
    path := logDir . "\log_" . time . ".txt"
    Log("Logging initialized. Log file: " . path)
    return path
}

Log(message) {
    global logFilePath
    FormatTime, time, , HH:mm:ss
    FileAppend, %time% - %message%`n, %logFilePath%
}
