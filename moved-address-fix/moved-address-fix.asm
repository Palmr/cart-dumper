INCLUDE "moved-address-fix\\opcode-length-LUT.asm"

; jp nn				: 11 000 011 : 0xC3
; jp cc, nn		: 11 0cc 010 : 0xE7(mask) & 0xC2
; call nn			: 11 001 101 : 0xCD
; call cc, nn	: 11 0cc 100 : 0xE7(mask) & 0xC4

;***************************************************************************
;*
;* updateMovedAddresses - Walk through bytecount bytes from pDest and update
;*												addresses for jump/call instructions
;*
;* input:
;*   hl - pCodeStart
;*   de - pOffset
;*   bc - pCodeLengthBytes
;*
;***************************************************************************
updateMovedAddresses::
	nop 
	nop
	nop

	ld a, 1
	inc	b
	inc	c
	jr	.jumpStart
.loop	ld	a, [hl] ; a = opcode
	push de
	push hl
		;; Look up opcode length
		ld hl, OpcodeLengthLUT
		ld d, 0
		ld e, a ; de = 16bit a
		add hl, de ; &LUT + a
		ld e, [hl] ; e = *LUT (op length)
	pop hl
	;; Test it for fixing
	cp $C3 ; a == jp nn ?
	jr z, .fixAddress
	cp $CD ; a == call nn ?
	jr z, .fixAddress
	ld d, a ; backup a
	and %11100111 ; Mask for all non-cc bits
	cp $C2 ; a == jp cc nn ?
	jr z, .fixAddress
	ld a, d ; restore a
	and %11100111 ; Mask for all non-cc bits
	cp $C4 ; a == call cc nn ?
	jr z, .fixAddress
	ld a, e ; a = *LUT (op length)
	pop de ; restore de back to pOffset
	jr .skipOverParams
.fixAddress:
	ld a, e ; a = *LUT (op length)
	pop de ; restore de back to pOffset
	; Add de to next two bytes
	push af
	push hl
		inc hl ; Skip past the opcode
		; Add low bytes
		ld a, [hl]
		add e
		ld [hl], a
		; Add (with carry) high bytes
		inc hl
		ld a, [hl]
		adc d
		ld [hl], a
	pop hl
	pop af
.skipOverParams:
	inc hl
.jumpStart: 	dec c
	jr nz, .nextParam
	dec b
	jr nz, .nextParam
	jr .end
.nextParam: dec a
	jr nz, .skipOverParams
	jr .loop
.end:	ret
