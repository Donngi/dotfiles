# ------------------------------------------------------------------------
# memo
#
# 1 memo = 1 ディレクトリ = 1 git リポジトリ。
#
#   $MEMO_DIR/
#     20260503-買い物メモ/
#       .git/
#       20260503-買い物メモ.md
#
# memo を開くとその memo ディレクトリに cd するので、そのまま git 操作や
# AI CLI の起動ができる。
# ------------------------------------------------------------------------

function memo() {
    if [[ -z "$MEMO_DIR" ]]; then
        echo "Error: MEMO_DIR is not set. Set it in .zlocal" >&2
        return 1
    fi
    [[ -d "$MEMO_DIR" ]] || mkdir -p "$MEMO_DIR"

    local today=$(date +%Y%m%d)

    case "$1" in
        help|-h|--help)
            cat <<'HELP'
Usage: memo [<subcommand>|<title>]

1 memo = 1 ディレクトリ = 1 git リポジトリ。
memo を開くとその memo のディレクトリに cd する。

Subcommands:
  (none)          今日の日付でメモを開く (YYYYMMDD/YYYYMMDD.md)
  <title>         今日の日付+タイトルでメモを開く (YYYYMMDD-<title>/YYYYMMDD-<title>.md)
  ls              fzf でメモを一覧・選択して開く
  grep <keyword>  メモ内をキーワード検索し、選択して開く
  vi              MEMO_DIR を nvim で開く
  migrate         フラットな *.md を 1 memo = 1 ディレクトリ構造へ移行する
                  (--dry-run で移行プランの表示のみ)
  help, -h, --help  このヘルプを表示する

Environment:
  MEMO_DIR        メモの保存先ディレクトリ (.zlocal で設定)
HELP
            return 0
            ;;
        ls)
            local selected
            selected=$(_memo_list_entries | \
                fzf --delimiter=$'\t' --with-nth=2 --height 60% --reverse \
                    --preview 'bat --color=always --style=plain {1}' --preview-window=right:60%)
            [[ -n "$selected" ]] || return 0
            local filepath="${selected%%$'\t'*}"
            cd "${filepath:h}"
            nvim "$filepath"
            ;;
        grep)
            if [[ -z "$2" ]]; then
                echo "Usage: memo grep <keyword>" >&2
                return 1
            fi
            local selected
            # MEMO_DIR 内で相対パス検索することで、fzf の表示から長い絶対パスを排除する。
            selected=$(cd "$MEMO_DIR" && rg --line-number --color=always --no-heading "$2" . | \
                fzf --ansi --delimiter=: --height 60% --reverse \
                    --preview 'bat --color=always --style=plain --highlight-line {2} {1}' --preview-window=right:60%)
            [[ -n "$selected" ]] || return 0
            # rg --color の ANSI エスケープを剥がしてからパス・行番号を取り出す。
            selected=$(print -r -- "$selected" | sed $'s/\x1b\\[[0-9;]*m//g')
            local relpath="${selected%%:*}"
            local rest="${selected#*:}"
            local lineno="${rest%%:*}"
            local filepath="${MEMO_DIR}/${relpath#./}"
            cd "${filepath:h}"
            nvim "+${lineno}" "$filepath"
            ;;
        vi)
            nvim "$MEMO_DIR"
            ;;
        migrate)
            _memo_migrate "$2"
            ;;
        "")
            _memo_open "$today" "$today"
            ;;
        *)
            _memo_open "${today}-${1}" "$today" "$1"
            ;;
    esac
}

# memo ディレクトリを (無ければ作成して) 開く。
#   $1: ディレクトリ名 (= メインファイルの basename)
#   $2: frontmatter の date
#   $3: frontmatter の title (省略時は date)
function _memo_open() {
    local name="$1"
    local date="$2"
    local title="$3"
    local dirpath="$MEMO_DIR/$name"
    local filepath="$dirpath/${name}.md"

    [[ -d "$dirpath" ]] || mkdir -p "$dirpath"
    if [[ ! -f "$filepath" ]]; then
        _memo_create_with_template "$filepath" "$date" "$title"
    fi
    [[ -d "$dirpath/.git" ]] || git -C "$dirpath" init --quiet

    cd "$dirpath"
    nvim "$filepath"
}

function _memo_create_with_template() {
    local filepath="$1"
    local date="$2"
    local title="${3:-$date}"

    cat > "$filepath" <<EOF
---
title: ${title}
date: ${date}
---

EOF
}

# memo ディレクトリ名を日付部とタイトル部に分解する。
# 結果は reply 配列に (date title) の形で入る。date は無い場合は空文字列。
#   20260503-買い物メモ -> ("20260503" "買い物メモ")
#   20260330_心境レポート -> ("20260330" "心境レポート")
#   20260325             -> ("20260325" "20260325")
#   育児の方針           -> (""         "育児の方針")
function _memo_split_name() {
    local name="$1"
    if [[ "$name" =~ '^([0-9]{8})[-_](.+)$' ]]; then
        reply=("$match[1]" "$match[2]")
    elif [[ "$name" =~ '^([0-9]{8})$' ]]; then
        reply=("$match[1]" "$match[1]")
    else
        reply=("" "$name")
    fi
}

# fzf に流す行を出力する。1 行の形式は
#   <メインファイルの絶対パス><TAB><タイトル(左寄せ)>  <日付(右寄せ)>
# 日本語は表示幅が 2 桁なので、${(m)#str} (マルチバイト表示幅) でパディングを計算する。
function _memo_list_entries() {
    local -a dirs
    dirs=("$MEMO_DIR"/*(N/:t))
    (( ${#dirs} )) || return 0

    # 日付付きは新しい順に前へ、日付なしは名前順で後ろにまとめる。
    local -a dated undated
    local d
    local -a reply
    for d in "${dirs[@]}"; do
        _memo_split_name "$d"
        if [[ -n "$reply[1]" ]]; then
            dated+=("$d")
        else
            undated+=("$d")
        fi
    done
    dirs=(${(On)dated} ${(on)undated})

    local -a names titles dates
    local width maxwidth=0
    for d in "${dirs[@]}"; do
        _memo_split_name "$d"
        names+=("$d")
        dates+=("$reply[1]")
        titles+=("$reply[2]")
        # 日付を右寄せする幅は、日付付きエントリのタイトル幅だけで決める。
        if [[ -n "$reply[1]" ]]; then
            width=${(m)#reply[2]}
            (( width > maxwidth )) && maxwidth=$width
        fi
    done
    (( maxwidth > 60 )) && maxwidth=60

    local i title date pad datestr filepath
    for (( i = 1; i <= ${#names}; i++ )); do
        title="$titles[$i]"
        date="$dates[$i]"
        filepath="$MEMO_DIR/$names[$i]/$names[$i].md"
        [[ -f "$filepath" ]] || filepath="$MEMO_DIR/$names[$i]"

        if [[ -n "$date" ]]; then
            datestr="${date[1,4]}-${date[5,6]}-${date[7,8]}"
            width=${(m)#title}
            (( width < maxwidth )) && pad="${(l:$(( maxwidth - width )):: :)}" || pad=""
            printf '%s\t%s%s    %s\n' "$filepath" "$title" "$pad" "$datestr"
        else
            printf '%s\t%s\n' "$filepath" "$title"
        fi
    done
}

# $MEMO_DIR 直下のフラットな *.md を 1 memo = 1 ディレクトリ構造へ移行する。
#   foo.md -> foo/foo.md (+ git init + 初期コミット)
# $MEMO_DIR 直下の既存 .git は一切触らない。
function _memo_migrate() {
    local dry_run=0
    if [[ "$1" == "--dry-run" ]]; then
        dry_run=1
    elif [[ -n "$1" ]]; then
        echo "Usage: memo migrate [--dry-run]" >&2
        return 1
    fi

    local -a files
    files=("$MEMO_DIR"/*.md(N.:t))
    if (( ! ${#files} )); then
        echo "移行対象のファイルはありません。"
        return 0
    fi

    local -a targets skipped
    local f name
    for f in "${files[@]}"; do
        name="${f%.md}"
        if [[ -e "$MEMO_DIR/$name" ]]; then
            skipped+=("$f")
        else
            targets+=("$f")
        fi
    done

    echo "移行プラン:"
    for f in "${targets[@]}"; do
        name="${f%.md}"
        echo "  $f -> $name/$name.md (git init + 初期コミット)"
    done
    for f in "${skipped[@]}"; do
        echo "  [skip] $f -> 同名のディレクトリが既に存在します"
    done
    echo ""

    if (( dry_run )); then
        echo "--dry-run のため、実際の移行は行いません。"
        return 0
    fi
    if (( ! ${#targets} )); then
        echo "移行できるファイルはありません。"
        return 0
    fi

    local answer
    read "answer?${#targets} 件を移行します。よろしいですか? [y/N]: "
    if [[ "$answer" != [yY] ]]; then
        echo "中止しました。"
        return 0
    fi

    local migrated=0 failed=0
    for f in "${targets[@]}"; do
        name="${f%.md}"
        local dirpath="$MEMO_DIR/$name"
        if ! mkdir -p "$dirpath"; then
            echo "  [error] $f: ディレクトリを作成できませんでした" >&2
            (( failed++ ))
            continue
        fi
        if ! mv "$MEMO_DIR/$f" "$dirpath/${name}.md"; then
            echo "  [error] $f: 移動に失敗しました" >&2
            (( failed++ ))
            continue
        fi
        git -C "$dirpath" init --quiet
        git -C "$dirpath" add -A
        git -C "$dirpath" commit --quiet -m "メモを git 管理下に置く"
        echo "  [ok] $name"
        (( migrated++ ))
    done

    echo ""
    echo "移行完了: ${migrated} 件 / スキップ: ${#skipped} 件 / 失敗: ${failed} 件"
    if (( migrated )); then
        cat <<'NOTE'

備考: $MEMO_DIR 直下の既存 git リポジトリはそのまま残しています。
各 memo が個別 repo になったため、親 repo の git status には
ネストした repo が並びます。気になる場合は $MEMO_DIR/.gitignore を調整してください。
NOTE
    fi
}
