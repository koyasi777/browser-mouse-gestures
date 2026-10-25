ApplyAppIcon() {
    global ICON_CONFIG, SETUI, ICON_UI
    selected := IconFilePath(ICON_CONFIG)
    if selected != "" && !IsLoadableIcon(selected)
        throw Error("アイコンを読み込めません: " selected)
    if selected = ""
        TraySetIcon("*", , false) ; Restore the normal AutoHotkey script icon.
    else
        TraySetIcon(selected, 1, true)
    if IsObject(SETUI)
        SetGuiAppIcon(SETUI.gui, selected)
    if IsObject(ICON_UI)
        SetGuiAppIcon(ICON_UI.gui, selected)
}

; WM_SETICON accepts HICON, but does not take ownership of it.
; Keep the handles alive as long as the corresponding GUI exists.
SetGuiAppIcon(windowGui, selected := "@CURRENT") {
    global GUI_ICON_HANDLES, ICON_CONFIG
    if selected = "@CURRENT"
        selected := IconFilePath(ICON_CONFIG)
    hSmall := 0, hBig := 0
    if selected = "" {
        ; Extract the original AHK executable's icon (index 0).
        count := DllCall("shell32\ExtractIconExW", "WStr", A_AhkPath,
            "Int", 0, "Ptr*", &hBig, "Ptr*", &hSmall, "UInt", 1, "UInt")
        if !count || !hBig || !hSmall {
            if hBig
                DllCall("user32\DestroyIcon", "Ptr", hBig)
            if hSmall
                DllCall("user32\DestroyIcon", "Ptr", hSmall)
            ; If the executable has no usable icon, use the Windows app icon.
            hBig := DllCall("user32\CopyIcon", "Ptr", DllCall("user32\LoadIconW", "Ptr", 0, "Ptr", 32512, "Ptr"), "Ptr")
            hSmall := DllCall("user32\CopyIcon", "Ptr", hBig, "Ptr")
        }
    } else {
        hBig := DllCall("user32\LoadImageW", "Ptr", 0, "WStr", selected,
            "UInt", 1, "Int", 32, "Int", 32, "UInt", 0x10, "Ptr")
        hSmall := DllCall("user32\LoadImageW", "Ptr", 0, "WStr", selected,
            "UInt", 1, "Int", 16, "Int", 16, "UInt", 0x10, "Ptr")
    }
    if !hBig || !hSmall {
        if hBig
            DllCall("user32\DestroyIcon", "Ptr", hBig)
        if hSmall
            DllCall("user32\DestroyIcon", "Ptr", hSmall)
        throw Error("設定ウィンドウ用アイコンの生成に失敗しました。")
    }
    ; Deliver both window icon sizes before releasing the previous handles.
    DllCall("user32\SendMessageW", "Ptr", windowGui.Hwnd, "UInt", 0x80, "UPtr", 1,
        "Ptr", hBig, "Ptr")
    DllCall("user32\SendMessageW", "Ptr", windowGui.Hwnd, "UInt", 0x80, "UPtr", 0,
        "Ptr", hSmall, "Ptr")
    if GUI_ICON_HANDLES.Has(windowGui.Hwnd) {
        old := GUI_ICON_HANDLES[windowGui.Hwnd]
        if old.big
            DllCall("user32\DestroyIcon", "Ptr", old.big)
        if old.small
            DllCall("user32\DestroyIcon", "Ptr", old.small)
    }
    GUI_ICON_HANDLES[windowGui.Hwnd] := {big:hBig, small:hSmall}
}

ShowIconSettings(*) {
    global SETUI, ICON_UI, ICON_CHOICE_LABELS
    if IsObject(ICON_UI) {
        RefreshIconControls()
        ICON_UI.gui.Show()
        return
    }
    g := Gui("+Owner" SETUI.gui.Hwnd " -Resize -MaximizeBox", "アプリアイコンの設定")
    try SetGuiAppIcon(g)
    g.BackColor := "F6F8FB"
    g.MarginX := 16, g.MarginY := 16
    g.SetFont("s10 bold", "Yu Gothic UI")
    g.AddText("x24 y20 w460 h29", "タスクトレイ・設定ウィンドウのアイコン")
    g.SetFont("s9 norm", "Yu Gothic UI")
    g.AddText("x24 y53 w463 h38", "プリセット、AHK標準、または任意の .ico を選べます。`n変更は保存後すぐに反映されます。")
    g.AddText("x24 y110 w220 h24", "アイコンの種類")
    choice := g.AddDropDownList("x24 y136 w310", ICON_CHOICE_LABELS)
    pic := g.AddPicture("x405 y117 w68 h68 Icon1", EnsurePresetIcon("cursor"))
    g.AddText("x24 y211 w440 h23", "カスタムアイコン（.ico）")
    customPath := g.AddEdit("x24 y239 w341 h29 ReadOnly", "")
    pickBtn := g.AddButton("x374 y238 w99 h31", "参照...")
    g.AddText("x24 y283 w455 h38", "選択したICOはアプリの設定フォルダへコピーします。`n元のファイルを移動しても設定を維持できます。")
    applyBtn := g.AddButton("x24 y338 w228 h38 Default", "適用して保存")
    closeBtn := g.AddButton("x263 y338 w210 h38", "閉じる")
    status := g.AddText("x24 y390 w460 h37", "")
    ICON_UI := {gui:g, choice:choice, pic:pic, customPath:customPath,
        pickBtn:pickBtn, status:status, chosenCustom:""}
    choice.OnEvent("Change", IconChoiceChanged)
    pickBtn.OnEvent("Click", PickCustomIcon)
    applyBtn.OnEvent("Click", SaveIconSelection)
    closeBtn.OnEvent("Click", IconSettingsClose)
    g.OnEvent("Close", IconSettingsClose)
    g.OnEvent("Escape", IconSettingsClose)
    RefreshIconControls()
    g.Show("w500 h441")
}

RefreshIconControls() {
    global ICON_CONFIG, ICON_UI, ICON_PRESET_IDS
    if !IsObject(ICON_UI)
        return
    iconCfg := ICON_CONFIG
    n := iconCfg.mode = "default" ? 5 : iconCfg.mode = "custom" ? 6 : ListIndex(ICON_PRESET_IDS, iconCfg.preset)
    ICON_UI.choice.Choose(n > 0 ? n : 1)
    ICON_UI.chosenCustom := iconCfg.customPath
    ICON_UI.customPath.Value := iconCfg.customPath
    IconChoiceChanged()
    ICON_UI.status.Text := "現在のアイコンを選択しています。"
}

IconChoiceChanged(*) {
    global ICON_UI, ICON_PRESET_IDS
    if !IsObject(ICON_UI)
        return
    n := ICON_UI.choice.Value
    isCustom := n = 6
    ICON_UI.pickBtn.Enabled := isCustom
    path := ""
    if n >= 1 && n <= 4
        path := EnsurePresetIcon(ICON_PRESET_IDS[n])
    else if n = 5
        path := A_AhkPath
    else if isCustom && FileExist(ICON_UI.chosenCustom)
        path := ICON_UI.chosenCustom
    if path != "" {
        try ICON_UI.pic.Value := path
        catch {
            ; Some systems cannot preview EXE icons in a Picture control.
            ICON_UI.status.Text := "この形式はプレビューできませんが、適用は可能です。"
        }
    }
}

PickCustomIcon(*) {
    global ICON_UI
    current := ICON_UI.chosenCustom
    path := FileSelect(1, current != "" ? current : "", "ICOファイルを選択", "アイコン (*.ico)")
    if path = ""
        return
    if !IsLoadableIcon(path) {
        MsgBox("有効なWindows ICOファイルを指定してください。", "アイコンを読み込めません", "Icon!")
        return
    }
    ICON_UI.chosenCustom := path
    ICON_UI.customPath.Value := path
    ICON_UI.choice.Choose(6)
    IconChoiceChanged()
    ICON_UI.status.Text := "カスタムICOを選択しました。保存して反映できます。"
}

SaveIconSelection(*) {
    global ICON_CONFIG, ICON_PRESET_IDS, ICON_UI, SETTINGS_DIR
    n := ICON_UI.choice.Value
    if n < 1 || n > 6
        return
    old := ICON_CONFIG
    candidate := {mode:"preset", preset:old.preset, customPath:old.customPath}
    if n <= 4
        candidate.preset := ICON_PRESET_IDS[n]
    else if n = 5
        candidate.mode := "default"
    else {
        candidate.mode := "custom"
        source := ICON_UI.chosenCustom
        if !IsLoadableIcon(source) {
            MsgBox("カスタムアイコンを選択してください。有効な .ico ファイルが必要です。", "アイコンの選択", "Icon!")
            return
        }
        targetFolder := SETTINGS_DIR "\icons"
        try {
            DirCreate(targetFolder)
            ; Keep a unique file name so Windows icon caching cannot show
            ; an older custom icon after the user selects a different one.
            if StrLower(source) = StrLower(old.customPath) {
                candidate.customPath := source
            } else {
                target := targetFolder "\custom_" A_Now "_" A_TickCount ".ico"
                FileCopy(source, target, 1)
                candidate.customPath := target
            }
        } catch as err {
            MsgBox("アイコンを保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
            return
        }
    }
    ICON_CONFIG := candidate
    try {
        ApplyAppIcon()
        SaveIconSettings()
    } catch as err {
        ICON_CONFIG := old
        try ApplyAppIcon()
        MsgBox("アイコンの適用・保存に失敗しました。`n" err.Message, "アイコン設定エラー", "Iconx")
        return
    }
    RefreshIconControls()
    ICON_UI.status.Text := "アイコンを変更して保存しました。"
}

IconSettingsClose(*) {
    global ICON_UI
    if IsObject(ICON_UI)
        ICON_UI.gui.Hide()
}

