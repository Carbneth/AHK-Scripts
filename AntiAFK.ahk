/************************************************************************
 * @description The Configureable Anti-AFK script
 * @author Carbneth
 * @date 2025/11/02
 * @version 1.0.0
 ***********************************************************************/

#Requires AutoHotkey v2.0+
#SingleInstance Force

; Compact configurable Anti-AFK (randomized timers + WASD)
; Configure:
minInterval := 10000       ; minimum ms between actions
maxInterval := 35000       ; maximum ms between actions
minHold := 80              ; minimum ms key hold
maxHold := 600             ; maximum ms key hold
keys := ["w","a","s","d"]  ; possible keys
chanceToAct := 1.0         ; 0..1 chance to perform an action when timer fires

; Internal
global Running := false

; --- Helpers --------------------------------------------------------------
; Robust random float in [min, max]. Tries to use built-in signatures but
; falls back to scaling Random() if signatures differ across versions.

randFloat(min := 0.0, max := 1.0) {
    ; Return a float in [min, max]
    return min + (max - min) * Random()
}

; Return an integer between min and max (inclusive).
randInt(min, max) {
    return min + Floor(randFloat(0, 1) * (max - min + 1))
}

; Validate config and clamp sensible values.
ValidateConfig(*) {
    global minInterval, maxInterval, minHold, maxHold, chanceToAct, keys
    if (minInterval < 0)
        minInterval := 0
    if (maxInterval < minInterval)
        maxInterval := minInterval
    if (minHold < 1)
        minHold := 1
    if (maxHold < minHold)
        maxHold := minHold
    if (chanceToAct < 0)
        chanceToAct := 0
    if (chanceToAct > 1)
        chanceToAct := 1
    if (!IsObject(keys) || keys.Length == 0)
        keys := ["w","a","s","d"]
}

; bind hotkey
; Validate configuration and bind a static hotkey (preferred compatibility)
ValidateConfig()
; create a function object reference for the timer callback (some AHK runtimes
; prefer a stored Func object when scheduling timers)
; Use an anonymous wrapper so we have a function object suitable for SetTimer
afkFunc := () => AFKAction()

^!a::Toggle()

Toggle(*) {
    global Running
    Running := !Running
    TrayTip("AntiAFK", Running ? "ON" : "OFF", 1)
    if Running
        ScheduleNext()
    else
    SetTimer(afkFunc, 0)
}

ScheduleNext(*) {
    global minInterval, maxInterval
    interval := randInt(minInterval, maxInterval)
    ; negative makes it a one-shot timer
    SetTimer(afkFunc, -interval)
}

AFKAction(*) {
    global Running, keys, minHold, maxHold, chanceToAct
    if !Running
        return
    if randFloat(0, 1) > chanceToAct {
        ScheduleNext()
        return
    }
    key := keys[ randInt(1, keys.Length) ]
    hold := randInt(minHold, maxHold)
    ; send keypress
    Send("{" . key . " down}")
    Sleep hold
    Send("{" . key . " up}")
    ScheduleNext()
}

; optional: provide a quick exit hotkey (Ctrl+Alt+Esc)
^!Esc:: {
    SetTimer(afkFunc, 0)
    ExitApp()
}