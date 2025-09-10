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
