    .include "longbranch.inc"
    .include "scrolling.inc"
    .include "vram_buffer.inc"
    .include "word_util.inc"
    .include "zeropage.inc"

    .segment "PRGFIXED_C000"

all_levels:
    .include "../build/levels/test.incs"

TILE_TYPE_AIR   = (0 << 2)
TILE_TYPE_SOLID = (1 << 2)

PAL_0 = 0
PAL_1 = 1
PAL_2 = 2
PAL_3 = 3

tile_attributes:
    .byte TILE_TYPE_AIR   | PAL_0 ; "air"
    .byte TILE_TYPE_SOLID | PAL_1 ; "wall"

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

; expects MapColumnPtr to point to the top-left of a 
; 2-column pair. Will compute and write attribute bytes
; to the vram buffer, efficiently combining transfers
; where possible

; TODO: see if we can make this a subroutine, it would
; save a LOT of ROM space. We don't care that badly about
; the speed, this won't be called very often.

.macro compute_single_attribute_byte offset
    ldy #LEFT_COL + offset + 0
    lda (MapColumnPtr), y
    tay
    lda tile_attributes, y
    and #%00000011 ; A contains palette bits for top-left tile
    sta AttributeByte

    ldy #RIGHT_COL + offset + 0
    lda (MapColumnPtr), y
    tay
    lda tile_attributes, y
    and #%00000011 ; A contains palette bits for top-right tile
    .repeat 2
    asl
    .endrepeat
    ora AttributeByte
    sta AttributeByte

    ldy #LEFT_COL + offset + 1
    lda (MapColumnPtr), y
    tay
    lda tile_attributes, y
    and #%00000011 ; A contains palette bits for bottom-left tile
    .repeat 4
    asl
    .endrepeat
    ora AttributeByte
    sta AttributeByte

    ldy #RIGHT_COL + offset + 1
    lda (MapColumnPtr), y
    tay
    lda tile_attributes, y
    and #%00000011 ; A contains palette bits for bottom-right tile
    .repeat 6
    asl
    .endrepeat
    ora AttributeByte
.endmacro

.proc draw_column_attributes
MapColumnPtr := R0
StartingPpuAddr := R2
AttributeByte := R4

    ; we need to skip past the first 4 rows, as they are
    ; not drawn, but do still exist (and affect gameplay)
    LEFT_COL = 0 + 4
    RIGHT_COL = 16 + 4

    ; attributes 0 and 4
    write_vram_header_ptr StartingPpuAddr, #2, VRAM_INC_32
    ldx VRAM_TABLE_INDEX
    compute_single_attribute_byte 0
    sta VRAM_TABLE_START, x
    inx
    compute_single_attribute_byte 8
    sta VRAM_TABLE_START, x
    inx
    stx VRAM_TABLE_INDEX
    inc VRAM_TABLE_ENTRIES

    add16b StartingPpuAddr, #8

    ; attributes 1 and 5
    write_vram_header_ptr StartingPpuAddr, #2, VRAM_INC_32
    ldx VRAM_TABLE_INDEX
    compute_single_attribute_byte 2
    sta VRAM_TABLE_START, x
    inx
    compute_single_attribute_byte 10
    sta VRAM_TABLE_START, x
    inx
    stx VRAM_TABLE_INDEX
    inc VRAM_TABLE_ENTRIES

    add16b StartingPpuAddr, #8

    ; attribute 2
    write_vram_header_ptr StartingPpuAddr, #1, VRAM_INC_32
    ldx VRAM_TABLE_INDEX
    compute_single_attribute_byte 4
    sta VRAM_TABLE_START, x
    inx
    stx VRAM_TABLE_INDEX
    inc VRAM_TABLE_ENTRIES

    add16b StartingPpuAddr, #8

    ; attribute 3
    write_vram_header_ptr StartingPpuAddr, #1, VRAM_INC_32
    ldx VRAM_TABLE_INDEX
    compute_single_attribute_byte 6
    sta VRAM_TABLE_START, x
    inx
    stx VRAM_TABLE_INDEX
    inc VRAM_TABLE_ENTRIES
    
    rts
.endproc

; call this with rendering disabled!

.proc demo_init_map
MapColumnPtr := R0
StartingPpuAddrAttributes := R2

PpuAddrTiles := R6
PpuAddrAttributes := R8
ColCounter := R10

    st16 MapColumnPtr, TEST_LEVEL_RAW_DATA
    st16 PpuAddrTiles, $2000
    st16 PpuAddrAttributes, $23C0

    lda #8
    sta ColCounter

loop:
    ; attributes
    mov16 StartingPpuAddrAttributes, PpuAddrAttributes
    jsr draw_column_attributes
    inc16 PpuAddrAttributes

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