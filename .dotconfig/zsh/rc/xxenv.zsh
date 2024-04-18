# ------------------------------------------------------------------------
# xxenv
# ------------------------------------------------------------------------

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init - --no-rehash)"

# rbenv
eval "$(rbenv init - --no-rehash)"

# go
export GOPATH=$HOME/.go
export PATH=$GOPATH/bin:$PATH

# goの利用するバージョンを明示的に指定したい場合、
# https://go.dev/doc/manage-install を参考にインストールしたうえで、明示的にGOROOT
# export GOROOT=`go1.22.1 env GOROOT` 
# export PATH=$GOROOT/bin:$PATH

# nodebrew
export PATH=$PATH:$HOME/.nodebrew/current/bin
