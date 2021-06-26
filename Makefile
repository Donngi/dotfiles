deploy:
	@$(foreach val, $(wildcard ./setup/deploy/deploy_home.sh), bash $(val);)

init:
	@$(foreach val, $(wildcard ./setup/init/*.sh), bash $(val);)
