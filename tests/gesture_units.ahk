#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon
#Warn All, StdOut
#ErrorStdOut UTF-8
; No hooks or GUI: exercise independent gesture/config helpers only.
#Include %A_ScriptDir%\..\src\Settings\SettingsPersistence.ahk
#Include %A_ScriptDir%\..\src\Settings\Appearance.ahk

try {
    TestAssert(IsValidSequence("D"), "single direction")
    TestAssert(IsValidSequence("DR"), "two directions")
    TestAssert(IsValidSequence("DRU"), "three directions")
    TestAssert(IsValidSequence("DU"), "backtracking is allowed")
    TestAssert(!IsValidSequence(""), "empty sequence rejected")
    TestAssert(!IsValidSequence("DD"), "repeated direction rejected")
    TestAssert(!IsValidSequence("DRUL"), "four directions rejected")
    TestAssert(!IsValidSequence("X"), "diagonal/unknown rejected")
    TestAssert(DefaultBindings().Get("D") = "new_tab", "default Down action")
    TestAssert(DefaultBindings().Get("DR") = "close_tab", "default Down-Right action")
    TestAssert(IsValidHex("67D9FF"), "valid RGB hex")
    TestAssert(!IsValidHex("G7D9FF"), "invalid RGB hex")
    FileAppend("PASS: AHK gesture helper tests`n", "*")
    ExitApp(0)
} catch as testFailure {
    FileAppend("FAIL: " testFailure.Message "`n", "**")
    ExitApp(1)
}

TestAssert(condition, message) {
    if !condition
        throw Error(message)
}
