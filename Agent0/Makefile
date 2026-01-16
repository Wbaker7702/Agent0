.PHONY: lint audit build

lint:
	python -m ruff check .
	python -m mypy .

audit:
	python -m pip-audit
	python -m pip-licenses --format=markdown

build:
	python -m pip install -r requirements.txt --dry-run
