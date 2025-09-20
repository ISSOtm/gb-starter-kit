INCLUDE "defines.inc"


SECTION "SGB routines", ROM0

; Sends SGB packets to the SGB, assuming we're running on one.
; @param  hl: Pointer to the packet data to be sent (can send any number of packets btw)
; @return hl: Points to the end of the packet data
; @return de: 0
; @return bc: 0
; @return a:  0
SendPackets::
    ld a, [hl] ; Length
    and %111
    ret z
    ld c, a

.sendPacket
    call SendPacketNoDelay
    call SGBDelay ; Let the ICD chip rest a bit
    dec c
    jr nz, .sendPacket
    ret


; Sends a SGB packet to the SGB to freeze the screen, assuming we're running on one.
; Does not perform any delay after sending the packet.
; Use only if you're not going to send another SGB packet in the next few frames.
; You're likely to perform some decompression or smth after this
; @param  hl: Pointer to the packet data to be sent.
; @return hl: Points to the end of the packet data
; @return b:  0
; @return d:  0
; @return a:  $30
; @destroy e
FreezeSGBScreen::
    ld hl, FreezeScreenPacket
; Sends a SGB packet to the SGB, assuming it's running on one.
; Does not perform any delay after sending the packet.
; Unsuitable to send multi-packet packets.
; Use only if you're not going to send another SGB packet in the next four frames.
; Assumes the joypad won't be polled by interrupts during this time, but since the VBlank handler doesn't poll except when waited for, this is fine.
; @param  hl: Pointer to the packet data to be sent.
; @return hl: Points to the end of the packet data.
; @return b:  0
; @return d:  0
; @return a:  $30
; @destroy e
SendPacketNoDelay::
    ; Packet transmission begins by sending $00 then $30
    assert JOYP_SGB_START == 0
    xor a
    ldh [rJOYP], a
    ld a, JOYP_SGB_FINISH
    ldh [rJOYP], a
    
    ld b, SGB_PACKET_SIZE
.sendByte
    ld d, 8 ; 8 bits in a byte
    ld a, [hli] ; Read byte to send
    ld e, a

.sendBit
    ld a, JOYP_SGB_ONE ; 1 bits are sent with $10
    rr e  ; Rotate d and get its lower bit, two birds in one stone!
    jr c, .bitSet
    assert JOYP_SGB_ZERO == JOYP_SGB_ONE * 2
    add a, a ; 0 bits are sent with $20
.bitSet
    ldh [rJOYP], a
    ld a, JOYP_SGB_FINISH ; Terminate pulse
    ldh [rJOYP], a
    dec d
    jr nz, .sendBit

    dec b
    jr nz, .sendByte

    ; Packets are terminated by a "STOP" 0 bit
    ld a, $20
    ldh [rJOYP], a
    ld a, JOYP_SGB_FINISH
    ldh [rJOYP], a
    ret

SGBDelay::
    ld de, 7000 ; Magic value, apparently
.loop
    nop
    nop
    nop
    dec de
    ld a, d
    or e
    jr nz, .loop
    ret

FreezeScreenPacket:
    sgb_packet MASK_EN, 1, 1


; Fill the $9C00 tilemap with a pattern suitable for SGB `*_TRN`.
; Also sets up the rendering parameters for the transfer.
; Finally, assumes the LCD is **off**.
; @destroy hl
FillScreenWithSGBMap::
    runtime_assert [rLCDC] & $80 == 0, "`FillScreenWithSGBMap` must be called with LCD off!"
    xor a
    ldh [hSCY], a
    ldh [hSCX], a
    ld b, a ; ld b, 0
    ld hl, $9C00
.writeRow
    ld c, SCREEN_WIDTH
.writeTile
    ld a, b
    ld [hli], a
    inc b
    jr z, .done
    dec c
    jr nz, .writeTile
    ld a, l
    add a, TILEMAP_WIDTH - SCREEN_WIDTH
    ld l, a
    jr nc, .writeRow
    inc h
    jr .writeRow
.done
    ld a, %11100100
    ldh [hBGP], a
SetupSGBLCDC::
    ld a, LCDC_ENABLE | LCDC_WIN_OFF | LCDC_BLOCK01 | LCDC_BG_9C00 | LCDC_OBJ_OFF | LCDC_BG_ON
    ldh [hLCDC], a
    ldh [rLCDC], a
    ret
