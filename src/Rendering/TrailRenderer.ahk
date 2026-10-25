; ----- Tiled mouse trail: CPU-painted premultiplied BGRA, NO GDI+ -----
; Each tile is a separate 512px layered window anchored in *screen* coordinates.
; Tiles do not move. The trail can therefore cross arbitrary tile/monitor edges
; without a single canvas boundary or a recentering flash/jump.
ResetTrail() {
    global Trail
    for _, tile in Trail.tiles
        DestroyCanvas(tile)
    Trail.tiles := Map()
}

HideTrail() {
    global Trail
    for _, tile in Trail.tiles
        tile.gui.Hide()
}

GetTrailTile(tx, ty) {
    global Trail, TRAIL_TILE_SIZE
    key := tx ":" ty
    if Trail.tiles.Has(key)
        return Trail.tiles[key]
    tile := NewCanvas(TRAIL_TILE_SIZE, TRAIL_TILE_SIZE)
    tile.left := tx * TRAIL_TILE_SIZE
    tile.top := ty * TRAIL_TILE_SIZE
    tile.shown := false
    Trail.tiles[key] := tile
    return tile
}

; Color state is derived from recognition status, not the last segment.
; A changed recognition result recolors the WHOLE path without redrawing geometry.
ActiveTrailColor() {
    global ST, APPEARANCE, BINDINGS
    if ST.invalid
        return APPEARANCE.invalidColor
    if ST.gesture != "" && BINDINGS.Has(ST.gesture)
        return GestureColor(ST.gesture)
    return APPEARANCE.pendingColor
}

DrawTrace() {
    global ST, Trail
    pts := ST.points
    if pts.Length < 2
        return

    dirty := Map()
    color := ActiveTrailColor()
    if color != ST.drawnColor {
        ; Recolor existing raster pixels in place, keeping their alpha and glow.
        ; No historical segment replay: cost follows visible pixels, not samples.
        RecolorPaintedTiles(color, dirty)
        ST.drawnColor := color
    }
    brush := TrailBrush(color)
    while ST.drawnCount < pts.Length {
        a := pts[ST.drawnCount]
        b := pts[ST.drawnCount + 1]
        DrawTraceAcrossTiles(a.x, a.y, b.x, b.y, brush, dirty)
        ST.drawnCount += 1
    }
    ; Present only changed tiles. Color transitions modify old pixels in place.
    for _, tile in dirty {
        if !tile.shown {
            tile.gui.Show("NA x" tile.left " y" tile.top " w" tile.w " h" tile.h)
            tile.shown := true
        }
        Present(tile, tile.left, tile.top)
    }
}

; Color-only pass over pixels actually stamped into the tile.
; Every pixel offset is recorded exactly once, on its first paint.
; Changing a recognized gesture does not erase or redraw the geometry.
RecolorPaintedTiles(hex, dirty) {
    global Trail
    rgb := ColorRGB(hex)
    ; Pixels from the same brush repeat alpha/boost combinations. Cache their
    ; final premultiplied BGRA values for this color (256*256*4 = 256 KiB).
    ; A nonzero alpha guarantees that zero means an unfilled cache entry.
    palette := Buffer(256 * 256 * 4, 0)
    for key, tile in Trail.tiles {
        if tile.occupied.Length = 0
            continue
        for byteOffset in tile.occupied {
            alpha := NumGet(tile.pixels, byteOffset + 3, "UChar")
            boost := NumGet(tile.shades, byteOffset // 4, "UChar")
            palOffset := ((boost << 8) | alpha) * 4
            pixelBGRA := NumGet(palette, palOffset, "UInt")
            if !pixelBGRA {
                red := Round(rgb.r + (255 - rgb.r) * boost / 255)
                green := Round(rgb.g + (255 - rgb.g) * boost / 255)
                blue := Round(rgb.b + (255 - rgb.b) * boost / 255)
                pixelBGRA := (alpha << 24) | (Round(red * alpha / 255) << 16) | (Round(green * alpha / 255) << 8) | Round(blue * alpha / 255)
                NumPut("UInt", pixelBGRA, palette, palOffset)
            }
            NumPut("UInt", pixelBGRA, tile.pixels, byteOffset)
        }
        dirty[key] := tile
    }
}

DrawTraceAcrossTiles(x0, y0, x1, y1, brush, dirty) {
    global TRAIL_TILE_SIZE, TRAIL_BRUSH_RADIUS
    size := TRAIL_TILE_SIZE
    pad := TRAIL_BRUSH_RADIUS
    ; Include neighbouring tiles when the soft brush overlaps a boundary.
    tx0 := Floor((Min(x0, x1) - pad) / size)
    tx1 := Floor((Max(x0, x1) + pad) / size)
    ty0 := Floor((Min(y0, y1) - pad) / size)
    ty1 := Floor((Max(y0, y1) + pad) / size)
    Loop tx1 - tx0 + 1 {
        tx := tx0 + A_Index - 1
        Loop ty1 - ty0 + 1 {
            ty := ty0 + A_Index - 1
            left := tx * size, top := ty * size
            ; Clip to the tile plus the brush radius before stamping.
            ; This prevents redrawing a huge off-tile segment for every tile.
            part := ClipTrailSegment(x0, y0, x1, y1,
                left - pad, top - pad, left + size + pad - 1,
                top + size + pad - 1)
            if !IsObject(part)
                continue
            tile := GetTrailTile(tx, ty)
            DrawTrailSegment(tile, part.x0 - left, part.y0 - top,
                part.x1 - left, part.y1 - top, brush)
            dirty[tx ":" ty] := tile
        }
    }
}

; Parametric line clipping (Liang-Barsky), with inclusive padded bounds.
; A diagonal can cross a tile bounding box without actually touching the tile.
ClipTrailSegment(x0, y0, x1, y1, left, top, right, bottom) {
    dx := x1 - x0, dy := y1 - y0
    p := [-dx, dx, -dy, dy]
    q := [x0 - left, right - x0, y0 - top, bottom - y0]
    lo := 0.0, hi := 1.0
    Loop 4 {
        if p[A_Index] = 0 {
            if q[A_Index] < 0
                return false
            continue
        }
        t := q[A_Index] / p[A_Index]
        if p[A_Index] < 0
            lo := Max(lo, t)
        else
            hi := Min(hi, t)
        if lo > hi
            return false
    }
    return {x0:x0 + dx*lo, y0:y0 + dy*lo,
        x1:x0 + dx*hi, y1:y0 + dy*hi}
}

; Stamp every ~2px along a segment, producing a continuous smooth line.
; A color-specific premultiplied brush is cached on first use.
DrawTrailSegment(c, x0, y0, x1, y1, brush) {
    dx := x1 - x0, dy := y1 - y0
    steps := Max(1, Ceil(Sqrt(dx*dx + dy*dy) / 2))
    Loop steps + 1 {
        t := (A_Index - 1) / steps
        StampTrail(c, Round(x0 + dx*t), Round(y0 + dy*t), brush)
    }
}

StampTrail(c, x, y, brush) {
    global TRAIL_BRUSH_RADIUS
    ; The centre is fully outside the tile including glow radius.
    if x < -TRAIL_BRUSH_RADIUS || y < -TRAIL_BRUSH_RADIUS
        || x >= c.w + TRAIL_BRUSH_RADIUS || y >= c.h + TRAIL_BRUSH_RADIUS
        return
    base := c.pixels
    stride := c.w
    w := c.w, h := c.h
    for pixel in brush {
        px := x + pixel.dx, py := y + pixel.dy
        if (px < 0 || py < 0 || px >= w || py >= h)
            continue
        offset := (py * stride + px) * 4
        ; Keep the strongest alpha where multiple soft circles overlap.
        ; This avoids a broken dotted appearance and remains pre-multiplied.
        oldAlpha := NumGet(base, offset + 3, "UChar")
        if oldAlpha < pixel.a {
            ; Keep a compact list of painted pixels for O(painted area) recoloring.
            if oldAlpha = 0
                c.occupied.Push(offset)
            NumPut("UInt", pixel.argb, base, offset)
            NumPut("UChar", pixel.boost, c.shades, offset // 4)
        }
    }
}

MakeTrailBrush(hex) {
    global APPEARANCE, TRAIL_BRUSH_RADIUS
    rgb := ColorRGB(hex)
    radius := TRAIL_BRUSH_RADIUS
    core := APPEARANCE.trailWidth / 2.0
    glow := APPEARANCE.glow
    brush := []
    Loop radius * 2 + 1 {
        dy := A_Index - radius - 1
        Loop radius * 2 + 1 {
            dx := A_Index - radius - 1
            r := Sqrt(dx*dx + dy*dy)
            if r > radius
                continue
            if r <= core {
                ; Bright, opaque centre plus antialiasing near core boundary.
                alpha := Round(255 * Min(1, Max(0.55, core - r + 0.75)))
                brighten := 0.58 * (1 - Min(1, r / Max(core, 1)))
            } else if glow {
                t := (r - core) / Max(0.5, radius - core)
                alpha := Round(145 * (1-t) * (1-t) + 8 * (1-t))
                brighten := 0.07
            } else {
                ; Soft 1px edge rather than a jagged hard cutoff.
                alpha := Round(100 * Max(0, radius - r))
                brighten := 0
            }
            if alpha <= 0
                continue
            ; Quantized white boost is stored separately from the display RGB.
            ; It allows exact recoloring without recomputing the trail geometry.
            boost := Max(0, Min(255, Round(brighten * 255)))
            red := Round(rgb.r + (255-rgb.r)*boost/255)
            green := Round(rgb.g + (255-rgb.g)*boost/255)
            blue := Round(rgb.b + (255-rgb.b)*boost/255)
            ; Layered windows require PREMULTIPLIED BGRA pixels.
            argb := (alpha << 24) | (Round(red*alpha/255) << 16) | (Round(green*alpha/255) << 8) | Round(blue*alpha/255)
            brush.Push({dx:dx, dy:dy, a:alpha, argb:argb, boost:boost})
        }
    }
    return brush
}

TrailBrush(hex) {
    global Brushes
    if !Brushes.Has(hex)
        Brushes[hex] := MakeTrailBrush(hex)
    return Brushes[hex]
}

RefreshTrailBrushes() {
    global Brushes, TRAIL_BRUSH_RADIUS, APPEARANCE
    TRAIL_BRUSH_RADIUS := Ceil(APPEARANCE.trailWidth / 2 + (APPEARANCE.glow ? 7 : 1))
    Brushes := Map()  ; Rebuild lazily for each actual gesture color.
}

