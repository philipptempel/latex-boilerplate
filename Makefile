# Set a default BASH shell
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

.PHONY: list
list: ## List all available targets
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

.PHONY: $(FINAL)
$(FINAL): $(FINAL).pdf ## Build the `final` PDF version

.PHONY: $(DRAFT)
$(DRAFT): $(DRAFT).pdf ## Build the `draft` PDF version

$(FINAL).tex: $(DRAFT).tex ## Create the TeX document for the `final` PDF version
	echo "%% This file is auto-generated" > $*.tex
	echo "%% Do not modify it unless you know what you are doing" >> $*.tex
	echo "\let\oldExecuteOptions\ExecuteOptions" >> $*.tex
	echo "\def\ExecuteOptions#1{\oldExecuteOptions{#1,final}}" >> $*.tex
	echo "\input{$<}" >> $*.tex

%.pdf: %.tex ## Create PDFs from existing TEX files
	$(LATEXMK) $(LFLAGS) $<
	cp "$@" "$*_$(shell git rev-parse --short HEAD).pdf"

.PHONY: clean
clean: ## Clean directory from intermediate files
	$(LATEXMK) -C $(DRAFT) $(FINAL)
	rm -f $(FINAL).tex

.PHONY: mostlyclean
mostlyclean: ## Like `clean` but not as clean
	$(LATEXMK) -c $(DRAFT) $(FINAL)

.PHONY: distclean
distclean: ## Clean directory from all files
	$(LATEXMK) -CA $(DRAFT) $(FINAL)
	rm -f $(DRAFT)_*.pdf
	rm -f $(FINAL)_*.pdf
	rm -f *.makefile
	rm -f tikz/*
	rm -f *.bak
