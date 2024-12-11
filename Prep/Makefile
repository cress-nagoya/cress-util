# Makefile

include ./Mkinclude

SUBDIR	= \
	  Topo

all:
	@for i in $(SUBDIR) ; do \
	  cd $$i ; \
	  $(MAKE) ; \
	  cd ../ ; \
	done

clean:
	@for i in $(SUBDIR) ; do \
	  cd $$i ; \
	  $(MAKE) clean; \
	  cd ../ ; \
	done
	rm -f *.o *.mod
