# Global

.PHONY: deps
deps:
	cd hatgame && flutter pub get
	uv sync

.PHONY: update-git-version
update-git-version:
	uv run tools/update_git_version.py

.PHONY: init-repo
init-repo:
	make deps
	make update-git-version
	dart run build_runner build

.PHONY: deploy-web
deploy-web:
	make update-git-version
	cd hatgame && flutter build web
	firebase deploy

.PHONY: check-all
check-all:
	make lint-python
	make lint-flutter
	make test-python
	make test-flutter

# Flutter

.PHONY: lint-flutter
lint-flutter:
	cd hatgame && dart format -o none --set-exit-if-changed .
	cd hatgame && flutter analyze

.PHONY: fix-flutter
fix-flutter:
	cd hatgame && dart format .
	cd hatgame && dart fix --apply

.PHONY: test-flutter
test-flutter:
	cd hatgame && flutter test

# Python

.PHONY: lint-python
lint-python:
	uv run ruff check tools
	uv run ruff format --check tools
	uv run pyright

.PHONY: fix-python
fix-python:
	uv run ruff check --fix tools
	uv run ruff format tools
	uv run pyright

.PHONY: fix-python-unsafe
fix-python-unsafe:
	uv run ruff check --fix --unsafe-fixes tools
	uv run ruff format tools
	uv run pyright

.PHONY: test-python
test-python:
	uv run pytest tools
