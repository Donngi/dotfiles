#!/bin/sh

# https://zenn.dev/matsukaz/articles/31bc31ff1c54b4
# 上記記事中では、macOSのfile descriptorsのデフォルト値=256とあったが、
# M1 Macではデフォルト10496となっていたため、初期値のままで利用することとした
#
# script_dir=$(cd $(dirname $0); pwd)
# 
# sudo ln -s "${script_dir}/lima_docker_limit.plist" /Library/LaunchDaemons/limit.maxfiles2.plist
# sudo chown root /Library/LaunchDaemons/limit.maxfiles2.plist
# sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles2.plist

if [ ! -d $HOME/.lima ]; then
  echo "$HOME/.lima not found. Start to initialize lima."
  mkdir $HOME/.lima
fi
