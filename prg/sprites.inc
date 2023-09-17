.global reset_oam, update_animations, draw_metasprites
.global metasprite_table

SHADOW_OAM = $0200

OAM_POS_Y = 0
OAM_TILE_ID = 1
OAM_ATTR = 2
OAM_POS_X = 3

.struct AnimationEntry
    Duration .byte
    OamTilesPtr .word
.endstruct

.struct OamEntry
    YPos .byte
    TileId .byte
    Attr .byte
    XPos .byte
.endstruct

.struct MetaSpriteState
    ; animation state
    CurrentAnimationPtr .word
    CurrentFramePtr .word
    DelayCounter .byte
    ; position within screen space (camera already applied!)
    ScreenPosX .word
    ScreenPosY .word
    ; misc. state
    Flags .byte
    Palette .byte
    BaseTileId .byte
.endstruct

; note: assumes X points to the desired metasprite state
.macro set_animation animation_ptr
    lda #<animation_ptr
    sta metasprite_table + MetaSpriteState::CurrentAnimationPtr, x
    lda #>animation_ptr
    sta metasprite_table + MetaSpriteState::CurrentAnimationPtr+1, x

    lda #<(animation_ptr - .sizeof(AnimationEntry))
    sta metasprite_table + MetaSpriteState::CurrentFramePtr, x
    lda #>(animation_ptr - .sizeof(AnimationEntry))
    sta metasprite_table + MetaSpriteState::CurrentFramePtr+1, x

    lda #0
    sta metasprite_table + MetaSpriteState::DelayCounter, x
.endmacro

METASPRITE_ACTIVE = %10000000
METASPRITE_HFLIP  = %01000000
