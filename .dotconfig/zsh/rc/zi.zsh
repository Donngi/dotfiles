if [[ ! -d $HOME/.zi ]]; then
    echo 'zi has not been installed.'
else
    source "$HOME/.zi/bin/zi.zsh"
    autoload -Uz _zi
    (( ${+_comps} )) && _comps[zi]=_zi
fi
