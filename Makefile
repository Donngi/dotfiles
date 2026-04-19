# ----------------------------------------------------------------------------
# macOS
# ----------------------------------------------------------------------------

### deploy
mac-os-deploy-all:
	@$(foreach val, $(wildcard ./setup/mac_os/deploy/deploy_*.sh), bash $(val);)

mac-os-deploy-home:
	bash ./setup/mac_os/deploy/deploy_home.sh

mac-os-deploy-idea:
	bash ./setup/mac_os/deploy/deploy_idea.sh

mac-os-deploy-vscode:
	bash ./setup/mac_os/deploy/deploy_vscode.sh

mac-os-deploy-nvim:
	bash ./setup/mac_os/deploy/deploy_nvim.sh

mac-os-deploy-claude:
	bash ./setup/mac_os/deploy/deploy_claude.sh

mac-os-deploy-ghostty:
	bash ./setup/mac_os/deploy/deploy_ghostty.sh

mac-os-deploy-npm:
	bash ./setup/mac_os/deploy/deploy_npm.sh

mac-os-deploy-uv:
	bash ./setup/mac_os/deploy/deploy_uv.sh

### init
mac-os-init-all:
	@$(foreach val, $(wildcard ./setup/mac_os/init/*.sh), bash $(val);)

mac-os-init-brew:
	bash ./setup/mac_os/init/init_homebrew.sh

mac-os-init-node:
	bash ./setup/mac_os/init/init_node.sh
	
mac-os-init-vim-plugins:
	bash ./setup/mac_os/init/init_vim_plugins.sh


# ----------------------------------------------------------------------------
# macOS
# ----------------------------------------------------------------------------

### deploy
wsl-deploy-all:
	@$(foreach val, $(wildcard ./setup/wsl/deploy/deploy_*.sh), bash $(val);)

wsl-deploy-home:
	bash ./setup/wsl/deploy/deploy_home.sh

wsl-deploy-wsl-conf:
	bash ./setup/wsl/deploy/deploy_wsl_conf.sh

### init
wsl-init-all:
	@$(foreach val, $(wildcard ./setup/wsl/init/*.sh), bash $(val);)

wsl-init-build-essential:
	bash ./setup/wsl/init/init_build_essential.sh

wsl-init-ca-certificates:
	bash ./setup/wsl/init/init_ca_certificates.sh

wsl-init-default-shell:
	bash ./setup/wsl/init/init_default_shell.sh

wsl-init-docker:
	bash ./setup/wsl/init/init_docker.sh

wsl-init-brew:
	bash ./setup/wsl/init/init_homebrew.sh
	
wsl-init-node:
	bash ./setup/wsl/init/init_node.sh


# ----------------------------------------------------------------------------
# Lint / Format
# ----------------------------------------------------------------------------

### fmt: フォーマット適用 (書き込みあり)
fmt: fmt-lua fmt-sh fmt-json

fmt-lua:
	stylua .

fmt-sh:
	shfmt -w setup/ setup.sh

fmt-json:
	biome format --write

### fmt-check: フォーマットチェック (書き込みなし)
fmt-check: fmt-check-lua fmt-check-sh fmt-check-json

fmt-check-lua:
	stylua --check .

fmt-check-sh:
	shfmt -d setup/ setup.sh

fmt-check-json:
	biome format

### lint: リンター実行
lint: lint-sh lint-json

lint-sh:
	shfmt -f setup/ setup.sh | xargs shellcheck

lint-json:
	biome lint

### check: lint + fmt-check (統合)
check: lint fmt-check
