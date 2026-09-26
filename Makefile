-include .env
export

.PHONY: help preview render post check hooks

help:  ## List targets
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | sed -E 's/:.*## /\t/'

preview:  ## Live preview in the browser
	quarto preview

render:  ## Render the site and refresh _freeze/
	quarto render

post:  ## New draft post: make post TITLE="Lyapunov functions"
	@test -n "$$TITLE" || { echo 'usage: make post TITLE="Post title"'; exit 1; }
	@scripts/new-post.sh "$$TITLE"

check:  ## Fail if any _freeze/ output is stale
	@python3 scripts/check-freeze.py

hooks:  ## Use the repo git hooks (run once after git init)
	git config core.hooksPath .githooks
