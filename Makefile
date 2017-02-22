#THEME_URL=https://github.com/vimux/mainroad
THEME_URL=https://github.com/yoshiharuyamashita/blackburn.git
BASEURL=http://ericnode.info
BIND=45.56.87.74

.PHONY: serve install_theme test alter help
.DEFAULT_GOAL := help

serve: ## run server
	hugo server --watch --config config.toml -p 8080 -b ${BASEURL} --bind ${BIND}

install_theme: ## install theme
	cd themes && git clone ${THEME_URL}

test: ## run test
	hugo server --watch --config config.toml

alter: ## run alternative theme
	hugo server --watch --config mainroad.config.toml -p 1414

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
