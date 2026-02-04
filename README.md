# dotfiles

macOS / WSL / Windows 向けの dotfiles です。

- [設計思想](#設計思想)
  - [1. 設定のコード管理](#1-設定のコード管理)
  - [2. Makefile による操作の抽象化](#2-makefile-による操作の抽象化)
  - [3. Deploy と Init の分離](#3-deploy-と-init-の分離)
  - [4. モジュラー設定](#4-モジュラー設定)
  - [5. シークレットの分離](#5-シークレットの分離)
  - [6. 誤操作の防止](#6-誤操作の防止)
- [ディレクトリ構造](#ディレクトリ構造)
  - [シンボリックリンクの対応](#シンボリックリンクの対応)
- [セットアップ](#セットアップ)
  - [All in one(初回セットアップ)](#all-in-one初回セットアップ)
  - [Deploy(設定ファイルの配置)](#deploy設定ファイルの配置)
  - [Init(パッケージのインストール)](#initパッケージのインストール)
- [設定ファイルの構造](#設定ファイルの構造)
  - [zsh 設定のモジュール分割](#zsh-設定のモジュール分割)
  - [Neovim 設定の構造](#neovim-設定の構造)
  - [Homebrew Brewfile の環境別分離](#homebrew-brewfile-の環境別分離)
- [端末固有の設定の追加ロード](#端末固有の設定の追加ロード)
  - [推奨設定](#推奨設定)
- [新しいアプリケーション設定を追加するには](#新しいアプリケーション設定を追加するには)
- [手動セットアップが必要なもの](#手動セットアップが必要なもの)
  - [iTerm2](#iterm2)
  - [VS Code(settings.json)](#vs-codesettingsjson)
  - [Karabiner-Elements](#karabiner-elements)

## 設計思想

このリポジトリは6つのコア原則に基づいて設計されています。

### 1. 設定のコード管理

設定ファイルはすべて Git リポジトリでバージョン管理します。変更履歴の追跡、差分の確認、以前の状態への復元が可能になります。

### 2. Makefile による操作の抽象化

環境構築は `make` コマンドで抽象化されており、利用者は個々のスクリプトパスを意識する必要がありません。

```bash
# 利用者が知るべきインターフェース
make mac-os-deploy-all    # 設定ファイルの配置
make mac-os-init-all      # パッケージのインストール
```

Makefile が内部スクリプトへのディスパッチャとして機能するため、スクリプトの配置やファイル名が変わっても利用者側の操作は変わりません。

### 3. Deploy と Init の分離

セットアップ処理は **Deploy(設定ファイルの配置)** と **Init(パッケージのインストール)** に明確に分離されています。

- **Deploy**: シンボリックリンクの作成。何度実行しても安全な冪等操作です。高速に完了します
- **Init**: Homebrew パッケージのインストール、Node.js 環境の構築など。時間がかかる処理です

この分離により、設定ファイルだけを更新したいときに `deploy` のみ実行するといった部分的な再実行が可能になります。

### 4. モジュラー設定

`.zshrc` を1ファイルで管理するのではなく、機能ごとにモジュール分割しています。

```
.dotconfig/zsh/rc/
├── alias.zsh        # エイリアス定義
├── appearance.zsh   # プロンプト・見た目
├── bindkey.zsh      # キーバインド
├── completion.zsh   # 補完設定
├── editor.zsh       # エディタ設定
├── history.zsh      # 履歴設定
├── path.zsh         # PATH 設定
├── wordstyle.zsh    # 単語区切り設定
├── wsl.zsh          # WSL 固有設定
└── xxenv.zsh        # バージョンマネージャ設定
```

問題が起きた機能だけを無効化でき、変更の影響範囲が明確になります。

### 5. シークレットの分離

シークレットやマシン固有の情報はリポジトリに含めません。端末固有の設定の追加ロードファイルを別途用意し、メインの設定ファイルからロードする仕組みにしています。

| ファイル | 用途 |
|----------|------|
| `~/.zlocal` | zsh の端末固有の設定の追加ロード |
| `~/.gitconfig.local` | Git のユーザー名・メールアドレスなど |

### 6. 誤操作の防止

**ホワイトリスト方式の .gitignore**: デフォルトで全ファイルを ignore し、管理対象だけを `!` で明示的に許可します。新しいファイルを誤ってコミットすることを防ぎます。

```gitignore
# すべて ignore
/**
/.**

# 許可するファイルを明示
!/.zshrc
!/.gitconfig
!/Makefile
...
```

**自動バックアップ**: デプロイスクリプトは既存の設定ファイルを `~/.dotbackup/<タイムスタンプ>/` に退避してからシンボリックリンクを作成します。上書きによるデータ損失を防ぎます。

## ディレクトリ構造

```
dotfiles/
├── .zshenv                  # zsh 環境変数(ZDOTDIR, HISTSIZE 等)
├── .zprofile                # zsh ログインシェル初期化
├── .zshrc                   # zsh 設定エントリポイント(モジュールを source)
├── .gitconfig               # Git 設定(.gitconfig.local を include)
├── .gitignore               # ホワイトリスト方式
├── Makefile                 # セットアップの統一インターフェース
├── setup.sh                 # 初回セットアップ用スクリプト
├── README.md
├── AGENTS.md                # AI エージェント向けガイドライン
├── CLAUDE.md                # Claude Code 設定
│
├── .dotconfig/              # アプリケーション設定
│   ├── zsh/
│   │   └── rc/              # zsh モジュラー設定
│   │       ├── alias.zsh
│   │       ├── appearance.zsh
│   │       ├── bindkey.zsh
│   │       ├── completion.zsh
│   │       ├── editor.zsh
│   │       ├── history.zsh
│   │       ├── path.zsh
│   │       ├── wordstyle.zsh
│   │       ├── wsl.zsh
│   │       └── xxenv.zsh
│   ├── nvim/                # Neovim 設定
│   │   ├── init.lua
│   │   └── lua/
│   │       ├── base.lua
│   │       └── plugins.lua
│   ├── homebrew/            # Homebrew Brewfile(環境別)
│   │   ├── mac_os/
│   │   │   ├── Brewfile_homebrew
│   │   │   ├── Brewfile_dev_cli
│   │   │   ├── Brewfile_dev_gui
│   │   │   └── Brewfile_applications
│   │   └── wsl/
│   │       └── Brewfile_dev_cli
│   ├── ghostty/             # Ghostty ターミナル設定
│   │   └── config
│   ├── bat/                 # bat 設定
│   │   └── bat.conf
│   ├── karabiner/           # Karabiner キーリマップ
│   │   └── _karabiner.json
│   ├── iterm2/              # iTerm2 設定
│   │   └── com.googlecode.iterm2.plist
│   ├── vscode/              # VS Code 設定
│   │   ├── _setting.json
│   │   ├── mac_os/keybindings.json
│   │   └── windows/keybindings.json
│   ├── idea/                # IntelliJ IDEA 設定
│   │   └── macOS_Donngi.xml
│   ├── lima/                # Lima(Docker VM)設定
│   │   └── docker_template.yml
│   ├── autohotkey/          # AutoHotkey(Windows)
│   │   └── apple-magic-keyboard-us.ahk
│   └── wsl/                 # WSL 設定
│       └── wsl.conf
│
├── setup/                   # セットアップスクリプト
│   ├── util_deploy.sh       # 汎用デプロイユーティリティ
│   ├── util_deploy_sudo.sh
│   ├── mac_os/
│   │   ├── deploy/          # macOS 設定配置スクリプト
│   │   │   ├── deploy_home.sh
│   │   │   ├── deploy_nvim.sh
│   │   │   ├── deploy_vscode.sh
│   │   │   ├── deploy_idea.sh
│   │   │   └── deploy_ghostty.sh
│   │   └── init/            # macOS 初期化スクリプト
│   │       ├── init_homebrew.sh
│   │       ├── init_macOS.sh
│   │       ├── init_custom_pure.sh
│   │       └── init_node.sh
│   ├── wsl/
│   │   ├── deploy/          # WSL 設定配置スクリプト
│   │   │   ├── deploy_home.sh
│   │   │   └── deploy_wsl_conf.sh
│   │   └── init/            # WSL 初期化スクリプト
│   │       ├── init_build_essential.sh
│   │       ├── init_ca_certificates.sh
│   │       ├── init_custom_pure.sh
│   │       ├── init_default_shell.sh
│   │       ├── init_docker.sh
│   │       ├── init_homebrew.sh
│   │       └── init_node.sh
│   └── windows/
│       └── init/
│           └── init_apps_with_winget.bat
│
├── .agents/                 # AI エージェント共通設定
│   └── skills/
│       └── commit/          # コミットスキル定義
│           ├── SKILL.md
│           └── references/
│               └── commit-conventions.md
│
├── .claude/                 # Claude Code 設定
│   └── skills/
│       └── commit -> ../../.agents/skills/commit
├── .codex/                  # Codex 設定
│   └── skills/
│       └── commit -> ../../.agents/skills/commit
└── .kiro/                   # Kiro CLI 設定
    └── skills/
        └── commit -> ../../.agents/skills/commit
```

### シンボリックリンクの対応

リポジトリ内の設定ファイルは、デプロイスクリプトによってシンボリックリンクで実際の配置先に接続されます。

```
Repository                       Destination
---------                        -----------
dotfiles/.zshrc               -> ~/.zshrc
dotfiles/.zshenv              -> ~/.zshenv
dotfiles/.zprofile            -> ~/.zprofile
dotfiles/.gitconfig           -> ~/.gitconfig
dotfiles/.dotconfig/          -> ~/.dotconfig/
dotfiles/.dotconfig/nvim/     -> ~/.config/nvim/
dotfiles/.dotconfig/ghostty/  -> ~/.config/ghostty/
```

シンボリックリンクのため、リポジトリ内のファイルを編集すれば設定がそのまま反映されます。

## セットアップ

### All in one(初回セットアップ)

新しい macOS 環境や WSL 環境で、すべてのセットアップを一括実行します。

```bash
bash setup.sh
```

このスクリプトはプラットフォームを自動判定し、適切な deploy と init を正しい順序で実行します。

### Deploy(設定ファイルの配置)

シンボリックリンクを作成します。既存ファイルは自動でバックアップされます。

```bash
# すべてデプロイ
make mac-os-deploy-all    # macOS
make wsl-deploy-all       # WSL

# 個別デプロイ
make mac-os-deploy-home      # ホームディレクトリのドットファイル
make mac-os-deploy-nvim      # Neovim
make mac-os-deploy-vscode    # VS Code
make mac-os-deploy-idea      # IntelliJ IDEA
make mac-os-deploy-ghostty   # Ghostty
```

### Init(パッケージのインストール)

アプリケーションのインストールや初期設定を行います。

```bash
# すべて初期化
make mac-os-init-all      # macOS
make wsl-init-all         # WSL

# 個別初期化
make mac-os-init-brew           # Homebrew + パッケージ
make mac-os-init-node           # Volta + Node.js
make mac-os-init-custom-pure    # Pure プロンプトテーマ
```

## 設定ファイルの構造

### zsh 設定のモジュール分割

zsh 設定は3層構造になっています。

1. **`.zshenv`**: 環境変数の定義。`ZDOTDIR`, `ZSHRC_DIR`, `HISTSIZE` など、すべてのシェルで必要な変数です
2. **`.zshrc`**: モジュールの source エントリポイント。各 `.zsh` ファイルをロードします
3. **`.dotconfig/zsh/rc/*.zsh`**: 機能ごとの設定モジュールです

`.zshrc` は以下の順序でモジュールをロードします:

```
appearance → completion → alias → bindkey → editor →
wordstyle → history → path → xxenv → wsl(条件付き)→ .zlocal(端末固有の設定の追加ロード)
```

### Neovim 設定の構造

Neovim は `lazy.nvim` をパッケージマネージャとして使用し、設定を分離しています。

- **`init.lua`**: 基本設定(インデント、クリップボード、キーマップ等)と lazy.nvim の初期化
- **`lua/base.lua`**: 基本的なエディタ設定
- **`lua/plugins.lua`**: プラグイン定義(nvim-tree, telescope, treesitter 等)

### Homebrew Brewfile の環境別分離

Brewfile はプラットフォームごとに分離されています。

```
.dotconfig/homebrew/
├── mac_os/
│   ├── Brewfile_homebrew       # Homebrew 自体の設定
│   ├── Brewfile_dev_cli        # 開発用 CLI ツール
│   ├── Brewfile_dev_gui        # 開発用 GUI アプリ
│   └── Brewfile_applications   # 一般アプリケーション
└── wsl/
    └── Brewfile_dev_cli        # WSL 用 CLI ツール
```

macOS と WSL で必要なパッケージが異なるため、環境別に Brewfile を管理しています。さらに用途(CLI/GUI/アプリ)で分割し、必要な範囲だけインストールできるようにしています。

## 端末固有の設定の追加ロード

一部の設定ファイルは `$HOME` にある端末固有の設定の追加ロードファイルを追加でロードします。これらのファイルはリポジトリに含めません。

| ファイル | 用途 |
|----------|------|
| `~/.zlocal` | zsh の端末固有の設定の追加ロード |
| `~/.gitconfig.local` | Git のユーザー名・メールアドレスなど |

### 推奨設定

`.zlocal`

```bash
# Lima のワークスペースディレクトリ
export LIMA_WORKSPACE_DIRECTORY="YOUR_LIMA_PATH"
```

`.gitconfig.local`

```gitconfig
[user]
    name = YOUR_NAME
    email = YOUR_EMAIL
[ghq]
    root = YOUR_GHQ_PATH
```

## 新しいアプリケーション設定を追加するには

### 1. 設定ファイルを配置する

```bash
# .dotconfig/ 配下にアプリ名のディレクトリを作成
mkdir .dotconfig/<app_name>

# 設定ファイルを配置
cp /path/to/config .dotconfig/<app_name>/
```

### 2. .gitignore にホワイトリストエントリを追加する

```gitignore
!/.dotconfig/<app_name>
!/.dotconfig/<app_name>/config_file
```

### 3. デプロイスクリプトを作成する

`setup/mac_os/deploy/deploy_<app_name>.sh` を作成し、シンボリックリンクの作成処理を記述します。既存の `deploy_ghostty.sh` や `deploy_nvim.sh` を参考にしてください。

### 4. Makefile にターゲットを追加する

```makefile
mac-os-deploy-<app_name>:
    bash ./setup/mac_os/deploy/deploy_<app_name>.sh
```

### 5. 必要に応じて init スクリプトを作成する

パッケージのインストールが必要な場合は `setup/mac_os/init/init_<app_name>.sh` も作成します。

## 手動セットアップが必要なもの

一部のアプリケーションはスクリプトだけでは完全にセットアップできません。

### iTerm2

設定ファイルのパスを手動で指定します。

1. `Settings` > `General` > `Preferences` を開く
2. `Load preferences from a custom folder or URL` にチェックを入れる
3. パスを `/Users/<NAME>/.dotconfig/iterm2` に設定する

### VS Code(settings.json)

`_setting.json` は自動デプロイされません。設定内容を手動で VS Code の `settings.json` にコピーしてください。

```bash
# macOS の settings.json の場所
~/Library/Application Support/Code/User/settings.json
```

keybindings.json は `make mac-os-deploy-vscode` で自動デプロイされます。

### Karabiner-Elements

`_karabiner.json` は自動デプロイされません。設定内容を手動で Karabiner の設定ファイルにコピーしてください。

```bash
~/.config/karabiner/karabiner.json
```

