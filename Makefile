deploy:
	@$(foreach val, $(wildcard ./setup/deploy/*.sh), bash $(val);)

