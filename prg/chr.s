    .include "chr.inc"
    .include "nes.inc"
    .include "ppu.inc"
    .include "word_util.inc"
    .include "zeropage.inc"

    .segment "PRG0_8000"

test_chr:
    .incbin "../art/test_chr.chr"

.proc FAR_init_palettes
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