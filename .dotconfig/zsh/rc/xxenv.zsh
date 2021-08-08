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
export GOENV_ROOT=$HOME/.goenv
export PATH=$GOENV_ROOT/bin:$PATH
eval "$(goenv init - --no-rehash)"
export PATH=$GOPATH/bin:$PATH

# nodebrew
export PATH=$PATH:$HOME/.nodebrew/current/bin
