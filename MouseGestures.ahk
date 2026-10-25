#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

; Browser Mouse Gestures v3.8.3 - Mouse-hover targeting; custom tray and settings icons; fast pixel recoloring
; Windows / AutoHotkey v2, no external libraries, no GDI+.
; Supported: selected Chromium and Gecko-family browsers, with per-browser toggles.
; Right mouse button + cardinal directions, up to three strokes.
; Configuration: tray icon -> Gestures / Wheel / Apps / Recognition / Appearance / Icon picker.
; Settings are saved to %APPDATA%\ChromiumMouseGestures\settings.ini
; Gesture mappings are limited to predefined browser shortcuts.

CoordMode("Mouse", "Screen")
; AHK normally waits 100 ms after window operations such as WinActivate and
; WinGetProcessPath. Yield instead of sleeping; preserve target verification.
; Calling in auto-execute sets the default for every new hotkey/timer thread.
SetWinDelay(0)

; Sensitivity in screen pixels. For R and L the minimum is rightMin.
global CFG := {
    poll: 16,
    drawStart: 9,
    downMin: 48,
    rightMin: 45,
    sidewaysMax: 24,
    verticalMax: 25,
    startRatio: 1.30,
    turnRatio: 1.30,
    turnStart: 24,
    backtrackMax: 23,
    sampleMin: 3,
    startConfirm: 23,
    startAbort: 70,
    driftSlope: 0.34,
    softTurnRatio: 0.85
}

global ACTIONS := Map(
    "new_tab",       {name:"新しいタブ",             key:"^t",       hint:"Ctrl + T"},
    "close_tab",     {name:"タブを閉じる",           key:"^w",       hint:"Ctrl + W"},
    "reopen_tab",    {name:"閉じたタブを復元",       key:"^+t",      hint:"Ctrl + Shift + T"},
    "reload",        {name:"再読み込み",             key:"^r",       hint:"Ctrl + R"},
    "hard_reload",   {name:"キャッシュを無視して再読み込み", key:"^+r", hint:"Ctrl + Shift + R"},
    "back",          {name:"前のページに戻る",       key:"!{Left}",  hint:"Alt + ←"},
    "forward",       {name:"次のページに進む",       key:"!{Right}", hint:"Alt + →"},
    "next_tab",      {name:"次のタブ",               key:"^{Tab}",   hint:"Ctrl + Tab"},
    "previous_tab",  {name:"前のタブ",               key:"^+{Tab}",  hint:"Ctrl + Shift + Tab"},
    "first_tab",     {name:"最初のタブ",             key:"^1",       hint:"Ctrl + 1"},
    "last_tab",      {name:"最後のタブ",             key:"^9",       hint:"Ctrl + 9"},
    "focus_address", {name:"アドレスバーに移動",     key:"^l",       hint:"Ctrl + L"},
    "new_window",    {name:"新しいウィンドウ",       key:"^n",       hint:"Ctrl + N"},
    "private_window",{name:"プライベートウィンドウ", key:"^+n",      hint:"Ctrl + Shift + N"},
    "fullscreen",    {name:"全画面表示を切り替え",   key:"{F11}",    hint:"F11"},
    "page_top",      {name:"ページの先頭へ",         key:"^{Home}",  hint:"Ctrl + Home"},
    "page_bottom",   {name:"ページの末尾へ",         key:"^{End}",   hint:"Ctrl + End"}
)

global ACTION_ORDER := ["new_tab", "close_tab", "reopen_tab", "reload", "hard_reload",
    "back", "forward", "next_tab", "previous_tab", "first_tab", "last_tab",
    "focus_address", "new_window", "private_window", "fullscreen",
    "page_top", "page_bottom"]

; Browser recognition is deliberately allowlisted, not a generic Chromium/Gecko test.
; Each entry starts enabled; users may opt out in the Browsers tab.
; Portable/renamed installations may require additional path rules.
global BROWSER_DEFS := [
    {id:"chrome",      name:"Google Chrome",          family:"Chromium"},
    {id:"brave",       name:"Brave / Brave Origin",   family:"Chromium"},
    {id:"edge",        name:"Microsoft Edge",         family:"Chromium"},
    {id:"vivaldi",     name:"Vivaldi",                family:"Chromium"},
    {id:"helium",      name:"Helium",                 family:"Chromium"},
    {id:"opera",       name:"Opera",                  family:"Chromium"},
    {id:"opera_gx",    name:"Opera GX",               family:"Chromium"},
    {id:"whale",       name:"NAVER Whale",            family:"Chromium"},
    {id:"slimjet",     name:"Slimjet",                family:"Chromium"},
    {id:"chromium",    name:"Chromium",               family:"Chromium"},
    {id:"ungoogled",   name:"ungoogled-chromium",      family:"Chromium"},
    {id:"cromite",     name:"Cromite",                family:"Chromium"},
    {id:"thorium",     name:"Thorium",                family:"Chromium"},
    {id:"supermium",   name:"Supermium",              family:"Chromium"},
    {id:"firefox",     name:"Mozilla Firefox 系",     family:"Gecko"},
    {id:"floorp",      name:"Floorp",                 family:"Gecko"},
    {id:"zen",         name:"Zen Browser",            family:"Gecko"},
    {id:"librewolf",   name:"LibreWolf",              family:"Gecko"},
    {id:"waterfox",    name:"Waterfox",               family:"Gecko"},
    {id:"mullvad",     name:"Mullvad Browser",         family:"Gecko"},
    {id:"tor",         name:"Tor Browser",            family:"Gecko"}
]
global BROWSER_ENABLED := Map()
; Windows Notepad is enabled by default. Additional apps are registered by
; selecting one of the user's currently open top-level windows.
global NOTEPAD_ENABLED := true
global CUSTOM_APPS := []
global NEXT_APP_ID := 1
; RButton + wheel: enabled by default, wheel up = previous, down = next.
global WHEEL := {enabled:true, reverse:false, delayMs:120}
global WHEEL_INTERVALS := [50, 80, 120, 160, 220, 300]
; Seven progressively more forgiving settings. Lateral drift is no longer
; capped at a fixed pixel amount: base + distance * slope (per stroke).
; Saved v3.2 levels 1..5 keep their level numbers after upgrade.
global RECOGNITION_PRESETS := [
    {label:"かなり厳しめ", drift:10, corner:14, startRatio:1.65, turnRatio:1.65, slope:0.12, seek:1.10, turn:29, back:18},
    {label:"厳しめ",       drift:14, corner:18, startRatio:1.45, turnRatio:1.50, slope:0.22, seek:0.95, turn:26, back:20},
    {label:"標準",         drift:18, corner:22, startRatio:1.30, turnRatio:1.35, slope:0.34, seek:0.85, turn:23, back:24},
    {label:"やや緩め",     drift:22, corner:27, startRatio:1.18, turnRatio:1.25, slope:0.48, seek:0.75, turn:20, back:26},
    {label:"緩め",         drift:26, corner:32, startRatio:1.09, turnRatio:1.15, slope:0.60, seek:0.65, turn:18, back:30},
    {label:"かなり緩め",   drift:30, corner:36, startRatio:1.05, turnRatio:1.08, slope:0.73, seek:0.60, turn:18, back:36},
    {label:"最大限に緩める", drift:34, corner:40, startRatio:1.02, turnRatio:1.04, slope:0.82, seek:0.55, turn:18, back:42}
]
global RECOGNITION_LEVEL := 3
global PICKER := 0

global BINDINGS := Map()
; Per-gesture overrides. A missing key means a stable, automatic color.
; Stored separately from action mappings for backward compatibility.
global GESTURE_COLORS := Map()
global AUTO_GESTURE_PALETTE := ["B38CFF", "FFAD65", "65E6BE", "FF83BD", "72D6D0", "FFD66B", "80AAFF", "CBA1F8"]
global SETTINGS_DIR := A_AppData "\ChromiumMouseGestures"
global SETTINGS_FILE := SETTINGS_DIR "\settings.ini"
global SETUI := 0

global ST := {
    active:false, visible:false, hudShown:false, invalid:false,
    phase:"await", current:"", sequence:"", gesture:"", progress:0,
    hwnd:0, pid:0, x0:0, y0:0, mx:0, my:0, prevX:0, prevY:0,
    sx:0, sy:0, peak:0, candidateDir:"", candidateX:0, candidateY:0,
    traceX:0, traceY:0, points:[],
    drawnCount:1, drawnColor:"",
    wheelMode:false, lastWheelTick:-100000
}

global Trail := 0
global Hud := 0
global Brushes := Map()
; Trail is split into fixed-position 512px tiles, created on demand.
; Unlike a single bitmap centered at mouse-down, it has no per-gesture
; clipping boundary and never shifts existing painted pixels.
global TRAIL_TILE_SIZE := 512
global TRAIL_BRUSH_RADIUS := 9
; Keep all positions during a single button hold: a color change must repaint
; the entire visible path, even for exceptionally long (>10k sample) strokes.
; Points are released when the next gesture starts; rendered tiles are cleaned up.
global HUD_W := 420
global HUD_H := 176
; Appearance is stored independently of gesture/app/recognition settings.
; Colors are RGB hex without #; presets are validated before use.
global APPEARANCE := DefaultAppearance()
global APPEARANCE_THEMES := ["midnight", "slate", "light", "forest"]
global APPEARANCE_THEME_NAMES := ["ミッドナイト", "スレート", "ライト", "フォレスト"]
global APPEARANCE_ALPHA := [255, 248, 235, 217]
global APPEARANCE_ALPHA_NAMES := ["100%（不透明）", "97%（標準）", "92%", "85%"]
global APPEARANCE_POSITIONS := ["auto", "bottomleft", "topright", "topleft"]
global APPEARANCE_POSITION_NAMES := ["自動（右下基準）", "左下", "右上", "左上"]
; Icon selection is independent from appearance reset. The four built-in .ico
; files are embedded as base64, decoded into AppData only when needed.
global ICON_CONFIG := {mode:"preset", preset:"cursor", customPath:""}
global ICON_PRESET_IDS := ["cursor", "gesture", "orbit", "spark"]
global ICON_CHOICE_LABELS := ["カーソル（シアン）", "ジェスチャー（ブルー）", "オービット（ミント）", "スパーク（パープル）", "AHK標準", "カスタム .ico"]
global ICON_UI := 0
global GUI_ICON_HANDLES := Map()

LoadBindings()
LoadBrowserSettings()
LoadAppSettings()
LoadWheelSettings()
LoadRecognitionSettings()
LoadAppearanceSettings()
LoadGestureColors()
MigrateLegacyTrailColor()
LoadIconSettings()
Trail := {tiles:Map()}
Hud := NewHud()
RefreshTrailBrushes()
OnExit(Cleanup)

A_TrayMenu.Add("設定を開く", ShowSettings)
A_TrayMenu.Default := "設定を開く"
A_IconTip := "Browser Mouse Gestures - ダブルクリックで設定"
; Failure to apply a configured icon must never prevent gesture hotkeys from starting.
try ApplyAppIcon()
catch as startupIconError
    OutputDebug("Browser Mouse Gestures icon startup warning: " startupIconError.Message)

#HotIf IsSupportedTarget()
RButton::StartGesture()
#HotIf IsWheelContext()
WheelUp::WheelGesture(-1)
WheelDown::WheelGesture(1)
#HotIf

; === Source modules (the release builder expands these in order) ===
#Include %A_ScriptDir%\src\Core\WindowTargeting.ahk
#Include %A_ScriptDir%\src\Core\GestureRecognizer.ahk
#Include %A_ScriptDir%\src\Core\GestureController.ahk
#Include %A_ScriptDir%\src\Rendering\TrailRenderer.ahk
#Include %A_ScriptDir%\src\Settings\Appearance.ahk
#Include %A_ScriptDir%\src\Rendering\GestureHUD.ahk
#Include %A_ScriptDir%\src\Rendering\LayeredCanvas.ahk
#Include %A_ScriptDir%\src\Settings\SettingsPersistence.ahk
#Include %A_ScriptDir%\src\Icons\IconStorage.ahk
#Include %A_ScriptDir%\src\Icons\EmbeddedIcons.ahk
#Include %A_ScriptDir%\src\Icons\IconUI.ahk
#Include %A_ScriptDir%\src\UI\SettingsWindow.ahk
#Include %A_ScriptDir%\src\UI\BrowserControls.ahk
#Include %A_ScriptDir%\src\UI\RecognitionControls.ahk
#Include %A_ScriptDir%\src\UI\WheelControls.ahk
#Include %A_ScriptDir%\src\UI\CustomAppControls.ahk
