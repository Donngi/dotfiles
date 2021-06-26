deploy:
	@$(foreach val, $(wildcard ./setup/deploy/*.sh), bash $(val);)

init:
	@$(foreach val, $(wildcard ./setup/init/*.sh), bash $(val);)
	