
INCLUDE "defines.asm"

SECTION "VBlank handler stub", ROM0[$40]

; VBlank handler
	push af
	ldh a, [hLCDC]
	ldh [rLCDC], a
	jr VBlankHandler

SECTION "VBlank handler", ROM0

VBlankHandler:
	ldh a, [hSCY]
	ldh [rSCY], a
	ldh a, [hSCX]
	ldh [rSCX], a
	ldh a, [hBGP]
	ldh [rBGP], a
	ldh a, [hOBP0]
	ldh [rOBP0], a
	ldh a, [hOBP1]
	ldh [rOBP1], a

	; OAM DMA can occur late in the handler, because it will still work even
	; outside of VBlank. Sprites just will not appear on the scanline(s)
	; during which it's running.
	ldh a, [hOAMHigh]
	and a
	jr z, .noOAMTransfer
	call hOAMDMA
	xor a
	ldh [hOAMHigh], a
.noOAMTransfer

	; Put all operations that cannot be interrupted above this line
	; For example, OAM DMA (can't jump to ROM in the middle of it),
	; VRAM accesses (can't screw up timing), etc
	ei

	ldh a, [hVBlankFlag]
	and a
	jr z, .lagFrame
	xor a
	ldh [hVBlankFlag], a

	ld c, LOW(rP1)
	ld a, $20 ; Select D-pad
	ldh [c], a
REPT 6
	ldh a, [c]
ENDR
	or $F0 ; Set 4 upper bits (give them consistency)
	ld b, a

	; Filter impossible D-pad combinations
	and $0C ; Filter only Down and Up
	ld a, b
	jr nz, .notUpAndDown
	or $0C ; If both are pressed, "unpress" them
	ld b, a
.notUpAndDown
	and $03 ; Filter only Left and Right
	jr nz, .notLeftAndRight
	; If both are pressed, "unpress" them
	inc b
	inc b
	inc b
.notLeftAndRight
	swap b ; Put D-pad buttons in upper nibble

	ld a, $10 ; Select buttons
	ldh [c], a
REPT 6
	ldh a, [c]
ENDR
	; On SsAB held, soft-reset
	and $0F
	jr z, .perhapsReset
.dontReset

	or $F0 ; Set 4 upper bits
	xor b ; Mix with D-pad bits, and invert all bits (such that pressed=1) thanks to "or $F0"
	ld b, a

	; Release joypad
	ld a, $30
	ldh [c], a

	ldh a, [hHeldKeys]
	cpl
	and b
	ldh [hPressedKeys], a
	ld a, b
	ldh [hHeldKeys], a

	pop af ; Pop off return address as well to exit infinite loop
.lagFrame
	pop af
	ret

.perhapsReset
	ldh a, [hCanSoftReset]
	and a
	jr z, .dontReset
	jp Reset

	; This ensures the handler is right before the header, avoiding a gap.
	; We do this also to ensure that `VBlankHandler` is in range of the `jr VBlankHandler`.
	align 16, $100


SECTION "VBlank HRAM", HRAM

; DO NOT TOUCH THIS
; When this flag is set, the VBlank handler will assume the caller is `WaitVBlank`,
; and attempt to exit it. You don't want that to happen outside of that function.
hVBlankFlag:: db

; High byte of the address of the OAM buffer to use.
; When this is non-zero, the VBlank handler will write that value to rDMA, and
; reset it.
hOAMHigh:: db

; Shadow registers for a bunch of hardware regs.
; Writing to the hardware regs causes them to take effect more or less immediately, so these
; are copied to the hardware regs by the VBlank handler instead, taking effect between frames.
; They also come in handy for "resetting" the regs if modifying them mid-frame for raster FX.
hLCDC:: db
hSCY:: db
hSCX:: db
hBGP:: db
hOBP0:: db
hOBP1:: db

; Keys that are currently being held, and that became held just this frame, respectively.
; Each bit represents a button, with that bit set == button pressed
; Button order: Down, Up, Left, Right, Start, select, B, A
; U+D and L+R are filtered out by software, so they will never happen
hHeldKeys:: db
hPressedKeys:: db

; If this is 0, pressing SsAB at the same time will not reset the game
hCanSoftReset:: db
