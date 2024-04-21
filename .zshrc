# CodeWhisperer pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.pre.zsh"

# ------------------------------------------------------------------------
# appearance
# ------------------------------------------------------------------------

source $ZSHRC_DIR/appearance.zsh

# ------------------------------------------------------------------------
# completion
# ------------------------------------------------------------------------

source $ZSHRC_DIR/completion.zsh

# ------------------------------------------------------------------------
# alias
# ------------------------------------------------------------------------

source $ZSHRC_DIR/alias.zsh

# ------------------------------------------------------------------------
# bindkey
# ------------------------------------------------------------------------

source $ZSHRC_DIR/bindkey.zsh

# ------------------------------------------------------------------------
# wordstyle
# ------------------------------------------------------------------------

source $ZSHRC_DIR/wordstyle.zsh

# ------------------------------------------------------------------------
# history
# ------------------------------------------------------------------------

source $ZSHRC_DIR/history.zsh

# ------------------------------------------------------------------------
# xxenv
# ------------------------------------------------------------------------

source $ZSHRC_DIR/xxenv.zsh

# ------------------------------------------------------------------------
# wsl
# ------------------------------------------------------------------------
if [[ `uname -a` == *"microsoft"* && `uname -s` == "Linux"* ]]; then 
    source $ZSHRC_DIR/wsl.zsh
fi

# ------------------------------------------------------------------------
# Other
# ファイル単位で切り出すと、1行のみになってしまう場合のみここに記載
# ------------------------------------------------------------------------



# ------------------------------------------------------------------------
# local config
# ------------------------------------------------------------------------

if [ -e $ZDOTDIR/.zlocal ]; then
    source $ZDOTDIR/.zlocal
fi

# ------------------------------------------------------------------------
# スピード測定用
# .zshenv先頭のコマンドと共に使う
# ------------------------------------------------------------------------

# if (which zprof > /dev/null 2>&1) ;then
#   zprof
# fi

# CodeWhisperer post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zshrc.post.zsh"
