# Set up a default goal
.DEFAULT_GOAL = list

# Name of the final document
FINAL = final
# Name of the draft document
DRAFT = draft

# Latexmk compiler
LATEXMK = latexmk
# Latexmk options
LFLAGS := -recorder -use-make -deps \
					-e 'warn qq(In Makefile, turn off custom dependencies\n);' \
					-e '@cus_dep_list = ();' \
					-e 'show_cus_dep();' \
					-pdflatex='lualatex --shell-escape --synctex=1 %O %S' \
					$(LFLAGS)
# Where to store dependencies as found by LATEXMK
DEPS_DIR = .deps
# All dependencies lists files
DEPS_FILES = $(wildcard $(DEPS_DIR)/*.deps)
# Load all dependencies
$(foreach file,$(DEPS_FILES),$(eval -include $(file)))

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
all: $(DRAFT).pdf $(FINAL).pdf ## Make all files

.PHONY: list
list: ## List all available targets
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

$(FINAL).pdf: $(FINAL).tex | $(DEPS_DIR) ## Create the FINAL version
	$(LATEXMK) -deps-out=$(DEPS_DIR)/$(FINAL).deps $(LFLAGS) $<

$(FINAL).tex: $(DRAFT).tex ## Create the document for the FINAL version
	cp $< $@
	sed -i.bak s/draft,//g $@

%.pdf: %.tex | $(DEPS_DIR) ## Create PDFs from existing TEX files
	$(LATEXMK) -deps-out=$(DEPS_DIR)/$*.deps $(LFLAGS) $<

$(DEPS_DIR): ## Create dependencies directory
	@mkdir -p $@

.PHONY: clean
clean: ## Clean directory from intermediate files
	$(LATEXMK) -C *.tex
	rm -f $(DEPS_DIR)/*

.PHONY: distclean
distclean: clean ## Clean directory from all files
	$(LATEXMK) -CA *.tex
	rm -f *.makefile
	rm -f $(FINAL).tex
	rm -f tikz/*
	rm -f *.bak
