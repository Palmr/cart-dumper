INCLUDE "gbhw.inc"
INCLUDE "ibmpc1.inc"
INCLUDE "hex-chars.inc"

SECTION "Org $100",HOME[$100]
	nop
	jp	begin

  ROM_HEADER      ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

  INCLUDE "memory.asm"

TileData:
	chr_IBMPC1      1,8
HexTiles:
	chr_HEXCHARS

HEX_CHAR_VRAM_OFFSET EQU $f0

JOY_CHAR EQU _HRAM
CART_IN EQU _HRAM+1
TX_TIMER EQU _HRAM+2
VAR_COUNT EQU 3

CART_NINTY_LOGO EQU $0104
COPY_NINTY_LOGO EQU $CFCF
CART_TITLE EQU $0134

begin:

	di
	ld	sp, $ffff ; init stack pointer
	call StopLCD

	ld	a, $e4
	ld	[rBGP], a ; background palette

	ld  a, 0 ; init scroll registers
	ld  [rSCX], a
	ld  [rSCY], a

	; Zero out HRAM (where I store  vars)
	ld   	a, 0
	ld   	hl, _HRAM
	ld  	bc, VAR_COUNT ; amount of vars
	call	mem_Set

	ld   	hl, TileData ; load tiles to vram
	ld 		de, _VRAM
	ld		bc, 8*256        ; length (8 bytes per tile) x (256 tiles)
	call	mem_CopyMono    ; Copy tile data to memory

	ld   	hl, HexTiles ; load hex-chars tiles to vram
	ld 		de, _VRAM + $0f00
	ld		bc, 8*16        ; length (8 bytes per tile) x (16 tiles)
	call	mem_CopyMono    ; Copy tile data to memory

	ld   	a, $20           ; Fill bg map with spaces
	ld   	hl, _SCRN0
	ld  	bc, SCRN_VX_B * SCRN_VY_B
	call	mem_Set

	ld      hl, Title       ; Draw title
	ld      de, _SCRN0+(SCRN_VY_B*$11)
	ld      bc, 20
	call    mem_Copy

	; copy mainloop to ram
	ld      hl, $4000
	ld      de, _RAM
	ld      bc, $0eff ; roughly enough bytes?
	call    mem_Copy

	; copy Nintendo logo to ram (to compare and check carts are in)
	ld      hl, CART_NINTY_LOGO
	ld      de, COPY_NINTY_LOGO
	ld      bc, 48
	call    mem_Copy


	; Turn screen on
	ld      a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJOFF
	ld      [rLCDC],a

	; jump to copied code in ram
	jp _RAM

Title:
	DB $DB, $B2, $B1, $B0
	DB "Cart Dumper!"
	DB $B0, $B1, $B2, $DB


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

SECTION "MainLoop",CODE[$4000]
	nop
.mainLoop:
		; wait for vblank
.vblankWait:
		ld a, [rSTAT]
		and $03
		cp STATF_VB
		jr nz, .vblankWait

.VRAMStuff:
	lcd_WaitVRAM

	; show cart title
	ld hl, CART_TITLE ; cart title location in rom
	ld de, _SCRN0+3+(SCRN_VY_B*8) ; position on screen to draw to
	ld bc, 15 ; 15 chars
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

	; draw joypad char
	ld a, [JOY_CHAR]
	ld [$9821], a

	; draw cart in char
	ld a, [CART_IN]
	ld [$9841], a

	; draw SB
	ld a, [rSB]
	and $0f
	add HEX_CHAR_VRAM_OFFSET
	ld [$9832], a
	ld a, [rSB] ; high bits
	swap a
	and $0f
	add HEX_CHAR_VRAM_OFFSET
	ld [$9831], a


	; Extract ROM if Start pressed and there's a cart in
	ld a, [CART_IN]
	cp $79 ; ascii y
	jr nz, .endExtract
	ld a, [JOY_CHAR]
	cp $53 ; ascii S
	jr nz, .endExtract
	; start extract routine
	ld hl, $0000 ; start at the beginning...
	ld bc, $8000 ; end of both ROM banks (okay for cart type 0)
	inc	b
	inc	c
	jr	.exSkip
.exLoop	ld a,[hl+]
	ld	[rSB], a ; Put byte in serial buffer
	ld a, 0
	ld [TX_TIMER], a ; zero the tx timer
	ld a, $81
	ld [rSC], a ; Start transfer, using internal clock
.txCheck:
	ld a, [rSC]
	BIT 7, a ; Test transfer flag
	jr z, .tskip ; if zero, skip timer
	ld a, [TX_TIMER] ; inc timer
	inc a ; inc timer
	ld [TX_TIMER], a ; inc timer
	cp $ff
	jr nz, .txCheck ; if timer != $ff, recheck the tx flag
	; wait for transfer to end...
.tskip	ld a, 0
 ld [TX_TIMER], a ; zero the tx timer
	; pause a bit
.postTxPause:	ld a, [TX_TIMER] ; inc timer
	inc a ; inc timer
	ld [TX_TIMER], a ; inc timer
	cp $ff
	jr nz, .postTxPause ; if timer != $ff, recheck the tx flag
.exSkip	dec	c
	jr	nz, .exLoop
	dec	b
	jr	nz, .exLoop
.endExtract:




.ReadJoypad:
	LD A,$20       ;<- bit 5 = $20
	LD [$FF00],A   ;<- select P14 by setting it low
	LD A,[$FF00]   ;
	LD A,[$FF00]   ;<- wait a few cycles
	CPL            ;<- complement A
	AND $0F        ;<- get only first 4 bits
	SWAP A         ;<- swap it
	LD B,A         ;<- store A in B
	LD A,$10       ;
	LD [$FF00],A   ;<- select P15 by setting it low
	LD A,[$FF00]   ;
	LD A,[$FF00]   ;
	LD A,[$FF00]   ;
	LD A,[$FF00]   ;
	LD A,[$FF00]   ;
	LD A,[$FF00]   ;<- Wait a few MORE cycles
	CPL            ;<- complement (invert)
	AND $0F        ;<- get first 4 bits
	OR B           ;<- put A and B together
								 ;
	LD B,A         ;<- store A in D
	LD A,[$FF8B]   ;<- read old joy data from ram
	XOR B          ;<- toggle w/current button bit
	AND B          ;<- get current button bit back
	LD [$FF8C],A   ;<- save in new Joydata storage
	LD A,B         ;<- put original value in A
	LD [$FF8B],A   ;<- store it as old joy data
								 ;
	LD A,$30       ;<- deselect P14 and P15
	LD [$FF00],A   ;<- RESET Joypad
	; Test joypad and put ascii char in b
	ld b, $db
	ld a, [$FF8B]
.start:
	bit PADB_START, a
	jr z, .select
	ld b, $53
.select:
	bit PADB_SELECT, a
	jr z, .btnB
	ld b, $73
.btnB:
	bit PADB_B, a
	jr z, .btnA
	ld b, $62
.btnA:
	bit PADB_A, a
	jr z, .down
	ld b, $61
.down:
	bit PADB_DOWN, a
	jr z, .up
	ld b, $19
.up:
	bit PADB_UP, a
	jr z, .left
	ld b, $18
.left:
	bit PADB_LEFT, a
	jr z, .right
	ld b, $1b
.right:
	bit PADB_RIGHT, a
	jr z, .joyOut
	ld b, $1a
.joyOut:
	ld a, b
	ld [JOY_CHAR], a


	; Test if a valid cart is there (y=$79, n=$6e)
	ld a, $6e
	ld [CART_IN], a ; Default cart in to 'no'
	LD HL, $0104		; point HL to Nintendo logo in cart
	LD DE, COPY_NINTY_LOGO		; point DE to Nintendo logo in DMG rom
.logoCmpLoop:
	LD A,[DE] ; a = copy[de]
	INC DE		; de++
	CP [HL]		; a == cart[hl]
	JR NZ, .endLogoCmpLoop; if not a match, lock up here
	INC HL		; hl++
	LD A, L		;
	CP $34		; $00ed	;do this for $30 bytes
	JR NZ, .logoCmpLoop
.validCart:
	ld a, $79
	ld [CART_IN], a
.endLogoCmpLoop:


	jp _RAM

	; code end-identifier
	DB $ca,$fe,$ba,$be
