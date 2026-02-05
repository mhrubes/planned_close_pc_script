#NoEnv
#SingleInstance Force
SetBatchLines -1

global totalSeconds := 0
global endTime := 0
global countdownActive := false

; --- GUI ---
Gui, Add, Text, , Zadej cas do vypnuti (napr.1h 30m, 45m, 2h 10m 5s):
Gui, Add, Edit, vHoursInput w200
Gui, Add, Button, gStartShutdown w200, Spustit vypnuti
Gui, Add, Button, gCancelShutdown w200, Zrusit vypnuti
Gui, Add, Text, vCountdownText w200, Odpocet: -
    Gui, Show, , Naplanovane vypnuti PC
return

; --- START ---
StartShutdown:
    Gui, Submit, NoHide
    input := Trim(HoursInput)

    if (input = "") {
        MsgBox, 48, Chyba, Nezadal jsi zadny cas.
        return
    }

    ; Pokud už běží odpočet, varuj uživatele
    if (countdownActive)
        {
            MsgBox, 48, Varovani, Odpocet uz bezi. Nejprve jej zruste tlacitkem "Zrusit vypnuti".
            return
        }

    totalSeconds := ParseTimeToSeconds(input)

    if (totalSeconds <= 0) {
        MsgBox, 48, Chyba, Nevalidni hodnota casu.
        return
    }

    ; Nastavení konce odpočtu
    endTime := A_TickCount + (totalSeconds * 1000)
    countdownActive := true

    ; Spuštění vypnutí Windows
    Run, shutdown.exe / s / t %totalSeconds%, , Hide

    ; Start timeru pro odpočet
    SetTimer, UpdateCountdown, 1000
    return

    ; --- CANCEL ---
CancelShutdown:
    if (countdownActive) {
        Run, shutdown.exe / a, , Hide
        SetTimer, UpdateCountdown, Off
        countdownActive := false
        GuiControl, , CountdownText, Odpocet: ZRUSENO
    }
    return

    ; --- UPDATE COUNTDOWN ---
UpdateCountdown:
    remainingMs := endTime - A_TickCount
    if (remainingMs <= 0) {
        SetTimer, UpdateCountdown, Off
        countdownActive := false
        GuiControl, , CountdownText, Odpocet: PC se vypina...
        return
    }

    totalSecLeft := Floor(remainingMs / 1000)
    hoursLeft := Floor(totalSecLeft / 3600)
    minutesLeft := Floor(Mod(totalSecLeft, 3600) / 60)
    secondsLeft := Mod(totalSecLeft, 60)

    ; formát 2 číslice
    hoursLeft := Format("{:02}", hoursLeft)
    minutesLeft := Format("{:02}", minutesLeft)
    secondsLeft := Format("{:02}", secondsLeft)

    GuiControl, , CountdownText, Odpocet: %hoursLeft%: %minutesLeft%: %secondsLeft%
    return

    ; --- PARSER TIME ---
    ParseTimeToSeconds(str) {
        str := Trim(str)
        str := RegExReplace(str, "\s+", " ")

        ; Ověření, že celý string je složen jen z bloků typu "číslo + jednotka"
        if !RegExMatch(str, "^(?:\d+(\.\d+)?\s*[hmsHMS]\s*)+$")
            return 0

        total := 0
        pos := 1

        while (pos := RegExMatch(str, "(\d+(\.\d+)?)[ ]*([hmsHMS])", m, pos)) {
            value := m1 + 0
            unit := m3

            if (unit = "h" or unit = "H")
                total += value * 3600
            else if (unit = "m" or unit = "M")
                total += value * 60
            else if (unit = "s" or unit = "S")
                total += value

            pos += StrLen(m)   ; správně pro AHK v1
        }

        return Round(total)
    }

    ; --- GUI CLOSE ---
GuiClose:
GuiEscape:
    if (countdownActive) {
        Run, shutdown.exe / a, , Hide
        SetTimer, UpdateCountdown, Off
        countdownActive := false
        MsgBox, 64, Vypnuti zrusene, Odpocet do vypnuti PC byl zrusen.
    }
    ExitApp