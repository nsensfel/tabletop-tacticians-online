SCSS_FILES = $(shell find sass -name "*.scss")
GREN_FILES = $(shell find src -name "*.gren")

build: public/Gren.js public/style.css

serve: public/style.css public/Gren.js
	npx serve public

public/Gren.js: $(GREN_FILES)
	gren make Main --output=$@

public/style.css: $(SCSS_FILES)
	sass sass/main.scss > $@
