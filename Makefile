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
venv: ## Create the python virtual environment
	python3 -m pip install --upgrade --user virtualenv
	virtualenv --python=$(which python3) --always-copy ./.venv

.PHONY: setup
setup: venv ## Install all python requirements
	. ./.venv/bin/activate
	pip install -r requirements.txt

.PHONY: list
list: ## List all available targets
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

.PHONY: $(FINAL)
$(FINAL): $(FINAL).pdf ## Build the `final` PDF version

.PHONY: $(DRAFT)
$(DRAFT): $(DRAFT).pdf ## Build the `draft` PDF version

$(FINAL).pdf: $(FINAL).tex ## Create the FINAL version
	$(LATEXMK) $(LFLAGS) $<

$(FINAL).tex: $(DRAFT).tex ## Create the TeX document for the `final` PDF version
	git show $(git branch | grep "\*" | cut -d ' ' -f2):"$<" | python3 finalizer.py -- - > $(FINAL).tex

%.pdf: %.tex ## Create PDFs from existing TEX files
	$(LATEXMK) $(LFLAGS) $<

.PHONY: clean
clean: ## Clean directory from intermediate files
	$(LATEXMK) -c *.tex

.PHONY: distclean
distclean: clean ## Clean directory from all files
	$(LATEXMK) -C *.tex
	rm -f *.makefile
	rm -f $(FINAL).tex
	rm -f tikz/*
	rm -f *.bak
	rm -rf ./.venv
