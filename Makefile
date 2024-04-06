# ----------------------------------------------------------------------------
# macOS
# ----------------------------------------------------------------------------
mac-os-all-in-one: deploy-home init-brew init-all deploy-all

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

### init
mac-os-init-all:
	@$(foreach val, $(wildcard ./setup/mac_os/init/*.sh), bash $(val);)

mac-os-init-brew:
	bash ./setup/mac_os/init/init_homebrew.sh

mac-os-init-node:
	bash ./setup/mac_os/init/init_node.sh
	
mac-os-init-vim-plugins:
	bash ./setup/mac_os/init/init_vim_plugins.sh

mac-os-init-custom-pure:
	bash ./setup/mac_os/init/init_custom_pure.sh

