
; The wheel hotkeys are only active while a right-button gesture has begun.
; Outside this context the wheel remains completely native to the app.
IsWheelContext() {
    global ST, WHEEL
    ; Wheel hotkeys only belong to the exact window captured on RButton-down,
    ; regardless of which window Windows currently considers active.
    return WHEEL.enabled && ST.active && GetKeyState("RButton", "P")
        && GestureTargetIsValid()
}

; MouseGetPos retrieves the HWND below the pointer even if it is inactive.
; Do NOT use WinExist("A") or WinGetID("A") for gesture targeting.
GetMouseTargetHwnd() {
    try {
        MouseGetPos(, , &targetHwnd)
        return targetHwnd ? targetHwnd : 0
    } catch {
        return 0
    }
}

IsSupportedTarget(hwnd := 0) {
    global BROWSER_ENABLED, NOTEPAD_ENABLED, CUSTOM_APPS
    if !hwnd
        hwnd := GetMouseTargetHwnd()
    if !hwnd
        return false
    browserId := DetectBrowser(hwnd)
    if browserId != ""
        return BROWSER_ENABLED.Get(browserId, false)
    try {
        target := "ahk_id " hwnd
        exe := StrLower(WinGetProcessName(target))
        path := StrLower(WinGetProcessPath(target))
        if IsWindowsNotepad(exe, path)
            return NOTEPAD_ENABLED
        if path = ""
            return false
        for app in CUSTOM_APPS {
            if app.enabled && StrLower(app.path) = path
                return true
        }
    } catch {
        return false
    }
    return false
}

; The target is locked when the right button is pressed, not at mouse release.
; Capture PID too to prevent sending to an unrelated HWND recycled by Windows.
GestureTargetIsValid() {
    global ST
    if !ST.hwnd || !ST.pid
        return false
    try {
        target := "ahk_id " ST.hwnd
        return WinExist(target) && WinGetPID(target) = ST.pid
            && IsSupportedTarget(ST.hwnd)
    } catch {
        return false
    }
}

; Browsers use shortcuts in their focused window, so activate the hovered
; target before sending. Never fall back to sending to an unrelated app.
ActivateGestureTarget() {
    global ST
    if !GestureTargetIsValid()
        return false
    target := "ahk_id " ST.hwnd
    if WinActive(target)
        return true
    try {
        WinActivate(target)
        return !!WinWaitActive(target, , 0.5) && GestureTargetIsValid()
    } catch {
        return false
    }
}

IsWindowsNotepad(exe, path) {
    if exe != "notepad.exe"
        return false
    sys := StrLower(A_WinDir)
    return path = sys "\system32\notepad.exe"
        || path = sys "\syswow64\notepad.exe"
        || path = sys "\notepad.exe"
        || InStr(path, "\microsoft.windowsnotepad_") > 0
}

; WinGetProcessName/Path + native top-level browser window class.
; Browser ID must be known and enabled; unknown Chromium/Electron windows fail closed.
IsSupportedBrowser(hwnd := 0) {
    global BROWSER_ENABLED
    browserId := DetectBrowser(hwnd)
    return browserId != "" && BROWSER_ENABLED.Get(browserId, false)
}

DetectBrowser(hwnd := 0) {
    if !hwnd
        hwnd := GetMouseTargetHwnd()
    if !hwnd
        return ""
    try {
        className := WinGetClass("ahk_id " hwnd)
        if className != "Chrome_WidgetWin_1" && className != "MozillaWindowClass"
            && className != "MozillaUIWindowClass"
            return ""
        exe := StrLower(WinGetProcessName("ahk_id " hwnd))
        path := StrLower(WinGetProcessPath("ahk_id " hwnd))
        if className = "Chrome_WidgetWin_1"
            return DetectChromium(exe, path)
        return DetectGecko(exe, path)
    } catch {
        return ""
    }
}

DetectChromium(exe, path) {
    ; Do not accept arbitrary chrome.exe, which is also used by Electron apps.
    switch exe {
        case "brave.exe":   return "brave"
        case "msedge.exe":  return "edge"
        case "vivaldi.exe": return "vivaldi"
        case "helium.exe":  return "helium"
        case "whale.exe":   return "whale"
        case "slimjet.exe": return "slimjet"
        case "thorium.exe": return "thorium"
        case "opera.exe":
            if InStr(path, "\opera gx\") || InStr(path, "\opera gx stable\")
                return "opera_gx"
            if InStr(path, "\opera\") || InStr(path, "\opera stable\")
                return "opera"
            return ""
        case "chrome.exe":
            ; Specific fork paths take precedence over generic Chromium/Chrome.
            if InStr(path, "\helium\")
                return "helium"
            if InStr(path, "\supermium\")
                return "supermium"
            if InStr(path, "\cromite\")
                return "cromite"
            if InStr(path, "\thorium\")
                return "thorium"
            if InStr(path, "\ungoogled-chromium\") || InStr(path, "\ungoogled chromium\")
                return "ungoogled"
            if InStr(path, "\google\chrome\application\")
                || InStr(path, "\google\chrome beta\application\")
                || InStr(path, "\google\chrome dev\application\")
                || InStr(path, "\google\chrome sxs\application\")
                return "chrome"
            if InStr(path, "\chromium\")
                return "chromium"
            return ""
    }
    return ""
}

DetectGecko(exe, path) {
    switch exe {
        case "floorp.exe":          return "floorp"
        case "zen.exe":             return "zen"
        case "librewolf.exe":       return "librewolf"
        case "waterfox.exe":        return "waterfox"
        case "mullvadbrowser.exe":  return "mullvad"
        case "firefox.exe":
            ; Tor commonly ships firefox.exe, so resolve it before Firefox.
            if InStr(path, "\tor browser\browser\") || InStr(path, "\tor-browser\browser\")
                return "tor"
            if InStr(path, "\mullvad browser\") || InStr(path, "\mullvad-browser\")
                return "mullvad"
            if InStr(path, "\mozilla firefox\")
                || InStr(path, "\mozilla firefox beta\")
                || InStr(path, "\mozilla firefox developer edition\")
                || InStr(path, "\mozilla firefox nightly\")
                || InStr(path, "\mozilla firefox esr\")
                || InStr(path, "\firefox developer edition\")
                || InStr(path, "\firefox nightly\")
                || InStr(path, "\firefox beta\")
                || InStr(path, "\firefox esr\")
                || InStr(path, "\firefox\")
                || InStr(path, "\nightly\")
                return "firefox"
    }
    return ""
}

