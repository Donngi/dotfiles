function memo() {
    if [[ -z "$MEMO_DIR" ]]; then
        echo "Error: MEMO_DIR is not set. Set it in .zlocal" >&2
        return 1
    fi
    [[ -d "$MEMO_DIR" ]] || mkdir -p "$MEMO_DIR"
    cd "$MEMO_DIR"

    local today=$(date +%Y%m%d)

    case "$1" in
        ls)
            local selected
            selected=$(find "$MEMO_DIR" -name '*.md' -type f | sort -r | \
                fzf --preview 'bat --color=always --style=plain {}' --preview-window=right:60%)
            [[ -n "$selected" ]] && nvim "$selected"
            ;;
        grep)
            if [[ -z "$2" ]]; then
                echo "Usage: memo grep <keyword>" >&2
                return 1
            fi
            local selected
            selected=$(rg --line-number --color=always "$2" "$MEMO_DIR" | \
                fzf --ansi --delimiter=: --preview 'bat --color=always --style=plain --highlight-line {2} {1}' --preview-window=right:60% | \
                cut -d: -f1)
            [[ -n "$selected" ]] && nvim "$selected"
            ;;
        dir)
            nvim "$MEMO_DIR"
            ;;
        "")
            local filepath="$MEMO_DIR/${today}.md"
            if [[ ! -f "$filepath" ]]; then
                _memo_create_with_template "$filepath" "$today"
            fi
            nvim "$filepath"
            ;;
        *)
            local title="$1"
            local filepath="$MEMO_DIR/${today}-${title}.md"
            if [[ ! -f "$filepath" ]]; then
                _memo_create_with_template "$filepath" "$today" "$title"
            fi
            nvim "$filepath"
            ;;
    esac
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
