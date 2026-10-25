; ----- Wheel settings UI -----
RefreshWheelControls() {
    global SETUI, WHEEL, WHEEL_INTERVALS
    if !IsObject(SETUI)
        return
    SETUI.wheelEnabled.Value := WHEEL.enabled ? 1 : 0
    SETUI.wheelNormal.Value := WHEEL.reverse ? 0 : 1
    SETUI.wheelReverse.Value := WHEEL.reverse ? 1 : 0
    for i, n in WHEEL_INTERVALS {
        if WHEEL.delayMs <= n {
            SETUI.wheelDelay.Choose(i)
            break
        }
    }
    SETUI.wheelNormal.Enabled := WHEEL.enabled
    SETUI.wheelReverse.Enabled := WHEEL.enabled
    SETUI.wheelDelay.Enabled := WHEEL.enabled
    SETUI.wheelStatus.Text := "現在：" (WHEEL.enabled ? "有効" : "無効") "   |   " (WHEEL.reverse ? "逆方向" : "標準方向") "   |   " WHEEL.delayMs " ms"
}

WheelChanged(*) {
    global SETUI, WHEEL, WHEEL_INTERVALS
    old := {enabled:WHEEL.enabled, reverse:WHEEL.reverse, delayMs:WHEEL.delayMs}
    WHEEL.enabled := SETUI.wheelEnabled.Value = 1
    WHEEL.reverse := SETUI.wheelReverse.Value = 1
    idx := SETUI.wheelDelay.Value
    if idx < 1 || idx > WHEEL_INTERVALS.Length
        idx := 3
    WHEEL.delayMs := WHEEL_INTERVALS[idx]
    try SaveWheelSettings()
    catch as err {
        WHEEL := old
        RefreshWheelControls()
        MsgBox("ホイール設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    RefreshWheelControls()
}

