#!/bin/sh

script_dir=$(cd $(dirname $0); pwd)

target="Docker environment with lima"
deploy_dir="$HOME/.lima"
source_dir="$ZDOTDIR/.dotconfig/lima"
files="docker_template.yml"
source "$script_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"

# 環境変数:LIMA_WORKSPACE_DIRECTORY が未設定の場合、ERRORとなるため、ダミーの値を暫定で入れる
if [[ -z "${LIMA_WORKSPACE_DIRECTORY}" ]]; then
    export LIMA_WORKSPACE_DIRECTORY="$HOME/.lima"
fi

# limaのmount pointは絶対パス指定限定で、環境変数からの読み込みはできないため、やむなく置換する
sed -e "s|__LIMA_WORKSPACE_DIRECTORY__|${LIMA_WORKSPACE_DIRECTORY}|" "$HOME/.lima/docker_template.yml" > "$HOME/.lima/docker.yml"

limactl start ${HOME}/.lima/docker.yml
sudo ln -sf ~/.lima/docker/sock/docker.sock /var/run/docker.sock