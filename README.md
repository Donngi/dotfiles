# dotfiles

## Set up

### All in one
If you are in new macOS environment, execute all in one commnad.

```
make all-in-one
```

This command performs both `deploy` and `install` in correct order.

### Deploy
Create symbolic links of dotfiles to target directories.

```
make deploy-<application_name>
```

If you want to deploy all of applications, you can use `make deploy-all`.

### Install
Install applications or setup configs of them.

```
make init-<application_name>
```

If you want to install all of applications, you can use `make install-all`.

## Local values

Some dotfiles can additionally load local dotfiles in your `$HOME`.

| file               | purpose                                  |
| ------------------ | ---------------------------------------- |
| `.zlocal`          | zsh local config                         |
| `.gitconfig.local` | git local config like user name or email |

### Recommended settings
`.zlocal`

```
# Set directory where lima can get write permission.
export LIMA_WORKSPACE_DIRECTORY="YOUR_LIMA_PATH"
```

`.gitconfig.local`

```
[user]
	name = YOUR_NAME
	email = YOUR_EMAIL
[ghq]
    root = YOUR_GHQ_PATH
    
```

## Additional settings to be done manually
Some apps can't be set up completely only by scripts. 

### iTerm2
Specify config file path.

- Go `Settings` > `General` > `Preferences`
- Check `Load preferences from a custom folder or URL` and set path to `/Users/NAME/.dotconfig/iterm2`

### SF Mono Square
Add fonts to mac.

```
open "$(brew --prefix sfmono-square)/share/fonts"
```

[SF Mono Square](https://github.com/delphinus/homebrew-sfmono-square)

