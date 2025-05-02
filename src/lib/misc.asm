INCLUDE "defines.inc"


; TODO: for `{,LCD}Mem{set,cpy}`, switch to `dec c :: jr nz :: dec b :: jr nz` loops
;       with sizes adjusted at compile time.
;       This would require RGBDS to implement functions to remain convenient, though...


INCLUDE "lib/rand.inc"
EXPORT randstate ; Defined in the above, exported here to avoid modifying that file (so it can be updated more easily).


SECTION "JumpToPtr / CallHL", ROM0
; Dereferences `hl` and jumps there.
; All other registers are passed to the called code intact, except Z is reset.
; Soft-crashes if the jump target is in RAM.
; @param  hl: Pointer to an address to jump to
JumpToPtr::
	ld a, [hli] :: ld h, [hl] :: ld l, a
; Jumps to the address contained in `hl`.
; All registers are passed to the called code intact, except Z is reset.
; (`jp CallHL` is equivalent to `jp hl`, but with the extra error checking on top;
;  `rst CallHL` is more useful, being equivalent to `call hl`.)
; Soft-crashes if attempting to jump to RAM.
; @param  hl: The address of the code to jump to
CallHL:: align 16, $28 ; Suitable for `rst CallHL`.
	bit 7, h
	error nz
	jp hl

SECTION "CallDE", ROM0
; Jumps to some address.
; All registers are passed to the target code intact, except Z is reset.
; (`jp CallDE` would be equivalent to `jp de` if that instruction existed;
;  `rst CallDE` is more useful, being equivalent to `call de`).
; Soft-crashes if attempting to jump to RAM.
; @param  de: The address of the code to jump to
CallDE:: align 16, $30 ; Suitable for `rst CallDE`.
	bit 7, d
	push de :: ret z ; No jumping to RAM, boy!
	rst Crash
