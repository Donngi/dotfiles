# https://gist.github.com/mollifier/4331a4db00a5555582e4
# 単語の区切り文字を拡張
autoload -Uz select-word-style
select-word-style default 
zstyle ':zle:*' word-chars ' /=;@:{}[]()<>,|.'
zstyle ':zle:*' word-style unspecified
