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

include project.mk
all: ${ROM}
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
	@touch $@
obj/%.mk: src/%.asm
	@mkdir -p "${@D}"
	${RGBASM} ${ASFLAGS} -o ${@:.mk=.o} $< \
	    -M $@ -MG -MP -MQ ${@:.mk=.o} -MQ $@
ifeq ($(filter clean,${MAKECMDGOALS}),)
include $(patsubst src/%.asm,obj/%.mk,${SRCS})
endif
${ROM}: $(patsubst src/%.asm,obj/%.o,${SRCS})
	@mkdir -p "${@D}"
	${RGBASM} ${ASFLAGS} -o obj/build_date.o src/assets/build_date.asm
	${RGBLINK} ${LDFLAGS} -m bin/$*.map -n bin/$*.sym -o $@ $^ \
	&& ${RGBFIX} -v ${FIXFLAGS} $@
hardware.inc/hardware.inc rgbds-structs/structs.asm:
	@echo '$@ is not present; have you initialized submodules?'
	@echo 'Run `git submodule update --init`,'
	@echo 'then `make clean`,'
	@echo 'then `make` again.'
	@echo 'Tip: to avoid this, use `git clone --recursive` next time!'
	@exit 1
