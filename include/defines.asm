
; First, let's include libraries

INCLUDE "hardware.inc/hardware.inc"
	rev_Check_hardware_inc 4.0

INCLUDE "rgbds-structs/structs.asm"


; A couple more hardware defines

def NB_SPRITES equ 40


; `ld b, X` followed by `ld c, Y` is wasteful (same with other reg pairs).
; This writes to both halves of the pair at once, without sacrificing readability
; Example usage: `lb bc, X, Y`
MACRO lb
	assert -128 <= (\2) && (\2) <= 255, "Second argument to `lb` must be 8-bit!"
	assert -128 <= (\3) && (\3) <= 255, "Third argument to `lb` must be 8-bit!"
	ld \1, (LOW(\2) << 8) | LOW(\3)
ENDM


; SGB packet types
RSRESET
def PAL01     rb 1
def PAL23     rb 1
def PAL12     rb 1
def PAL03     rb 1
def ATTR_BLK  rb 1
def ATTR_LIN  rb 1
def ATTR_DIV  rb 1
def ATTR_CHR  rb 1
def SOUND     rb 1 ; $08
def SOU_TRN   rb 1
def PAL_SET   rb 1
def PAL_TRN   rb 1
def ATRC_EN   rb 1
def TEST_EN   rb 1
def ICON_EN   rb 1
def DATA_SND  rb 1
def DATA_TRN  rb 1 ; $10
def MLT_REQ   rb 1
def JUMP      rb 1
def CHR_TRN   rb 1
def PCT_TRN   rb 1
def ATTR_TRN  rb 1
def ATTR_SET  rb 1
def MASK_EN   rb 1
def OBJ_TRN   rb 1 ; $18
def PAL_PRI   rb 1

def SGB_PACKET_SIZE equ 16

; sgb_packet packet_type, nb_packets, data...
MACRO sgb_packet
def PACKET_SIZE equ _NARG - 1 ; Size of what's below
	db (\1 << 3) | (\2)
	REPT _NARG - 2
		SHIFT
		db \2
	ENDR

	ds SGB_PACKET_SIZE - PACKET_SIZE, 0
ENDM


; 64 bytes, should be sufficient for most purposes. If you're really starved on
; check your stack usage and consider setting this to 32 instead. 16 is probably not enough.
def STACK_SIZE equ $40


; Use this to cause a crash.
; I don't recommend using this unless you want a condition:
; `call cc, Crash` is 3 bytes (`cc` being a condition); `error cc` is only 2 bytes
; This should help minimize the impact of error checking
MACRO error
	IF _NARG == 0
		rst Crash
	ELSE
		assert Crash == $0038
		; This assembles to XX FF (with XX being the `jr` instruction)
		; If the condition is fulfilled, this jumps to the operand: $FF
		; $FF encodes the instruction `rst $38`!
		jr \1, @+1
	ENDC
ENDM
