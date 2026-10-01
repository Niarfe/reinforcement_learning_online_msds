default:
	@cat makefile

env:
	python3 -m venv env; . env/bin/activate; pip install --upgrade pip

update: env
	. env/bin/activate; pip install -r requirements.txt -r requirements-dev.txt

tools: env
	. env/bin/activate; pip install -r requirements-dev.txt

# Syntax errors and undefined names only, so student "fill-in" slots do not fail the build
lint:
	. env/bin/activate; ruff check --select E9,F63,F7,F82 --output-format github .

# Spell check markdown, text, and notebooks (base64 image blobs are ignored)
spell:
	. env/bin/activate; codespell --skip="CI_REVIEW.md,*.pdf,*.ppt,*.docx,*.png,*.jpg,./env,./.git" --ignore-regex="[A-Za-z0-9+/=]{40,}" -L ans .

test:
	. env/bin/activate; pytest -vv tests
