deploy-all:
	@$(foreach val, $(wildcard ./setup/deploy/*.sh), bash $(val);)

deploy-home:
	@$(foreach val, $(wildcard ./setup/deploy/deploy_home.sh), bash $(val);)

init-all:
	@$(foreach val, $(wildcard ./setup/init/*.sh), bash $(val);)

init-brew:
	@$(foreach val, $(wildcard ./setup/init/init_homebrew.sh), bash $(val);)
	