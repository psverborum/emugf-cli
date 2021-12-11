PREFIX := /usr/local

all: install

install:
	bundle install
	cp psone-gf.rb $(DESTDIR)$(PREFIX)/bin/psone-gf
	chmod 0755 $(DESTDIR)$(PREFIX)/bin/psone-gf
uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/bin/psone-gf


.PHONY: all install uninstall