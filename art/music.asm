; Dn-FamiTracker exported music data: music.dnm
;

; Module header
	.word ft_song_list
	.word ft_instrument_list
	.word ft_sample_list
	.word ft_samples
	.word ft_groove_list
	.byte 0 ; flags
	.word 3600 ; NTSC speed
	.word 3000 ; PAL speed
	.word 1 ; N163 channels

; Instrument pointer list
ft_instrument_list:
	.word ft_inst_0
	.word ft_inst_1

; Instruments
ft_inst_0:
	.byte 9
	.byte $11
	.word ft_seq_n163_0
	.word ft_seq_n163_9
	.byte $10
	.byte $00
	.word ft_waves_1

ft_inst_1:
	.byte 0
	.byte $11
	.word ft_seq_2a03_0
	.word ft_seq_2a03_4

; Sequences
ft_seq_2a03_0:
	.byte $11, $FF, $0B, $00, $0F, $0F, $0F, $0F, $0D, $0C, $0B, $09, $07, $06, $06, $02, $02, $01, $01, $01
	.byte $00
ft_seq_2a03_4:
	.byte $01, $FF, $00, $00, $02
ft_seq_n163_0:
	.byte $11, $FF, $0B, $00, $0F, $0F, $0F, $0F, $0D, $0C, $0B, $09, $07, $06, $06, $02, $02, $01, $01, $01
	.byte $00
ft_seq_n163_9:
	.byte $01, $FF, $00, $00, $00

; N163 waves
ft_waves_1:
	.byte $10, $32, $54, $76, $98, $BA, $DC, $FE, $10, $32, $54, $76, $98, $BA, $DC, $FE
	.byte $10, $32, $54, $76, $98, $BA, $DC, $FE, $10, $32, $54, $76, $98, $BA, $DC, $FE
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte $10, $32, $54, $76, $98, $BA, $DC, $FE, $EF, $CD, $AB, $89, $67, $45, $23, $01

; DPCM instrument list (pitch, sample index)
ft_sample_list:

; DPCM samples list (location, size, bank)
ft_samples:

; Groove list
ft_groove_list:
	.byte $00
; Grooves (size, terms)

; Song pointer list
ft_song_list:
	.word ft_song_0
	.word ft_song_1
	.word ft_song_2

; Song info
ft_song_0:
	.word ft_s0_frames
	.byte 1	; frame count
	.byte 64	; pattern length
	.byte 6	; speed
	.byte 150	; tempo
	.byte 0	; groove position
	.byte 0	; initial bank

ft_song_1:
	.word ft_s1_frames
	.byte 1	; frame count
	.byte 64	; pattern length
	.byte 3	; speed
	.byte 150	; tempo
	.byte 0	; groove position
	.byte 0	; initial bank

ft_song_2:
	.word ft_s2_frames
	.byte 1	; frame count
	.byte 64	; pattern length
	.byte 6	; speed
	.byte 150	; tempo
	.byte 0	; groove position
	.byte 0	; initial bank


;
; Pattern and frame data for all songs below
;

; Bank 0
ft_s0_frames:
	.word ft_s0f0
ft_s0f0:
	.word ft_s0p0c0, ft_s0p0c0, ft_s0p0c0, ft_s0p0c0, ft_s0p0c0, ft_s0p0c0
; Bank 0
ft_s0p0c0:
	.byte $00, $3F

; Bank 0
ft_s1_frames:
	.word ft_s1f0
ft_s1f0:
	.word ft_s1p0c0, ft_s0p0c0, ft_s0p0c0, ft_s0p0c0, ft_s1p0c5, ft_s0p0c0
; Bank 0
ft_s1p0c0:
	.byte $00, $07, $E1, $F8, $25, $01, $7E, $0D, $F8, $25, $01, $7E, $0D, $F8, $25, $01, $7E, $0D, $F8, $25
	.byte $01, $7E, $05

; Bank 0
ft_s1p0c5:
	.byte $E0, $19, $01, $7E, $0D, $19, $01, $7E, $0D, $19, $01, $7E, $0D, $19, $01, $7E, $0D

; Bank 0
ft_s2_frames:
	.word ft_s2f0
ft_s2f0:
	.word ft_s0p0c0, ft_s0p0c0, ft_s0p0c0, ft_s0p0c0, ft_s2p0c5, ft_s0p0c0
; Bank 0
ft_s2p0c5:
	.byte $E0, $F1, $19, $3F


; DPCM samples (located at DPCM segment)
