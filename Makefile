all-in-one: deploy-home init-brew init-all deploy-all

deploy-all:
	@$(foreach val, $(wildcard ./setup/deploy/deploy_*.sh), bash $(val);)

deploy-home:
	bash ./setup/deploy/deploy_home.sh

deploy-idea:
	bash ./setup/deploy/deploy_idea.sh

deploy-vscode:
	bash ./setup/deploy/deploy_vscode.sh

deploy-nvim:
	bash ./setup/deploy/deploy_nvim.sh

init-all:
	@$(foreach val, $(wildcard ./setup/init/*.sh), bash $(val);)

init-brew:
	bash ./setup/init/init_homebrew.sh

init-node:
	bash ./setup/init/init_node.sh
	
init-vim-plugins:
	bash ./setup/init/init_vim_plugins.sh

init-custom-pure:
	bash ./setup/init/init_custom_pure.sh
	