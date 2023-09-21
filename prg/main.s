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
        .include "scrolling.inc"
        .include "sound.inc"
        .include "sprites.inc"
        .include "word_util.inc"
        .include "zeropage.inc"

.segment "PRGFIXED_C000"

test_animation:
    ;.include "../build/animations/floaty-crystal-test.anim.incs"
    .include "../build/animations/robot-idle.anim.incs"

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

        lda #1
        sta NmiSoftDisable

        lda #(VBLANK_NMI)
        sta PPUCTRL
        cli ; enable interrupts

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

        
        ; FOR NOW, do demo init of our first level
        jsr demo_init_map

        ; Now with valid HUD graphics, it should be safe to
        ; enable normal NMI things

        lda #0
        sta NmiSoftDisable

        ; now enable rendering and proceed to the main game loop
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | BG_0000 | OBJ_1000)
        sta PPUCTRL

        jsr init_demo_metasprite

main_loop:
        jsr poll_input

        jsr reset_oam
        jsr update_animations
        jsr draw_metasprites

        jsr debug_scroll_playfield
        jsr wait_for_next_vblank

        jmp main_loop


.proc init_demo_metasprite
        ldx #0

        set_animation robot_idle_anim

        lda #METASPRITE_ACTIVE
        sta metasprite_table + MetaSpriteState::Flags, x

        lda #50
        sta metasprite_table + MetaSpriteState::ScreenPosX, x
        lda #0
        sta metasprite_table + MetaSpriteState::ScreenPosX+1, x

        lda #50
        sta metasprite_table + MetaSpriteState::ScreenPosY, x
        lda #0
        sta metasprite_table + MetaSpriteState::ScreenPosY+1, x

        lda #1
        sta metasprite_table + MetaSpriteState::BaseTileId, x
        lda #0
        sta metasprite_table + MetaSpriteState::Palette, x        

        rts
.endproc