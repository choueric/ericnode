THEME_URL=https://github.com/choueric/mainroad
THEME=mainroad

PREFIX=/usr/local
SYSTEMD_DIR=/lib/systemd/system

SA="`pwd`/scripts/serve.sh"
SERVICE=hugo.service
UPDATE_SERVICE=hugo-update.service
UPDATE_TIMER=hugo-update.timer
HUGO="$(PREFIX)/bin/hugo"
SITEDIR="`pwd`"
CONFIG=$(SITEDIR)/data/mainroad.config.toml
TEMP=$(PWD)/generated

.DEFAULT_GOAL := help

clone_theme: ##  clone web site's theme
	@cd themes && git clone ${THEME_URL}

install: ## install hugo, theme and service
	@./scripts/gen.sh
	@tar xfv static/hugo-joinLines-linux-amd64.tar.bz2 -C $(TEMP)
	@sudo install -v $(TEMP)/hugo $(PREFIX)/bin
	@sudo install -v $(TEMP)/$(SERVICE) $(SYSTEMD_DIR)
	@sudo install -v $(TEMP)/$(UPDATE_SERVICE) $(SYSTEMD_DIR)
	@sudo install -v $(SITEDIR)/scripts/$(UPDATE_TIMER) $(SYSTEMD_DIR)
	@sudo systemctl enable $(SERVICE)
	@sudo systemctl enable $(UPDATE_SERVICE)

uninstall: ## uninstall hugo and service
	@sudo systemctl stop $(UPDATE_SERVICE)
	@sudo systemctl stop $(SERVICE)
	@sudo systemctl disable $(UPDATE_SERVICE)
	@sudo systemctl disable $(SERVICE)
	@sudo rm -fv $(SYSTEMD_DIR)/$(SERVICE)
	@sudo rm -fv $(SYSTEMD_DIR)/$(UPDATE_SERVICE)
	@sudo rm -fv $(SYSTEMD_DIR)/$(UPDATE_TIMER)
	@sudo rm -fv $(PREFIX)/bin/hugo

start: ## start server
	@sudo systemctl start $(SERVICE)

status: ## show server status
	@systemctl status $(SERVICE)

stop: ## stop server
	@sudo systemctl stop $(SERVICE)

new: ## execute `hugo new` to add a new post
	@`pwd`/scripts/post.sh ${THEME} new 

local: ## run hugo as local server
	@$(HUGO) server -ws $(SITEDIR) --config $(CONFIG) --buildDrafts -b http://localhost

clean: ## clean temporate files
	@rm -rf $(TEMP)

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
