# dotfiles

## Set up

### Deploy
dotfiles のシンボリックリンクを`$HOME`に作成。

```
make deploy-all
```

_NOTE_ `make deploy-all`は、VSCodeやIdeaのDeployもまとめて実施する仕様。 特定のアプリケーションがインストールされているときだけDeployしたいetc の事情で、個別にDeploy したい場合は、`make deploy-home` のみ実行して、手動で `setup/deploy` 配下の残りのScriptを起動する。

### Install
Applicationのインストールや初期設定。

```
make init-all
```

## Local values

Some dotfiles can load local dotfiles in your local $HOME additionally.

| file               | purpose                                  |
| ------------------ | ---------------------------------------- |
| `.zlocal`          | zsh local config                         |
| `.gitconfig.local` | git local config like user name or email |
