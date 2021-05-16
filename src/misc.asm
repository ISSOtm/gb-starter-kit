
INCLUDE "defines.asm"

INCLUDE "misc/rand.asm"
EXPORT randstate ; Defined in the above, exported here to avoid touching the file

SECTION "LCDMemsetSmallFromB", ROM0

; Writes a value to all bytes in an area of memory
; Works when the destination is in VRAM, even while the LCD is on
; @param hl Beginning of area to fill
; @param c Amount of bytes to write (0 causes 256 bytes to be written)
; @param a Value to write
; @return c 0
; @return hl Pointer to the byte after the last written one
; @return b Equal to a
; @return f Z set, C reset
LCDMemsetSmall::
	ld b, a
; Writes a value to all bytes in an area of memory
; Works when the destination is in VRAM, even while the LCD is on
; Protip: you may want to use `lb bc,` to set both B and C at the same time
; @param hl Beginning of area to fill
; @param c Amount of bytes to write (0 causes 256 bytes to be written)
; @param b Value to write
; @return c 0
; @return hl Pointer to the byte after the last written one
; @return b Equal to a
; @return f Z set, C reset
LCDMemsetSmallFromB::
	wait_vram
	ld a, b
	ld [hli], a
	dec c
	jr nz, LCDMemsetSmallFromB
	ret

SECTION "LCDMemset", ROM0

; Writes a value to all bytes in an area of memory
; Works when the destination is in VRAM, even while the LCD is on
; @param hl Beginning of area to fill
; @param bc Amount of bytes to write (0 causes 65536 bytes to be written)
; @param a Value to write
; @return bc 0
; @return hl Pointer to the byte after the last written one
; @return d Equal to parameter passed in a
; @return a 0
; @return f Z set, C reset
LCDMemset::
	ld d, a
; Writes a value to all bytes in an area of memory
; Works when the destination is in VRAM, even while the LCD is on
; @param hl Beginning of area to fill
; @param bc Amount of bytes to write (0 causes 65536 bytes to be written)
; @param d Value to write
; @return bc 0
; @return hl Pointer to the byte after the last written one
; @return a 0
; @return f Z set, C reset
LCDMemsetFromD::
	; Increment B if C is non-zero
	dec bc
	inc b
	inc c
.loop
	wait_vram
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
; @param de Pointer to beginning of block to copy
; @param hl Pointer to where to copy (bytes will be written from there onwards)
; @param c Amount of bytes to copy (0 causes 256 bytes to be copied)
; @return de Pointer to byte after last copied one
; @return hl Pointer to byte after last written one
; @return c 0
; @return a Last byte copied
; @return f Z set, C reset
LCDMemcpySmall::
	wait_vram
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, LCDMemcpySmall
	ret

SECTION "LCDMemcpy", ROM0

; Copies a block of memory somewhere else
; Works when the source or destination is in VRAM, even while the LCD is on
; @param de Pointer to beginning of block to copy
; @param hl Pointer to where to copy (bytes will be written from there onwards)
; @param bc Amount of bytes to copy (0 causes 65536 bytes to be copied)
; @return de Pointer to byte after last copied one
; @return hl Pointer to byte after last written one
; @return bc 0
; @return a 0
; @return f Z set, C reset
LCDMemcpy::
	; Increment B if C is non-zero
	dec bc
	inc b
	inc c
.loop
	wait_vram
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	ret

SECTION "Memcpy", ROM0

; Copies a block of memory somewhere else
; @param de Pointer to beginning of block to copy
; @param hl Pointer to where to copy (bytes will be written from there onwards)
; @param bc Amount of bytes to copy (0 causes 65536 bytes to be copied)
; @return de Pointer to byte after last copied one
; @return hl Pointer to byte after last written one
; @return bc 0
; @return a 0
; @return f Z set, C reset
Memcpy::
	; Increment B if C is non-zero
	dec bc
	inc b
	inc c
.loop
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	ret
