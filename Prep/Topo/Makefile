# Makefile

include ../Mkinclude

SRC	= \
	  TOPO3.f90 \
	  TOPO30.f90
DCLSRC	= \
	  TOPO3_draw.f90 \
	  TOPO30_draw.f90

DCLTAR	= \
	  TOPO3_draw \
	  TOPO30_draw

TARGET	= \
	  TOPO3 \
	  TOPO30

all: $(TARGET) draw #stpk
#all: $(TARGET)
#	@for i in $(TARGET) ; do \
	  cp $$i ${BIN} ; \
	done
$(TARGET): %:%.f90
	$(FC) ${FFLAGS} $< -o $@

draw: $(DCLTAR)
$(DCLTAR): %:%.f90
	$(DCLFC) ${FFLAGS} -I${AF90LD}/include $< -o $@ -L${LDFLAGS} -l${LFLAGS} -L${AF90LD}/lib -l${AF90LIB}

#stpk: $(TARGET1)
#$(TARGET1): %:%.f90
#	$(DCLFC) ${FFLAGS} -I${STPKLD}/include $< -o $@ -L${LDFLAGS} -l${LFLAGS} -L${STPKLD}/lib -l${STPKLIB}

clean:
	rm -rf $(TARGET) *.o *.mod #$(DCLTAR) $(TARGET1)
