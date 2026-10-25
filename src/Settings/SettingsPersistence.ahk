; ----- Direction recognition tolerance (persistent) -----
LoadRecognitionSettings() {
    global SETTINGS_FILE
    try level := Integer(IniRead(SETTINGS_FILE, "Recognition", "ToleranceLevel", "3"))
    catch
        level := 3
    ApplyRecognitionLevel(level)
}

ApplyRecognitionLevel(level) {
    global CFG, RECOGNITION_LEVEL, RECOGNITION_PRESETS
    RECOGNITION_LEVEL := Max(1, Min(RECOGNITION_PRESETS.Length, level))
    preset := RECOGNITION_PRESETS[RECOGNITION_LEVEL]
    CFG.sidewaysMax := preset.drift
    CFG.verticalMax := preset.corner
    CFG.startRatio := preset.startRatio
    CFG.turnRatio := preset.turnRatio
    CFG.turnStart := preset.turn
    CFG.backtrackMax := preset.back
    CFG.driftSlope := preset.slope
    CFG.softTurnRatio := preset.seek
    CFG.startConfirm := 23
    CFG.startAbort := 70
}

SaveRecognitionSettings() {
    global SETTINGS_DIR, SETTINGS_FILE, RECOGNITION_LEVEL
    DirCreate(SETTINGS_DIR)
    IniWrite(RECOGNITION_LEVEL, SETTINGS_FILE, "Recognition", "ToleranceLevel")
}

LoadWheelSettings() {
    global WHEEL, SETTINGS_FILE
    WHEEL.enabled := IniRead(SETTINGS_FILE, "Wheel", "Enabled", "1") != "0"
    WHEEL.reverse := IniRead(SETTINGS_FILE, "Wheel", "Reverse", "0") = "1"
    try delay := Integer(IniRead(SETTINGS_FILE, "Wheel", "DelayMs", "120"))
    catch
        delay := 120
    WHEEL.delayMs := Max(50, Min(300, delay))
}

SaveWheelSettings() {
    global WHEEL, SETTINGS_DIR, SETTINGS_FILE
    DirCreate(SETTINGS_DIR)
    IniWrite(WHEEL.enabled ? "1" : "0", SETTINGS_FILE, "Wheel", "Enabled")
    IniWrite(WHEEL.reverse ? "1" : "0", SETTINGS_FILE, "Wheel", "Reverse")
    IniWrite(WHEEL.delayMs, SETTINGS_FILE, "Wheel", "DelayMs")
}

LoadAppSettings() {
    global NOTEPAD_ENABLED, CUSTOM_APPS, NEXT_APP_ID, SETTINGS_FILE
    NOTEPAD_ENABLED := IniRead(SETTINGS_FILE, "Apps", "Notepad", "1") != "0"
    CUSTOM_APPS := []
    NEXT_APP_ID := 1
    try lines := IniRead(SETTINGS_FILE, "CustomApps", , "")
    catch
        lines := ""
    for line in StrSplit(lines, "`n", "`r") {
        eq := InStr(line, "=")
        if !eq
            continue
        id := Trim(SubStr(line, 1, eq-1))
        if !RegExMatch(id, "^app([0-9]+)$", &m)
            continue
        parts := StrSplit(Trim(SubStr(line,eq+1)), "|", , 3)
        if parts.Length != 3
            continue
        enabled := parts[1] != "0"
        exe := parts[2], path := parts[3]
        if exe = "" || path = "" || SubStr(StrLower(path), -4) != ".exe"
            continue
        CUSTOM_APPS.Push({id:id, name:exe, path:path, enabled:enabled})
        NEXT_APP_ID := Max(NEXT_APP_ID, Integer(m[1])+1)
    }
}

SaveNotepadSetting() {
    global NOTEPAD_ENABLED, SETTINGS_DIR, SETTINGS_FILE
    DirCreate(SETTINGS_DIR)
    IniWrite(NOTEPAD_ENABLED ? "1" : "0", SETTINGS_FILE, "Apps", "Notepad")
}

SaveCustomApps() {
    global CUSTOM_APPS, SETTINGS_DIR, SETTINGS_FILE
    DirCreate(SETTINGS_DIR)
    try IniDelete(SETTINGS_FILE, "CustomApps")
    for app in CUSTOM_APPS
        IniWrite((app.enabled ? "1" : "0") "|" app.name "|" app.path,
            SETTINGS_FILE, "CustomApps", app.id)
}

FindCustomApp(id) {
    global CUSTOM_APPS
    for app in CUSTOM_APPS {
        if app.id = id
            return app
    }
    return 0
}

 ; ----- Persistent mapping / settings GUI -----
; User-specific overrides in [GestureColors], keyed by the direction path.
; No keys in old settings.ini => no change to old configuration.
LoadGestureColors() {
    global GESTURE_COLORS, BINDINGS, SETTINGS_FILE
    GESTURE_COLORS := Map()
    for seq, actionId in BINDINGS {
        raw := IniRead(SETTINGS_FILE, "GestureColors", seq, "")
        if IsValidHex(raw)
            GESTURE_COLORS[seq] := NormalizeHex(raw, "67D9FF")
    }
}

SaveGestureColors() {
    global GESTURE_COLORS, SETTINGS_DIR, SETTINGS_FILE, BINDINGS
    DirCreate(SETTINGS_DIR)
    try IniDelete(SETTINGS_FILE, "GestureColors")
    for seq, color in GESTURE_COLORS {
        if BINDINGS.Has(seq) && IsValidHex(color)
            IniWrite(color, SETTINGS_FILE, "GestureColors", seq)
    }
}

; Preserve pre-v3.6.2 default colors when no per-gesture override exists.
; The former [Appearance] TrailColor custom value is migrated to [GestureColors] D.
; One-time upgrade: [Appearance] TrailColor previously colored the auto "D"
; gesture. Keep any customized value as an explicit per-gesture override,
; but never replace an existing [GestureColors] D selection. Delete the old
; key only after successfully persisting its replacement. An older file can
; therefore be upgraded without confusing the new PendingColor setting.
MigrateLegacyTrailColor() {
    global GESTURE_COLORS, BINDINGS, SETTINGS_FILE
    legacy := IniRead(SETTINGS_FILE, "Appearance", "TrailColor", "")
    if legacy = ""
        return
    ; Save the original INI before the one-time migration. Never overwrite
    ; this backup on subsequent starts (or after the user changes settings).
    backup := SETTINGS_FILE ".pre-v3.6.2.bak"
    if !FileExist(backup) {
        try FileCopy(SETTINGS_FILE, backup)
        catch {
            ; A failed backup must not trigger destructive migration.
            return
        }
    }
    if BINDINGS.Has("D") && !GESTURE_COLORS.Has("D") && IsValidHex(legacy) {
        legacy := NormalizeHex(legacy, "67D9FF")
        if legacy != "67D9FF" {
            GESTURE_COLORS["D"] := legacy
            try SaveGestureColors()
            catch {
                ; Do not remove the old key until the custom color is saved.
                return
            }
        }
    }
    try IniDelete(SETTINGS_FILE, "Appearance", "TrailColor")
}

AutoGestureColor(seq) {
    global AUTO_GESTURE_PALETTE
    if seq = "D"
        return "67D9FF"
    if seq = "DR"
        return "65E6BE"
    ; Stable deterministic palette, independent of the listing/order of keys.
    hash := 0
    for dir in StrSplit(seq)
        hash := Mod(hash * 31 + Ord(dir), 65521)
    return AUTO_GESTURE_PALETTE[Mod(hash, AUTO_GESTURE_PALETTE.Length) + 1]
}

GestureColor(seq) {
    global GESTURE_COLORS
    return GESTURE_COLORS.Get(seq, AutoGestureColor(seq))
}

DefaultBindings() {
    return Map("D", "new_tab", "DR", "close_tab")
}

LoadBrowserSettings() {
    global BROWSER_DEFS, BROWSER_ENABLED, SETTINGS_FILE
    BROWSER_ENABLED := Map()
    for item in BROWSER_DEFS {
        ; For v2.9 migrations, absent browser keys default to enabled.
        try val := IniRead(SETTINGS_FILE, "Browsers", item.id, "1")
        catch
            val := "1"
        BROWSER_ENABLED[item.id] := (val != "0")
    }
}

SaveOneBrowser(id, enabled) {
    global SETTINGS_DIR, SETTINGS_FILE
    DirCreate(SETTINGS_DIR)
    IniWrite(enabled ? "1" : "0", SETTINGS_FILE, "Browsers", id)
}

SaveAllBrowsers() {
    global BROWSER_DEFS, BROWSER_ENABLED, SETTINGS_DIR, SETTINGS_FILE
    DirCreate(SETTINGS_DIR)
    for item in BROWSER_DEFS
        IniWrite(BROWSER_ENABLED.Get(item.id, true) ? "1" : "0", SETTINGS_FILE, "Browsers", item.id)
}

LoadBindings() {
    global BINDINGS, SETTINGS_FILE, ACTIONS
    BINDINGS := DefaultBindings()
    if !FileExist(SETTINGS_FILE)
        return
    try {
        initialized := IniRead(SETTINGS_FILE, "General", "Initialized", "0")
        if initialized != "1"
            return
        BINDINGS := Map()
        lines := IniRead(SETTINGS_FILE, "Gestures", , "")
        for line in StrSplit(lines, "`n", "`r") {
            eq := InStr(line, "=")
            if !eq
                continue
            seq := Trim(SubStr(line, 1, eq-1))
            actionID := Trim(SubStr(line, eq+1))
            if IsValidSequence(seq) && ACTIONS.Has(actionID)
                BINDINGS[seq] := actionID
        }
    } catch {
        ; Corrupt/unreadable file must not accidentally intercept unknown gestures.
        BINDINGS := Map()
    }
}

SaveBindings() {
    global BINDINGS, SETTINGS_FILE, SETTINGS_DIR
    DirCreate(SETTINGS_DIR)
    ; Each save rewrites the gesture section, including when empty.
    try IniDelete(SETTINGS_FILE, "Gestures")
    for seq, actionID in BINDINGS
        IniWrite(actionID, SETTINGS_FILE, "Gestures", seq)
    IniWrite("1", SETTINGS_FILE, "General", "Initialized")
}

IsValidSequence(seq) {
    if StrLen(seq) < 1 || StrLen(seq) > 3
        return false
    prev := ""
    for char in StrSplit(seq) {
        if !InStr("UDLR", char) || char = prev
            return false
        prev := char
    }
    return true
}

DirArrow(dir) {
    switch dir {
        case "U": return "↑"
        case "D": return "↓"
        case "L": return "←"
        case "R": return "→"
    }
    return ""
}

ArrowDir(char) {
    switch char {
        case "↑": return "U"
        case "↓": return "D"
        case "←": return "L"
        case "→": return "R"
    }
    return ""
}

SequenceToArrows(seq) {
    result := ""
    for char in StrSplit(seq)
        result .= DirArrow(char)
    return result
}

ArrowsToSequence(arrows) {
    result := ""
    for char in StrSplit(arrows)
        result .= ArrowDir(char)
    return result
}

 ; ----- Tray and settings window icon customization (v3.8) -----
