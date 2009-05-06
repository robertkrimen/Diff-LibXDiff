.PHONY: all test clean distclean dist xdiff

LIBXDIFF_DIR := src/libxdiff-0.23

all: test

dist:
	rm -rf inc META.y*ml
	perl Makefile.PL
	$(MAKE) -f Makefile dist

install distclean tardist: Makefile
	$(MAKE) -f $< $@

test: Makefile
	TEST_RELEASE=1 $(MAKE) -f $< $@

Makefile: Makefile.PL
	perl $<

clean: distclean

reset: clean
	perl Makefile.PL
	$(MAKE) test

xdiff:
	echo '#define PACKAGE_VERSION "0.23"' > xdiff.c
	for file in xdiffi.c xprepare.c xpatchi.c xmerge3.c xemit.c xmissing.c xutils.c xadler32.c xbdiff.c \
		xbpatchi.c xversion.c xalloc.c xrabdiff.c; do cat $(LIBXDIFF_DIR)/xdiff/$$file  >> xdiff.c; done
	cp $(LIBXDIFF_DIR)/xdiff/*.h xdiff/
	cp $(LIBXDIFF_DIR)/xdiff/xrabply.c xdiff/
