
; First, let's include libraries.

INCLUDE "hardware.inc/hardware.inc"
	rev_Check_hardware_inc 4.0

INCLUDE "debugfile.inc/debugfile.inc"
	require_debugfile_inc_v 1.0

INCLUDE "rgbds-structs/structs.inc"


INCLUDE "sgb.inc"


; `ld b, X` followed by `ld c, Y` is wasteful (same with other reg pairs).
; This writes to both halves of the pair at once, without sacrificing readability.
; Example usage: `lb bc, 42, 69`
MACRO lb
	assert -128 <= (\2) && (\2) <= 255, "Second argument to `lb` must be 8-bit!"
	assert -128 <= (\3) && (\3) <= 255, "Third argument to `lb` must be 8-bit!"
	ld \1, (LOW(\2) << 8) | LOW(\3)
ENDM


; Where the current ROM bank number can be read.
; The default value of $7fff is the most friendly to the section packing algorithm,
;   but it can be customised just fine.
def RomBank equ $7fff


; 64 bytes, should be sufficient for most purposes; preferably, keep this even, but not necessarily a power of 2.
; If you're really starved on memory, check your stack usage and consider setting this to 32 instead.
; 16 is unlikely to be enough.
def STACK_SIZE equ 64


; Use this to cause a crash.
; Note that `runtime_assert` may be more ergonomic on emulators, and is less intrusive.
;
; `call cc, Crash` is 3 bytes (`cc` being a condition); `error cc` is only 2 bytes!
; This should help minimize the impact of error checking.
MACRO error
	assert Crash == $0038
	; This assembles to XX FF (with XX being the `jr` instruction).
	; If the condition is fulfilled, this jumps to the operand, which is $FF.
	; And $FF encodes the instruction `rst $38`!
	jr \1, @+1
ENDM
