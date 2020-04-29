
.SUFFIXES:

################################################
#                                              #
#             CONSTANT DEFINITIONS             #
#                                              #
################################################

# Directory constants
SRCDIR := src
BINDIR := bin
OBJDIR := obj
DEPDIR := dep
RESDIR := res

# Program constants
MKDIR  := $(shell which mkdir)
# Shortcut if you want to use a local copy of RGBDS
RGBDS   =
RGBASM  = $(RGBDS)rgbasm
RGBLINK = $(RGBDS)rgblink
RGBFIX  = $(RGBDS)rgbfix
RGBGFX  = $(RGBDS)rgbgfx

ROM = $(BINDIR)/$(ROMNAME).$(ROMEXT)

# Argument constants
INCDIRS  = $(SRCDIR)/ $(SRCDIR)/include/
WARNINGS = all extra
ASFLAGS  = -p $(PADVALUE) $(addprefix -i,$(INCDIRS)) $(addprefix -W,$(WARNINGS))
LDFLAGS  = -p $(PADVALUE)
FIXFLAGS = -p $(PADVALUE) -v -i "$(GAMEID)" -k "$(LICENSEE)" -l $(OLDLIC) -m $(MBC) -n $(VERSION) -r $(SRAMSIZE) -t $(TITLE)

# The list of "root" ASM files that RGBASM will be invoked on
SRCS = $(wildcard $(SRCDIR)/*.asm)

## Project-specific configuration
# Use this to override the above
include project.mk

################################################
#                                              #
#                RESOURCE FILES                #
#                                              #
################################################

# By default, asset recipes convert files in `res/` into other files in `res/`
# This line causes assets not found in `res/` to be also looked for in `src/res/`
# "Source" assets can thus be safely stored there without `make clean` removing them
VPATH := $(SRCDIR)

$(RESDIR)/%.1bpp: $(RESDIR)/%.png
	@$(MKDIR) -p $(@D)
	$(RGBGFX) -d 1 -o $@ $<

# Define how to compress files using the PackBits16 codec
# Compressor script requires Python 3
$(RESDIR)/%.pb16 $(RESDIR)/%.pb16.size: $(RESDIR)/% $(SRCDIR)/tools/pb16.py
	@$(MKDIR) -p $(@D)
	$(SRCDIR)/tools/pb16.py $< $(RESDIR)/$*.pb16
	echo 'NB_PB16_BLOCKS equ (' `wc -c $< | cut -d ' ' -f 1` ' + 15) / 16' > $(RESDIR)/$*.pb16.size

# Define how to compress files using the PackBits8 codec
# Compressor script requires Python 3
$(RESDIR)/%.pb8 $(RESDIR)/%.pb8.size: $(RESDIR)/% $(SRCDIR)/tools/pb8.py
	@$(MKDIR) -p $(@D)
	$(SRCDIR)/tools/pb8.py $< $(RESDIR)/$*.pb8
	echo 'NB_PB8_BLOCKS equ (' `wc -c $< | cut -d ' ' -f 1` ' + 7) / 8' > $(RESDIR)/$*.pb8.size

###############################################
#                                             #
#                 COMPILATION                 #
#                                             #
###############################################

# `all` (Default target): build the ROM
all: $(ROM)
.PHONY: all

# `clean`: Clean temp and bin files
clean:
	-rm -rf $(BINDIR) $(OBJDIR) $(DEPDIR) $(RESDIR)
.PHONY: clean

# `rebuild`: Build everything from scratch
# It's important to do these two in order if we're using more than one job
rebuild:
	$(MAKE) clean
	$(MAKE) all
.PHONY: rebuild

# How to build a ROM
$(BINDIR)/%.$(ROMEXT) $(BINDIR)/%.sym $(BINDIR)/%.map: $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(SRCS))
	@$(MKDIR) -p $(@D)
	$(RGBASM) $(ASFLAGS) -o $(OBJDIR)/build_date.o $(SRCDIR)/res/build_date.asm
	$(RGBLINK) $(LDFLAGS) -m $(BINDIR)/$*.map -n $(BINDIR)/$*.sym -o $(BINDIR)/$*.$(ROMEXT) $^ $(OBJDIR)/build_date.o \
	&& $(RGBFIX) -v $(FIXFLAGS) $(BINDIR)/$*.$(ROMEXT)

# `.mk` files are auto-generated dependency lists of the "root" ASM files, to save a lot of hassle.
# Also add all obj dependencies to the dep file too, so Make knows to remake it
# Caution: some of these flags were added in RGBDS 0.4.0, using an earlier version WILL NOT WORK
# (and produce weird errors)
$(OBJDIR)/%.o $(DEPDIR)/%.mk: $(SRCDIR)/%.asm
	@$(MKDIR) -p $(dir $(OBJDIR)/$* $(DEPDIR)/$*)
	$(RGBASM) $(ASFLAGS) -M $(DEPDIR)/$*.mk -MG -MP -MQ $(OBJDIR)/$*.o -MQ $(DEPDIR)/$*.mk -o $(OBJDIR)/$*.o $<

ifneq ($(MAKECMDGOALS),clean)
-include $(patsubst $(SRCDIR)/%.asm,$(DEPDIR)/%.mk,$(SRCS))
endif
