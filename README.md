# dotfiles

## Set up

### Deploy

dotfiles のシンボリックリンクを`$HOME`に作成。

```
make deploy
```

_NOTE_ VSCode etc ... の特定のアプリケーションがインストールされているときだけ Deploy したいものは、`make`では読み込まないように設定しているため、手動で実行する。

### Install

TBD

## Local values

Some dotfiles can load local dotfiles in your local $HOME additionally.

| file               | purpose                                  |
| ------------------ | ---------------------------------------- |
| `.zlocal`          | zsh local config                         |
| `.gitconfig.local` | git local config like user name or email |
