; ----- Direction recognition tolerance UI -----
RefreshRecognitionControls() {
    global SETUI, CFG, RECOGNITION_LEVEL, RECOGNITION_PRESETS
    if !IsObject(SETUI)
        return
    SETUI.recognitionSlider.Value := RECOGNITION_LEVEL
    preset := RECOGNITION_PRESETS[RECOGNITION_LEVEL]
    SETUI.recognitionTitle.Text := "レベル " RECOGNITION_LEVEL " / " RECOGNITION_PRESETS.Length "  ：  " preset.label
    SETUI.recognitionDetails.Text := "横方向の基本許容：±" CFG.sidewaysMax " px ＋ 距離に比例`n100px進んだときの横ずれ許容：約±" Round(CFG.sidewaysMax + 100 * CFG.driftSlope) " px`n曲がり判定の距離：" CFG.turnStart " px ／ 最小移動：縦 " CFG.downMin " px・横 " CFG.rightMin " px"
}

RecognitionChanged(ctrl, *) {
    global RECOGNITION_LEVEL, ST
    level := Round(ctrl.Value)
    if level = RECOGNITION_LEVEL
        return
    oldLevel := RECOGNITION_LEVEL
    ApplyRecognitionLevel(level)
    try SaveRecognitionSettings()
    catch as err {
        ApplyRecognitionLevel(oldLevel)
        RefreshRecognitionControls()
        MsgBox("認識感度の設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
        return
    }
    ; The new sensitivity applies to the next right-button press.
    ; Do not change the interpretation of a gesture already in progress.
    if ST.active
        ST.invalid := true
    RefreshRecognitionControls()
}

RecognitionRestoreDefault(*) {
    global RECOGNITION_LEVEL
    oldLevel := RECOGNITION_LEVEL
    ApplyRecognitionLevel(3)
    try SaveRecognitionSettings()
    catch as err {
        ApplyRecognitionLevel(oldLevel)
        MsgBox("認識感度の設定を保存できませんでした。`n" err.Message, "保存エラー", "Iconx")
    }
    RefreshRecognitionControls()
}

