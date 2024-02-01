# ------------------------------------------------------------------------
# Theme
# ------------------------------------------------------------------------

# pure
zi ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
zi light Donngi/pure

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
# Others
# ------------------------------------------------------------------------

# ls時のcolor
# no: global default
# fi: normal file
# di: directory
# ln: symbolic link
# pi: named pipe
# so: socket
# do: door
# bd: block device
# cd: character device
# or: orphan symlink
# mi: missing file
# su: set uid
# sg: set gid
# tw: sticky other writable
# ow: other writable
# st: sticky
# ex: executable
# 違和感なかったため、Preztoのdefault設定そのままを転記
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01:su=31;40;07:sg=36;40;07:tw=32;40;07:ow=33;40;07:'
