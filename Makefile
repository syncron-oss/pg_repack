#
# pg_repack: Makefile
#
#  Portions Copyright (c) 2008-2011, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
#  Portions Copyright (c) 2011, Itagaki Takahiro
#  Portions Copyright (c) 2012, The Reorg Development Team
#

PG_CONFIG ?= pg_config
EXTENSION = pg_repack

.PHONY: dist/$(EXTENSION)-$(EXTVERSION).zip

# Pull out PostgreSQL version number from pg_config
VERSION := $(shell $(PG_CONFIG) --version | awk '{print $$2}')
ifeq ("$(VERSION)","")
$(error pg_config not found)
endif

# PostgreSQL version as a number, e.g. 9.1.4 -> 901
INTVERSION := $(shell echo $$(($$(echo $(VERSION) | sed 's/\([[:digit:]]\{1,\}\)\.\([[:digit:]]\{1,\}\).*/\1*100+\2/'))))

# The version number of the library
EXTVERSION = $(shell grep '"version":' META.json | head -1 \
	| sed -e 's/[ 	]*"version":[ 	]*"\(.*\)",/\1/')

# We support PostgreSQL 8.3 and later.
ifeq ($(shell echo $$(($(INTVERSION) < 803))),1)
$(error $(EXTENSION) requires PostgreSQL 8.3 or later. This is $(VERSION))
endif


SUBDIRS = bin lib regress

all install installdirs uninstall distprep clean distclean maintainer-clean debug:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir $@ || exit; \
	done

# We'd like check operations to run all the subtests before failing.
check installcheck:
	@CHECKERR=0; for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir $@ || CHECKERR=$$?; \
	done; \
	exit $$CHECKERR

# Prepare the package for PGXN submission
package: $(EXTENSION)-$(EXTVERSION).zip

$(EXTENSION)-$(EXTVERSION).zip:
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ --output $@ master
