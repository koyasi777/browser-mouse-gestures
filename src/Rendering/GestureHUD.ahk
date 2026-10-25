; ----- Native HUD: Windows draws all text -----
; +E0x08080020: WS_EX_NOACTIVATE | WS_EX_LAYERED | WS_EX_TRANSPARENT
; The rounded floating HUD is click-through and never takes keyboard focus.
NewHud() {
    global HUD_W, HUD_H, APPEARANCE
    pal := HudThemeColors(APPEARANCE.hudTheme)
    accent := APPEARANCE.pendingColor
    cancel := APPEARANCE.invalidColor
    mint := (APPEARANCE.hudTheme = "light") ? "219A7B" : "65E6BE"

    w := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08080020")
    w.BackColor := pal.bg
    w.MarginX := 0, w.MarginY := 0

    edge := w.AddProgress("x20 y24 w3 h112 c" pal.edge " Background" pal.bg " Smooth", 100)
    badge := w.AddProgress("x40 y64 w96 h70 c" pal.badge " Background" pal.badge " Smooth", 100)

    w.SetFont("s9 c" pal.eyebrow, "Segoe UI")
    eyebrow := w.AddText("x154 y23 w249 h29 +0x200 BackgroundTrans", "BROWSER  /  GESTURE")
    w.SetFont("s19 bold c" accent, "Segoe UI Symbol")
    glyph := w.AddText("x42 y65 w92 h68 Center +0x200 BackgroundTrans", "↓")
    w.SetFont("s14 bold c" pal.title, "Yu Gothic UI")
    title := w.AddText("x152 y59 w252 h46 +0x200 BackgroundTrans", "新しいタブ")
    w.SetFont("s9 c" pal.detail, "Yu Gothic UI")
    sub := w.AddText("x153 y110 w252 h32 +0x200 BackgroundTrans", "Ctrl + T  ·  離すと実行")

    barBg := w.AddProgress("x40 y156 w340 h5 c" pal.track " Background" pal.track " Smooth", 100)
    barDown := w.AddProgress("x40 y156 w340 h5 c" accent " Background" pal.track " Smooth", 0)
    barClose := w.AddProgress("x40 y156 w340 h5 c" mint " Background" pal.track " Smooth", 0)
    barCancel := w.AddProgress("x40 y156 w340 h5 c" cancel " Background" pal.track " Smooth", 0)
    barClose.Visible := false
    barCancel.Visible := false

    hrgn := DllCall("gdi32\CreateRoundRectRgn", "Int", 0, "Int", 0,
        "Int", HUD_W+1, "Int", HUD_H+1, "Int", 24, "Int", 24, "Ptr")
    if hrgn {
        if !DllCall("user32\SetWindowRgn", "Ptr", w.Hwnd, "Ptr", hrgn, "Int", 1, "Int")
            DllCall("gdi32\DeleteObject", "Ptr", hrgn)
    }

    return {gui:w, w:HUD_W, h:HUD_H, eyebrow:eyebrow, glyph:glyph,
        title:title, sub:sub, bars:Map("down",barDown, "close",barClose,
        "cancel",barCancel), edge:edge, badge:badge, accent:"", accentMode:""}
}

UpdateHud(mx, my) {
    global ST, Hud, HUD_W, HUD_H, BINDINGS, ACTIONS, APPEARANCE
    if ST.invalid {
        clr := APPEARANCE.invalidColor, glyph := "×", ttl := "未登録のジェスチャー"
        detail := "何も実行しません", pct := 0, mode := "cancel"
    } else if ST.phase = "await" {
        clr := ActiveTrailColor(), glyph := "·", ttl := "方向を判定中"
        detail := "上下左右に動かしてください", pct := 0, mode := "down"
    } else {
        glyph := SequenceToArrows(ST.sequence)
        if ST.gesture != "" && BINDINGS.Has(ST.gesture) {
            action := ACTIONS[BINDINGS[ST.gesture]]
            ttl := action.name
            detail := action.hint "  ·  離すと実行"
            clr := GestureColor(ST.gesture)
            pct := 100
            mode := StrLen(ST.gesture) = 1 ? "down" : "close"
        } else {
            clr := ActiveTrailColor(), ttl := "ジェスチャー認識中"
            detail := ST.progress >= 100 ? "次の方向を入力してください" : "その方向にもう少し動かしてください"
            pct := ST.progress
            mode := "down"
        }
    }
    Hud.glyph.Text := glyph
    Hud.glyph.SetFont("c" clr)
    ; Progress bar and vertical accent always match the active trail color.
    if Hud.accent != clr || Hud.accentMode != mode {
        Hud.bars[mode].Opt("c" clr)
        Hud.edge.Opt("c" clr)
        Hud.accent := clr
        Hud.accentMode := mode
    }
    Hud.title.Text := ttl
    Hud.sub.Text := detail
    for key, ctrl in Hud.bars {
        ctrl.Visible := (key = mode)
        if key = mode
            ctrl.Value := pct
    }
    if APPEARANCE.hudPosition = "bottomleft" {
        hx := mx - HUD_W - 24, hy := my + 23
    } else if APPEARANCE.hudPosition = "topright" {
        hx := mx + 24, hy := my - HUD_H - 23
    } else if APPEARANCE.hudPosition = "topleft" {
        hx := mx - HUD_W - 24, hy := my - HUD_H - 23
    } else {
        hx := mx + 24, hy := my + 23
    }
    KeepInsideMonitor(&hx, &hy, HUD_W, HUD_H, mx, my)
    if !ST.hudShown {
        Hud.gui.Show("NA x" hx " y" hy " w" HUD_W " h" HUD_H)
        WinSetTransparent(APPEARANCE.hudAlpha, "ahk_id " Hud.gui.Hwnd)
        ST.hudShown := true
    } else {
        DllCall("user32\SetWindowPos", "Ptr", Hud.gui.Hwnd, "Ptr", 0,
            "Int", hx, "Int", hy, "Int", HUD_W, "Int", HUD_H,
            "UInt", 0x0010|0x0004)
    }
}

KeepInsideMonitor(&hx, &hy, w, h, mx, my) {
    try {
        Loop MonitorGetCount() {
            MonitorGet(A_Index, &l, &t, &r, &b)
            if mx >= l && mx < r && my >= t && my < b {
                MonitorGetWorkArea(A_Index, &wl, &wt, &wr, &wb)
                if hx + w > wr
                    hx := mx - w - 22
                if hy + h > wb
                    hy := my - h - 22
                hx := Max(wl + 3, Min(hx, wr - w - 3))
                hy := Max(wt + 3, Min(hy, wb - h - 3))
                return
            }
        }
    } catch {
        ; If monitor information is temporarily unavailable, use mx/my + offset.
        return
    }
}

