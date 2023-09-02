        .setcpu "6502"
;
; NES (1.0) header
; http://wiki.nesdev.com/w/index.php/INES
;
.segment "HEADER"
        .byte "NES", $1a
        .byte $04               ; 4x 16KB PRG-ROM banks = 64 KB total
        .byte $00               ; 0x 8KB CHR-ROM banks = 32 KB total
        .byte $C1, $18          ; Mapper 28 (Action53) w/ battery-backed RAM
        .byte $00               ; 0k of PRG RAM
        .byte $00               ;
        .byte $00
        .byte $09
        .byte $00
        .byte $00
        .byte $00
        .byte $00

