GenRandom: ; 0x959
	push bc
	push de
	push hl
	ld a, [wRNGPointer]
	ld c, a
	ld b, $0
	inc a
	cp 54 + 1
	jr nz, .asm_96e
	; We've reached the end of the array, reroll the RNG and loop back to the start.
	call UpdateRNG
	xor a
	ld bc, $0000
.asm_96e
	ld [wRNGPointer], a
	ld hl, wRNGValues
	add hl, bc
	ld a, [hl]
	pop hl
	pop de
	pop bc
	ret

ResetRNG: ; 0x97a
	ld a, [wRNGModulus]
	ld d, a
	; [wRNGSub] = [sRNGMod] % [wRNGModulus]
	ld a, [sRNGMod]
.modulo
	cp d
	jr c, .okay
	sub d
	jr .modulo

.okay
	ld [wRNGSub], a
	ld [wRNGSub2], a
	ld e, $1
	ld hl, .Data
	ld a, 54
.init_prng
	push af
	ld c, [hl]
	inc hl
	ld b, $0
	push hl
	ld hl, wRNGValues
	add hl, bc
	ld [hl], e
	ld a, [wRNGSub]
	sub e
	jr nc, .next
	add d
.next
	ld e, a
	ld a, [hl]
	ld [wRNGSub], a
	pop hl
	pop af
	dec a
	jr nz, .init_prng
	call UpdateRNG
	call UpdateRNG
	call UpdateRNG
	call GenRandom
	ld [sRNGMod], a
	ret

.Data
; offsets from wRNGValues
	db $14, $29, $07, $1c, $31, $0f, $24, $02, $17
	db $2c, $0a, $1f, $34, $12, $27, $05, $1a, $2f
	db $0d, $22, $00, $15, $2a, $08, $1d, $32, $10
	db $25, $03, $18, $2d, $0b, $20, $35, $13, $28
	db $06, $1b, $30, $0e, $23, $01, $16, $2b, $09
	db $1e, $33, $11, $26, $04, $19, $2e, $0c, $21

UpdateRNG: ; 0x9fa
; Adjusts the RNG values using wRNGModulus
	ld a, [wRNGModulus]
	ld d, a
 ; for i in range(24): [d812+i] = ([d812+i] - [d831]) % [d810]
	ld bc, wRNGValues
	ld hl, wRNGValues + $1f
	ld e, $18
.loop
	ld a, [bc]
	sub [hl]
	jr nc, .no_carry
	add d
.no_carry
	ld [bc], a
	inc bc
	dec e
	jr nz, .loop
 ; for i in range(31): [d82a+i] = ([d82a+i] - [d812]) % [d810]
	ld bc, wRNGValues + $18 ; d82a
	ld hl, wRNGValues
	ld e, $1f
.loop2
	ld a, [bc]
	sub [hl]
	jr nc, .no_carry2
	add d
.no_carry2
	ld [bc], a
	inc bc
	dec e
	jr nz, .loop2
	ret

RandomRange: ; 0xa21
; Random value 0 <= x <= a, generated as float rounded to nearest u8
	push bc
	rlca
	ld b, a
	call GenRandom
	ld c, a
	call MultiplyBbyCUnsigned
	inc b
	srl b
	ld a, b
	pop bc
	ret
