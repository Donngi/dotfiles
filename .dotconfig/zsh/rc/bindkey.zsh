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

# fzfと組み合わせて、QUERYを有効化
# https://qiita.com/shepabashi/items/f2bc2be37a31df49bca5
function fzf-history-selection() {
  if command -v tac >/dev/null 2>&1; then
    # tacコマンドの利用が可能な場合 (主にLinux)
    BUFFER=$(history -n 1 | tac | awk '!a[$0]++' | fzf --height 60% --reverse)
    CURSOR=$#BUFFER
    zle reset-prompt
  elif tail --help 2>&1 | grep -q "\-r"; then
    # tacがなく、tailに-rオプションがある場合（主にmacOS）
    BUFFER=$(history -n 1 | tail -r | awk '!a[$0]++' | fzf --height 60% --reverse)
    CURSOR=$#BUFFER
    zle reset-prompt
  else
    echo "Neither tac nor tail -r are available in this environment."
    return 1
  fi
}
zle -N fzf-history-selection
bindkey '^R' fzf-history-selection

# ------------------------------------------------------------------------
# cdr
# ------------------------------------------------------------------------

# fzfと組み合わせて、QUERYを有効化
# https://qiita.com/sukebeeeeei/items/9b815e56a173a281f42f
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi
function fzf-get-destination-from-cdr() {
  cdr -l | \
  sed -e 's/^[[:digit:]]*[[:blank:]]*//' | \
  fzf --height 60% --reverse --query "$LBUFFER"
}
function fzf-cdr() {
  local destination="$(fzf-get-destination-from-cdr)"
  if [ -n "$destination" ]; then
    BUFFER="cd $destination"
    zle accept-line
  else
    zle reset-prompt
  fi
}
zle -N fzf-cdr
bindkey '^U' fzf-cdr

# ------------------------------------------------------------------------
# ghq
# ------------------------------------------------------------------------

# fzfと組み合わせて、QUERYを有効化
function fzf-ghq () {
  local selected_dir=$(ghq list -p | fzf --height 60% --reverse --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-ghq
bindkey '^G^G' fzf-ghq

# fzfで選択して、vscodeで開く
function fzf-ghq-vscode () {
  local selected_dir=$(ghq list -p | fzf --height 60% --reverse --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="code ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-ghq-vscode
bindkey '^G^F' fzf-ghq-vscode

# fzfで選択して、neovimで開く（nvim-treeも表示）
function fzf-ghq-nvim () {
  local selected_dir=$(ghq list -p | fzf --height 60% --reverse --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="nvim ${selected_dir} -c \"lua require('nvim-tree.api').tree.toggle()\""
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-ghq-nvim
bindkey '^G^V' fzf-ghq-nvim


# ------------------------------------------------------------------------
# 自分のGitHub Repositoryをクエリして開く
# ------------------------------------------------------------------------

function open-my-repos() {
  local page=1
  local all_repos=""
  while true; do
    local repos=$(curl -s "https://api.github.com/users/donngi/repos?per_page=100&page=${page}" | jq -r ".[].full_name")
    [[ -z "$repos" ]] && break
    all_repos+="${repos}"$'\n'
    ((page++))
  done
  local selected_repo=$(echo "$all_repos" | fzf --height 60% --reverse)
  if [ -n "$selected_repo" ]; then
    BUFFER="open https://github.com/${selected_repo}"
    echo $BUFFER
    zle accept-line
  fi
  zle clear-screen
}
zle -N open-my-repos
bindkey '^G^R' open-my-repos
