
INCLUDE "defines.asm"

	newcharmap crash_handler
CHARS equs "0123456789ABCDEF-GHIJKLMNOPQR:SUVWXYZabcdefghijklmnopqrTstuvwxyz! "
CHAR = 0
REPT STRLEN("{CHARS}")
	charmap STRSUB("{CHARS}", CHAR + 1, 1), CHAR
CHAR = CHAR + 1
ENDR

HEADER_WIDTH EQU 19
HEADER_HEIGHT EQU 3

SECTION "Crash handler", ROM0

HandleCrash::
	; We will use VRAM as scratch, since we are going to overwrite it for
	; screen output anyways. The thing is, we need to turn the LCD off
	; *without* affecting flags... fun task, eh?

	; Note: it's assumed that this was jumped to with IME off.
	; Don't call this directly, use `rst Crash`.

	ld [wCrashA], a ; We need to have at least one working register, so...
	ldh a, [rIE] ; We're also going to overwrite this
	ld [wCrashIE], a
	ldh a, [rLCDC]
	ld [wCrashLCDC], a
	ld a, LCDCF_ON ; Make sure the LCD is turned on to avoid waiting infinitely
	ldh [rLCDC], a
	ld a, IEF_VBLANK
	ldh [rIE], a
	ld a, 0 ; `xor a` would overwrite flags
	ldh [rIF], a ; No point in backing up that register, it's always changing
	halt ; With interrupts disabled, this will exit when `IE & IF != 0`
	nop ; Handle hardware bug if it becomes true *before* starting to execute the instruction (1-cycle window)

	; We're now in VBlank! So we can now use VRAM as scratch for some cycles

	ld a, 0
	ldh [rLCDC], a ; Turn off LCD so VRAM can always be safely accessed
	; Save regs
	ld [vCrashSP], sp
	ld sp, vCrashSP
	push hl
	push de
	push bc
	ld a, [wCrashA]
	push af
	; We need to have all the data in bank 0, but we can't guarantee we were there
	ldh a, [rVBK]
	ld [vCrashVBK], a
	bit 0, a
	jr z, .bank0
	; Oh noes. We need to copy the data across banks!
	ld [vCrashDumpScreen], a ; Use this as a scratch byte
	ld hl, vCrashAF
	ld c, 5 * 2
.copyAcross
	ld b, [hl]
	xor a
	ldh [rVBK], a
	ld [hl], b
	inc l ; inc hl
	inc a ; ld a, 1
	ldh [rVBK], a
	dec c
	jr nz, .copyAcross
	ld a, [vCrashDumpScreen]
	ld hl, rVBK
	ld [hl], 0
.bank0
	ld [vCrashVBK], a

	; Kill sound for this screen
	xor a
	ldh [rNR52], a

	inc a ; ld a, 1
	ldh [rVBK], a
	ld hl, vCrashDumpScreen
	ld b, SCRN_Y_B
.writeAttrRow
	xor a
	ld c, SCRN_X_B + 1
	rst MemsetSmall
	ld a, l
	add a, SCRN_VX_B - SCRN_X_B - 1
	ld l, a
	dec b
	jr nz, .writeAttrRow
	xor a
	ldh [rVBK], a

	; Load palettes
	ld a, $03
	ldh [rBGP], a
	ld a, $80
	ldh [rBCPS], a
	xor a
	ld c, LOW(rBCPD)
	ldh [c], a
	ldh [c], a
	dec a ; ld a, $FF
REPT 3 * 2
	ldh [c], a
ENDR
	; TODO: SGB palettes?

	ld a, SCRN_VY - SCRN_Y
	ldh [rSCY], a
	ld a, SCRN_VX - SCRN_X - 4
	ldh [rSCX], a

	; Copy 1bpp font, compressed using PB8 by PinoBatch
	ld hl, .font
	ld de, $9000
INCLUDE "res/crash_font.1bpp.pb8.size"
	ld c, NB_PB8_BLOCKS
	PURGE NB_PB8_BLOCKS
.pb8BlockLoop
	; Register map for PB8 decompression
	; HL: source address in boot ROM
	; DE: destination address in VRAM
	; A: Current literal value
	; B: Repeat bits, terminated by 1000...
	; C: Number of 8-byte blocks left in this block
	; Source address in HL lets the repeat bits go straight to B,
	; bypassing A and avoiding spilling registers to the stack.
	ld b, [hl]
	inc hl

	; Shift a 1 into lower bit of shift value.  Once this bit
	; reaches the carry, B becomes 0 and the byte is over
	scf
	rl b

.pb8BitLoop
	; If not a repeat, load a literal byte
	jr c,.pb8Repeat
	ld a, [hli]
.pb8Repeat
	; Decompressed data uses colors 0 and 3, so write twice
	ld [de], a
	inc e ; inc de
	ld [de], a
	inc de
	sla b
	jr nz, .pb8BitLoop

	dec c
	jr nz, .pb8BlockLoop

	; Copy the registers to the dump viewers
	ld hl, vDumpHL
	ld de, vCrashHL
	ld c, 4
	rst MemcpySmall

	; We're now going to draw the screen, top to bottom
	ld hl, vCrashDumpScreen

	; First 3 lines of text
	ld de, .header
	ld b, HEADER_HEIGHT
.writeHeaderLine
	ld a, " "
	ld [hli], a
	ld c, HEADER_WIDTH
	rst MemcpySmall
	ld a, " "
	ld [hli], a
	ld a, l
	add a, SCRN_VX_B - HEADER_WIDTH - 2
	ld l, a
	dec b
	jr nz, .writeHeaderLine

	; Blank line
	ld a, " "
	ld c, SCRN_X_B + 1
	rst MemsetSmall

	; AF and console model
	ld l, LOW(vCrashDumpScreen.row4)
	ld c, 4
	rst MemcpySmall
	pop bc
	call .printHexBC
	ld c, 8
	rst MemcpySmall
	ldh a, [hConsoleType]
	call .printHexA
	ld a, " "
	ld [hli], a
	ld [hli], a
	ld [hli], a

	; BC and DE
	ld l, LOW(vCrashDumpScreen.row5)
	ld c, 4
	rst MemcpySmall
	pop bc
	call .printHexBC
	ld c, 6
	rst MemcpySmall
	pop bc
	call .printHexBC
	ld a, " "
	ld [hli], a
	ld [hli], a
	ld [hli], a

	; Now, the two memory dumps
.writeDump
	ld a, l
	add a, SCRN_VX_B - SCRN_X_B - 1
	ld l, a
	ld c, 4
	rst MemcpySmall
	pop bc
	push bc
	call .printHexBC
	ld de, .viewStr
	ld c, 7
	rst MemcpySmall
	pop de
	call .printDump
	ld de, .spStr
	bit 7, l
	jr z, .writeDump

	ld de, .hwRegsStrs
	ld l, LOW(vCrashDumpScreen.row14)
	ld c, 6
	rst MemcpySmall
	ld a, [wCrashLCDC]
	call .printHexA
	ld c, 4
	rst MemcpySmall
	ldh a, [rKEY1]
	call .printHexA
	ld c, 4
	rst MemcpySmall
	ld a, [wCrashIE]
	call .printHexA
	ld [hl], " "

	ld l, LOW(vCrashDumpScreen.row15)
	ld c, 7
	rst MemcpySmall
.writeBank
	ld a, " "
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	cp " "
	jr z, .banksDone
	ld a, [de]
	inc de
	ld c, a
	ld a, [de]
	inc de
	ld b, a
	ld a, [bc]
	call .printHexA
	jr .writeBank
.banksDone

	ld l, LOW(vCrashDumpScreen.row16)
	ld [hli], a
	ld de, BuildDate
	ld c, 19
.writeBuildDate
	ld a, [de]
	inc de
	; Build date is in ASCII, translate it to our custom encoding
	sub $30
	cp 10
	jr c, .digit
	add a, $13
.digit
	ld [hli], a
	dec c
	jr nz, .writeBuildDate
	ld a, " "
	ld [hli], a

	ld l, LOW(vCrashDumpScreen.row17)
	ld c, SCRN_X_B + 1
	rst MemsetSmall

	; Start displaying
	ld a, LCDCF_ON | LCDCF_BG9C00 | LCDCF_BGON
	ldh [rLCDC], a

	xor a
	ld [vWhichDump], a
	ld [vHeldKeys], a ; Mark all keys as "previously held"
	ld a, 30
	ld [vUnlockCounter], a
.loop
	; The code never lags, and IE is equal to IEF_VBLANK
	xor a
	ldh [rIF], a
	halt

	; Poll joypad
	ld c, LOW(rP1)
	ld a, P1F_GET_DPAD
	call .poll
	ld b, a
	swap b
	ld a, P1F_GET_BTN
	call .poll
	and b
	ld b, a
	ld a, $30
	ldh [c], a

	ld hl, vHeldKeys
	ld a, [hl]
	cpl
	or b
	ld c, a ; Buttons pressed just now
	ld a, b
	ld [hli], a

	assert vHeldKeys + 1 == vUnlockCounter
	ld a, [hli]
	and a
	jr z, .unlocked
	ld a, b
	and PADF_B | PADF_A
	jr nz, .loop
	dec hl
	dec [hl]
	jr .loop
.unlocked
	assert vUnlockCounter + 1 == vWhichDump
	bit PADB_B, c
	ld a, [hl]
	jr nz, .noDumpSwitch
	xor 2
	ld [hl], a
.noDumpSwitch
	ld b, a

	scf
	adc a, l
	ld l, a
	adc a, h
	sub l
	ld h, a
	; Process input, compute 16-bit offset to add to current addr
	ld de, 0
	bit PADB_START, c
	jr nz, .noInc
	inc de
.noInc
	rlc c ; Check if Down was pressed
	jr c, .noDown
	ld a, [vHeldKeys]
	rra ; Carry reset iff A held
	sbc a, a
	cpl
	or $0F ; $FF if held, $0F otherwise
	ld e, a
	; ld d, 0
	inc de
.noDown
	rlc c ; Check if Up was pressed
	jr c, .noUp
	ld a, [vHeldKeys]
	rra ; Carry reset iff A held
	sbc a, a
	and $F0 ; $00 if held, $F0 otherwise
	ld e, a
	ld d, $FF
.noUp
	; Add offset to cur address, and store back
	ld a, [hl]
	add a, e
	ld e, a
	ld [hli], a
	ld a, [hl]
	adc a, d
	ld d, a
	ld [hl], a

	; Compute pointer to "view:" number
	rrc b ; 0 or 1
	ld a, b
	xor HIGH(vCrashDumpScreen.row5 + 47)
	ld h, a
	ld a, b
	rrca ; 0 or $80
	xor LOW(vCrashDumpScreen.row5 + 47)
	ld l, a
	call .printDump

	; Now, let's highlight the selected dump region
	ld a, [vWhichDump] ; 0 or 2
	swap a ; 0 or 32
	add a, 56
	ld e, a
	ld c, LOW(rBCPD)
	ld a, $86
	ldh [rBCPS], a
.wait
	ldh a, [rLY]
	cp e
	jr nz, .wait
	; CGB pal is more critical because it can only be written during Mode 0
	ld a, LOW($294A)
	ldh [c], a
	ld a, HIGH($294A)
	ldh [c], a
	ld a, $43
	ldh [rBGP], a
	ld a, e
	add a, 3 * 8
	ld e, a
	ld a, $86
	ldh [rBCPS], a
.waitAfter
	ldh a, [rLY]
	sub e
	jr nz, .waitAfter
	dec a ; ld a, $FF
	ldh [c], a
	ldh [c], a
	ld a, $03
	ldh [rBGP], a
	jp .loop

.poll
	ldh [c], a
REPT 6
	ldh a, [c]
ENDR
	or $F0
	ret

.printHexBC
	call .printHexB
	ld a, c
.printHexA
	ld b, a
.printHexB
	ld a, b
	and $F0
	swap a
	ld [hli], a
	ld a, b
	and $0F
	ld [hli], a
	ret

.printDump
	ld b, d
	ld c, e
	call .printHexBC
	ld a, " "
	ld [hli], a
	ld [hli], a
	ld a, e
	sub 8
	ld e, a
	sbc a, a
	add a, d
	ld d, a
.writeDumpLine
	ld a, l
	add a, SCRN_VX_B - SCRN_X_B - 1
	ld l, a
	ld a, " "
	ld [hli], a
.writeDumpWord
	ld a, [de]
	inc de
	call .printHexA
	ld a, [de]
	inc de
	call .printHexA
	ld a, " "
	ld [hli], a
	bit 4, l
	jr nz, .writeDumpWord
	ld a, l
	and $7F
	jr nz, .writeDumpLine
	ret

.font
INCBIN "res/crash_font.1bpp.pb8"

.header
	;   0123456789ABCDEFGHI  19 chars
	db "GAME CRASH!! Please"
	db "send a clear pic of"
	db "this screen to devs"

	assert @ - .header == HEADER_WIDTH * HEADER_HEIGHT

	db " AF:"
	db "  Model:"
	db " BC:"
	db "   DE:"
	db " HL:"
.viewStr
	db "  View:"
.spStr
	db " SP:"
.hwRegsStrs
	db " LCDC:"
	db " K1:"
	db " IE:"
	db "  Bank:", "R", LOW(hCurROMBank), HIGH(hCurROMBank), "V", LOW(vCrashVBK), HIGH(vCrashVBK), "W", LOW(rSVBK), HIGH(rSVBK), " "

; This is made to be as small as possible, since the footprint of this should be minimal
; Unfortunately, I don't think I can do better
SECTION "Crash handler scratch", WRAM0

wCrashA: db ; We need at least one working register, and A allows accessing memory
wCrashIE: db
wCrashLCDC: db

SECTION UNION "9C00 tilemap", VRAM[$9C00],BANK[0]

; Put the crash dump screen at the bottom-right of the 9C00 tilemap, since that tends to be unused space
	ds SCRN_VX_B * (SCRN_VY_B - SCRN_Y_B - 2) ; 2 rows reserved as scratch space

	ds SCRN_X_B ; Try not to overwrite the window area
	ds 2 * 1 ; Free stack entries (we spill into the above by 1 entry, though :/)
	; These are the initial values of the registers
	; They are popped off the stack when printed, freeing up stack space
vCrashAF: dw
vCrashBC: dw
vCrashDE: dw
vCrashHL: dw
vCrashSP: dw

	ds SCRN_X_B
vHeldKeys: db ; Keys held on previous frame
vUnlockCounter: db ; How many frames until dumps are "unlocked"
vWhichDump: db
vDumpHL: dw
vDumpSP: dw
vCrashVBK: db
	ds 4 ; Unused

	ds SCRN_VX_B - SCRN_X_B - 1
vCrashDumpScreen:
	ds SCRN_X_B + 1
ROW = 0
	REPT SCRN_Y_B - 1
ROW = ROW + 1
ROW_LABEL equs ".row{d:ROW}"
		ds SCRN_VX_B - SCRN_X_B - 1
	ROW_LABEL
		ds SCRN_X_B + 1
		PURGE ROW_LABEL
	ENDR
