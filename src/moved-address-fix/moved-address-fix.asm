INCLUDE "moved-address-fix/opcode-length-LUT.asm"

;***************************************************************************
;*
;* updateMovedAddresses - Walk through bytecount bytes from pDest and update
;*                        addresses for jump/call instructions
;*
;* input:
;*   hl - pCodeStart
;*   de - pOffset
;*   bc - pCodeLengthBytes
;*
;***************************************************************************
updateMovedAddresses::
	ld a, 1
	inc	b
	inc	c
	jr	.jumpStart
.loop	ld	a, [hl] ; a = opcode
	;; Test opcode for fixing
	push de
	cp $C3 ; a == jp nn ?
	jr z, .fixAddress
	cp $CD ; a == call nn ?
	jr z, .fixAddress
	ld d, a ; backup a into d
	and %11100111 ; Mask for all non-cc bits
	cp $C2 ; a == jp cc nn ?
	jr z, .fixAddress
	ld a, d ; restore a from d
	and %11100111 ; Mask for all non-cc bits
	cp $C4 ; a == call cc nn ?
	jr z, .fixAddress
	pop de
	jr .skipOverParams

.fixAddress:
	pop de ; This remained on the stack as we jumped here from the opcode test, fix?
	; Add pOffset to next two bytes (least significant byte first)
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
	push de
	push hl
		;; Look up opcode length
		ld hl, OpcodeLengthLUT
		ld d, 0
		ld e, a ; de = padded opcode
		add hl, de ; &LUT + opcode
		ld a, [hl] ; e = *LUT (op length)
	pop hl
	pop de ; restore de back to pOffset

.paramLoop	inc hl
.jumpStart: 	dec c
	jr nz, .nextParam
	dec b
	jr nz, .nextParam
	jr .end
.nextParam: dec a
	jr nz, .paramLoop
	jr .loop
.end:	ret
