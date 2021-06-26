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
export PATH=$GOPATH/bin:$PATH
autoload -U compinit; compinit
eval "$(goenv init - --no-rehash)"