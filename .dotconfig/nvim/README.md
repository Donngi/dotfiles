# Neovim設定ガイド

## 概要

このNeovim設定は、シンプルで軽量な構成を目指しています。基本的なエディタ機能に加えて、ファイルエクスプローラー、ファジーファインダー、VSCode風のカラースキームを提供します。

## 機能

- ✅ シンタックスハイライト（Neovim標準機能 + nvim-treesitter）
- ✅ ファイルエクスプローラー（nvim-tree）
- ✅ ファジーファインダー（Telescope）
- ✅ VSCode風カラースキーム
- ✅ Markdownの箇条書き自動挿入
- ✅ クリップボード連携
- ✅ Git統合（nvim-tree）
- ✅ macOS標準のEmacs風キーバインド（インサートモード）
- ✅ マルチカーソル（vim-visual-multi）
- ✅ アウトライン表示（aerial.nvim）

## インストール済みプラグイン

### プラグインマネージャー
- **lazy.nvim**: プラグインの管理（自動インストール）

### エディタ機能
- **nvim-tree.lua**: ファイルエクスプローラー
  - ツリー形式でファイルを表示・操作
  - Gitステータス表示
- **nvim-web-devicons**: ファイルアイコン表示

### ファジーファインダー
- **Telescope.nvim**: ファイル検索、文字列検索
  - プロジェクト全体から素早く検索
- **plenary.nvim**: Telescope の依存ライブラリ

### カラースキーム
- **vscode.nvim**: Visual Studio Code風のダークテーマ

### マルチカーソル
- **vim-visual-multi**: 複数箇所を同時編集
  - 同じ単語を複数選択して一度に変更
  - VSCodeのCtrl+Dと同様の機能

### 構文解析・アウトライン
- **nvim-treesitter**: 高度な構文解析
  - より正確なシンタックスハイライト
  - コード構造の理解
- **aerial.nvim**: アウトライン表示
  - Markdownの見出し一覧をサイドバーに表示
  - VSCodeのアウトライン機能と同様

## セットアップ手順（新しい環境での再現）

### 1. Neovimのインストール

```bash
brew install neovim
```

### 2. 依存ツールのインストール

Telescopeの文字列検索機能（`<Space>fg`）を使う場合：

```bash
# macOS
brew install ripgrep

# Ubuntu/Debian
sudo apt install ripgrep
```

### 3. 設定ファイルの配置

```bash
# このdotfilesリポジトリをクローン
git clone <your-repo-url> ~/dotfiles

# シンボリックリンクを作成
ln -s ~/dotfiles/.dotconfig/nvim ~/.config/nvim
```

### 4. Neovimを起動

```bash
nvim
```

初回起動時に、lazy.nvimとすべてのプラグインが自動的にインストールされます。

## キーマッピング一覧

### 共通
- **リーダーキー**: `<Space>`（スペースキー）

### ファイルエクスプローラー（nvim-tree）
| キー       | 機能                                  |
| ---------- | ------------------------------------- |
| `<Space>e` | ファイルツリーの表示/非表示を切り替え |

**nvim-tree内でのキー操作**:
| キー    | 機能                                            |
| ------- | ----------------------------------------------- |
| `Enter` | ファイルを開く / ディレクトリを展開・折りたたむ |
| `a`     | 新規ファイル/ディレクトリ作成                   |
| `d`     | 削除                                            |
| `r`     | リネーム                                        |
| `x`     | カット                                          |
| `c`     | コピー                                          |
| `p`     | ペースト                                        |
| `R`     | 更新                                            |
| `?`     | ヘルプ表示                                      |

### アウトライン表示（aerial.nvim）
| キー       | 機能                                  |
| ---------- | ------------------------------------- |
| `<Space>o` | アウトライン（目次）の表示/非表示を切り替え |

**アウトラインへの移動**:
| キー         | 機能                     |
| ------------ | ------------------------ |
| `Ctrl+w` `l` | 右のウィンドウ（アウトライン）へ移動 |
| `Ctrl+w` `h` | 左のウィンドウ（エディタ）へ移動     |
| `Ctrl+w` `w` | 次のウィンドウへトグル               |

**アウトライン内でのキー操作**:
| キー    | 機能                               |
| ------- | ---------------------------------- |
| `j`/`k` | 上下に移動                         |
| `Enter` | 見出しの位置にジャンプ             |
| `o`     | ジャンプ（アウトラインを閉じない） |
| `q`     | アウトラインを閉じる               |
| `?`     | ヘルプを表示                       |

Markdownの見出し（`#`, `##`, `###`など）をツリー形式で表示します。

### ファジーファインダー（Telescope）
| キー        | 機能                                 |
| ----------- | ------------------------------------ |
| `<Space>ff` | ファイル名で検索                     |
| `<Space>fg` | 文字列をgrep検索（プロジェクト全体） |
| `<Space>fb` | 開いているバッファ一覧               |
| `<Space>fh` | ヘルプタグ検索                       |

**Telescope内でのキー操作**:
| キー           | 機能         |
| -------------- | ------------ |
| `Ctrl-n` / `↓` | 次の候補     |
| `Ctrl-p` / `↑` | 前の候補     |
| `Enter`        | 選択して開く |
| `Esc`          | キャンセル   |

### インサートモードでのカーソル移動（Emacs風）

macOSの標準的なEmacs風キーバインドをインサートモードで使用できます。

| キー     | 機能                         |
| -------- | ---------------------------- |
| `Ctrl+f` | 右に移動（→）                |
| `Ctrl+b` | 左に移動（←）                |
| `Ctrl+p` | 上に移動（↑）                |
| `Ctrl+n` | 下に移動（↓）                |
| `Ctrl+a` | 行頭に移動                   |
| `Ctrl+e` | 行末に移動                   |
| `Ctrl+h` | 前の文字を削除（Backspace）  |
| `Ctrl+d` | カーソル位置の文字を削除     |
| `Ctrl+k` | カーソル位置から行末まで削除 |

これにより、他のmacOSアプリケーション（ブラウザ、ターミナルなど）と同じ操作感でテキスト編集ができます。

### 15行ずつ移動

| キー              | 機能         | モード                     |
| ----------------- | ------------ | -------------------------- |
| `Ctrl+j` `Ctrl+k` | 15行上に移動 | ノーマル・インサート両方   |
| `Ctrl+j` `Ctrl+j` | 15行下に移動 | ノーマル・インサート両方   |

### マルチカーソル（vim-visual-multi）

複数箇所を同時に編集できます。

| キー     | 機能                                                   |
| -------- | ------------------------------------------------------ |
| `Ctrl+N` | カーソル位置の単語を選択（繰り返しで次の同じ単語も選択） |
| `Q`      | 現在の選択を削除（選択を1つ減らす）                    |
| `q`      | 現在の箇所をスキップして次へ                            |
| `n`      | 次の箇所へ移動                                          |
| `N`      | 前の箇所へ移動                                          |
| `i/a/I/A`| インサートモードで全ての選択箇所を同時編集              |
| `Esc`    | マルチカーソルモードを終了                              |

**使用例：**
1. 変更したい単語の上にカーソルを置く
2. `Ctrl+N`を押す（その単語が選択される）
3. もう一度`Ctrl+N`を押す（次の同じ単語も選択される）
4. 必要なだけ`Ctrl+N`を繰り返す
5. `i`を押してインサートモードに入る
6. 編集すると全ての選択箇所が同時に変更される
7. `Esc`でマルチカーソルモードを終了

### 検索ハイライトのクリア

| キー        | 機能                           |
| ----------- | ------------------------------ |
| `Esc` `Esc` | 検索ハイライトをクリア         |

`*`や`/`で検索した後のハイライト表示を消すことができます。

## 設定詳細

### 基本設定（.dotconfig/nvim/lua/base.lua）

- **インデント**: 4スペース
- **行番号表示**: 有効
- **クリップボード連携**: yankした内容がOSのクリップボードに保存される
- **True Color**: 24-bitカラー表示
- **シンタックスハイライト**: 有効
- **Markdown箇条書き**: `- `で始まる行でEnterを押すと次の行にも`- `が自動挿入
- **Emacs風キーバインド**: インサートモードでmacOS標準のCtrl+f/b/p/n/a/e/h/d/kが使用可能
- **15行移動**: Ctrl+j Ctrl+k/Ctrl+j Ctrl+jで15行ずつ上下に移動
- **マルチカーソル**: vim-visual-multiで複数箇所を同時編集
- **検索ハイライトクリア**: Esc Escで検索ハイライトをクリア
- **アウトライン表示**: Space oでMarkdownの見出し一覧を表示

### カラースキーム

VSCode風のダークテーマを使用しています。変更したい場合は`.dotconfig/nvim/lua/plugin_nvim_vscode.lua`を編集してください。

## よく使うコマンド

### Neovim内コマンド

```vim
:Lazy              " プラグイン管理画面を開く
:NvimTreeToggle    " ファイルツリーの表示/非表示
:Telescope         " Telescopeを開く
:checkhealth       " Neovimの健全性チェック
:q                 " 終了
:w                 " 保存
:wq                " 保存して終了
```

### lazy.nvim操作

`:Lazy`コマンドで開く画面で：

| キー | 機能                                           |
| ---- | ---------------------------------------------- |
| `I`  | プラグインをインストール                       |
| `U`  | プラグインを更新                               |
| `X`  | プラグインをクリーン（不要なものを削除）       |
| `S`  | プラグインの同期（インストール+更新+クリーン） |

### プラグインの更新手順

この設定では`lazy-lock.json`でプラグインのバージョンを固定しています。プラグインを更新する場合は以下の手順を実行してください。

1. **Neovimでプラグインを更新**
   ```vim
   :Lazy sync
   ```
   または
   ```vim
   :Lazy update
   ```

2. **lazy-lock.jsonの変更を確認**
   ```bash
   git diff .dotconfig/nvim/lazy-lock.json
   ```

3. **変更をコミット**
   ```bash
   git add .dotconfig/nvim/lazy-lock.json
   git commit -m "Update nvim plugins"
   git push
   ```

4. **他の環境で同期**
   他のマシンで最新のlazy-lock.jsonを取得後、Neovimを起動すると自動的に同じバージョンのプラグインがインストールされます。

**注意**: lazy-lock.jsonはGitで管理されているため、全ての環境で同じバージョンのプラグインが使用されます。

## トラブルシューティング

### プラグインが読み込まれない

```vim
:Lazy sync
```

を実行して、プラグインを再同期してください。

### Telescopeのgrep検索が動かない

ripgrepがインストールされているか確認：

```bash
rg --version
```

インストールされていない場合：

```bash
# macOS
brew install ripgrep

# Ubuntu/Debian
sudo apt install ripgrep
```

### nvim-treeが表示されない

```vim
:NvimTreeToggle
```

または `<Space>e` を押してください。

### カラースキームが正しく表示されない

ターミナルがTrue Color（24-bitカラー）に対応しているか確認してください。

iTerm2、Alacritty、WezTermなどの最新ターミナルでは対応しています。

### Neovimのバージョンが古い

この設定はNeovim 0.9.0以上を想定しています。バージョンを確認：

```bash
nvim --version
```

アップデート：

```bash
# macOS
brew upgrade neovim

# Ubuntu/Debian
# 最新版は公式のAppImageまたはPPAから
```

## ファイル構成

```
.dotconfig/nvim/
├── init.lua                      # メインの設定ファイル
├── README.md                     # このファイル
└── lua/
    ├── base.lua                  # 基本設定
    ├── keymaps.lua               # Telescopeのキーマッピング
    ├── plugins.lua               # プラグイン一覧
    ├── plugin_nvim_tree.lua      # nvim-treeの設定
    ├── plugin_nvim_vscode.lua    # VSCodeテーマの設定
    └── plugin_telescope.lua      # Telescopeの設定
```

## カスタマイズ

### インデント幅を変更したい

`.dotconfig/nvim/lua/base.lua`を編集：

```lua
vim.opt.shiftwidth=2  -- 2スペースに変更
vim.opt.tabstop=2
```

### カラースキームを変更したい

`.dotconfig/nvim/lua/plugins.lua`でカラースキームプラグインを変更：

```lua
-- 例: tokyonight.nvimに変更
{ "folke/tokyonight.nvim" },
```

`.dotconfig/nvim/lua/plugin_nvim_vscode.lua`の内容を変更：

```lua
require("tokyonight").setup()
vim.cmd[[colorscheme tokyonight]]
```

### nvim-treeのdotfiles表示を有効にしたい

`.dotconfig/nvim/lua/plugin_nvim_tree.lua`を編集：

```lua
filters = {
  dotfiles = false,  -- trueをfalseに変更
},
```

## 参考リンク

- [Neovim公式サイト](https://neovim.io/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [vscode.nvim](https://github.com/Mofiqul/vscode.nvim)
- [vim-visual-multi](https://github.com/mg979/vim-visual-multi)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [aerial.nvim](https://github.com/stevearc/aerial.nvim)
