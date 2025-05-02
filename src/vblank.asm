INCLUDE "defines.inc"


SECTION "WaitVBlank", ROM0
; Waits for the next VBlank to begin.
; Requires the VBlank handler to be able to trigger, otherwise will loop infinitely; this means:
;  - IME should be set,
;  - the VBlank interrupt should be selected in IE, and
;  - the LCD should be turned on.
; @destroy Every register
WaitVBlank:: align 16, $08 ; Suitable for `rst WaitVBlank`.
	runtime_assert ime, "`WaitVBlank` called with interrupts disabled!"
	runtime_assert [{rIE}] & {IEF_VBLANK}, "`WaitVBlank` called with VBlank interrupt disabled!"
	runtime_assert [{rLCDC}] & {LCDCF_ON}, "`WaitVBlank` called with LCD off!"
	; This function may seem magical: an infinite loop that somehow exits!?
	; Like all magic, there's a secret to it:
	;   the logic that exits this function is not in the function itself,
	;   but in the VBlank handler.
	; The VBlank handler recognises being called from this function (via the `hVBlankFlag` variable)
	;   and manipulates the stack in order to return to this function's caller.
	ld a, 1 :: ldh [hVBlankFlag], a
.wait
	halt
	jr .wait
.end


SECTION "VBlank HRAM", HRAM

; High byte of the address of the OAM buffer to use.
; When this is non-zero, the VBlank handler will write that value to `rDMA`, and reset the variable.
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
; Each bit represents a key, with that bit set meaning the key is pressed.
; Button order: Down, Up, Left, Right, Start, select, B, A (see `PADF_*` constants in hardware.inc).
; Holding Up+Down or Left+Right is treated as if neither was held.
hHeldKeys:: db
hPressedKeys:: db

; If this is 1, pressing Start+Select+B+A at the same time will reset the game.
; Set this to 0 to inhibit that behaviour.
hCanSoftReset:: db

; DO NOT TOUCH THIS!!
; When this flag is set, the VBlank handler will assume the caller is `WaitVBlank`, and attempt to exit it.
; You don't want this to happen outside of that function.
hVBlankFlag:: db


SECTION "VBlank handler stub", ROM0[$40]

	push af
	; First, copy shadow registers to their actual counterparts.
	ldh a, [hLCDC] :: ldh [rLCDC], a
	jr VBlankHandler ; There isn't room here for more instructions; continued below.

SECTION "VBlank handler", ROM0

VBlankHandler:
	ldh a, [hSCY]  :: ldh [rSCY], a
	ldh a, [hSCX]  :: ldh [rSCX], a
	ldh a, [hBGP]  :: ldh [rBGP], a
	ldh a, [hOBP0] :: ldh [rOBP0], a
	ldh a, [hOBP1] :: ldh [rOBP1], a


	; OAM DMA can occur late in the handler, because it will still work even outside of VBlank.
	; OBJs just will not appear on the scanline(s) during which it's running.
	ldh a, [hOAMHigh]
	and a
	jr z, .noOAMTransfer
	call hOAMDMA
	xor a :: ldh [hOAMHigh], a
.noOAMTransfer


	; Put all operations that cannot be interrupted above this line.
	; For example, OAM DMA (can't jump to ROM in the middle of it),
	; VRAM accesses (can't screw up timing), etc
	ei


	ldh a, [hVBlankFlag]
	and a
	jr z, .lagFrame
	xor a
	ldh [hVBlankFlag], a


	ld c, LOW(rP1)
	ld a, P1F_GET_DPAD
	call .readOneNibble
	or $F0 ; Set 4 upper bits (they are garbage otherwise).
	swap a ; Put D-pad buttons in upper nibble.
	ld b, a

	; Filter impossible D-pad combinations, and treat them as if neither key was pressed.
	and PADF_UP | PADF_DOWN
	ld a, b
	jr nz, .notUpAndDown
	or PADF_UP | PADF_DOWN
	ld b, a
.notUpAndDown
	and PADF_LEFT | PADF_RIGHT
	jr nz, .notLeftAndRight
	ld a, b
	or PADF_LEFT | PADF_RIGHT
	ld b, a
.notLeftAndRight

	ld a, P1F_GET_BTN
	call .readOneNibble
	and PADF_START | PADF_SELECT | PADF_A | PADF_B
	jr z, .perhapsReset
.dontReset
	or $F0 ; Set 4 upper bits (they are garbage otherwise).

	; This `xor` instruction pulls double duty:
	;   it both combines the two nibbles, *and* inverts all bits.
	; Here's how: right now, A = 1111 SsBA
	;                   and  B = DULR 1111
	;   ...so each key bit will be XOR'd with a 1 bit, thus inverting it.
	; Inverting is convenient: by default, a key being pressed sets its bit to 0;
	;  inverting that makes buttons conform to the more common convention of `1 = pressed`.
	xor b
	ld b, a

	; Release joypad. (This is especially important on SGB.)
	ld a, P1F_GET_NONE
	ldh [c], a

	; Compute the keys that have just been pressed: they are...
	ldh a, [hHeldKeys]
	cpl   ; ...the keys that *weren't* pressed last frame...
	and b ; ...but are right now.
	ldh [hPressedKeys], a
	ld a, b
	ldh [hHeldKeys], a


	; As signalled by `hVBlankFlag` being non-zero, the caller is `WaitVBlank`, which is a function
	;   that never returns on its own.
	; Instead, this very VBlank handler will return to its caller; this is done by popping the stack
	;   one extra time; the stack is currently:  SP->[       saved AF        ]
	;                                                [somewhere in WaitVBlank]
	;                                                [  WaitVBlank's caller  ]
	;  ...then, after the following `pop af`:
	;                                                [                       ]
	;                                            SP->[somewhere in WaitVBlank]
	;                                                [  WaitVBlank's caller  ]
	;  ...then, after `.lagFrame`'s `pop af`:
	;                                                [                       ]
	;                                                [                       ]
	;                                            SP->[  WaitVBlank's caller  ]
	;  ...thus, `ret` will return to `WaitVBlank`'s caller.'
	pop af
	runtime_assert [@sp!] >= WaitVBlank && [@sp!] < WaitVBlank.end, "The VBlank flag must only be set by `WaitVBlank`!"
.lagFrame
	pop af
	ret

.readOneNibble
	ldh [c], a ; Select the appropriate half of the buttons.
	; We now need to wait a bit for the key matrix to settle; the following way to do so
	; was come up with empirically, but has been shown to be reliable.
	call .delay ; Burn 10 cycles calling a known `ret`.
	ldh a, [c] ; A few extra reads appear to help the matrix settle...
	ldh a, [c] ;
	ldh a, [c] ; ...but only the last one's value can be trusted.
.delay
	ret

.perhapsReset
	ldh a, [hCanSoftReset]
	and a
	jr z, .dontReset
	jr Reset

	; This ensures the handler is right before the header, avoiding a gap.
	; We do this also to ensure that `VBlankHandler` is in range of the `jr VBlankHandler`.
	; As a bonus, it also ensures that `Reset` is in range for a `jr`, since it's right after the header.
	align 16, $100
