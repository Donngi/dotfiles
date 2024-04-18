# ------------------------------------------------------------------------
# Reset 
# ------------------------------------------------------------------------

# Reset to default keybind
bindkey -d

# ------------------------------------------------------------------------
# macOS basis
# ------------------------------------------------------------------------

# Enable Emacs keybind
bindkey -e

# Enable fn + delete key
bindkey "^[[3~" delete-char

# ------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------

# pecoと組み合わせて、QUERYを有効化
# https://qiita.com/shepabashi/items/f2bc2be37a31df49bca5
function peco-history-selection() {
  if command -v tac >/dev/null 2>&1; then
    # tacコマンドの利用が可能な場合 (主にLinux)
    BUFFER=`history -n 1 | tac  | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
  elif tail --help 2>&1 | grep -q "\-r"; then
    # tacがなく、tailに-rオプションがある場合（主にmacOS）
    BUFFER=`history | tail -r | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
  else
    echo "Neither tac nor tail -r are available in this environment."
    exit 1
  fi
}
zle -N peco-history-selection
bindkey '^R' peco-history-selection

# ------------------------------------------------------------------------
# cdr
# ------------------------------------------------------------------------

# pecoと組み合わせて、QUERYを有効化
# https://qiita.com/sukebeeeeei/items/9b815e56a173a281f42f
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi
function peco-get-destination-from-cdr() {
  cdr -l | \
  sed -e 's/^[[:digit:]]*[[:blank:]]*//' | \
  peco --query "$LBUFFER"
}
function peco-cdr() {
  local destination="$(peco-get-destination-from-cdr)"
  if [ -n "$destination" ]; then
    BUFFER="cd $destination"
    zle accept-line
  else
    zle reset-prompt
  fi
}
zle -N peco-cdr
bindkey '^U' peco-cdr

# ------------------------------------------------------------------------
# ghq
# ------------------------------------------------------------------------

# pecoと組み合わせて、QUERYを有効化
function peco-ghq () {
  local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-ghq
bindkey '^G^G' peco-ghq

# pecoで選択して、vscodeで開く
function peco-ghq-vscode () {
  local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="code ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-ghq-vscode
bindkey '^G^F' peco-ghq-vscode


# ------------------------------------------------------------------------
# 自分のGitHub Repositoryをクエリして開く
# ------------------------------------------------------------------------

function open-my-repos() {
  local selected_repo=$(curl -s https://api.github.com/users/donngi/repos | jq -r ".[].full_name" | peco )
  if [ -n "$selected_repo" ]; then
    BUFFER="open https://github.com/${selected_repo}"
    echo $BUFFER
    zle accept-line
  fi
  zle clear-screen
}
zle -N open-my-repos
bindkey '^J^I' open-my-repos
