# Dotfiles Agent Guidelines

このリポジトリを変更する AI エージェント向けのガイドライン。

## リポジトリ概要

macOS / WSL / Windows 向けの dotfiles リポジトリ。

- **`.dotconfig/`**: アプリケーション設定ファイル
- **`setup/`**: プラットフォーム別のデプロイ・初期化スクリプト
- **`Makefile`**: セットアップの統一インターフェース（`make <platform>-<action>-<target>`）
- **ルートのドットファイル**: `.zshrc`, `.zshenv`, `.zprofile`, `.gitconfig`

設定ファイルはシンボリックリンクでホームディレクトリに配置される。

## 変更時のルール

### 変更可能な範囲

- `.dotconfig/` 配下の設定ファイル
- `setup/` 配下のスクリプト
- `Makefile` のターゲット追加
- ルートのドットファイル（`.zshrc`, `.zshenv`, `.zprofile`, `.gitconfig`）
- `.agents/` 配下の AI エージェント設定

### 変更禁止事項

- `.gitignore` のホワイトリスト方式の構造を変更しない（`/**` と `/.**` による全 ignore ルールを削除しない）
- デプロイスクリプトのバックアップ処理を削除しない
- `.zlocal` や `.gitconfig.local` の内容をリポジトリにコミットしない（シークレットが含まれる可能性がある）
- `setup.sh` のプラットフォーム判定ロジックを壊さない

### .gitignore のホワイトリスト方式

このリポジトリの `.gitignore` はホワイトリスト方式を採用している。**新しいファイルを追加する場合は、必ず `.gitignore` にも `!/<パス>` エントリを追加すること。** これを忘れると、ファイルが git に追跡されない。

ディレクトリの場合は、ディレクトリ自体と配下のファイルの両方を許可する必要がある:

```gitignore
!/.dotconfig/<app_name>
!/.dotconfig/<app_name>/config_file
```

## 変更パターン

### Zsh 設定の追加・変更

1. `.dotconfig/zsh/rc/` 配下の該当モジュールファイルを編集する
2. 新しいモジュールを追加する場合は `.zshrc` に `source` 行を追加する
3. 環境変数の追加は `.zshenv` に記述する

**モジュール一覧と役割**:

| ファイル | 役割 |
|----------|------|
| `alias.zsh` | コマンドエイリアス |
| `appearance.zsh` | プロンプト・表示設定 |
| `bindkey.zsh` | キーバインド |
| `completion.zsh` | 補完設定 |
| `editor.zsh` | EDITOR / VISUAL 設定 |
| `history.zsh` | 履歴設定 |
| `path.zsh` | PATH 設定 |
| `wordstyle.zsh` | 単語区切り設定 |
| `wsl.zsh` | WSL 固有設定（WSL でのみロード） |
| `xxenv.zsh` | バージョンマネージャ設定 |

### 新規アプリケーション設定の追加

1. `.dotconfig/<app_name>/` ディレクトリを作成し、設定ファイルを配置
2. `.gitignore` にホワイトリストエントリを追加
3. `setup/<platform>/deploy/deploy_<app_name>.sh` を作成
4. `Makefile` にデプロイターゲットを追加
5. 必要であれば `setup/<platform>/init/init_<app_name>.sh` も作成

### 既存設定の変更

- `.dotconfig/` 配下のファイルを直接編集する
- シンボリックリンク経由で変更が即座に反映される
- `.gitignore` の変更は不要（既にホワイトリスト登録済み）

## テスト方法

- `git status` で変更ファイルが正しく追跡されていることを確認
- zsh 設定の変更後は `source ~/.zshrc` でリロードし、エラーがないことを確認
- デプロイスクリプトの変更後は `make <platform>-deploy-<target>` を実行し、シンボリックリンクが正しく作成されることを確認

## 利用可能なスキル

`.agents/skills/` にエージェント共通のスキルが定義されている。各 AI ツール(`.claude/`, `.codex/`, `.kiro/`)からシンボリックリンクで参照される。

| スキル | パス | 説明 |
|--------|------|------|
| `commit` | `.agents/skills/commit/` | コミット規約に沿ったコミットを作成する。変更の分類・分割も自動判断する |

## コミット規約

コミットメッセージは `.agents/skills/commit/references/commit-conventions.md` に定義された規約に従う。

- フォーマット: `<scope>: <message>`
- メッセージは日本語、動詞で始める
- 50文字以内を目安

主なスコープ: `zsh`, `nvim`, `ghostty`, `vscode`, `homebrew`, `git`, `setup`, `agents`, `docs`

## Neovim プラグイン管理のセキュリティ規律

lazy.nvim はプラグインのコードがインストール時/起動時に shell-level の権限で動くため、サプライチェーン攻撃の標的になりうる。以下の運用を守ること。

### 通常運用

- 設定変更だけのときは `:Lazy update` 等を実行しない。lockfile (`.dotconfig/nvim/lazy-lock.json`) の内容が信頼の源
- 別マシンや初回起動時の同期は `:Lazy restore` で lockfile に合わせる
- `:Lazy sync` は install/update/clean を一括で行うため使わない。install したいだけなら `:Lazy install`、update したいときは `:Lazy update` を使う

### Lazy UI のキー操作

`:Lazy` UI 内のキーは本来すべて確認なしで即実行される (lazy.nvim の設計)。
このリポジトリでは `.dotconfig/nvim/lua/base.lua` の `FileType lazy` autocmd で、状態を変更するキーに `vim.fn.confirm` を挟むようバッファローカルで上書きしている。

- 確認あり (デフォルト No): `I` / `U` / `S` / `X` / `R` (全件)、`i` / `u` / `x` (カーソル位置 + visual mode で選択した範囲のプラグイン)、`r` (個別 restore)
- 確認なし (read-only): `C` (check) / `L` (log) / `c` (個別 check)

意図的にプラグインの状態を変更する場合のみ Yes を選ぶこと。プロンプト中で `Enter` を押すと No が確定する設計にしてある (誤操作防止)。

### プラグインの更新フロー

1. `:Lazy update` で更新候補を取得 (lockfile はまだ書き換わらない)
2. UI で各プラグインの commit 差分を確認 (`<CR>` で diff 表示)
3. 不審な変更がないと判断したら確定
4. `git diff .dotconfig/nvim/lazy-lock.json` で diff を再確認
5. 問題なければ commit

`:Lazy update <plugin>` で個別更新も可能。普段は数プラグインずつ更新するのが安全。

### プラグイン追加時のチェックリスト

- リポジトリの star 数、最終 commit 日、メンテナの活動度を確認
- `build` フィールドを伴うプラグインは Makefile / build script を必ず読む
- `version = "*"` は使わない。lockfile に任せるか、メジャー固定 (`^N` / `N.*`) のみ可
- `branch = "main"` 追従は原則禁止。archive 済みリポジトリは spec に `commit = "<sha>"` を直接書いて固定する

### 既知の attack surface

- `telescope-fzf-native`: `build = "make"` で Makefile を実行
- `nvim-treesitter`: リポジトリは archive 済みで spec で `commit` を固定。`:Lazy update` でも no-op になる (spec の `commit` が `target` を上書きするため)。本当に commit を動かしたい場合は、新フォークの存在を確認した上で spec の commit hash を手動で書き換える。`build = ":TSUpdate"` は初回 install 時のみ走り、各言語の parser を GitHub から取得 + compile する点に注意

### 将来検討

- lazy.nvim の `minimum_release_age` 機能 ([Issue #2141](https://github.com/folke/lazy.nvim/issues/2141) / [PR #2152](https://github.com/folke/lazy.nvim/pull/2152)) がマージされたら、全プラグインに `7d` 程度の cooldown を入れる
- `lazy-lock.json` を Renovate で自動更新 PR 化することも検討余地あり

## プラットフォーム固有の注意

### macOS

- Homebrew のパスは Apple Silicon (`/opt/homebrew`) と Intel (`/usr/local`) で異なる
- `.zprofile` でプラットフォームに応じた Homebrew パスを設定している

### WSL

- `.zshrc` 内で `uname -a` による WSL 判定を行い、`wsl.zsh` を条件付きでロードしている
- WSL 固有の設定は `.dotconfig/zsh/rc/wsl.zsh` と `.dotconfig/wsl/` に分離されている

### Windows

- AutoHotkey スクリプトが `.dotconfig/autohotkey/` に配置されている
- winget によるアプリインストールスクリプトが `setup/windows/` にある
