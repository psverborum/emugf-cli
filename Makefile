PREFIX := /usr/local

all: install

install:
	bundle install
	cp emugf-cli.rb $(DESTDIR)$(PREFIX)/bin/emugf-cli
	chmod 0755 $(DESTDIR)$(PREFIX)/bin/emugf-cli
uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/bin/emugf-cli


.PHONY: all install uninstall