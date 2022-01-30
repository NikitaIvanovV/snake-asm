AS := nasm

BUILDDIR := build
BIN := snake

SRC := $(wildcard *.asm)
OBJ := ${SRC:%.asm=${BUILDDIR}/%.o}
DEP := ${OBJ:.o=.d}

${BIN}: ${OBJ}
	$(LD) -o $@ $^

${BUILDDIR}/%.o: %.asm
	@mkdir -p ${BUILDDIR}
	@$(AS) -o $@ -M -MF ${@:.o=.d} $<
	$(AS) -o $@ -felf64 $<

clean:
	$(RM) ${BIN} ${OBJ} ${DEP}

-include ${DEP}

.PHONY: clean
