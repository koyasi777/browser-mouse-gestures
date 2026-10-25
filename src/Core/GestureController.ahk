FinishGesture(*) {
    global ST, Hud, CFG, BINDINGS, ACTIONS
    if !ST.active
        return
    ; A wheel gesture consumes the complete right-button press.  Never
    ; synthesize a context menu or execute an unrelated drawing gesture.
    if ST.wheelMode {
        SetTimer(TrackGesture, 0)
        ST.active := false
        HideTrail()
        Hud.gui.Hide()
        return
    }
    MouseGetPos(&fx, &fy)
    if (fx != ST.mx || fy != ST.my) {
        ST.mx := fx, ST.my := fy
        Recognize(fx, fy)
    }
    if !ST.visible && (Abs(fx-ST.x0) >= CFG.drawStart
        || Abs(fy-ST.y0) >= CFG.drawStart)
        ST.visible := true
    SetTimer(TrackGesture, 0)
    ST.active := false
    if ST.visible {
        HideTrail()
        if ST.hudShown
            Hud.gui.Hide()
    }
    if !GestureTargetIsValid()
        return
    if !ST.visible {
        ; Preserve the native context menu and do not focus the window on
        ; an ordinary click. Avoid clicking some other window after a drag.
        if GetMouseTargetHwnd() = ST.hwnd
            Click("Right")
    } else if !ST.invalid && ST.gesture != "" && BINDINGS.Has(ST.gesture) {
        actionID := BINDINGS[ST.gesture]
        if ACTIONS.Has(actionID) {
            key := ACTIONS[actionID].key
            if actionID = "private_window" {
                browserId := DetectBrowser(ST.hwnd)
                if IsGeckoBrowserId(browserId)
                    key := "^+p"
            }
            ; If activation fails, skip. Sending into the currently active
            ; but unrelated window would repeat the original safety bug.
            if ActivateGestureTarget()
                Send(key)
        }
    }
}

WheelGesture(step) {
    global ST, WHEEL, Hud
    if !ST.active || !GetKeyState("RButton", "P")
        return
    if !GestureTargetIsValid()
        return
    if !ST.wheelMode {
        ST.wheelMode := true
        ST.gesture := ""
        ST.invalid := true
        ; Do not display a canceled gesture trail or HUD over wheel navigation.
        HideTrail()
        Hud.gui.Hide()
        ST.visible := false
        ST.hudShown := false
    }
    now := A_TickCount
    if now - ST.lastWheelTick < WHEEL.delayMs
        return
    ST.lastWheelTick := now
    ; step -1 = wheel upward. Default upward selects previous tab.
    previous := (step < 0) != WHEEL.reverse
    if ActivateGestureTarget()
        Send(previous ? "^+{Tab}" : "^{Tab}")
}

IsGeckoBrowserId(browserId) {
    return browserId = "firefox" || browserId = "floorp" || browserId = "zen"
        || browserId = "librewolf" || browserId = "waterfox"
        || browserId = "mullvad" || browserId = "tor"
}

Hypot(dx, dy) => Sqrt(dx * dx + dy * dy)

