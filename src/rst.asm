
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
