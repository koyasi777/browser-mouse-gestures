; ----- Per-browser checkbox UI -----
RefreshBrowserBoxes() {
    global SETUI, BROWSER_DEFS, BROWSER_ENABLED
    if !IsObject(SETUI)
        return
    for item in BROWSER_DEFS
        SETUI.browserBoxes[item.id].Value := BROWSER_ENABLED.Get(item.id, true) ? 1 : 0
    BrowserStatusUpdate()
}

BrowserStatusUpdate(msg := "") {
    global SETUI, BROWSER_DEFS, BROWSER_ENABLED
    if !IsObject(SETUI)
        return
    enabledCount := 0
    for item in BROWSER_DEFS {
        if BROWSER_ENABLED.Get(item.id, false)
            enabledCount += 1
    }
    prefix := msg = "" ? "保存済み" : msg
    SETUI.browserStatus.Text := prefix "  |  有効 " enabledCount " / " BROWSER_DEFS.Length " ブラウザ"
}

BrowserToggled(id, ctrl, *) {
    global BROWSER_ENABLED
    wasEnabled := BROWSER_ENABLED.Get(id, true)
    enabled := (ctrl.Value = 1)
    BROWSER_ENABLED[id] := enabled
    try SaveOneBrowser(id, enabled)
    catch as err {
        BROWSER_ENABLED[id] := wasEnabled
        ctrl.Value := wasEnabled ? 1 : 0
        MsgBox("ブラウザの設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    BrowserStatusUpdate("変更を保存しました")
}

BrowserSetAll(enabled, *) {
    global BROWSER_DEFS, BROWSER_ENABLED
    old := BROWSER_ENABLED.Clone()
    for item in BROWSER_DEFS
        BROWSER_ENABLED[item.id] := enabled
    try SaveAllBrowsers()
    catch as err {
        BROWSER_ENABLED := old
        try SaveAllBrowsers()
        RefreshBrowserBoxes()
        MsgBox("ブラウザの設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    RefreshBrowserBoxes()
    BrowserStatusUpdate(enabled ? "すべて有効にしました" : "すべて無効にしました")
}


