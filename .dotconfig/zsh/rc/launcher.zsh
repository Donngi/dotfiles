# ------------------------------------------------------------------------
# ghq + fzf + split + AI CLI ランチャー
#
# ghq 管理 repo を fzf で選択 → cd → ターミナルを縦 split → 左で AI CLI を起動。
# Ghostty / cmux (coder/cmux) どちらでも同じキーで動く。
#
#   Ctrl+G → c  : claude
#   Ctrl+G → k  : kiro-cli
# ------------------------------------------------------------------------

# 現在の pane が cmux 配下かを親プロセス系統で判定する。
# cmux app が別途起動しているだけの Ghostty shell では false を返したいので、
# cmux identify の exit code ではなく自プロセスの祖先プロセスを辿って判定する。
_launcher-inside-cmux() {
    local pid=$$
    local comm
    while [[ -n "$pid" && "$pid" != 0 && "$pid" != 1 ]]; do
        comm=$(ps -o comm= -p "$pid" 2>/dev/null) || return 1
        case "$comm" in
            *cmux*) return 0 ;;
        esac
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    done
    return 1
}

_launcher-split-right() {
    if _launcher-inside-cmux && command -v cmux > /dev/null 2>&1; then
        cmux new-split right > /dev/null 2>&1
    elif [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
        # Ghostty.app の AppleScript Dictionary (Ghostty.sdef) 経由で直接 split を呼ぶ。
        # System Events の keystroke 偽装より堅く、widget 実行中でも確実に発火する。
        # 初回のみ macOS のオートメーション権限ダイアログが出る。
        osascript -e 'tell application "Ghostty" to split front window'"'"'s selected tab'"'"'s focused terminal direction right' > /dev/null 2>&1
    fi
}

_launcher-ghq-fzf-run() {
    local cmd=$1
    local target
    target=$(ghq list --full-path | fzf --height 60% --reverse) || { zle reset-prompt; return 0; }
    [[ -d "$target" ]] || { zle reset-prompt; return 0; }

    BUFFER=""
    zle reset-prompt
    cd "$target"
    _launcher-split-right
    "$cmd"
    zle reset-prompt
}

ghq-fzf-claude-launcher() { _launcher-ghq-fzf-run claude; }
ghq-fzf-kiro-launcher()   { _launcher-ghq-fzf-run kiro-cli; }
zle -N ghq-fzf-claude-launcher
zle -N ghq-fzf-kiro-launcher
bindkey '^Gc' ghq-fzf-claude-launcher
bindkey '^Gk' ghq-fzf-kiro-launcher
