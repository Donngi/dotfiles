all-in-one: deploy-home init-brew init-all deploy-all

deploy-all:
	@$(foreach val, $(wildcard ./setup/deploy/deploy_*.sh), bash $(val);)

deploy-home:
	bash ./setup/deploy/deploy_home.sh

deploy-idea:
	bash ./setup/deploy/deploy_idea.sh

deploy-vscode:
	bash ./setup/deploy/deploy_vscode.sh

deploy-lima-docker:
	bash ./setup/deploy/deploy_lima_docker.sh

init-all:
	@$(foreach val, $(wildcard ./setup/init/*.sh), bash $(val);)

init-brew:
	bash ./setup/init/init_homebrew.sh

init-lima-docker:
	bash ./setup/init/init_lima_docker.sh
	