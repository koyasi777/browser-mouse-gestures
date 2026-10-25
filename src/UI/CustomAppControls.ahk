; ----- Default Notepad and user-registered applications -----
NotepadToggled(ctrl, *) {
    global NOTEPAD_ENABLED, SETUI
    old := NOTEPAD_ENABLED
    NOTEPAD_ENABLED := ctrl.Value = 1
    try SaveNotepadSetting()
    catch as err {
        NOTEPAD_ENABLED := old
        ctrl.Value := old ? 1 : 0
        MsgBox("メモ帳の設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    SETUI.appStatus.Text := "Windows メモ帳: " (NOTEPAD_ENABLED ? "有効" : "無効")
}

RefreshCustomAppsList() {
    global SETUI, CUSTOM_APPS, NOTEPAD_ENABLED
    if !IsObject(SETUI)
        return
    SETUI.refreshingApps := true
    lv := SETUI.appList
    lv.Delete()
    SETUI.appRows := []
    for app in CUSTOM_APPS {
        lv.Add(app.enabled ? "Check" : "", app.name, app.path)
        SETUI.appRows.Push(app.id)
    }
    SETUI.refreshingApps := false
    SETUI.notepadCB.Value := NOTEPAD_ENABLED ? 1 : 0
    SETUI.appStatus.Text := CUSTOM_APPS.Length " 件登録中。ウィンドウ一覧から追加できます。"
}

CustomAppToggled(ctrl, row, checked) {
    global SETUI
    if !IsObject(SETUI) || SETUI.refreshingApps || row > SETUI.appRows.Length
        return
    app := FindCustomApp(SETUI.appRows[row])
    if !IsObject(app)
        return
    old := app.enabled
    app.enabled := checked
    try SaveCustomApps()
    catch as err {
        app.enabled := old
        SETUI.refreshingApps := true
        ctrl.Modify(row, old ? "Check" : "-Check")
        SETUI.refreshingApps := false
        MsgBox("アプリ設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    SETUI.appStatus.Text := app.name " : " (app.enabled ? "有効" : "無効")
}

ShowWindowPicker(*) {
    global PICKER
    if IsObject(PICKER) {
        PickerClose()
    }
    p := Gui("-Resize -MaximizeBox", "起動中のウィンドウからアプリを追加")
    p.SetFont("s9", "Yu Gothic UI")
    p.AddText("x22 y16 w835 h43", "登録するウィンドウを選んでください。アプリの実行ファイルのパスを保存します。`n同じアプリの別ウィンドウも対象になります。")
    winLV := p.AddListView("x22 y72 w856 h377 -Multi Grid NoSortHdr", ["ウィンドウのタイトル", "アプリ", "実行ファイルのパス"])
    winLV.ModifyCol(1, 330)
    winLV.ModifyCol(2, 125)
    winLV.ModifyCol(3, 375)
    addBtn := p.AddButton("x478 y468 w196 h38 Default", "選択したアプリを追加")
    cancelBtn := p.AddButton("x688 y468 w190 h38", "キャンセル")
    p.AddText("x22 y470 w424 h52", "※管理者権限などでパスを取得できない`nウィンドウは候補から除外します。")
    windows := []
    ownPID := DllCall("kernel32\GetCurrentProcessId", "UInt")
    for hwnd in WinGetList() {
        if !DllCall("user32\IsWindowVisible", "Ptr", hwnd, "Int")
            continue
        ; Show ordinary top-level app windows, not tooltips or owned dialogs.
        if DllCall("user32\GetWindow", "Ptr", hwnd, "UInt", 4, "Ptr")
            continue
        try {
            ref := "ahk_id " hwnd
            title := Trim(WinGetTitle(ref))
            if title = "" || WinGetPID(ref) = ownPID
                continue
            exe := WinGetProcessName(ref)
            path := WinGetProcessPath(ref)
            if path = "" || SubStr(StrLower(path), -4) != ".exe"
                continue
            windows.Push({title:title, name:exe, path:path,
                className:WinGetClass(ref)})
            winLV.Add("", title, exe, path)
        } catch {
            continue
        }
    }
    PICKER := {gui:p, lv:winLV, windows:windows}
    addBtn.OnEvent("Click", PickerAddSelected)
    winLV.OnEvent("DoubleClick", PickerAddSelected)
    cancelBtn.OnEvent("Click", PickerClose)
    p.OnEvent("Close", PickerClose)
    p.OnEvent("Escape", PickerClose)
    p.Show("w900 h535")
}

PickerAddSelected(*) {
    global PICKER, CUSTOM_APPS, NEXT_APP_ID, SETUI
    if !IsObject(PICKER)
        return
    row := PICKER.lv.GetNext()
    if row <= 0 || row > PICKER.windows.Length {
        MsgBox("ウィンドウを選択してください。", "選択なし", "Iconi")
        return
    }
    item := PICKER.windows[row]
    exe := StrLower(item.name), path := StrLower(item.path)
    if IsWindowsNotepad(exe, path) {
        MsgBox("Windows メモ帳は最初から登録されています。`n対応アプリ画面のチェック欄で切り替えてください。", "登録済み", "Iconi")
        return
    }
    if exe = "applicationframehost.exe" {
        MsgBox("このウィンドウは複数のアプリで共用されるホストプロセスです。`n誤適用を避けるため登録できません。", "登録対象外", "Icon!")
        return
    }
    knownBrowser := ""
    if item.className = "Chrome_WidgetWin_1"
        knownBrowser := DetectChromium(exe, path)
    else if item.className = "MozillaWindowClass" || item.className = "MozillaUIWindowClass"
        knownBrowser := DetectGecko(exe, path)
    if knownBrowser != "" {
        MsgBox("このブラウザは既に標準対応しています。`n対応アプリ画面のブラウザ一覧で有効・無効を切り替えてください。", "登録済み", "Iconi")
        return
    }
    for app in CUSTOM_APPS {
        if StrLower(app.path) = path {
            MsgBox("この実行ファイルは既に登録されています。`n必要なら対応アプリ画面で有効にしてください。", "登録済み", "Iconi")
            return
        }
    }
    newApp := {id:"app" Format("{:05d}", NEXT_APP_ID), name:item.name,
        path:item.path, enabled:true}
    CUSTOM_APPS.Push(newApp)
    try SaveCustomApps()
    catch as err {
        CUSTOM_APPS.Pop()
        MsgBox("アプリを保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    NEXT_APP_ID += 1
    PickerClose()
    RefreshCustomAppsList()
    SETUI.appStatus.Text := item.name " を追加しました。"
}

DeleteCustomApp(*) {
    global SETUI, CUSTOM_APPS
    row := SETUI.appList.GetNext()
    if row <= 0 || row > SETUI.appRows.Length {
        MsgBox("削除するアプリを一覧から選択してください。", "選択なし", "Iconi")
        return
    }
    id := SETUI.appRows[row]
    app := FindCustomApp(id)
    if !IsObject(app)
        return
    if MsgBox("「" app.name "」の登録を削除しますか？`n" app.path, "登録を削除", "YesNo Icon?") != "Yes"
        return
    oldApps := CUSTOM_APPS.Clone()
    for i, item in CUSTOM_APPS {
        if item.id = id {
            CUSTOM_APPS.RemoveAt(i)
            break
        }
    }
    try SaveCustomApps()
    catch as err {
        CUSTOM_APPS := oldApps
        try SaveCustomApps()
        MsgBox("アプリの登録を削除できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    RefreshCustomAppsList()
    SETUI.appStatus.Text := app.name " を削除しました。"
}

PickerClose(*) {
    global PICKER
    if IsObject(PICKER)
        PICKER.gui.Destroy()
    PICKER := 0
}
