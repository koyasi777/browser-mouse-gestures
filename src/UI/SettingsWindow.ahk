ShowSettings(*) {
    global SETUI, BINDINGS, ACTIONS, ACTION_ORDER, BROWSER_DEFS, WHEEL_INTERVALS
    global APPEARANCE_THEME_NAMES, APPEARANCE_ALPHA_NAMES, APPEARANCE_POSITION_NAMES
    if IsObject(SETUI) {
        RefreshSettingsList()
        RefreshBrowserBoxes()
        RefreshWheelControls()
        RefreshRecognitionControls()
        RefreshAppearanceControls()
        RefreshCustomAppsList()
        SettingsClear()
        SETUI.gui.Show()
        return
    }

    g := Gui("-Resize -MaximizeBox", "Browser Mouse Gestures  |  設定")
    try SetGuiAppIcon(g)
    g.BackColor := "F6F8FB"
    g.MarginX := 14, g.MarginY := 14
    g.SetFont("s9", "Yu Gothic UI")
    tabs := g.AddTab3("x14 y14 w672 h760", ["ジェスチャー", "ホイール", "対応アプリ", "判定感度", "外観"])
    tabs.UseTab(1)

    g.SetFont("s10 bold", "Yu Gothic UI")
    g.AddText("x36 y68 w610 h30", "マウスジェスチャーの割り当て")
    g.SetFont("s9 norm", "Yu Gothic UI")
    g.AddText("x36 y100 w620 h39", "右ボタンを押しながら上下左右に動かします。1～3方向まで登録できます。`n未登録の動きは何も実行しません。")
    lv := g.AddListView("x36 y150 w628 h235 Grid -Multi", ["ジェスチャー", "実行する操作", "軌跡色"])
    lv.ModifyCol(1, 105)
    lv.ModifyCol(2, 315)
    lv.ModifyCol(3, 185)
    lv.OnEvent("ItemSelect", SettingsSelectionChanged)

    g.SetFont("s10 bold", "Yu Gothic UI")
    g.AddText("x36 y401 w620 h24", "割り当てを追加・編集")
    g.SetFont("s9 norm", "Yu Gothic UI")
    g.AddText("x36 y435 w190 h22", "方向1（必須）")
    g.AddText("x248 y435 w190 h22", "方向2（任意）")
    g.AddText("x460 y435 w190 h22", "方向3（任意）")
    choices := ["（なし）", "↑", "↓", "←", "→"]
    d1 := g.AddDropDownList("x36 y459 w194 Choose1", choices)
    d2 := g.AddDropDownList("x248 y459 w194 Choose1", choices)
    d3 := g.AddDropDownList("x460 y459 w194 Choose1", choices)
    g.AddText("x36 y506 w620 h22", "実行する操作")
    names := []
    for id in ACTION_ORDER
        names.Push(ACTIONS[id].name)
    actionDDL := g.AddDropDownList("x36 y530 w618 Choose1", names)

    g.AddText("x36 y575 w79 h23", "軌跡の色")
    gestureColorEdit := g.AddEdit("x114 y570 w120 h27 Limit7", "")
    gesturePickBtn := g.AddButton("x245 y570 w112 h28", "色を選択...")
    gestureAutoBtn := g.AddButton("x364 y570 w105 h28", "自動配色に戻す")
    g.AddText("x481 y575 w176 h23", "空欄なら自動配色")
    saveBtn := g.AddButton("x36 y628 w179 h38 Default", "追加 / 更新して保存")
    deleteBtn := g.AddButton("x225 y628 w132 h38", "選択した設定を削除")
    clearBtn := g.AddButton("x367 y628 w128 h38", "入力をクリア")
    defaultBtn := g.AddButton("x505 y628 w149 h38", "初期設定に戻す")
    status := g.AddText("x36 y682 w620 h28", "")
    g.AddText("x36 y715 w620 h43", "色は6桁のRRGGBB形式。空欄は各方向に応じた自動色です。`n※同じ方向の連続（↓↓など）は登録できません。")

    tabs.UseTab(2)
    g.SetFont("s11 bold", "Yu Gothic UI")
    g.AddText("x36 y77 w620 h31", "右クリック ＋ ホイールでタブを移動")
    g.SetFont("s9 norm", "Yu Gothic UI")
    g.AddText("x36 y120 w618 h54", "右ボタンを押しながらホイールを回すと、現在のアプリのタブを切り替えます。`nホイール操作を始めると軌跡ジェスチャーはキャンセルされます。")
    wheelEnabled := g.AddCheckBox("x43 y201 w580 h34", "右クリック ＋ ホイール操作を有効にする")
    g.SetFont("s10 bold", "Yu Gothic UI")
    g.AddText("x44 y270 w595 h29", "移動方向")
    g.SetFont("s9 norm", "Yu Gothic UI")
    wheelNormal := g.AddRadio("x56 y306 w575 h29 Group", "上回転：前のタブ　／　下回転：次のタブ（標準）")
    wheelReverse := g.AddRadio("x56 y353 w575 h29", "上回転：次のタブ　／　下回転：前のタブ（逆方向）")
    g.SetFont("s10 bold", "Yu Gothic UI")
    g.AddText("x44 y437 w596 h28", "連続切り替え間隔")
    g.SetFont("s9 norm", "Yu Gothic UI")
    intervals := []
    for n in WHEEL_INTERVALS
        intervals.Push(n " ms")
    wheelDelay := g.AddDropDownList("x46 y477 w214", intervals)
    g.AddText("x285 y480 w347 h50", "短くすると高速スクロール時に多くのタブを移動します。")
    wheelStatus := g.AddText("x44 y585 w586 h50", "")
    g.AddText("x44 y654 w590 h70", "※通常のホイールは変更しません。`n※タブ切り替えのキー操作は Ctrl + Tab / Ctrl + Shift + Tab です。")

    tabs.UseTab(3)
    g.SetFont("s10 bold", "Yu Gothic UI")
    g.AddText("x36 y69 w620 h30", "マウスジェスチャーを有効にするアプリ")
    g.SetFont("s9 norm", "Yu Gothic UI")
    g.AddText("x36 y99 w620 h45", "標準ブラウザとWindows メモ帳は初期状態で有効です。`nアプリを追加した場合も、個別に無効化できます。変更は自動保存されます。")
    g.SetFont("s9 bold", "Yu Gothic UI")
    g.AddText("x36 y150 w260 h25", "Chromium 系")
    g.AddText("x362 y150 w260 h25", "Firefox / Gecko 系")
    g.SetFont("s9 norm", "Yu Gothic UI")
    browserBoxes := Map()
    chromiumRow := 0, geckoRow := 0
    for item in BROWSER_DEFS {
        if item.family = "Chromium" {
            bx := 38, by := 182 + chromiumRow*32
            chromiumRow += 1
        } else {
            bx := 363, by := 182 + geckoRow*32
            geckoRow += 1
        }
        cb := g.AddCheckBox("x" bx " y" by " w290 h27 Checked", item.name)
        browserBoxes[item.id] := cb
        cb.OnEvent("Click", BrowserToggled.Bind(item.id))
    }
    g.SetFont("s9 bold", "Yu Gothic UI")
    g.AddText("x363 y414 w295 h26", "その他のアプリ")
    g.SetFont("s9 norm", "Yu Gothic UI")
    notepadCB := g.AddCheckBox("x363 y441 w290 h29 Checked", "Windows メモ帳")
    g.AddText("x363 y477 w285 h20", "追加したアプリ（チェックで切替）")
    appList := g.AddListView("x363 y500 w300 h120 Checked -Multi Grid NoSortHdr", ["アプリ", "実行ファイルのパス"])
    appList.ModifyCol(1, 120)
    appList.ModifyCol(2, 280)
    addAppBtn := g.AddButton("x363 y627 w170 h35", "起動中のウィンドウから追加")
    removeAppBtn := g.AddButton("x542 y627 w121 h35", "選択を削除")
    appStatus := g.AddText("x363 y671 w300 h58", "")
    allOnBtn := g.AddButton("x36 y662 w150 h36", "ブラウザをすべて有効")
    allOffBtn := g.AddButton("x195 y662 w150 h36", "ブラウザをすべて無効")
    browserStatus := g.AddText("x36 y716 w302 h28", "")

    tabs.UseTab(4)
    g.SetFont("s11 bold", "Yu Gothic UI")
    g.AddText("x36 y73 w610 h36", "方向認識のゆるさを調整")
    g.SetFont("s9 norm", "Yu Gothic UI")
    g.AddText("x36 y118 w614 h74", "長い移動でも斜めへのずれを許容します。↑ ↓ ← → の4方向のみを認識します。`n曲がり角の動きを連続して確認することで、小さな手ぶれを吸収します。`n最大3方向・未登録ジェスチャーは無効という仕様も維持します。")
    g.SetFont("s10 bold", "Yu Gothic UI")
    g.AddText("x44 y242 w595 h32", "斜め方向へのずれの許容度")
    g.SetFont("s9 norm", "Yu Gothic UI")
    g.AddText("x45 y287 w120 h26", "厳密に判定")
    g.AddText("x524 y287 w125 h26 Right", "ゆるく判定")
    recognitionSlider := g.AddSlider("x43 y324 w610 h70 Range1-7 TickInterval1 ToolTip", 3)
    recognitionTitle := g.AddText("x44 y413 w610 h35", "")
    recognitionDetails := g.AddText("x44 y459 w604 h86", "")
    g.SetFont("s9 bold", "Yu Gothic UI")
    g.AddText("x44 y573 w595 h26", "調整時の注意")
    g.SetFont("s9 norm", "Yu Gothic UI")
    g.AddText("x44 y609 w602 h78", "レベル6～7は大きな斜めずれも許容するため、誤認識の可能性があります。`nまずレベル4～5を試し、まだ厳しい場合に6～7へ上げてください。`n右クリック＋ホイールや通常の右クリックは従来どおりです。")
    recognitionDefaultBtn := g.AddButton("x44 y706 w220 h37", "標準の判定に戻す")

    tabs.UseTab(5)
    g.SetFont("s11 bold", "Yu Gothic UI")
    g.AddText("x36 y72 w614 h35", "マウスの軌跡とHUDをカスタマイズ")
    g.SetFont("s9 norm", "Yu Gothic UI")
    g.AddText("x36 y112 w612 h39", "見た目だけを変更します。上下左右の認識・タブ操作は変わりません。`n設定は「適用して保存」を押したときに反映されます。")

    g.SetFont("s10 bold", "Yu Gothic UI")
    g.AddText("x42 y168 w600 h29", "マウスの軌跡")
    g.SetFont("s9 norm", "Yu Gothic UI")
    appearanceTrailVisible := g.AddCheckBox("x46 y203 w260 h28", "軌跡を表示する")
    g.AddText("x46 y247 w115 h23", "未確定時の色")
    appearancePendingColor := g.AddEdit("x158 y243 w105 h27 Limit7", "")
    trailPickBtn := g.AddButton("x274 y242 w99 h28", "色を選択...")
    g.AddText("x387 y247 w115 h23", "無効時の色")
    appearanceInvalidColor := g.AddEdit("x489 y243 w102 h27 Limit7", "")
    invalidPickBtn := g.AddButton("x596 y242 w58 h28", "選択...")
    g.AddText("x46 y297 w107 h24", "軌跡の太さ")
    ; An edit control with an UpDown buddy accepts every integer from 1 to 30.
    ; Keep the Edit reference so typed values can be validated before saving.
    appearanceWidth := g.AddEdit("x158 y291 w138 h28 Number", "5")
    appearanceWidthSpinner := g.AddUpDown("Range1-30", 5)
    g.AddText("x299 y297 w33 h24", "px")
    appearanceGlow := g.AddCheckBox("x336 y295 w276 h29", "柔らかい発光を表示する")
    g.AddText("x46 y334 w598 h48", "太さは1～30px、色は6桁の16進数です。未確定時の色は方向がまだ認識されていないときに使用します。`n登録済みジェスチャーの色は「ジェスチャー」タブで設定できます。")

    g.SetFont("s10 bold", "Yu Gothic UI")
    g.AddText("x42 y397 w594 h29", "ジェスチャーHUD")
    g.SetFont("s9 norm", "Yu Gothic UI")
    appearanceHudVisible := g.AddCheckBox("x46 y428 w294 h30", "HUD（操作名のカード）を表示する")
    g.AddText("x46 y482 w140 h23", "配色テーマ")
    appearanceTheme := g.AddDropDownList("x174 y478 w178", APPEARANCE_THEME_NAMES)
    g.AddText("x375 y482 w105 h23", "透明度")
    appearanceAlpha := g.AddDropDownList("x472 y478 w168", APPEARANCE_ALPHA_NAMES)
    g.AddText("x46 y533 w140 h23", "表示位置")
    appearancePosition := g.AddDropDownList("x174 y529 w250", APPEARANCE_POSITION_NAMES)
    g.AddText("x46 y581 w596 h53", "※ライトテーマでは文字が読みやすいように色も切り替えます。`n※複数モニターでもカードは画面内に収まるよう調整されます。")
    appearanceSaveBtn := g.AddButton("x45 y663 w185 h41", "適用して保存")
    appearanceDefaultBtn := g.AddButton("x240 y663 w183 h41", "外観だけ初期化")
    appearanceIconBtn := g.AddButton("x433 y663 w220 h41", "アプリアイコンを変更...")
    appearanceStatus := g.AddText("x44 y716 w599 h27", "")
    tabs.UseTab()

    SETUI := {gui:g, tabs:tabs, lv:lv, dir:[d1,d2,d3], action:actionDDL,
        gestureColor:gestureColorEdit, status:status, selected:"", browserBoxes:browserBoxes,
        browserStatus:browserStatus, wheelEnabled:wheelEnabled,
        wheelNormal:wheelNormal, wheelReverse:wheelReverse,
        wheelDelay:wheelDelay, wheelStatus:wheelStatus,
        recognitionSlider:recognitionSlider, recognitionTitle:recognitionTitle,
        recognitionDetails:recognitionDetails,
        appearanceTrailVisible:appearanceTrailVisible, appearancePendingColor:appearancePendingColor,
        appearanceInvalidColor:appearanceInvalidColor, appearanceWidth:appearanceWidth,
        appearanceWidthSpinner:appearanceWidthSpinner,
        appearanceGlow:appearanceGlow, appearanceHudVisible:appearanceHudVisible,
        appearanceTheme:appearanceTheme, appearanceAlpha:appearanceAlpha,
        appearancePosition:appearancePosition, appearanceStatus:appearanceStatus,
        notepadCB:notepadCB, appList:appList,
        appStatus:appStatus, appRows:[], refreshingApps:false}
    saveBtn.OnEvent("Click", SettingsSave)
    deleteBtn.OnEvent("Click", SettingsDelete)
    clearBtn.OnEvent("Click", SettingsClear)
    defaultBtn.OnEvent("Click", SettingsRestoreDefaults)
    gesturePickBtn.OnEvent("Click", PickGestureColor)
    gestureAutoBtn.OnEvent("Click", GestureAutoColor)
    allOnBtn.OnEvent("Click", BrowserSetAll.Bind(true))
    allOffBtn.OnEvent("Click", BrowserSetAll.Bind(false))
    wheelEnabled.OnEvent("Click", WheelChanged)
    wheelNormal.OnEvent("Click", WheelChanged)
    wheelReverse.OnEvent("Click", WheelChanged)
    wheelDelay.OnEvent("Change", WheelChanged)
    recognitionSlider.OnEvent("Change", RecognitionChanged)
    recognitionDefaultBtn.OnEvent("Click", RecognitionRestoreDefault)
    trailPickBtn.OnEvent("Click", PickAppearanceColor.Bind("pending"))
    invalidPickBtn.OnEvent("Click", PickAppearanceColor.Bind("invalid"))
    appearanceSaveBtn.OnEvent("Click", AppearanceSave)
    appearanceDefaultBtn.OnEvent("Click", AppearanceRestoreDefaults)
    appearanceIconBtn.OnEvent("Click", ShowIconSettings)
    notepadCB.OnEvent("Click", NotepadToggled)
    appList.OnEvent("ItemCheck", CustomAppToggled)
    addAppBtn.OnEvent("Click", ShowWindowPicker)
    removeAppBtn.OnEvent("Click", DeleteCustomApp)
    g.OnEvent("Close", SettingsClose)
    g.OnEvent("Escape", SettingsClose)
    RefreshSettingsList()
    RefreshBrowserBoxes()
    RefreshWheelControls()
    RefreshRecognitionControls()
    RefreshAppearanceControls()
    RefreshCustomAppsList()
    g.Show("w700 h795")
}

RefreshAppearanceControls() {
    global SETUI, APPEARANCE, APPEARANCE_THEMES, APPEARANCE_ALPHA, APPEARANCE_POSITIONS
    if !IsObject(SETUI)
        return
    a := APPEARANCE
    SETUI.appearanceTrailVisible.Value := a.trailVisible ? 1 : 0
    SETUI.appearancePendingColor.Value := a.pendingColor
    SETUI.appearanceInvalidColor.Value := a.invalidColor
    SETUI.appearanceWidthSpinner.Value := a.trailWidth
    SETUI.appearanceWidth.Value := a.trailWidth
    SETUI.appearanceGlow.Value := a.glow ? 1 : 0
    SETUI.appearanceHudVisible.Value := a.hudVisible ? 1 : 0
    SETUI.appearanceTheme.Choose(ListIndex(APPEARANCE_THEMES, a.hudTheme))
    SETUI.appearanceAlpha.Choose(ListIndex(APPEARANCE_ALPHA, a.hudAlpha))
    SETUI.appearancePosition.Choose(ListIndex(APPEARANCE_POSITIONS, a.hudPosition))
    SETUI.appearanceStatus.Text := "現在の設定を表示しています。"
}

AppearanceSave(*) {
    global SETUI, APPEARANCE, APPEARANCE_THEMES, APPEARANCE_ALPHA, APPEARANCE_POSITIONS
    global ST, Hud
    c1 := SETUI.appearancePendingColor.Text
    c2 := SETUI.appearanceInvalidColor.Text
    if !IsValidHex(c1) || !IsValidHex(c2) {
        MsgBox("色はRRGGBB形式の6桁の16進数で入力してください。`n例：67D9FF または #67D9FF", "色の入力エラー", "Icon!")
        return
    }
    widthText := Trim(SETUI.appearanceWidth.Text)
    if !RegExMatch(widthText, "^[0-9]{1,2}$") || Integer(widthText) < 1 || Integer(widthText) > 30 {
        MsgBox("軌跡の太さは1～30の整数で指定してください。", "太さの入力エラー", "Icon!")
        SETUI.appearanceWidth.Focus()
        return
    }
    widthPx := Integer(widthText)
    newStyle := {
        trailVisible:SETUI.appearanceTrailVisible.Value = 1,
        pendingColor:NormalizeHex(c1, "9BACBF"),
        invalidColor:NormalizeHex(c2, "FF787F"),
        trailWidth:widthPx,
        glow:SETUI.appearanceGlow.Value = 1,
        hudVisible:SETUI.appearanceHudVisible.Value = 1,
        hudTheme:APPEARANCE_THEMES[Max(1, Min(APPEARANCE_THEMES.Length, SETUI.appearanceTheme.Value))],
        hudAlpha:APPEARANCE_ALPHA[Max(1, Min(APPEARANCE_ALPHA.Length, SETUI.appearanceAlpha.Value))],
        hudPosition:APPEARANCE_POSITIONS[Max(1, Min(APPEARANCE_POSITIONS.Length, SETUI.appearancePosition.Value))]
    }
    oldStyle := APPEARANCE
    ; Persist before rebuilding Windows resources; on disk failure, keep old UI.
    APPEARANCE := newStyle
    try SaveAppearanceSettings()
    catch as err {
        APPEARANCE := oldStyle
        MsgBox("外観設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    ; The next gesture will use the new palette. Never change the brush
    ; or destroy a layered window while a right-button gesture is active.
    if ST.active {
        SetTimer(TrackGesture, 0)
        ST.active := false
        HideTrail()
        if ST.hudShown
            Hud.gui.Hide()
    }
    try {
        RefreshTrailBrushes()
        Hud.gui.Destroy()
        Hud := NewHud()
    } catch as err {
        ; Configuration remains saved; show the error for troubleshooting.
        MsgBox("外観の再生成で問題が発生しました。再起動して再試行してください。`n" err.Message,
            "表示の更新エラー", "Iconx")
        return
    }
    RefreshAppearanceControls()
    SETUI.appearanceStatus.Text := "適用して保存しました。次のジェスチャーから反映されます。"
}

AppearanceRestoreDefaults(*) {
    global SETUI
    if MsgBox("軌跡の色・太さ・HUDの見た目を初期状態に戻しますか？`nジェスチャーやブラウザ設定は変更しません。",
        "外観を初期化", "YesNo Icon?") != "Yes"
        return
    defaults := DefaultAppearance()
    SETUI.appearanceTrailVisible.Value := 1
    SETUI.appearancePendingColor.Value := defaults.pendingColor
    SETUI.appearanceInvalidColor.Value := defaults.invalidColor
    SETUI.appearanceWidthSpinner.Value := defaults.trailWidth
    SETUI.appearanceWidth.Value := defaults.trailWidth
    SETUI.appearanceGlow.Value := 1
    SETUI.appearanceHudVisible.Value := 1
    SETUI.appearanceTheme.Choose(1)
    SETUI.appearanceAlpha.Choose(2)
    SETUI.appearancePosition.Choose(1)
    AppearanceSave()
}

; Reuse the same native Windows color picker for global and per-gesture colors.
ChooseTrailColor(initial, ownerHwnd) {
    rgb := ColorRGB(initial)
    is64 := (A_PtrSize = 8)
    cc := Buffer(is64 ? 72 : 36, 0)
    customColors := Buffer(16 * 4, 0)
    NumPut("UInt", cc.Size, cc, 0)
    NumPut("Ptr", ownerHwnd, cc, is64 ? 8 : 4)
    NumPut("UInt", rgb.r | (rgb.g << 8) | (rgb.b << 16), cc, is64 ? 24 : 12)
    NumPut("Ptr", customColors.Ptr, cc, is64 ? 32 : 16)
    NumPut("UInt", 0x00000003, cc, is64 ? 40 : 20) ; CC_RGBINIT | CC_FULLOPEN
    if !DllCall("comdlg32\ChooseColorW", "Ptr", cc.Ptr, "Int")
        return ""
    selected := NumGet(cc, is64 ? 24 : 12, "UInt")
    return Format("{:02X}{:02X}{:02X}", selected & 255,
        (selected >> 8) & 255, (selected >> 16) & 255)
}

PickAppearanceColor(which, *) {
    global SETUI
    field := which = "pending" ? SETUI.appearancePendingColor : SETUI.appearanceInvalidColor
    selected := ChooseTrailColor(field.Text, SETUI.gui.Hwnd)
    if selected != ""
        field.Value := selected
}

RefreshSettingsList() {
    global SETUI, BINDINGS, ACTIONS, GESTURE_COLORS
    if !IsObject(SETUI)
        return
    lv := SETUI.lv
    lv.Delete()
    for seq, id in BINDINGS {
        if ACTIONS.Has(id) {
            suffix := GESTURE_COLORS.Has(seq) ? "" : " (自動)"
            lv.Add("", SequenceToArrows(seq), ACTIONS[id].name, "#" GestureColor(seq) suffix)
        }
    }
    lv.ModifyCol(1, 105)
    lv.ModifyCol(2, 315)
    lv.ModifyCol(3, 185)
}

SettingsSelectionChanged(ctrl, row, selected) {
    global SETUI, BINDINGS, ACTION_ORDER, GESTURE_COLORS
    if !selected || !row
        return
    seq := ArrowsToSequence(ctrl.GetText(row, 1))
    if !BINDINGS.Has(seq)
        return
    SETUI.selected := seq
    Loop 3 {
        ch := A_Index <= StrLen(seq) ? SubStr(seq, A_Index, 1) : ""
        index := 1
        switch ch {
            case "U": index := 2
            case "D": index := 3
            case "L": index := 4
            case "R": index := 5
        }
        SETUI.dir[A_Index].Choose(index)
    }
    for i, id in ACTION_ORDER {
        if id = BINDINGS[seq] {
            SETUI.action.Choose(i)
            break
        }
    }
    SETUI.gestureColor.Value := GESTURE_COLORS.Get(seq, "")
    SETUI.status.Text := "「" SequenceToArrows(seq) "」を編集中です。色が空欄なら自動配色です。"
}

SettingsSave(*) {
    global SETUI, BINDINGS, ACTION_ORDER, GESTURE_COLORS
    seq := "", blankSeen := false
    for index, ddl in SETUI.dir {
        ch := ArrowDir(ddl.Text)
        if ch = "" {
            blankSeen := true
            continue
        }
        if blankSeen {
            MsgBox("方向を飛ばさず、左から順に選択してください。", "入力エラー", "Icon!")
            return
        }
        seq .= ch
    }
    if !IsValidSequence(seq) {
        MsgBox("上下左右から1～3方向を指定してください。`n連続する同じ方向（↓↓など）は指定できません。", "入力エラー", "Icon!")
        return
    }
    idx := SETUI.action.Value
    if idx < 1 || idx > ACTION_ORDER.Length
        return
    if BINDINGS.Has(seq) && seq != SETUI.selected {
        MsgBox("「" SequenceToArrows(seq) "」はすでに登録されています。`n一覧から選択して編集してください。", "重複した設定", "Icon!")
        return
    }
    chosen := Trim(SETUI.gestureColor.Text)
    if chosen != "" && !IsValidHex(chosen) {
        MsgBox("軌跡色は6桁の16進数（RRGGBB）で入力するか、空欄で自動配色にしてください。",
            "色の入力エラー", "Icon!")
        SETUI.gestureColor.Focus()
        return
    }
    old := BINDINGS.Clone()
    oldColors := GESTURE_COLORS.Clone()
    if SETUI.selected != "" && BINDINGS.Has(SETUI.selected) {
        BINDINGS.Delete(SETUI.selected)
        if GESTURE_COLORS.Has(SETUI.selected)
            GESTURE_COLORS.Delete(SETUI.selected)
    }
    BINDINGS[seq] := ACTION_ORDER[idx]
    if chosen != ""
        GESTURE_COLORS[seq] := NormalizeHex(chosen, "67D9FF")
    else if GESTURE_COLORS.Has(seq)
        GESTURE_COLORS.Delete(seq)
    try {
        SaveBindings()
        SaveGestureColors()
    } catch as err {
        BINDINGS := old
        GESTURE_COLORS := oldColors
        try SaveBindings()
        try SaveGestureColors()
        MsgBox("設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    RefreshSettingsList()
    SettingsClear()
    SETUI.status.Text := "保存しました：" SequenceToArrows(seq)
}

SettingsDelete(*) {
    global SETUI, BINDINGS, GESTURE_COLORS
    seq := SETUI.selected
    if seq = "" || !BINDINGS.Has(seq) {
        MsgBox("削除する割り当てを一覧から選択してください。", "選択なし", "Iconi")
        return
    }
    old := BINDINGS.Clone()
    oldColors := GESTURE_COLORS.Clone()
    BINDINGS.Delete(seq)
    if GESTURE_COLORS.Has(seq)
        GESTURE_COLORS.Delete(seq)
    try {
        SaveBindings()
        SaveGestureColors()
    } catch as err {
        BINDINGS := old
        GESTURE_COLORS := oldColors
        try SaveBindings()
        try SaveGestureColors()
        MsgBox("設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    RefreshSettingsList()
    SettingsClear()
    SETUI.status.Text := "削除しました：" SequenceToArrows(seq)
}

SettingsClear(*) {
    global SETUI
    SETUI.selected := ""
    for ddl in SETUI.dir
        ddl.Choose(1)
    SETUI.action.Choose(1)
    SETUI.gestureColor.Value := ""
    SETUI.lv.Modify(0, "-Select -Focus")
    SETUI.status.Text := "新しい割り当てを登録できます。"
}

SettingsRestoreDefaults(*) {
    global BINDINGS, SETUI, GESTURE_COLORS
    if MsgBox("現在の割り当てをすべて消去し、`n↓ = 新規タブ、↓→ = タブを閉じる`nに戻しますか？", "初期設定に戻す", "YesNo Icon?") != "Yes"
        return
    old := BINDINGS.Clone()
    oldColors := GESTURE_COLORS.Clone()
    BINDINGS := DefaultBindings()
    GESTURE_COLORS := Map()
    try {
        SaveBindings()
        SaveGestureColors()
    } catch as err {
        BINDINGS := old
        GESTURE_COLORS := oldColors
        try SaveBindings()
        try SaveGestureColors()
        MsgBox("設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    RefreshSettingsList()
    SettingsClear()
    SETUI.status.Text := "初期設定に戻しました。"
}

GestureAutoColor(*) {
    global SETUI
    SETUI.gestureColor.Value := ""
    SETUI.status.Text := "色を自動配色にしました。「追加 / 更新して保存」で反映されます。"
}

PickGestureColor(*) {
    global SETUI, BINDINGS
    seq := SETUI.selected
    if seq = "" {
        seq := ""
        for ddl in SETUI.dir
            seq .= ArrowDir(ddl.Text)
    }
    initial := IsValidHex(SETUI.gestureColor.Text) ? SETUI.gestureColor.Text : (seq != "" ? GestureColor(seq) : "67D9FF")
    result := ChooseTrailColor(initial, SETUI.gui.Hwnd)
    if result != ""
        SETUI.gestureColor.Value := result
}

SettingsClose(*) {
    global SETUI
    SETUI.gui.Hide()
}


