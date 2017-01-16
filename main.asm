INCLUDE "gbhw.inc"
INCLUDE "tiles.inc"
INCLUDE "moved-address-fix\\moved-address-fix.asm"


; VRAM Offsets
VRO_HEX_CHAR EQU $F0

; Tile Addresses
TILE_LOADING_START EQU $E0
TILE_LOADING_END EQU $E2
TILE_LOADING_EMPTY EQU $E1
TILE_LOADING_PARTIAL EQU $E3
TILE_LOADING_FULL EQU $E4

; Background positions
BG_POS_CART_PROMPT EQU _SCRN0 + 1 + (SCRN_VY_B * 3)
BG_POS_CART_TITLE EQU _SCRN0 + 2 + (SCRN_VY_B * 5)
BG_POS_DUMP_STATUS EQU _SCRN0 + 0 + (SCRN_VY_B * 13)
BG_POS_LOADING_BAR EQU _SCRN0 + 1 + (SCRN_VY_B * 15)

; Booleans
TRUE EQU 1
FALSE EQU 0

; Cart header locations
CART_TITLE EQU $0134
CART_TITLE_LEN EQU 15
CART_NINTY_LOGO EQU $0104
CART_NINTY_LOGO_LEN EQU CART_TITLE - CART_NINTY_LOGO

; HRAM Variable locations
VAR_CART_IN EQU _HRAM+0
VAR_TX_TIMER EQU _HRAM+1
VAR_CURRENT_BANK EQU _HRAM+2
VAR_DUMP_PROGRESS EQU _HRAM+3
VAR_COUNT EQU 4

; RAM CONST locations (don't shuffle the lines below)
RC_START EQU _RAM + $0FFF
RC_NINTY_LOGO_LEN EQU CART_NINTY_LOGO_LEN
RC_NINTY_LOGO EQU RC_START - RC_NINTY_LOGO_LEN
RC_NO_CART_STR_LEN EQU CART_TITLE_LEN
RC_NO_CART_STR EQU RC_NINTY_LOGO - RC_NO_CART_STR_LEN
RC_DUMP_STATUS_LINES_LEN EQU 20 * 5
RC_DUMP_STATUS_LINES EQU RC_NO_CART_STR - RC_DUMP_STATUS_LINES_LEN


SECTION "Org $100",HOME[$100]
	nop
	jp	initialise

  ROM_HEADER "CART DUMPER  NP", ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

	; Include GABY Memory Manipulation Code
  INCLUDE "memory.asm"

initialise:
	di
	ld	sp, $ffff ; init stack pointer

	; turn the display off
	call StopLCD

	ld	a, $e4
	ld	[rBGP], a ; set background palette

	ld  a, 0 ; init scroll registers
	ld  [rSCX], a
	ld  [rSCY], a

	; Zero out HRAM (where I store vars)
	ld   	a, 0
	ld   	hl, _HRAM
	ld  	bc, VAR_COUNT
	call	mem_Set

	;; VRAM loads
	; load font to vram (Comes in two tile sets)
	ld   	hl, IBMPC1_1
	ld 		de, _VRAM
	ld		bc, 16*IBMPC1_1Len
	call	mem_Copy
	ld   	hl, IBMPC1_2
	ld 		de, _VRAM + 16*IBMPC1_1Len
	ld		bc, 16*IBMPC1_2Len
	call	mem_Copy
	; load hex-chars tiles to vram
	ld   	hl, HexChars
	ld 		de, _VRAM + $0f00
	ld		bc, 16*HexCharsLen
	call	mem_Copy
	; load the loading bar tiles to vram
	ld   	hl, LoadingBar
	ld 		de, $8e00
	ld		bc, 16*LoadingBarLen
	call	mem_Copy

	;; Clear the background
	ld   	a, $20 ; $20 = blank tile
	ld   	hl, _SCRN0
	ld  	bc, SCRN_VX_B * SCRN_VY_B
	call	mem_Set

	;; Initialise background map
	; Draw ROM title
	ld      hl, RomTitle
	ld      de, _SCRN0
	ld      bc, 20
	call    mem_Copy
	; Draw cart prompt
	ld      hl, CartPrompt
	ld      de, BG_POS_CART_PROMPT
	ld      bc, 10
	call    mem_Copy
	; Draw empty loading bar
	ld      hl, EmptyLoadingBar
	ld      de, BG_POS_LOADING_BAR
	ld      bc, 18
	call    mem_Copy

	;; Copy code & data to gameboy RAM
	; Copy mainloop to RAM
	ld      hl, $4000
	ld      de, _RAM
	ld      bc, $0FFF ; Hopefully bigger than the compiled size of my code...
	call    mem_Copy
	; Fix jump/call addresses in RAM
	ld      hl, _RAM 	; pCodeStart
	ld      de, $8000 ; pOffset
	ld      bc, $0FFF ; pCodeLengthBytes
	call		updateMovedAddresses
	; Copy Nintendo logo to RAM (to compare and check carts are in)
	ld      hl, CART_NINTY_LOGO
	ld      de, RC_NINTY_LOGO
	ld      bc, RC_NINTY_LOGO_LEN
	call    mem_Copy
	; Copy no-cart string to RAM
	ld      hl, NoCart
	ld      de, RC_NO_CART_STR
	ld      bc, RC_NO_CART_STR_LEN
	call    mem_Copy
	; Copy dump status lines to RAM
	ld      hl, DumpStatusLines
	ld      de, RC_DUMP_STATUS_LINES
	ld      bc, RC_DUMP_STATUS_LINES_LEN
	call    mem_Copy

	;; Turn screen on
	ld      a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJOFF
	ld      [rLCDC],a

	;; jump to copied code in ram
	jp _RAM

;; Functions in ROM
; *** Turn off the LCD display ***
StopLCD:
	ld      a,[rLCDC]
	rlca                    ; Put the high bit of LCDC into the Carry flag
	ret     nc              ; Screen is off already. Exit.
; Loop until we are in VBlank
.stopWait:
	ld      a,[rLY]
	cp      145             ; Is display on scan line 145 yet?
	jr      nz, .stopWait        ; no, keep waiting
	; Turn off the LCD
	ld      a,[rLCDC]
	res     7,a             ; Reset bit 7 of LCDC
	ld      [rLCDC],a
	ret

;; Data only needed when loading
RomTitle:
	DB $DB, $B2, $B1, $B0
	DB "Cart Dumper!"
	DB $B0, $B1, $B2, $DB
CartPrompt:
	DB "Cartridge:"
EmptyLoadingBar:
	DB TILE_LOADING_START, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY
	DB TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY
	DB TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_EMPTY, TILE_LOADING_END

;; Data that will be copied to the top end of RAM
NoCart:
	DB "<No Cartridge> "
DumpStatusLines:
	DB "  Insert Cartridge  "
	DB " Ready, press Start "
	DB "     Dumping...     "
	DB "   Dump complete!   "
	DB "   No link cable?   "




SECTION "Code for RAM",CODE[$4000]
	nop
.mainLoop:
	nop
	; Loop until vblank status flag is set
.vblankWait:
	ld a, [rSTAT]
	and $03
	cp STATF_VB
	jr nz, .vblankWait

.VRAMStuff:
	lcd_WaitVRAM

;; Drawing
	; Check for cart
	ld a, [VAR_CART_IN]
	cp TRUE
	jr nz, .noCartDraw
	; If cart inserted, draw cart title
	call DrawCartTitle
	jr .cartTitleEnd
.noCartDraw:
	; Draw the no-cart title
	call DrawNoCartTitle
.cartTitleEnd:

	; Draw some debug info
	call DrawDebug

	; Test if a valid cart is attached
	call ValidCartTest

;; ROM Extraction
	ld a, [VAR_CART_IN]
	cp TRUE
	jr nz, .noExtract
	;; Extract ROM if Start pressed and there's a cart in
	ld a, P1F_4
	ld [rP1], a
	ld a, [rP1]
	ld a, [rP1]
	and PADF_START
	call z, DumpRomViaSerial
.noExtract:

	jp .mainLoop

;; Functions for RAM
; *** All debug display code ***
DrawDebug::
	; Draw SB
	ld a, [rSB]
	and $0f
	add VRO_HEX_CHAR
	ld [$9A33], a ; low nibble
	ld a, [rSB]
	swap a
	and $0f
	add VRO_HEX_CHAR
	ld [$9A32], a ; high nibble
	ret

; *** Draw the cartridge title ***
DrawCartTitle::
	ld hl, CART_TITLE ; Cart title location in rom
	ld de, BG_POS_CART_TITLE
	ld bc, CART_TITLE_LEN
	inc	b
	inc	c
	jr	.ctSkip
.cartTitleLoop	ld a,[hl+]
	cp 0
	jr nz, .writeChar ; if not zero go straight to draw
	ld a, $20 ; load a with $20 = space
.writeChar ld	[de], a
	inc	de
.ctSkip	dec	c
	jr	nz, .cartTitleLoop
	dec	b
	jr	nz, .cartTitleLoop
	; Draw the ready dump status line
	ld a, 1
	call SetDumpStatusLine
	ret

; *** Draw the no-cart string as the cartridge title ***
DrawNoCartTitle::
	ld hl, RC_NO_CART_STR
	ld de, BG_POS_CART_TITLE
	ld bc, CART_TITLE_LEN
	inc	b
	inc	c
	jr	.nctSkip
.nctLoop	ld	a,[hl+]
	ld	[de],a
	inc	de
.nctSkip	dec	c
	jr	nz, .nctLoop
	dec	b
	jr	nz, .nctLoop
	; Draw the insert-cart dump status line
	ld a, 0
	call SetDumpStatusLine
	ret

; *** Set the dump status line using a as the index ***
SetDumpStatusLine::
	ld hl, RC_DUMP_STATUS_LINES
	; Add line offset
	; a*20
	add a,a
	add a,a
	ld b,a
	add a,a
	add a,a
	add a,b
	; make a 16bit a
	ld b, 0
	ld c, a
	add hl, bc ; do offset
	ld de, BG_POS_DUMP_STATUS ; Set position of the line
	ld bc, SCRN_X_B ; Amount of data to copy (line length)
	inc	b
	inc	c
	jr	.jumpStart
.loop:
	lcd_WaitVRAM ; wait for lcd
	ld	a, [hl+]
	ld	[de], a
	inc	de
.jumpStart	dec	c
	jr	nz, .loop
	dec	b
	jr	nz, .loop
	ret

; *** Check if a valid cartridge is inserted, if so, set VAR_CART_IN = TRUE ***
ValidCartTest::
	ld a, FALSE
	ld [VAR_CART_IN], a ; Default to FALSE
	LD HL, CART_NINTY_LOGO	; Compare cartridge Nintendo logo
	LD DE, RC_NINTY_LOGO		; To the one copied into ram at the start
.logoCmpLoop:
	LD A,[DE] ; a = RC_NINTY_LOGO[de]
	INC DE		; de++
	CP [HL]		; a == CART_NINTY_LOGO[hl]
	JR NZ, .endLogoCmpLoop ; if not a match, break out leaving cart_in=false
	INC HL		; hl++
	LD A, L		;
	CP $34		; Loop until L = $34 (meaning HL=$0134, 48 bytes after CART_TITLE($0104))
	JR NZ, .logoCmpLoop
.validCart:
	ld a, TRUE
	ld [VAR_CART_IN], a
.endLogoCmpLoop:
	ret

; *** Dump the contents of the cartridge via the serial port ***
DumpRomViaSerial::
	; Draw the dumping dump status line
	ld a, 2
	call SetDumpStatusLine
	; Start extract routine (ROM-only currently)
	ld a, 0
	ld [VAR_CURRENT_BANK], a ; zero the current bank
	ld hl, $0000 ; start at the beginning...
	ld bc, $8000 ; end of both ROM banks (okay for cart type 0)
	inc	b
	inc	c
	jr	.txJumpStart
.txLoop:
	call DrawProgress
	call DebugExtractAddress
	;; Send byte via serial
  ld a,[hl+]
	ld	[rSB], a ; Put byte in serial buffer
	ld a, 0
	ld [VAR_TX_TIMER], a ; zero the tx timer
	ld a, $81
	ld [rSC], a ; Start transfer, using internal clock
.txCheck:
	ld a, [rSC]
	BIT 7, a ; Test transfer flag
	jr z, .txDone ; if zero, skip timer loop
	ld a, [VAR_TX_TIMER] ; inc timer
	inc a ; inc timer
	ld [VAR_TX_TIMER], a ; inc timer
	cp $ff
	jr nz, .txCheck ; if timer != $ff, recheck the tx flag
	; wait for transfer to end...
.txDone:
	; pause a bit between bytes being transferred
	call PostTransmitPause
.txJumpStart	dec	c
	jr	nz, .txLoop
	dec	b
	jr	nz, .txLoop
	call ClearProgressBar
	ret

; *** Use HL to set update the progress ***
DrawProgress::
	call UpdateBankNumber

	;; Increase VAR_DUMP_PROGRESS whenever hl % 0400 == 0 (every 1024 bytes, 16 times per bank)
	ld a, l ; Test low byte
	cp $00
	jr nz, .endNoProgIncr
	ld a, h ; Test high byte
.loopSub sub $04
	jr c, .endNoProgIncr ; h !% 4, so no incr
	jr nz, .loopSub ; keep going
.progInc ld a, [VAR_DUMP_PROGRESS]
	inc a
	ld [VAR_DUMP_PROGRESS], a
.endNoProgIncr

	;; Draw progress bar
	push hl
	push de
		ld hl, BG_POS_LOADING_BAR
		inc hl ; Skip the first tile
		ld a, [VAR_DUMP_PROGRESS]
		ld d, a
		inc d
		lcd_WaitVRAM ; wait for lcd
		ld a, TILE_LOADING_FULL
		jr .jumpStart
.loop ld [hl+], a
.jumpStart dec d
		jr nz, .loop
	pop de
	pop hl

	ret

; *** Use HL to set the current bank number ***
UpdateBankNumber::
	;; Increase bank number whenever hl at $4000 (start of bank 1)
	ld a, h ; Test high byte
	cp $40
	jr nz, .endBankNoIncr
	ld a, l ; Test low byte
	cp $00
	jr nz, .endBankNoIncr
	ld a, [VAR_CURRENT_BANK] ; If HL=$4000 then increment the bank counter
	inc a
	ld [VAR_CURRENT_BANK], a
	call ClearProgressBar
.endBankNoIncr
	ret

; *** Reset the progress bar ***
ClearProgressBar::
	ld a, 0
	ld [VAR_DUMP_PROGRESS], a
	push hl
	push de
		ld hl, BG_POS_LOADING_BAR
		inc hl ; Skip the first tile
		ld d, 16
.loop:
		lcd_WaitVRAM ; wait for lcd
		ld a, TILE_LOADING_EMPTY
		ld [hl+], a
		dec d
		jr nz, .loop
	pop de
	pop hl
	ret

; *** Use HL to set the current bank number ***
DebugExtractAddress::
	ld a,[rSTAT]
	and STATF_BUSY
	ret nz ; return straight away if screen is busy
	; Draw hl
	; H
	ld a, h
	and $0f
	add VRO_HEX_CHAR
	ld [$9a2e], a ; low nibble
	ld a, h
	swap a
	and $0f
	add VRO_HEX_CHAR
	ld [$9a2d], a ; high nibble
	; L
	ld a, l
	and $0f
	add VRO_HEX_CHAR
	ld [$9a30], a ; low nibble
	ld a, l
	swap a
	and $0f
	add VRO_HEX_CHAR
	ld [$9a2f], a ; high nibble
	ret

; *** Pause by looping a few times ***
PostTransmitPause::
	ld a, 0
  ld [VAR_TX_TIMER], a ; zero the tx timer
.loop:	ld a, [VAR_TX_TIMER] ; inc timer
	inc a ; inc timer
	ld [VAR_TX_TIMER], a ; inc timer
	cp $7f ; Amount to loop
	jr nz, .loop
	ret

	; code-end identifier
	DB $DE,$AD,$DE,$AD
