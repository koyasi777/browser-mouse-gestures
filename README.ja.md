# Browser Mouse Gestures

[English](README.md) | 日本語

**正式リリース: v1.0.0** · [リリースノート](docs/RELEASE_NOTES_v1.0.0.md)

Windows向けの、AutoHotkey v2で動くオープンソースのマウスジェスチャーツールです。Chromium系・Firefox系ブラウザ、Windowsメモ帳、ユーザーが登録したアプリを対象にできます。ブラウザ拡張機能ではなくOS側で動作するため、一般的な拡張機能では操作できないブラウザ内部ページでも利用できます（アプリ側の制限は残ります）。

> **正式公開バージョン: v1.0.0。** 動作確認済みの旧v3.8.3実装を、機能を変更せずモジュール分割したものです。バージョンコメントのみ変更しています。全ブラウザ・すべてのWindows構成での動作を保証するものではありません。

## 主な機能

- 上下左右のみ、最大3方向のマウスジェスチャーと任意のショートカット操作の割り当て（用意された17種類の操作から選択）。
- 右クリック＋ホイールによるタブ切り替え。方向と連続操作間隔を設定可能。
- タスクトレイから開く設定画面。ブラウザ別の有効／無効切り替えと、起動中ウィンドウからのアプリ追加。
- Windowsメモ帳を初期状態で有効化。
- 7段階の認識感度、ジェスチャー別の軌跡色、太さ（1～30px）、発光、HUD、アイコンのカスタマイズ。
- 複数モニター対応のタイル式軌跡描画。色変更時は描画済みピクセルの色を高速更新。
- 右クリック開始時の**マウス下のウィンドウ**を対象として固定し、誤ったアクティブウィンドウへの送信を避ける。
- 設定を `%APPDATA%\ChromiumMouseGestures\settings.ini` に保存。**ネットワークへの自動通信・テレメトリーなし**。

## インストールと実行

**方法A：Windows x64 EXE版（推奨・AutoHotkeyの導入不要）**

1. [v1.0.0のRelease](https://github.com/koyasi777/browser-mouse-gestures/releases/tag/v1.0.0) から `BrowserMouseGestures-v1.0.0.exe` をダウンロード。
2. 古い版が実行中ならタスクトレイから終了して、EXEを通常の権限で起動（管理者権限は原則不要）。
3. タスクトレイのアイコンをダブルクリックして設定画面を開く。

**方法B：単一AHK版（AutoHotkey v2が必要）**

1. [AutoHotkey v2](https://www.autohotkey.com/) を公式サイトからインストール。
2. 上記Releaseから `Browser_MouseGestures_v1_0_0_Standalone.ahk` をダウンロード（または `python scripts/build.py` で `dist/` に生成）。
3. 古い版を終了し、AHKファイルを実行。設定はタスクトレイから開けます。

**方法C：開発用の分割版**

リポジトリをクローンし、ルートの `MouseGestures.ahk` を実行します。`src/` と一緒に配置してください。Pythonは実行時には不要です。

## 初期操作

| マウス操作 | 動作 |
|---|---|
| 右ボタンを押しながら ↓ | 新しいタブ |
| 右ボタンを押しながら ↓→ | タブを閉じる |
| 右ボタン＋ホイール上 | 前のタブ |
| 右ボタン＋ホイール下 | 次のタブ |
| 登録されていないジェスチャー | 何もしない |
| 普通の右クリック | 通常のコンテキストメニュー |

割り当て・ホイール方向は設定画面で変更できます。ジェスチャーは**右ボタンを離したとき**に実行されます。

## 対応アプリについて

Chrome、Brave、Edge、Vivaldi、HeliumなどのChromium系とFirefox、Floorp、Zen、LibreWolf、WaterfoxなどのGecko系を認識対象として登録しています（定義一覧は `MouseGestures.ahk` 冒頭を参照）。**「対応候補として定義している」ことと「その環境で実機検証済み」は異なります**。特にポータブル版・独自ビルドは実行ファイル名やパスが異なる場合があります。

OperaやVivaldiのように標準のマウスジェスチャーを持つブラウザでは、操作の二重実行を防ぐため、ブラウザ側のジェスチャーを無効にすることを検討してください。

設定画面では、起動中のウィンドウから追加対象を選べます。既存アプリでショートカットが別の意味を持つ場合、その操作は使わないでください。ユーザーが登録したアプリは実行ファイルのフルパスで識別します。

## 安全性と制限

- 右クリック開始時に対象ウィンドウを記録し、操作時にそのウィンドウをアクティブ化してキー操作を送信します。**バックグラウンドのまま操作する方式ではありません。**
- 管理者権限で実行されるアプリには、通常権限のAHKから入力を送れない場合があります。むやみにAHK全体を管理者として実行しないでください。
- 起動中のアプリのパスや設定がローカルに保存されます。`settings.ini` をGitHubの公開リポジトリへコミットしないでください。
- Windows x64向けEXE版は公式Ahk2ExeとAutoHotkey v2.0.27ベースで手動生成・Windows上で動作確認しています。現行CIはAHKソースを検証しますが、EXE自体のビルドや検証は自動化していません。未署名のEXEはSmartScreenの警告が出る場合があります。
- 詳しくは [SECURITY.md](SECURITY.md) を参照してください。

## 開発・検証

```powershell
python -m unittest discover -s tests -v
python scripts/build.py

# Windows / AutoHotkey v2 がインストールされている環境で
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut=UTF-8 /Validate .\MouseGestures.ahk
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut=UTF-8 /Validate .\dist\Browser_MouseGestures_v1_0_0_Standalone.ahk
```

`build.py` は開発用の全モジュールを結合し、**バージョンコメントだけを比較時に旧表記へ戻した上で、元のv3.8.3と実行コードが一致することをSHA-256で確認**します。Windowsの自動構文検証・独立した関数テストはGitHub Actionsで実行されます。実機でのマウス操作は自動CIだけでは確認できないため、[CONTRIBUTING.md](CONTRIBUTING.md) に従って手動確認してください。

ファイル分割の詳細は [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) を参照してください。

## ライセンス

本プロジェクト独自のスクリプト・アイコンは [MIT License](LICENSE) で配布する想定です（公開前に権利・出所を最終確認）。EXEに組み込まれるAutoHotkey v2.0.27の実行環境には、別途 **GNU GPL v2** が適用されます。詳細は [第三者ライセンス告知](THIRD_PARTY_NOTICES.md) と [GPL v2本文](LICENSES/GPL-2.0.txt) を参照してください。EXE全体がMITライセンスだけで構成されるという意味ではありません。
