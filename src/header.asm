
INCLUDE "defines.asm"


SECTION "Header", ROM0[$100]

	; This is your ROM's entry point
	; You have 4 bytes of code to do... something
	sub $11 ; This helps check if we're on CGB more efficiently
	jr EntryPoint

	; Make sure to allocate some space for the header, so no important
	; code gets put there and later overwritten by RGBFIX.
	; RGBFIX is designed to operate over a zero-filled header, so make
	; sure to put zeros regardless of the padding value. (This feature
	; was introduced in RGBDS 0.4.0, but the -MG etc flags were also
	; introduced in that version.)
	ds $150 - @, 0

EntryPoint:
	ldh [hConsoleType], a

Reset::
	di ; Disable interrupts while we set up

	; Kill sound
	xor a
	ldh [rNR52], a

	; Wait for VBlank and turn LCD off
.waitVBlank
	ldh a, [rLY]
	cp SCRN_Y
	jr c, .waitVBlank
	xor a
	ldh [rLCDC], a
	; Goal now: set up the minimum required to turn the LCD on again
	; A big chunk of it is to make sure the VBlank handler doesn't crash

	ld sp, wStackBottom

	assert BANK(OAMDMA) != 0, "`OAMDMA` is in ROM0, please remove this write to `rROMB0`"
	ld a, BANK(OAMDMA)
	; No need to write bank number to HRAM, interrupts aren't active
	ld [rROMB0], a
	ld hl, OAMDMA
	lb bc, OAMDMA.end - OAMDMA, LOW(hOAMDMA)
.copyOAMDMA
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, .copyOAMDMA

	WARN "Edit to set palettes here"
	; CGB palettes maybe, DMG ones always

	; You will also need to reset your handlers' variables below
	; I recommend reading through, understanding, and customizing this file
	; in its entirety anyways. This whole file is the "global" game init,
	; so it's strongly tied to your own game.
	; I don't recommend clearing large amounts of RAM, nor to init things
	; here that can be initialized later.

	; Reset variables necessary for the VBlank handler to function correctly
	; But only those for now
	xor a
	ldh [hVBlankFlag], a
	ldh [hOAMHigh], a
	ldh [hCanSoftReset], a
	dec a ; ld a, $FF
	ldh [hHeldKeys], a

	; Load the correct ROM bank for later
	; Important to do it before enabling interrupts
	assert BANK(Intro) != 0, "`Intro` is in ROM0, please write 1 to the bank registers instead"
	ld a, BANK(Intro)
	ldh [hCurROMBank], a
	ld [rROMB0], a

	; Select wanted interrupts here
	; You can also enable them later if you want
	ld a, IEF_VBLANK
	ldh [rIE], a
	xor a
	ei ; Only takes effect after the following instruction
	ldh [rIF], a ; Clears "accumulated" interrupts

	; Init shadow regs
	; xor a
	ldh [hSCY], a
	ldh [hSCX], a
	ld a, LCDCF_ON | LCDCF_BGON
	ldh [hLCDC], a
	; And turn the LCD on!
	ldh [rLCDC], a

	; Clear OAM, so it doesn't display garbage
	; This will get committed to hardware OAM after the end of the first
	; frame, but the hardware doesn't display it, so that's fine.
	ld hl, wShadowOAM
	ld c, NB_SPRITES * 4
	xor a
	rst MemsetSmall
	ld a, h ; ld a, HIGH(wShadowOAM)
	ldh [hOAMHigh], a

	; `Intro`'s bank has already been loaded earlier
	jp Intro

SECTION "OAM DMA routine", ROMX

; OAM DMA prevents access to most memory, but never HRAM.
; This routine starts an OAM DMA transfer, then waits for it to complete.
; It gets copied to HRAM and is called there from the VBlank handler
OAMDMA:
	ldh [rDMA], a
	ld a, NB_SPRITES
.wait
	dec a
	jr nz, .wait
	ret
.end

SECTION "Global vars", HRAM

; 0 if CGB (including DMG mode and GBA), non-zero for other models
hConsoleType:: db

; Copy of the currently-loaded ROM bank, so the handlers can restore it
; Make sure to always write to it before writing to ROMB0
; (Mind that if using ROMB1, you will run into problems)
hCurROMBank:: db


SECTION "OAM DMA", HRAM

hOAMDMA::
	ds OAMDMA.end - OAMDMA


SECTION UNION "Shadow OAM", WRAM0,ALIGN[8]

wShadowOAM::
	ds NB_SPRITES * 4


SECTION "Stack", WRAM0

wStack:
	ds STACK_SIZE
wStackBottom:

