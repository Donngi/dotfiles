# homebrew
if [[ `uname -m` == 'arm64' ]]; then
    # Only run M1 Mac.  
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
