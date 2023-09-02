    .include "longbranch.inc"
    .include "scrolling.inc"
    .include "vram_buffer.inc"
    .include "word_util.inc"
    .include "zeropage.inc"

    .segment "PRGFIXED_C000"

all_levels:
    .include "../build/levels/test.incs"

.struct LevelHeader
    width .byte
.endstruct

TEST_LEVEL_RAW_DATA = level_test + .sizeof(LevelHeader)


; note: all drawing functions expect the vram buffer
; to already be set up, with the destination PPUADDR
; contained in that header

; X should be the next position to write into the vram buffer

.proc draw_column_left_half_tiles
MapColumnPtr := R0

    ; the top 4 tiles are in the HUD region, so we intentionally
    ; do not draw them
    ; (the topmost tile technically is offscreen, logically; it's whatever)
    ldy #4
loop:
    lda (MapColumnPtr), y
    ; multiply by 4 to obtain base background tile index
    asl
    asl
    ; top-left is position 0
    sta VRAM_TABLE_START, x
    inx
    ; bottom-left is position 2
    clc
    adc #2
    sta VRAM_TABLE_START, x
    inx
    iny
    cpy #16
    bne loop
    
    rts
.endproc

.proc draw_column_right_half_tiles
MapColumnPtr := R0

    ; the top 4 tiles are in the HUD region, so we intentionally
    ; do not draw them
    ; (the topmost tile technically is offscreen, logically; it's whatever)
    ldy #4
loop:
    lda (MapColumnPtr), y
    ; multiply by 4 to obtain base background tile index
    asl
    asl
    ; top-left is position 1
    clc
    adc #1
    sta VRAM_TABLE_START, x
    inx
    ; bottom-left is position 3
    clc
    adc #2
    sta VRAM_TABLE_START, x
    inx
    iny
    cpy #16
    bne loop
    
    rts
.endproc

.proc draw_column_attributes
    rts
.endproc

; call this with rendering disabled!

.proc demo_init_map
MapColumnPtr := R0
PpuAddrTiles := R2
PpuAddrAttributes := R4
ColCounter := R6

    st16 MapColumnPtr, TEST_LEVEL_RAW_DATA
    st16 PpuAddrTiles, $20C0
    ; TODO PpuAddrAttributes!

    lda #8
    sta ColCounter

loop:
    ; attributes
    ; TODO: this!

    ; left half of column 0
    write_vram_header_ptr PpuAddrTiles, #24, VRAM_INC_32
    ldx VRAM_TABLE_INDEX
    jsr draw_column_left_half_tiles
    stx VRAM_TABLE_INDEX
    inc VRAM_TABLE_ENTRIES
    inc16 PpuAddrTiles

    ; right half of column 0
    write_vram_header_ptr PpuAddrTiles, #24, VRAM_INC_32
    ldx VRAM_TABLE_INDEX
    jsr draw_column_right_half_tiles
    stx VRAM_TABLE_INDEX
    inc VRAM_TABLE_ENTRIES
    inc16 PpuAddrTiles

    add16b MapColumnPtr, #16

    ; left half of column 1
    write_vram_header_ptr PpuAddrTiles, #24, VRAM_INC_32
    ldx VRAM_TABLE_INDEX
    jsr draw_column_left_half_tiles
    stx VRAM_TABLE_INDEX
    inc VRAM_TABLE_ENTRIES
    inc16 PpuAddrTiles

    ; right half of column 1
    write_vram_header_ptr PpuAddrTiles, #24, VRAM_INC_32
    ldx VRAM_TABLE_INDEX
    jsr draw_column_right_half_tiles
    stx VRAM_TABLE_INDEX
    inc VRAM_TABLE_ENTRIES
    inc16 PpuAddrTiles

    add16b MapColumnPtr, #16

    ; process the vram buffer here, otherwise we'll fill it up
    ; and smash our stack

    jsr vram_slowboat

    ; TODO: would loop here
    dec ColCounter
    jne loop

    rts
.endproc