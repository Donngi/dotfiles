# CodeWhisperer pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zprofile.pre.zsh"

### homebrew

# Apple silicon mac
if [[ `uname -m` == 'arm64' ]]; then 
    eval "$(/opt/homebrew/bin/brew shellenv)"
# WSL
elif [[ `uname -a` == *"microsoft"* && `uname -s` == "Linux"* ]]; then 
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# CodeWhisperer post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zprofile.post.zsh"
