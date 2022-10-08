# スピード測定用
# .zshrc末尾のコマンドと共に使う
# zmodload zsh/zprof && zprof

# zsh
export ZDOTDIR=$HOME
export ZSHRC_DIR=$ZDOTDIR/.dotconfig/zsh/rc

# history
export HISTSIZE=10000
export SAVEHIST=10000

# bat
export BAT_CONFIG_PATH=$ZDOTDIR/.dotconfig/bat/bat.conf

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
