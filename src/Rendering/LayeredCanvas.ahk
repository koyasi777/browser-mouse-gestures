; ----- Direct Win32 layered-window canvas: GDI+ is not used -----
NewCanvas(w, h) {
    c := {gui:Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08080020"),
        w:w, h:h, dc:0, bmp:0, old:0, pixels:0,
        shades:Buffer(w*h, 0), occupied:[]}
    c.dc := DllCall("gdi32\CreateCompatibleDC", "Ptr", 0, "Ptr")
    if !c.dc
        throw Error("CreateCompatibleDC failed: " A_LastError)

    bmi := Buffer(40, 0)
    NumPut("UInt", 40, bmi, 0)     ; BITMAPINFOHEADER size
    NumPut("Int", w, bmi, 4)
    NumPut("Int", -h, bmi, 8)      ; top-down, 32-bit pixels
    NumPut("UShort", 1, bmi, 12)   ; planes
    NumPut("UShort", 32, bmi, 14)  ; bits per pixel

    ; Use an explicit output Buffer instead of a Ptr* variable. This
    ; avoids any ambiguity about pointer-output marshalling on AHK v2 x64.
    pixelsOut := Buffer(A_PtrSize, 0)
    c.bmp := DllCall("gdi32\CreateDIBSection", "Ptr", c.dc, "Ptr", bmi.Ptr,
        "UInt", 0, "Ptr", pixelsOut.Ptr, "Ptr", 0, "UInt", 0, "Ptr")
    c.pixels := NumGet(pixelsOut, 0, "Ptr")
    if !c.bmp || !c.pixels
        throw Error("CreateDIBSection failed: " A_LastError)
    c.old := DllCall("gdi32\SelectObject", "Ptr", c.dc, "Ptr", c.bmp, "Ptr")
    if !c.old || c.old = -1
        throw Error("SelectObject failed: " A_LastError)
    ClearCanvas(c)
    return c
}

ClearCanvas(c) {
    ; Used only when creating a fresh tile; the color-switch path never clears.
    ; msvcrt.dll is included in Windows; no external library required.
    DllCall("msvcrt\memset", "Ptr", c.pixels, "Int", 0,
        "UPtr", c.w*c.h*4, "Ptr")
}

Present(c, x, y) {
    pointDst := Buffer(8, 0)
    pointSrc := Buffer(8, 0)
    size := Buffer(8, 0)
    blend := Buffer(4, 0)
    NumPut("Int", x, pointDst, 0)
    NumPut("Int", y, pointDst, 4)
    NumPut("Int", c.w, size, 0)
    NumPut("Int", c.h, size, 4)
    NumPut("UChar", 255, blend, 2) ; BLENDFUNCTION.SourceConstantAlpha
    NumPut("UChar", 1, blend, 3)   ; AC_SRC_ALPHA
    ok := DllCall("user32\UpdateLayeredWindow",
        "Ptr", c.gui.Hwnd, "Ptr", 0, "Ptr", pointDst.Ptr, "Ptr", size.Ptr,
        "Ptr", c.dc, "Ptr", pointSrc.Ptr, "UInt", 0, "Ptr", blend.Ptr,
        "UInt", 2, "Int")         ; ULW_ALPHA
    if !ok
        throw Error("UpdateLayeredWindow failed: " A_LastError)
}

DestroyCanvas(tile) {
    ; Select old bitmap back before deleting the DIBSection.
    if tile.dc && tile.old
        DllCall("gdi32\SelectObject", "Ptr", tile.dc, "Ptr", tile.old)
    if tile.bmp
        DllCall("gdi32\DeleteObject", "Ptr", tile.bmp)
    if tile.dc
        DllCall("gdi32\DeleteDC", "Ptr", tile.dc)
    tile.gui.Destroy()
}

Cleanup(*) {
    global Trail, Hud, GUI_ICON_HANDLES
    SetTimer(TrackGesture, 0)
    if IsObject(Trail) {
        for _, tile in Trail.tiles
            DestroyCanvas(tile)
        Trail.tiles := Map()
    }
    if IsObject(Hud)
        Hud.gui.Destroy()
    ; WM_SETICON does not transfer ownership of custom icon handles.
    for _, icons in GUI_ICON_HANDLES {
        if icons.big
            DllCall("user32\DestroyIcon", "Ptr", icons.big)
        if icons.small
            DllCall("user32\DestroyIcon", "Ptr", icons.small)
    }
    GUI_ICON_HANDLES.Clear()
}
 ; ----- Wheel and custom app persistence -----
