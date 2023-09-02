    .include "hud.inc"
    .include "nes.inc"
    .include "ppu.inc"

PPUCTRL_BASE = VBLANK_NMI | NT_2000 | OBJ_1000 | BG_0000

OAM_POS_X  = 3
OAM_POS_Y  = 0
OAM_TILE_ID = 1
OAM_ATTR    = 2

OAM_BASE = $0200

    .segment "RAM"
playfield_pixel_x: .res 1
playfield_nametable: .res 1

    .segment "PRGFIXED_C000"

.proc init_sprite_zero
    lda #240
    sta OAM_BASE + OAM_POS_X
    lda #38
    sta OAM_BASE + OAM_POS_Y
    lda #0
    sta OAM_BASE + OAM_ATTR
    lda #0
    sta OAM_BASE + OAM_TILE_ID

    rts
.endproc

.proc debug_scroll_playfield
    inc playfield_pixel_x
    bne done
    inc playfield_nametable
done:
    rts
.endproc

.proc perform_hud_split
    lda PPUSTATUS

    ; set PPUSCROLL to 0,192 to display the HUD (and also align a sprite zero hit)
    lda #0
    sta PPUSCROLL
    lda #192
    sta PPUSCROLL
    lda #PPUCTRL_BASE
    sta PPUCTRL

    ; wait for sprite zero hit to clear, so we are sure we've left NMI
spr0_clear_loop:
    bit PPUSTATUS
    bvs spr0_clear_loop

    ; wait for sprite zero hit to SET, so we know it is time to make our change
spr0_set_loop:
    bit PPUSTATUS
    bvc spr0_set_loop

    ; spin a bit here, just to ensure that we clear the 
    ; visible scanline we triggered on before we perform the X adjustment

    .repeat 10
    nop
    .endrepeat

    ; write PPUCTRL and PPUSCROLL with the new X position (Y position will be ignored)
    lda playfield_pixel_x
    sta PPUSCROLL
    sta PPUSCROLL ; ignored
    lda playfield_nametable
    and #%00000011
    ora #PPUCTRL_BASE
    sta PPUCTRL

    rts    
.endproc