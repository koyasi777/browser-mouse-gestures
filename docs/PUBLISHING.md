# GitHub公開前チェックリスト

1. **権利の確認:** ライセンスをMITとすることについて、コード・アイコンを含むすべての権利を確認する。必要に応じて`LICENSE`の著作権者表記を変更する。
2. **個人情報の確認:** `settings.ini`、PCのユーザーフォルダへのパス、ログ、秘密情報を含めない。ローカル設定はGitの管理対象外にする。
3. **Windowsの動作検証:** `MouseGestures.ahk`と、`dist/Browser_MouseGestures_v3_8_3_Standalone.ahk`を別々に実行し、ジェスチャー・右クリック・ホイール・設定画面・複数ウィンドウ・配色とアイコンを確認する。
4. **CIが通過することを確認:** Pull Request・Push時にWindows runnerでAutoHotkey v2 `/Validate`、ヘルパーテスト、Pythonの一致検証が成功する。
5. **READMEと対応アプリの確認:** 「対応候補」と「実機動作確認済み」を区別して記載する。READMEのスクリーンショットは、個人情報のない環境で取得する。
6. **公開:** GitHubで空の公開リポジトリを作成してソースをpushする。配布用1ファイル版をReleasesに添付し、タグと変更履歴を記入する。

## GitHub CLIによる例（実行は任意）

```powershell
# ダウンロードしたZIPを展開後、そのリポジトリのルートで実行
# ghのインストールとサインインが必要です。
git init
git add .
git commit -m "Initial open-source release (modular v3.8.3)"
gh repo create browser-mouse-gestures --public --source=. --remote=origin --push

# GitHub Actionsの実行結果とWindows動作を確認してからタグを打つ
# git tag v3.8.3
# git push origin v3.8.3
```

※配布用の `dist/` は `.gitignore` の対象です。公開後はActionsのartifact、またはローカルで `python scripts/build.py` により生成した単体 `.ahk` をReleasesに添付してください。
