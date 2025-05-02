; SGB packet types
rsreset
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
