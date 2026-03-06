DRAGOMAN ?= $(HOME)/src/dragoman/dragoman-gren.py
DRAGOMAN_DIR ?= ../dragoman
DRAGOMAN_FILES = $(shell find $(DRAGOMAN_DIR) -name "*.dgl")
SCSS_FILES = $(shell find sass -name "*.scss")
GREN_FILES = $(shell find src -name "*.gren")

build: public/Gren.js public/style.css

serve: public/style.css public/Gren.js
	npx serve public

public/Gren.js: $(GREN_FILES) $(DRAGOMAN_FILES)
	rm -rf src/Dragoman
	$(DRAGOMAN) $(DRAGOMAN_DIR)/main.dgl \
		--include $(DRAGOMAN_DIR) \
		--output-folder src/Dragoman/
	gren make Main --output=$@

public/style.css: $(SCSS_FILES)
	sass sass/main.scss > $@
