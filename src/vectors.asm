
INCLUDE "defines.asm"

SECTION "Rst $00", ROM0[$00]

NULL::
	; This traps jumps to $0000, which is a common "default" pointer
	; $FFFF is another one, but reads rIE as the instruction byte
	; Thus, we put two `nop`s that may serve as operands, before soft-crashing
	; The operand will always be 0, so even jumps will work fine. Nice!
	nop
	nop
	rst Crash

SECTION "Rst $08", ROM0[$08]

; Waits for the next VBlank beginning
; Requires the VBlank handler to be able to trigger, otherwise will loop infinitely
; This means IME should be set, the VBlank interrupt should be selected in IE,
; and the LCD should be turned on.
; WARNING: Be careful if calling this with IME reset (`di`), if this was compiled
; with the `-h` flag, then a hardware bug is very likely to cause this routine to
; go horribly wrong.
; Note: the VBlank handler recognizes being called from this function (through `hVBlankFlag`),
; and does not try to save registers if so. To be safe, consider all registers to be destroyed.
; @destroy Possibly every register. The VBlank handler stops preserving anything when executed from this function
WaitVBlank::
	ld a, 1
	ldh [hVBlankFlag], a
.wait
	halt
	jr .wait

SECTION "Rst $10", ROM0[$10 - 1]

MemsetLoop:
	ld a, d

	assert @ == $10
; You probably don't want to use this for writing to VRAM while the LCD is on. See LCDMemset.
Memset::
	ld [hli], a
	ld d, a
	dec bc
	ld a, b
	or c
	jr nz, MemsetLoop
	ret

SECTION "Rst $18", ROM0[$18]

MemcpySmall::
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, MemcpySmall
	ret

SECTION "Rst $20", ROM0[$20]

MemsetSmall::
	ld [hli], a
	dec c
	jr nz, MemsetSmall
	ret

SECTION "Rst $28", ROM0[$28 - 3]

; Dereferences `hl` and jumps there
; All other registers are passed to the called code intact, except Z is reset
; Soft-crashes if the jump target is in RAM
; @param hl Pointer to an address to jump to
JumpToPtr::
	ld a, [hli]
	ld h, [hl]
	ld l, a

	assert @ == $28
; Jump to some address
; All registers are passed to the called code intact, except Z is reset
; (`jp CallHL` is equivalent to `jp hl`, but with the extra error checking on top)
; Soft-crashes if attempting to jump to RAM
; @param hl The address of the code to jump to
CallHL::
	bit 7, h
	error nz
	jp hl

SECTION "Rst $30", ROM0[$30]

; Jumps to some address
; All registers are passed to the target code intact, except Z is reset
; (`jp CallDE` would be equivalent to `jp de` if that instruction existed)
; Soft-crashes if attempting to jump to RAM
; @param de The address of the code to jump to
CallDE::
	bit 7, d
	push de
	ret z ; No jumping to RAM, boy!
	rst Crash

SECTION "Rst $38", ROM0[$38]

; Perform a soft-crash. Prints debug info on-screen
Crash::
	di ; Doing this as soon as possible to avoid interrupts messing up
	jp HandleCrash

SECTION "Handlers", ROM0[$40]

; VBlank handler
	push af
	ldh a, [hLCDC]
	ldh [rLCDC], a
	jp VBlankHandler
	ds $48 - @

; STAT handler
	rst $38
	ds $50 - @

; Timer handler
	rst $38
	ds $58 - @

; Serial handler
	rst $38
	ds $60 - @

; Joypad handler (useless)
	rst $38

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
; Writing to these causes them to take effect more or less immediately, so these
; are copied to the hardware regs by the VBlank handler, taking effect between frames.
; They also come in handy for "resetting" them if modifying them mid-frame for raster FX.
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
