####################################################################################################
# Configuration
####################################################################################################

include .env
export

# Build configuration

BUILD = build
MAKEFILE = Makefile
OUTPUT_FILENAME = book
METADATA = metadata.yml
CHAPTERS = md/*.md
TOC = --toc --toc-depth 2
METADATA_ARGS = --metadata-file $(METADATA)
IMAGES = $(shell find images -type f)
TEMPLATES = $(shell find templates/ -type f)
COVER_IMAGE = images/image.png
MATH_FORMULAS = --webtex

# Chapters content
CONTENT = awk 'FNR==1 && NR!=1 {print "\n\n"}{print}' $(CHAPTERS)
CONTENT_FILTERS = tee # Use this to add sed filters or other piped commands

# Pages to blank

# === Configuration ===
BOOK_PDF := build/pdf/book.pdf
EMPTY_PDF := build/empty.pdf
MODIFIED_PDF := build/pdf/bookww.pdf

# List of page numbers to replace with blank pages
REPLACE_PAGES := 

# === Internal Variables ===
define GEN_PAGE_ARGS
$(shell \
  total_pages=$$(qpdf --show-npages $(BOOK_PDF)); \
  pages=""; \
  last=0; \
  for p in $(REPLACE_PAGES); do \
    before=$$((p - 1)); \
    if [ $$before -gt $$last ]; then \
      pages="$$pages . $$((last+1))-$$before"; \
    fi; \
    pages="$$pages $(EMPTY_PDF) 1"; \
    last=$$p; \
  done; \
  if [ $$last -lt $$total_pages ]; then \
    pages="$$pages . $$((last+1))-z"; \
  fi; \
  echo $$pages \
)
endef

# Debugging

# DEBUG_ARGS = --verbose

# Pandoc filtes - uncomment the following variable to enable cross references filter. For more
# information, check the "Cross references" section on the README.md file.

# FILTER_ARGS = --filter pandoc-crossref

# Combined arguments

ARGS = $(TOC) $(MATH_FORMULAS) $(METADATA_ARGS) $(FILTER_ARGS) $(DEBUG_ARGS)
	
PANDOC_COMMAND = pandoc

# Per-format options

DOCX_ARGS = --standalone --reference-doc templates/docx.docx
EPUB_ARGS = --template templates/epub.html --epub-cover-image $(COVER_IMAGE)
HTML_ARGS = --template templates/html.html --standalone --to html5
PDF_ARGS = --pdf-engine xelatex # --lua-filter=remove-footnotes.lua
# 	--template templates/pdf.latex


# Per-format file dependencies

BASE_DEPENDENCIES = $(MAKEFILE) $(CHAPTERS) $(METADATA) $(IMAGES) $(TEMPLATES)
DOCX_DEPENDENCIES = $(BASE_DEPENDENCIES)
EPUB_DEPENDENCIES = $(BASE_DEPENDENCIES)
HTML_DEPENDENCIES = $(BASE_DEPENDENCIES)
PDF_DEPENDENCIES = $(BASE_DEPENDENCIES)

# Detected Operating System

OS = $(shell sh -c 'uname -s 2>/dev/null || echo Unknown')

# OS specific commands

ifeq ($(OS),Darwin) # Mac OS X
	COPY_CMD = cp -P
else # Linux
	COPY_CMD = cp --parent
endif

MKDIR_CMD = mkdir -p
RMDIR_CMD = rm -r
ECHO_BUILDING = @echo "building $@...\n\n"
ECHO_BUILT = @echo "$@ was built\n\n"
RENAME_CHAPTERS = rename -f 's/ /_/g' md/*
GET_EP = latexmk -pdf -outdir=$(BUILD) -quiet templates/empty.tex && latexmk -c -outdir=$(BUILD) templates/empty.tex

####################################################################################################
# Basic actions
####################################################################################################

.PHONY: all book clean replace emptypage epub html pdf docx

all:	book

book:	epub html pdf docx replace

clean:
	$(RMDIR_CMD) $(BUILD)

emptypage:
	$(GET_EP)

replace: emptypage $(BOOK_PDF)
	@echo "🔍 Reading total page count from $(BOOK_PDF)..."
	@total_pages=$$(qpdf --show-npages $(BOOK_PDF)); \
	echo "📘 Total pages: $$total_pages"; \
	echo "🧩 Replacing pages: $(REPLACE_PAGES)"; \
	\
	pages=""; \
	last=0; \
	for p in $(REPLACE_PAGES); do \
	  before=$$((p - 1)); \
	  if [ $$before -gt $$last ]; then \
	    pages="$$pages . $$((last+1))-$$before"; \
	  fi; \
	  pages="$$pages $(EMPTY_PDF) 1"; \
	  last=$$p; \
	done; \
	if [ $$last -lt $$total_pages ]; then \
	  pages="$$pages . $$((last+1))-z"; \
	fi; \
	\
	echo "⚙️  Running qpdf with assembled page arguments:"; \
	echo "   $$pages"; \
	qpdf $(BOOK_PDF) --pages $$pages -- $(MODIFIED_PDF); \
	echo "✅ Created $(MODIFIED_PDF) (replaced pages: $(REPLACE_PAGES))"

####################################################################################################
# File builders
####################################################################################################

epub:	$(BUILD)/epub/$(OUTPUT_FILENAME).epub

html:	$(BUILD)/html/$(OUTPUT_FILENAME).html

pdf:	$(BUILD)/pdf/$(OUTPUT_FILENAME).pdf replace

docx:	$(BUILD)/docx/$(OUTPUT_FILENAME).docx

$(BUILD)/epub/$(OUTPUT_FILENAME).epub:	$(EPUB_DEPENDENCIES)
	$(ECHO_BUILDING)
	$(MKDIR_CMD) $(BUILD)/epub
	$(CONTENT) | $(CONTENT_FILTERS) | $(PANDOC_COMMAND) $(ARGS) $(EPUB_ARGS) -o $@
	$(ECHO_BUILT)

$(BUILD)/html/$(OUTPUT_FILENAME).html:	$(HTML_DEPENDENCIES)
	$(ECHO_BUILDING)
	$(MKDIR_CMD) $(BUILD)/html
	$(CONTENT) | $(CONTENT_FILTERS) | $(PANDOC_COMMAND) $(ARGS) $(HTML_ARGS) -o $@
	$(COPY_CMD) $(IMAGES) $(BUILD)/html/
	$(ECHO_BUILT)

$(BUILD)/pdf/$(OUTPUT_FILENAME).pdf:	$(PDF_DEPENDENCIES)
	$(ECHO_BUILDING)
	$(MKDIR_CMD) $(BUILD)/pdf
	$(CONTENT) | $(CONTENT_FILTERS) | $(PANDOC_COMMAND) $(ARGS) $(PDF_ARGS) -o $@
	$(ECHO_BUILT)

$(BUILD)/docx/$(OUTPUT_FILENAME).docx:	$(DOCX_DEPENDENCIES)
	$(ECHO_BUILDING)
	$(MKDIR_CMD) $(BUILD)/docx
	$(CONTENT) | $(CONTENT_FILTERS) | $(PANDOC_COMMAND) $(ARGS) $(DOCX_ARGS) -o $@
	$(ECHO_BUILT)