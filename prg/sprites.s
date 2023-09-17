    .include "nes.inc"
    .include "ppu.inc"
    .include "sprites.inc"
    .include "word_util.inc"
    .include "zeropage.inc"

.segment "RAM"

MAX_METASPRITES = 12

metasprite_table: .res ::MAX_METASPRITES * .sizeof(MetaSpriteState)
current_oam_entry: .res 1

.segment "PRGFIXED_C000"

.proc reset_oam
    ; set Y-pos to $FF for all sprites EXCEPT sprite zero (!!)
    ldx #4
    lda #$FF
loop:
    sta SHADOW_OAM, x
    .repeat 4
    inx
    .endrepeat
    bne loop

    ; TODO: if we're going to do sprite shuffling, this is
    ; the place to initialize it
    lda #4
    sta current_oam_entry

    rts
.endproc

.macro next_oam_entry
    ; for now, just advance by 4, later if we do sprite shuffling apply
    ; that offset here instead
    clc
    lda #4
    adc current_oam_entry
    sta current_oam_entry
.endmacro

.proc update_animations
CurrentMetaspriteIndex := R0
CurrentAnimationPtr := R1
    ; process frame delay and update metasprite pointers
    lda #0
    sta CurrentMetaspriteIndex
loop:
    ldx CurrentMetaspriteIndex
    lda metasprite_table + MetaSpriteState::Flags, x
    and #METASPRITE_ACTIVE
    beq next_metasprite

    lda metasprite_table + MetaSpriteState::DelayCounter, x
    beq advance_frame
    dec metasprite_table + MetaSpriteState::DelayCounter, x
    jmp next_metasprite

advance_frame:
    clc
    lda metasprite_table + MetaSpriteState::CurrentFramePtr, x
    adc #.sizeof(AnimationEntry)
    sta CurrentAnimationPtr
    lda metasprite_table + MetaSpriteState::CurrentFramePtr+1, x
    adc #0
    sta CurrentAnimationPtr+1

    ldy #AnimationEntry::Duration
    lda (CurrentAnimationPtr), y
    ; have we reached the end of the list?
    cmp #$FF
    beq loop_animation
    ; if not, this must be our delay byte, so set that up
    sta metasprite_table + MetaSpriteState::DelayCounter, x
    lda CurrentAnimationPtr
    sta metasprite_table + MetaSpriteState::CurrentFramePtr, x
    lda CurrentAnimationPtr+1
    sta metasprite_table + MetaSpriteState::CurrentFramePtr+1, x
    jmp next_metasprite

loop_animation:
    lda metasprite_table + MetaSpriteState::CurrentAnimationPtr, x
    sta metasprite_table + MetaSpriteState::CurrentFramePtr, x
    sta CurrentAnimationPtr
    lda metasprite_table + MetaSpriteState::CurrentAnimationPtr+1, x
    sta metasprite_table + MetaSpriteState::CurrentFramePtr+1, x
    sta CurrentAnimationPtr+1
    ldy #AnimationEntry::Duration
    lda (CurrentAnimationPtr), y
    sta metasprite_table + MetaSpriteState::DelayCounter, x

next_metasprite:
    clc
    lda #.sizeof(MetaSpriteState)
    adc CurrentMetaspriteIndex
    sta CurrentMetaspriteIndex
    cmp #(.sizeof(MetaSpriteState) * MAX_METASPRITES)
    bne loop

    rts
.endproc

.proc draw_metasprites
CurrentMetaspriteIndex := R0
CurrentAnimationPtr := R1
OamTilesPtr := R3
    ; draw every active metasprite to its onscreen position
    lda #0
    sta CurrentMetaspriteIndex
loop:
    ldx CurrentMetaspriteIndex
    lda metasprite_table + MetaSpriteState::Flags, x
    and #METASPRITE_ACTIVE
    beq next_metasprite

    lda metasprite_table + MetaSpriteState::CurrentFramePtr, x
    sta CurrentAnimationPtr
    lda metasprite_table + MetaSpriteState::CurrentFramePtr+1, x
    sta CurrentAnimationPtr+1

    ldy #AnimationEntry::OamTilesPtr
    lda (CurrentAnimationPtr), y
    sta OamTilesPtr
    iny
    lda (CurrentAnimationPtr), y
    sta OamTilesPtr+1

    ; TODO: if this metasprite is horizontally flipped, this is where
    ; we could branch to the alternate tile drawing routine
    jsr draw_oam_tiles

next_metasprite:
    clc
    lda #.sizeof(MetaSpriteState)
    adc CurrentMetaspriteIndex
    sta CurrentMetaspriteIndex
    cmp #(.sizeof(MetaSpriteState) * MAX_METASPRITES)
    bne loop

    rts
.endproc

; TODO: we need a separate version of this to deal with horizontal flips
.proc draw_oam_tiles
CurrentMetaspriteIndex := R0
CurrentAnimationPtr := R1
OamTilesPtr := R3
NumTiles := R5
TilePosX := R7
TilePosY := R8
    ldy #0
    lda (OamTilesPtr), y
    sta NumTiles
    inc16 OamTilesPtr

loop:
    ldx CurrentMetaspriteIndex
    ldy #OamEntry::XPos
    clc
    lda (OamTilesPtr), y
    adc metasprite_table + MetaSpriteState::ScreenPosX, x
    sta TilePosX
    lda #0
    adc metasprite_table + MetaSpriteState::ScreenPosX + 1, x
    ; if the result is not on our current screen, bail
    bne next_tile
    ; no need to store the high byte, we won't use it to draw

    ldy #OamEntry::YPos
    clc
    lda (OamTilesPtr), y
    adc metasprite_table + MetaSpriteState::ScreenPosY, x
    sta TilePosY
    lda #0
    adc metasprite_table + MetaSpriteState::ScreenPosY + 1, x
    ; if the result is not on our current screen, bail
    bne next_tile
    ; no need to store the high byte, we won't use it to draw

    ; at this point we are confident we will be drawing this sprite,
    ; so copy the two coordinates into place
    ldx current_oam_entry
    lda TilePosX
    sta SHADOW_OAM + OAM_POS_X, x
    lda TilePosY
    sta SHADOW_OAM + OAM_POS_Y, x

    ; the tile ID is a straight copy pretty much
    ldx CurrentMetaspriteIndex
    lda metasprite_table + MetaSpriteState::BaseTileId, x
    clc
    ldy #OamEntry::TileId
    adc (OamTilesPtr), y
    ldx current_oam_entry
    sta SHADOW_OAM + OAM_TILE_ID, x

    ; attributes are a wee bit trickier
    ; though in this case we can leave the upper flip bits alone
    ldx CurrentMetaspriteIndex
    lda metasprite_table + MetaSpriteState::Palette, x
    clc
    ldy #OamEntry::Attr
    adc (OamTilesPtr), y
    ldx current_oam_entry
    sta SHADOW_OAM + OAM_ATTR, x

    next_oam_entry

next_tile:
    add16b OamTilesPtr, #4
    dec NumTiles
    bne loop

    rts
.endproc