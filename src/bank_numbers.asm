INCLUDE "defines.inc"

IF !def(NB_BANKS)
	def NB_BANKS equ 256
ENDC

FOR rom_bank, 1, NB_BANKS
	SECTION "ROM bank {rom_bank} number", ROMX[RomBank],BANK[rom_bank]
		db rom_bank
ENDR
