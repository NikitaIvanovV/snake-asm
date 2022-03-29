AS := nasm

PREFIX   ?= /usr/local
BINPREFIX = $(DESTDIR)${PREFIX}/bin

BUILDDIR := build

BIN    := snake-asm
SRC    := $(wildcard *.asm)
OBJ    := ${SRC:%.asm=${BUILDDIR}/%.o}
DEP    := ${OBJ:.o=.d}
BINTAR := ${BIN}.tar.gz

ASFLAGS += -felf64

${BIN}: ${OBJ}
	$(LD) -o $@ $(LDFLAGS) $^

${BUILDDIR}/%.o: %.asm
	@mkdir -p ${@D}
	@$(AS) -o $@ -M -MF ${@:.o=.d} $<
	$(AS) -o $@ $(ASFLAGS) $<

${BINTAR}: ${BIN}
	tar czf $@ $^

dist: ${BINTAR}

install: ${BIN}
	install -d ${BINPREFIX}
	install ${BIN} ${BINPREFIX}

uninstall:
	$(RM) ${BINPREFIX}/${BIN}

clean:
	$(RM) ${BIN} ${OBJ} ${DEP} ${BINTAR}

-include ${DEP}

.PHONY: dist install uninstall clean
