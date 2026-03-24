# OSC 7: カレントディレクトリをターミナルに通知する
# タブ/ペイン分割時の CWD 継承に必要
_osc7_chpwd() {
    printf '\e]7;file://%s%s\e\\' "${HOST}" "${PWD}"
}

if [[ -z "${chpwd_functions[(r)_osc7_chpwd]}" ]]; then
    chpwd_functions+=(_osc7_chpwd)
fi
