.SUFFIXES:

ifeq (${MAKE_VERSION},3.81)
.NOTPARALLEL:
endif

rwildcard = $(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

RGBDS   ?=
RGBASM  := ${RGBDS}rgbasm
RGBLINK := ${RGBDS}rgblink
RGBFIX  := ${RGBDS}rgbfix
RGBGFX  := ${RGBDS}rgbgfx

INCDIRS  := src/ include/
WARNINGS := all extra
ASFLAGS  = -p ${PADVALUE} $(addprefix -I,${INCDIRS}) $(addprefix -W,${WARNINGS})
LDFLAGS  = -p ${PADVALUE}
FIXFLAGS = -p ${PADVALUE} -i "${GAMEID}" -k "${LICENSEE}" -l ${OLDLIC} -m ${MBC} -n ${VERSION} -r ${SRAMSIZE} -t ${TITLE}

ROM = bin/${ROMNAME}.${ROMEXT}
SRCS := $(call rwildcard,src,*.asm)
OBJS := $(patsubst src/%.asm,obj/%.o,${SRCS})
DEPFILES := ${OBJS:.o=.mk}
DEBUGFILES := ${OBJS:.o=.dbg}
include project.mk
all: ${ROM} ${DEBUGFILES} bin/${ROMNAME}.dbg
.PHONY: all

clean:
	rm -rf bin obj assets
.PHONY: clean

VPATH := src
assets/%.2bpp: assets/%.png
	@mkdir -p "${@D}"
	${RGBGFX} -o $@ $<

assets/%.1bpp: assets/%.png
	@mkdir -p "${@D}"
	${RGBGFX} -d 1 -o $@ $<
assets/%.pb16: src/tools/pb16.py assets/%
	@mkdir -p "${@D}"
	$^ $@$
assets/%.pb16.size: assets/%
	@mkdir -p "${@D}"
	printf 'def NB_PB16_BLOCKS equ ((%u) + 15) / 16\n' \
	    "$$(wc -c <$<)" >assets/$*.pb16.size
assets/%.pb8: src/tools/pb8.py assets/%
	@mkdir -p "${@D}"
	$^ $@

assets/%.pb8.size: assets/%
	@mkdir -p "${@D}"
	printf 'def NB_PB8_BLOCKS equ ((%u) + 7) / 8\n' \
	    "$$(wc -c <$<)" >assets/$*.pb8.size
obj/%.o: obj/%.mk
	@touch -c $@
obj/%.mk: src/%.asm
	@mkdir -p "${@D}"
	${RGBASM} ${ASFLAGS} -o ${@:.mk=.o} $< \
	    -M $@ -MG -MP -MQ ${@:.mk=.o} -MQ $@
ifeq ($(filter clean,${MAKECMDGOALS}),)
include ${DEPFILES}
endif
SYMFILE := $(basename ${ROM}).sym
MAPFILE := $(basename ${ROM}).map
${ROM}: src/tools/nb_used_banks.py ${OBJS}
	@mkdir -p "${@D}"
	${RGBASM} ${ASFLAGS} -o obj/lib/build_date.o src/lib/build_date.asm
	${RGBLINK} ${LDFLAGS} -m ${MAPFILE}.tmp ${OBJS}
	NB_BANKS=$$(src/tools/nb_used_banks.py ${MAPFILE}.tmp) \
	&& ${RGBASM} ${ASFLAGS} -DNB_BANKS=$$NB_BANKS \
	    -o obj/lib/bank_numbers.o src/lib/bank_numbers.asm
	rm ${MAPFILE}.tmp
	${RGBLINK} ${LDFLAGS} -m ${MAPFILE} -n ${SYMFILE} -o $@ ${OBJS} \
	&& ${RGBFIX} -v ${FIXFLAGS} $@
obj/%.dbg: obj/%.o
	${RGBASM} ${ASFLAGS} src/$*.asm -DPRINT_DEBUGFILE >$@
bin/${ROMNAME}.dbg: ${SRCS}
	@mkdir -p "${@D}"
	echo @debugfile 1.0 >$@
	printf '@include "../%s"\n' ${DEBUGFILES} >>$@
hardware.inc/hardware.inc rgbds-structs/structs.inc debugfile.inc/debugfile.inc:
	@echo '$@ is not present; have you initialized submodules?'
	@echo 'Run `git submodule update --init`,'
	@echo 'then `make clean`,'
	@echo 'then `make` again.'
	@echo 'Tip: to avoid this, use `git clone --recursive` next time!'
	@exit 1
