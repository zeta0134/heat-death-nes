        .setcpu "6502"

        .include "debug.inc"
        .include "chr.inc"
        .include "far_call.inc"
        .include "input.inc"
        .include "hud.inc"
        .include "main.inc"
        .include "memory_util.inc"
        .include "nes.inc"
        .include "ppu.inc"
        .include "prng.inc"
        .include "sound.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.segment "PRGFIXED_C000"

.proc wait_for_next_vblank
        debug_color 0
        inc GameloopCounter
@loop:
        lda LastNmi
        cmp GameloopCounter
        bne @loop
        rts
.endproc

start:
        lda #$00
        sta PPUMASK ; disable rendering
        sta PPUCTRL ; and NMI

        ; Clear out main memory regions
        st16 R0, ($0200)
        st16 R2, ($0600)
        jsr clear_memory

        ; disable unusual IRQ sources
        lda #%01000000
        sta $4017 ; APU frame counter
        lda #0
        sta $4010 ; DMC DMA

        jsr init_audio

        lda #2
        jsr play_track

        far_call FAR_init_palettes
        far_call FAR_init_nametable
        far_call FAR_init_chr

        jsr init_sprite_zero

        ; initialize the prng seed to a nonzero value
        lda #1
        sta seed

        ; now enable rendering and proceed to the main game loop
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | BG_0000 | OBJ_1000)
        sta PPUCTRL

        cli ; enable interrupts

main_loop:
        jsr poll_input

        jsr debug_scroll_playfield
        jsr wait_for_next_vblank

        jmp main_loop


