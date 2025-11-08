#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance Force

CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
SetTitleMatchMode, 2

; === Log Initialization ===
logFilePath := InitLogging()

; === Window Identifier -> COC Emulator ===
TargetWin := "ahk_class CROSVM_1 ahk_exe crosvm.exe"

; === Image Files (Load dynamically from folders) ===
images := {}
image_groups := ["builder", "mauer", "gold", "elexier", "popup"]

images := LoadImagePaths(image_groups)




; === Status Variables ===
MonitoringActive := false
runCounter := 0 ; Counts the runs until the upgrade cycle
popupSearchState := "" ; Prevents log spam during popup search

; === Hotkeys ===
F2::ToggleScript()
F3::
    MsgBox, 64, COC Popup Monitor - Help, Script Hotkeys:`n`n• F2 - Start/Stop `n• F3 - Show this help`n• F4 - Test Mauer Images`n• F5 - Test Gold Images`n• F6 - Test Elexier Images`n• F7 - Test Builder Images`n• F8 - Test Popup Images`n• ESC - Exit script (kills COC macro)`n`nNotes:`n- Make sure "popup.png" is in script folder`n- Works on all monitors`n- COC macro gets killed when stopping/exiting
return
F4::CheckImageGroupWithPopup("mauer")
F5::CheckImageGroupWithPopup("gold")
F6::CheckImageGroupWithPopup("elexier")
F7::CheckImageGroupWithPopup("builder")
F8::CheckImageGroupWithPopup("popup")

F9::
    MouseGetPos, xpos, ypos
    ToolTip, Mouse Position: %xpos%`, %ypos%
    SetTimer, RemoveToolTip, 2000
return

Esc::ExitAppWithKill()

; === Script Start/Stop with F2 ===
ToggleScript() {
    global MonitoringActive
    MonitoringActive := !MonitoringActive

    RunWait, taskkill /F /IM "Attack.exe", , Hide
    Sleep, 300

    if (MonitoringActive) {
        Log("Script enabled.")
        ToolTip, ✅ Macro activated
        SetTimer, StartRoutine, 1000
    } else {
        Log("Script disabled.")
        ToolTip, ❌ Macro stopped
        SetTimer, StartRoutine, Off
    }
    SetTimer, RemoveToolTip, 2000
}

; === Main Routine ===
StartRoutine:
    global runCounter
    Log("--- Starting new routine cycle ---")

    ; 1. ALWAYS wait for and click the initial popup first
    if (popupSearchState != "waiting") {
        Log("Searching for popup...")
    }

    if !ImageFoundInGroup(images["popup"], x, y) {
        if (popupSearchState != "waiting") {
            popupSearchState := "waiting"
            Log("Popup not found. Quietly waiting for it to appear...")
        }
        return ; Ends the routine if no popup is found
    }

    popupSearchState := "found" ; Reset, because popup was found
    Log("Popup found and clicked.")
    xOffset := x + 10
    yOffset := y + 10
    Click, %xOffset%, %yOffset%
    Sleep, 500

    runCounter++ ; Increment counter
    Log("Run counter is now: " . runCounter)

    ; When 10 runs are complete, execute the upgrade cycle //change this to any number you want
    if (runCounter >= 10) {
        Log("Run counter reached 6. Starting upgrade cycle.")
        runCounter := 0 ; Reset counter
        Log("Counter reset to 0.")

        ; 2. Single, continuous loop for the upgrade cycle
        Loop {
            ; --- Search for builder ---
            Log("Searching for a free builder...")
            Tolerance := GetTolerance("builder.png")
            if !WaitForImageClick(images["builder"], 30000, Tolerance) {
                Log("No free builder found within 30s. Breaking upgrade loop.")
                break ; No builder found, exit loop
            }
            Log("Builder found and clicked.")
            Sleep, 300

            ; --- Move mouse down ---
            MouseMove, 0, 200, 0, R
            Sleep, 300
            
            ; --- Search for wall (with scrolling) ---
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
                Sleep, 700 ; Adjusted wait time
                ScrollAttempts++
            }

            if (!MauerFound) {
                Log("Breaking upgrade loop because no wall was found.")
                break ; No wall found, exit loop
            }

            ; --- Search for Gold or Elixir ---
            Log("Searching for Gold or Elixir to upgrade...")
            goldAndElexier := images["gold"].Clone()
            for _, img in images["elexier"] {
                goldAndElexier.Push(img)
            }

            if !WaitForEitherClick(goldAndElexier, 5000) {
                Log("No Gold or Elixir button found. Breaking upgrade loop.")
                break ; No resources found, exit loop
            }
            else{
                Sleep, 500
                Click, 1300, 925
                Sleep, 400
            }
            Log("Resource found and clicked.")
            Log("Upgrade initiated. Looping back to find next builder.")
            
            ; The loop starts over (searches for builder again)
        }
         Sleep, 1000
        ; After the upgrade attempt (successful or not), proceed to attack
        Log("Upgrade cycle finished. Starting attack.")
        SetTimer, StartRoutine, Off ; Pause the main routine
        RunAngriff()
        WaitForPopupAndRestart() ; Wait for popup and then restart
        return
    }
    Sleep, 8000
    ; 3. Start attack if it's not the upgrade cycle's turn yet
    Log("Starting attack.")
    SetTimer, StartRoutine, Off ; Pause the main routine
    RunAngriff()
    WaitForPopupAndRestart() ; Wait for popup and then restart
    
return

WaitForPopupAndRestart() {
    global images, popupSearchState
    Log("Now waiting for the popup to restart the main loop...")
    Loop {
        if ImageFoundInGroup(images["popup"], x, y) {
            Log("Popup found. Restarting main routine.")
            popupSearchState := "" ; Reset state
            SetTimer, StartRoutine, 1000 ; Reactivate timer
            break
        }
        Sleep, 1000 ; Wait 1 second between search attempts
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
                Sleep, 700 ; Short delay before the click
                Click, %x%, %y% ; Click on the found Gold/Elixir image
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



; === Image Search with Window Context (F3-F6) ===
CheckImageGroupWithPopup(groupName) {
    global images, TargetWin

    if !images.HasKey(groupName) {
        MsgBox, ⚠️ Image group '%groupName%' not defined.
        return
    }

    if !WinExist(TargetWin) {
        MsgBox, ❌ Window not found: Clash of Clans Emulator is not running!
        return
    }

    WinGetPos, X, Y, W, H, %TargetWin%
    
    found := false
    for _, imageFile in images[groupName] {
        Tolerance := GetTolerance(imageFile)
        ImageSearch, FoundX, FoundY, X, Y, X+W, Y+H, %Tolerance% %A_ScriptDir%\%imageFile%
        
        if (ErrorLevel = 0) {
            ToolTip, ✅ %imageFile% found at %FoundX%, %FoundY%
            Gui, +AlwaysOnTop -Caption +ToolWindow
            Gui, Color, Red
            Gui, Add, Text, x0 y0 w80 h20 Center BackgroundTrans cWhite, ✔ Found
            Gui, Show, x%FoundX% y%FoundY% w80 h20 NoActivate
            SetTimer, CloseTestGui, 2000
            found := true
            break ; Stop searching after first find in group
        }
    }

    if (!found) {
        ToolTip, ❌ No image from group '%groupName%' found.
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

; === Logging Functions ===
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
