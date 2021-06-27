# ------------------------------------------------------------------------
# zinitの推奨plugin
# ------------------------------------------------------------------------

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zinit-zsh/z-a-rust \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-bin-gem-node

# ------------------------------------------------------------------------
# Theme
# ------------------------------------------------------------------------

# pure
zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
zinit light Jimon-s/pure

zstyle :prompt:pure:execution_time color yellow
zstyle :prompt:pure:git:arrow color cyan
zstyle :prompt:pure:git:stash color 242
zstyle :prompt:pure:git:branch color 242
zstyle :prompt:pure:git:branch:cached color red
zstyle :prompt:pure:git:action color 242
zstyle :prompt:pure:git:dirty color 242
zstyle :prompt:pure:host color 242
zstyle :prompt:pure:path color yellow
zstyle :prompt:pure:prompt:error color red
zstyle :prompt:pure:prompt:success color magenta
zstyle :prompt:pure:prompt:continuation color 242
zstyle :prompt:pure:user color 242
zstyle :prompt:pure:user:root color default
zstyle :prompt:pure:virtualenv color 242
zstyle :prompt:pure:aws:envs color magenta

# ------------------------------------------------------------------------
# Prezto
# ------------------------------------------------------------------------

# zinit snippet PZT::modules/environment/init.zsh
# zinit snippet PZT::modules/terminal/init.zsh
# zinit snippet PZT::modules/editor/init.zsh
# zinit snippet PZT::modules/history/init.zsh
# zinit snippet PZT::modules/directory/init.zsh
# zinit snippet PZT::modules/spectrum/init.zsh
# zinit snippet PZT::modules/utility/init.zsh
zinit snippet PZT::modules/completion/init.zsh
