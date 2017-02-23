#THEME_URL=https://github.com/vimux/mainroad
#THEME_URL=https://github.com/yoshiharuyamashita/blackburn.git
THEME_URL=https://github.com/choueric/mainroad

THEME=mainroad
ALTER_THEME=blackburn

.PHONY: serve install_theme test alter help
.DEFAULT_GOAL := help

serve: ## run server
	`pwd`/scripts/serve.sh

test: ## run test
	`pwd`/scripts/serve.sh test

alter: ## run alternative theme
	hugo server --watch --config data/${ALTER_THEME}.config.toml \
		-p 1414 --buildDrafts -b http://localhost

install_theme: ## install theme
	cd themes && git clone ${THEME_URL}

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
