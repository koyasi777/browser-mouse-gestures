ColorRGB(hex) {
    hex := NormalizeHex(hex, "67D9FF")
    return {r:Integer("0x" SubStr(hex, 1, 2)),
        g:Integer("0x" SubStr(hex, 3, 2)),
        b:Integer("0x" SubStr(hex, 5, 2))}
}

NormalizeHex(value, fallback) {
    value := StrUpper(RegExReplace(Trim(value), "^#"))
    return RegExMatch(value, "^[0-9A-F]{6}$") ? value : fallback
}

IsValidHex(value) {
    return RegExMatch(StrUpper(RegExReplace(Trim(value), "^#")), "^[0-9A-F]{6}$")
}

DefaultAppearance() {
    return {trailVisible:true, pendingColor:"9BACBF", invalidColor:"FF787F",
        trailWidth:5, glow:true, hudVisible:true, hudTheme:"midnight",
        hudAlpha:248, hudPosition:"auto"}
}

LoadAppearanceSettings() {
    global APPEARANCE, SETTINGS_FILE, APPEARANCE_THEMES
    global APPEARANCE_ALPHA, APPEARANCE_POSITIONS
    style := DefaultAppearance()
    style.trailVisible := IniRead(SETTINGS_FILE, "Appearance", "TrailVisible", "1") != "0"
    style.pendingColor := NormalizeHex(IniRead(SETTINGS_FILE, "Appearance", "PendingColor", style.pendingColor), style.pendingColor)
    style.invalidColor := NormalizeHex(IniRead(SETTINGS_FILE, "Appearance", "InvalidColor", style.invalidColor), style.invalidColor)
    try width := Integer(IniRead(SETTINGS_FILE, "Appearance", "TrailWidth", "5"))
    catch
        width := 5
    style.trailWidth := (width >= 1 && width <= 30) ? width : 5
    style.glow := IniRead(SETTINGS_FILE, "Appearance", "Glow", "1") != "0"
    style.hudVisible := IniRead(SETTINGS_FILE, "Appearance", "HudVisible", "1") != "0"
    theme := IniRead(SETTINGS_FILE, "Appearance", "HudTheme", style.hudTheme)
    if ListIndex(APPEARANCE_THEMES, theme)
        style.hudTheme := theme
    try alpha := Integer(IniRead(SETTINGS_FILE, "Appearance", "HudAlpha", "248"))
    catch
        alpha := 248
    if ListIndex(APPEARANCE_ALPHA, alpha)
        style.hudAlpha := alpha
    position := IniRead(SETTINGS_FILE, "Appearance", "HudPosition", style.hudPosition)
    if ListIndex(APPEARANCE_POSITIONS, position)
        style.hudPosition := position
    APPEARANCE := style
}

SaveAppearanceSettings() {
    global APPEARANCE, SETTINGS_DIR, SETTINGS_FILE
    DirCreate(SETTINGS_DIR)
    IniWrite(APPEARANCE.trailVisible ? "1" : "0", SETTINGS_FILE, "Appearance", "TrailVisible")
    IniWrite(APPEARANCE.pendingColor, SETTINGS_FILE, "Appearance", "PendingColor")
    IniWrite(APPEARANCE.invalidColor, SETTINGS_FILE, "Appearance", "InvalidColor")
    IniWrite(APPEARANCE.trailWidth, SETTINGS_FILE, "Appearance", "TrailWidth")
    IniWrite(APPEARANCE.glow ? "1" : "0", SETTINGS_FILE, "Appearance", "Glow")
    IniWrite(APPEARANCE.hudVisible ? "1" : "0", SETTINGS_FILE, "Appearance", "HudVisible")
    IniWrite(APPEARANCE.hudTheme, SETTINGS_FILE, "Appearance", "HudTheme")
    IniWrite(APPEARANCE.hudAlpha, SETTINGS_FILE, "Appearance", "HudAlpha")
    IniWrite(APPEARANCE.hudPosition, SETTINGS_FILE, "Appearance", "HudPosition")
}

ListIndex(arr, value) {
    for i, entry in arr {
        if entry = value
            return i
    }
    return 0
}

HudThemeColors(theme) {
    switch theme {
        case "slate":
            return {bg:"282D37", badge:"394351", edge:"4B5268", eyebrow:"B2BCCB",
                title:"FAFBFE", detail:"CFD6E1", track:"464F61"}
        case "light":
            return {bg:"F2F5FA", badge:"DFE7F2", edge:"B1C5DC", eyebrow:"576778",
                title:"172334", detail:"43546B", track:"CCD7E4"}
        case "forest":
            return {bg:"142E2C", badge:"285048", edge:"3B8875", eyebrow:"A5C7BD",
                title:"F0FAF6", detail:"B9D7CB", track:"3A5550"}
        default:
            return {bg:"192434", badge:"2E3C52", edge:"48CEFF", eyebrow:"9BACBF",
                title:"F3F7FF", detail:"B3C1D3", track:"36475B"}
    }
}

