# GitHub公開前チェックリスト

1. **権利の確認:** ライセンスをMITとすることについて、コード・アイコンを含むすべての権利を確認する。必要に応じて`LICENSE`の著作権者表記を変更する。
2. **個人情報の確認:** `settings.ini`、PCのユーザーフォルダへのパス、ログ、秘密情報を含めない。ローカル設定はGitの管理対象外にする。
3. **Windowsの動作検証:** `MouseGestures.ahk`と、`dist/Browser_MouseGestures_v1_0_0_Standalone.ahk`を別々に実行し、ジェスチャー・右クリック・ホイール・設定画面・複数ウィンドウ・配色とアイコンを確認する。
4. **CIが通過することを確認:** Pull Request・Push時にWindows runnerでAutoHotkey v2 `/Validate`、ヘルパーテスト、Pythonの一致検証が成功する。
5. **READMEと対応アプリの確認:** 「対応候補」と「実機動作確認済み」を区別して記載する。READMEのスクリーンショットは、個人情報のない環境で取得する。
6. **Release公開:** CI成功後にタグを確認する。GitHub Releasesに `BrowserMouseGestures-v1.0.0.exe` と `Browser_MouseGestures_v1_0_0_Standalone.ahk` の両方を添付する。EXEのベースはAutoHotkey v2.0.27 x64、手動で動作確認済み。SHA-256・権利・[第三者ライセンス](../THIRD_PARTY_NOTICES.md)を確認する。

## 初回正式リリース v1.0.0 の手順

```powershell
# 既存リポジトリで v1.0.0 への更新をpushする
git add .
git commit -m "chore: prepare v1.0.0 release"
git push

# GitHub Actionsが成功し、問題がなければタグを作成する
git tag -a v1.0.0 -m "Browser Mouse Gestures v1.0.0"
git push origin v1.0.0

# GitHubの Releases -> Draft a new release から v1.0.0 タグを選択し、
# dist/BrowserMouseGestures-v1.0.0.exe と
# dist/Browser_MouseGestures_v1_0_0_Standalone.ahk の両方を添付して公開する。
```

※配布用の `dist/` は `.gitignore` の対象です。AHK版はGitHub Actions artifactまたは `python scripts/build.py` の生成物を使います。EXE版はAhk2Exeで手動生成・検証した成果物を使用します。タグをすでに公開済みの状態で、後からREADME等を変更した場合、タグが指すコミットにもその変更を含める必要があるか慎重に検討してください。公開済みReleaseのタグは原則として書き換えません。
