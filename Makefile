# Set a default BASh shell
SHELL = /usr/bin/env bash

# Set up a default goal
.DEFAULT_GOAL = list

# Name of the final document
FINAL = final
# Name of the draft document
DRAFT = draft

# Latexmk compiler
LATEXMK = latexmk
# Latexmk options
LFLAGS := 

define PRINT_HELP_PYSCRIPT
import re, sys

ts = {}
for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		t, h = match.groups()
		ts[t] = h

for t in sorted(ts):
  print("  %-20s %s" % (t, ts[t]))
endef
export PRINT_HELP_PYSCRIPT

.PHONY: all
all: $(DRAFT) $(FINAL) ## Make all files

.PHONY: venv
venv:  ## Create the python virtual environment
	python3 -m pip install --upgrade virtualenv
	virtualenv --python=$(which python3) --always-copy ./.venv

.PHONY: setup
setup: SHELL = ./pythonsh
setup: venv ## Install all python requirements
	python -m pip install --upgrade pip;
	pip install --upgrade -r requirements.txt;

.PHONY: list
list: ## List all available targets
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

.PHONY: $(FINAL)
$(FINAL): SHELL = ./pythonsh
$(FINAL): $(FINAL).pdf ## Build the `final` PDF version

.PHONY: $(DRAFT)
$(DRAFT): SHELL = ./pythonsh
$(DRAFT): $(DRAFT).pdf ## Build the `draft` PDF version

$(FINAL).tex: SHELL = ./pythonsh
$(FINAL).tex: $(DRAFT).tex ## Create the TeX document for the `final` PDF version
	git show $(git branch | grep "\*" | cut -d ' ' -f2):"$<" | python3 finalizer.py -- - > $(FINAL).tex

%.pdf: SHELL = ./pythonsh
%.pdf: %.tex ## Create PDFs from existing TEX files
	$(LATEXMK) $(LFLAGS) $<
	cp "$@" "$*_$(shell git rev-parse --short HEAD).pdf"

.PHONY: clean
clean: mostlyclean ## Clean directory from intermediate files
	$(LATEXMK) -C *.tex
	rm -f $(FINAL).tex

.PHONY: mostlyclean
mostlyclean: ## Like `clean` but not as clean
	$(LATEXMK) -c *.tex

.PHONY: distclean
distclean: clean ## Clean directory from all files
	rm -f *.makefile
	rm -f tikz/*
	rm -f *.bak
	rm -rf ./.venv
