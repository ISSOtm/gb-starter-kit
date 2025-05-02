INCLUDE "defines.asm"


SECTION "Memset", ROM0
Memset.loop
	ld a, d
; Writes a value to all bytes in an area of memory.
; Not suitable for writing to VRAM while the LCD is on; use `LCDMemset` instead.
; @param  hl: Beginning of area to fill
; @param  bc: Amount of bytes to write (0 causes 256 bytes to be written)
; @param  a:  Value to write
; @return c:  0
; @return hl: Pointer to the byte after the last written one
; @return d:  Equal to a
; @return f:  Z set, C preserved
Memset:: align 16, $10 ; Suitable for `rst Memset`.
	ld [hli], a
	ld d, a
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

SECTION "MemcpySmall", ROM0
; Copies a block of memory somewhere else.
; Not suitable for reading from or writing to VRAM while the LCD is on; use `LCDMemcpySmall` instead.
; @param  de: Pointer to the first byte to copy
; @param  hl: Beginning of area to write to
; @param  c:  Amount of bytes to write (0 causes 256 bytes to be written)
; @param  a:  Value to write
; @return c:  0
; @return hl: Pointer to the byte after the last written one
; @return b:  Equal to a
; @return f:  Z set, C preserved
MemcpySmall:: align 16, $18 ; Suitable for `rst MemcpySmall`.
	ld a, [de] :: ld [hli], a :: inc de
	dec c
	jr nz, MemcpySmall
	ret

SECTION "MemsetSmall", ROM0
; Writes a value to all bytes in an area of memory.
; Not suitable for writing to VRAM while the LCD is on; use `LCDMemsetSmall` instead.
; @param  hl: Beginning of area to fill
; @param  c:  Amount of bytes to write (0 causes 256 bytes to be written)
; @param  a:  Value to write
; @return c:  0
; @return hl: Pointer to the byte after the last written one
; @return b:  Equal to a
; @return f:  Z set, C preserved
MemsetSmall:: align 16, $20 ; Suitable for `rst MemsetSmall`.
	ld [hli], a
	dec c
	jr nz, MemsetSmall
	ret

SECTION "LCDMemsetSmallFromB", ROM0
; Writes a value to all bytes in an area of memory.
; Works when the destination is in VRAM, even while the LCD is on.
; @param  hl: Beginning of area to fill
; @param  c:  Amount of bytes to write (0 causes 256 bytes to be written)
; @param  a:  Value to write
; @return c:  0
; @return hl: Pointer to the byte after the last written one
; @return b:  Equal to a
; @return f:  Z set, C reset
LCDMemsetSmall::
	ld b, a
; Writes a value to all bytes in an area of memory
; Works when the destination is in VRAM, even while the LCD is on
; Protip: you may want to use `lb bc,` to set both B and C at the same time
; @param  hl: Beginning of area to fill
; @param  c:  Amount of bytes to write (0 causes 256 bytes to be written)
; @param  b:  Value to write
; @return c:  0
; @return hl: Pointer to the byte after the last written one
; @return b:  Equal to a
; @return f:  Z set, C reset
LCDMemsetSmall.fromB::
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, b
	ld [hli], a
	dec c
	jr nz, .fromB
	ret

SECTION "LCDMemset", ROM0
; Writes a value to all bytes in an area of memory
; Works when the destination is in VRAM, even while the LCD is on
; @param  hl: Beginning of area to fill
; @param  bc: Amount of bytes to write (0 causes 65536 bytes to be written)
; @param  a:  Value to write
; @return bc: 0
; @return hl: Pointer to the byte after the last written one
; @return d:  Equal to parameter passed in a
; @return a:  0
; @return f:  Z set, C reset
LCDMemset::
	ld d, a
; Writes a value to all bytes in an area of memory
; Works when the destination is in VRAM, even while the LCD is on
; @param  hl: Beginning of area to fill
; @param  bc: Amount of bytes to write (0 causes 65536 bytes to be written)
; @param  d:  Value to write
; @return bc: 0
; @return hl: Pointer to the byte after the last written one
; @return a:  0
; @return f:  Z set, C reset
LCDMemsetFromD::
	; Increment B if C is non-zero
	dec bc
	inc b
	inc c
.loop
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, d
	ld [hli], a
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	ret

SECTION "LCDMemcpySmall", ROM0
; Copies a block of memory somewhere else
; Works when the source or destination is in VRAM, even while the LCD is on
; @param  de: Pointer to beginning of block to copy
; @param  hl: Pointer to where to copy (bytes will be written from there onwards)
; @param  c:  Amount of bytes to copy (0 causes 256 bytes to be copied)
; @return de: Pointer to byte after last copied one
; @return hl: Pointer to byte after last written one
; @return c:  0
; @return a:  Last byte copied
; @return f:  Z set, C reset
LCDMemcpySmall::
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, [de] :: ld [hli], a :: inc de
	dec c
	jr nz, LCDMemcpySmall
	ret

SECTION "LCDMemcpy", ROM0
; Copies a block of memory somewhere else.
; Works when the source or destination is in VRAM, even while the LCD is on.
; @param  de: Pointer to beginning of block to copy
; @param  hl: Pointer to where to copy (bytes will be written from there onwards)
; @param  bc: Amount of bytes to copy (0 causes 65536 bytes to be copied)
; @return de: Pointer to byte after last copied one
; @return hl: Pointer to byte after last written one
; @return bc: 0
; @return a:  0
; @return f:  Z set, C reset
LCDMemcpy::
	; Increment B if C is non-zero (TODO: replace this with a compile-time adjust!)
	dec bc :: inc b :: inc c
.loop
:	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, [de] :: ld [hli], a :: inc de
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	ret

SECTION "Memcpy", ROM0
; Copies a block of memory somewhere else.
; @param  de: Pointer to beginning of block to copy
; @param  hl: Pointer to where to copy (bytes will be written from there onwards)
; @param  bc: Amount of bytes to copy (0 causes 65536 bytes to be copied)
; @return de: Pointer to byte after last copied one
; @return hl: Pointer to byte after last written one
; @return bc: 0
; @return a:  0
; @return f:  Z set, C reset
Memcpy::
	; Increment B if C is non-zero (TODO: replace this with a compile-time adjust!)
	dec bc :: inc b :: inc c
.loop
	ld a, [de] :: ld [hli], a :: inc de
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	ret
