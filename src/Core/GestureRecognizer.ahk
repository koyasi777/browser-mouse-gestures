StartGesture(*) {
    global ST, CFG
    if ST.active
        return
    MouseGetPos(&x, &y, &hoverHwnd)
    ; Recheck at the actual click position; #HotIf may have been evaluated
    ; before a window moved or the pointer crossed its edge.
    if !hoverHwnd || !IsSupportedTarget(hoverHwnd)
        return
    try hoverPID := WinGetPID("ahk_id " hoverHwnd)
    catch
        return
    ST.active := true
    ST.visible := false
    ST.hudShown := false
    ST.invalid := false
    ST.phase := "await"
    ST.current := ""
    ST.sequence := ""
    ST.gesture := ""
    ST.progress := 0
    ST.hwnd := hoverHwnd
    ST.pid := hoverPID
    ST.x0 := x, ST.y0 := y
    ST.mx := x, ST.my := y
    ST.prevX := x, ST.prevY := y
    ST.sx := x, ST.sy := y, ST.peak := 0
    ST.candidateDir := "", ST.candidateX := x, ST.candidateY := y
    ST.traceX := x, ST.traceY := y
    ST.points := [{x:x, y:y}]
    ST.drawnCount := 1
    ST.drawnColor := ""
    ST.wheelMode := false
    ST.lastWheelTick := -100000
    ; Dispose previous gesture's tiles. Never recenter a live overlay.
    ResetTrail()
    SetTimer(TrackGesture, CFG.poll)
}

TrackGesture(*) {
    global ST, CFG, APPEARANCE
    if !ST.active
        return
    if !GetKeyState("RButton", "P") {
        FinishGesture()
        return
    }
    if ST.wheelMode
        return  ; Wheel has priority: do not attempt a drawing gesture.
    MouseGetPos(&x, &y)
    if x = ST.mx && y = ST.my
        return
    ST.mx := x, ST.my := y
    Recognize(x, y)
    if !ST.visible && (Abs(x - ST.x0) >= CFG.drawStart || Abs(y - ST.y0) >= CFG.drawStart) {
        ST.visible := true
    }
    if ST.visible {
        if APPEARANCE.trailVisible {
            if (Hypot(x - ST.traceX, y - ST.traceY) >= CFG.sampleMin) {
                ST.points.Push({x:x, y:y})
                ST.traceX := x, ST.traceY := y
                ; Do not discard historical points: a mid-gesture color change
                ; repaints the complete path without losing earlier segments.
            }
            DrawTrace()
        }
        if APPEARANCE.hudVisible
            UpdateHud(x, y)
    }
}

; Adaptive cardinal-direction recognition, with a confirmed-turn candidate.
; A slight diagonal is treated as a cardinal stroke if its dominant component
; stays ahead. Perpendicular turns need sustained motion, not one noisy sample.
; Only configured paths, up to three segments, may fire actions.
Recognize(x, y) {
    global ST, CFG, BINDINGS
    if ST.invalid
        return

    if ST.phase = "await" {
        dx := x - ST.x0, dy := y - ST.y0
        magnitude := Max(Abs(dx), Abs(dy))
        if magnitude < CFG.startConfirm
            return
        dir := ""
        if Abs(dx) >= Abs(dy) * CFG.startRatio
            dir := dx >= 0 ? "R" : "L"
        else if Abs(dy) >= Abs(dx) * CFG.startRatio
            dir := dy >= 0 ? "D" : "U"
        if dir = "" {
            ; Allow a briefly diagonal start to settle instead of canceling
            ; immediately. A sustained 45-degree line is still invalid.
            if magnitude >= CFG.startAbort
                Invalidate()
            return
        }
        if !HasMappingPrefix(dir) {
            Invalidate()
            return
        }
        ST.current := dir
        ST.sequence := dir
        ST.phase := "stroke"
        ST.sx := ST.x0, ST.sy := ST.y0
        ST.peak := 0
        ST.candidateDir := ""
    }

    dir := ST.current
    along := ForwardDistance(dir, x - ST.sx, y - ST.sy)
    cross := LateralDistance(dir, x - ST.sx, y - ST.sy)
    stepAlong := ForwardDistance(dir, x - ST.prevX, y - ST.prevY)
    stepCross := LateralDistance(dir, x - ST.prevX, y - ST.prevY)
    peakBefore := ST.peak
    ST.peak := Max(ST.peak, along)

    ; Candidate turns can be perpendicular (↓→) or reverse (↓↑).
    ; Their anchor is the point where the turn began, so small curves at
    ; the corner do not consume the new direction's 45px travel requirement.
    if ST.candidateDir = "" && peakBefore >= StrokeMinimum(dir) * 0.80 {
        if Abs(stepCross) >= 1 && Abs(stepCross) >= Abs(stepAlong) * CFG.softTurnRatio {
            ST.candidateDir := IsVertical(dir) ? (stepCross > 0 ? "R" : "L") : (stepCross > 0 ? "D" : "U")
        } else if stepAlong <= -3 && Abs(stepAlong) > Abs(stepCross) * CFG.turnRatio {
            ST.candidateDir := OppositeDir(dir)
        }
        if ST.candidateDir != "" {
            ST.candidateX := ST.prevX
            ST.candidateY := ST.prevY
        }
    }

    pendingDistance := 0
    if ST.candidateDir != "" {
        cdir := ST.candidateDir
        pendingDistance := ForwardDistance(cdir, x - ST.candidateX, y - ST.candidateY)
        pendingCross := LateralDistance(cdir, x - ST.candidateX, y - ST.candidateY)
        ; A short sideways twitch is noise. Reset the candidate when the
        ; mouse resumes its original direction or pulls back.
        if pendingDistance < -8 || (Abs(pendingCross) > CFG.verticalMax + 14
            && Abs(pendingCross) > Abs(pendingDistance) * 1.7) {
            ST.candidateDir := ""
            pendingDistance := 0
        } else if pendingDistance >= CFG.turnStart && ST.peak >= StrokeMinimum(dir)
            && Abs(pendingCross) <= CFG.verticalMax + pendingDistance * 0.38 {
            newSeq := ST.sequence cdir
            if StrLen(ST.sequence) >= 3 || !HasMappingPrefix(newSeq) {
                Invalidate()
                return
            }
            TurnStroke(cdir, ST.candidateX, ST.candidateY)
            dir := ST.current
            along := ForwardDistance(dir, x - ST.sx, y - ST.sy)
            cross := LateralDistance(dir, x - ST.sx, y - ST.sy)
            ST.peak := Max(0, along)
            pendingDistance := 0
        }
    }

    ; An angle-aware corridor: the longer the stroke, the more sideways
    ; drift can be tolerated. The start direction must still be cardinal.
    tolerance := CFG.sidewaysMax + Max(0, along) * CFG.driftSlope
    if Abs(cross) > tolerance {
        if ST.candidateDir = "" || Abs(cross) > tolerance + CFG.turnStart {
            Invalidate()
            return
        }
    }
    if ST.peak - along > CFG.backtrackMax + CFG.turnStart
        && ST.candidateDir = "" {
        Invalidate()
        return
    }

    ST.progress := Max(0, Min(100, Round(100 * Max(0, along) / StrokeMinimum(dir))))
    ST.gesture := (along >= StrokeMinimum(dir) && BINDINGS.Has(ST.sequence)) ? ST.sequence : ""
    ; A partly drawn new direction must not accidentally fire the previous
    ; shorter gesture when the right button is released.
    if ST.candidateDir != "" && pendingDistance >= 8
        ST.gesture := ""
    ST.prevX := x, ST.prevY := y
}

; Switch stroke origin to the *beginning* of the confirmed bend.
TurnStroke(nextDir, anchorX, anchorY) {
    global ST
    ST.sx := anchorX
    ST.sy := anchorY
    ST.sequence .= nextDir
    ST.current := nextDir
    ST.peak := 0
    ST.candidateDir := ""
    ST.gesture := ""
}

OppositeDir(dir) {
    switch dir {
        case "U": return "D"
        case "D": return "U"
        case "L": return "R"
        case "R": return "L"
    }
    return ""
}

ForwardDistance(dir, dx, dy) {
    switch dir {
        case "U": return -dy
        case "D": return dy
        case "L": return -dx
        case "R": return dx
    }
    return 0
}

LateralDistance(dir, dx, dy) => IsVertical(dir) ? dx : dy
IsVertical(dir) => (dir = "D" || dir = "U")
StrokeMinimum(dir) {
    global CFG
    return IsVertical(dir) ? CFG.downMin : CFG.rightMin
}

HasMappingPrefix(seq) {
    global BINDINGS
    for path, actionID in BINDINGS {
        if SubStr(path, 1, StrLen(seq)) = seq
            return true
    }
    return false
}

Invalidate() {
    global ST
    ST.invalid := true
    ST.phase := "invalid"
    ST.gesture := ""
}

