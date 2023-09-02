    .include "chr.inc"
    .include "nes.inc"
    .include "ppu.inc"
    .include "word_util.inc"
    .include "zeropage.inc"

    .segment "PRG0_8000"

test_chr:
    .incbin "../art/test_chr.chr"
test_palette:
    .incbin "../art/test_pal.pal"
test_nametable:
    .incbin "../art/test_nametable.nam"

.proc FAR_init_palettes
SourceAddr := R0
    lda PPUSTATUS

    st16 SourceAddr, test_palette
    set_ppuaddr #$3F10
    ldy #0
obj_loop:
    lda (SourceAddr), y
    sta PPUDATA
    iny
    cpy #16
    bne obj_loop

    st16 SourceAddr, test_palette
    set_ppuaddr #$3F00
    ldy #0
bg_loop:
    lda (SourceAddr), y
    sta PPUDATA
    iny
    cpy #16
    bne bg_loop

    rts
.endproc

.proc FAR_init_nametable
    rts
.endproc

.proc FAR_init_chr
SourceAddr := R0
Length := R2
    st16 SourceAddr, test_chr
    st16 Length, 8192

    lda PPUSTATUS
    set_ppuaddr #$0000

    ldy #0
loop:
    lda (SourceAddr), y
    sta PPUDATA
    inc16 SourceAddr
    dec16 Length
    lda Length
    ora Length
    bne loop

    rts
.endproc