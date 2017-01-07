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
	
HEX_CHAR_VRAM EQU $9000
NUM1 EQU $c000
NUM2 EQU $c001
NUM1_POS EQU $9831
NUM2_POS EQU $9832
TM1 EQU $c002
TM2 EQU $c003
CART_TITLE EQU $0134
COPIED_MAIN_LOOP EQU $c004

begin:

	di
	ld	sp, $ffff ; init stack pointer
	call StopLCD

	ld	a, $e4
	ld	[rBGP], a ; background palette

	ld  a, 0 ; init scroll registers
	ld  [rSCX], a
	ld  [rSCY], a

	ld   	hl, TileData ; load tiles to vram
	ld 		de, _VRAM
	ld		bc, 8*256        ; length (8 bytes per tile) x (256 tiles)
	call	mem_CopyMono    ; Copy tile data to memory

	ld   	hl, HexTiles ; load hex-chars tiles to vram
	ld 		de, HEX_CHAR_VRAM
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
	ld      de, $c000
	ld      bc, $0eff ; roughly enough bytes?
	call    mem_Copy
	
	; Set and display numbers
	ld a, $30
	ld [NUM1], a
	ld [NUM2], a
	ld [NUM1_POS], a
	ld [NUM2_POS], a
	
	; Set loop-delay timers to 0
	ld a, $0
	ld [TM1], a
	ld [TM2], a

	; Turn screen on
	ld      a,LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJOFF
	ld      [rLCDC],a       
	
	; jump to copied code in ram
	jp COPIED_MAIN_LOOP

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
		nop
		nop
		nop
		
.mainLoop:
		; wait for vblank
.wait:
		ld a, [rSTAT]
		and $03
		cp STATF_VB
		jr nz, .wait

.drawChars:
	; draw numbers
	lcd_WaitVRAM
	ld a, [NUM1]
	ld [NUM1_POS], a
	ld a, [NUM2]
	ld [NUM2_POS], a

	; show cart title
	lcd_WaitVRAM
	ld hl, CART_TITLE ; cart title location in rom
	ld de, _SCRN0+3+(SCRN_VY_B*8) ; position on screen to draw to
	ld bc, 15 ; 15 chars
	inc	b
	inc	c
	jr	.skip
.loop	ld	a,[hl+]
	cp 0
	jr nz, .draw ; if not zero go straight to draw
	ld a, $20 ; load a with $20 = space
.draw	ld	[de],a
	inc	de
.skip	dec	c
	jr	nz,.loop
	dec	b
	jr	nz,.loop

	;input
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
	; look for start, 18=up, 19=down, 1a=right, 1b=left
	;		$80 - Start             $8 - Down
	;		$40 - Select            $4 - Up
	;		$20 - B                 $2 - Left
	;		$10 - A                 $1 - Right
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
	ld [$9821], a ; draw joypad char


	
	; wait for one val to overflow
	ld a, [TM1]
	inc a
	ld [TM1], a
	cp $ff
	jp nz, COPIED_MAIN_LOOP
	; wait for that 10 times..
	ld a, [TM2]
	inc a
	ld [TM2], a
	cp 1                     ;; np lowered to speed up
	jp nz, COPIED_MAIN_LOOP
	; reset zero timers
	ld a, 0
	ld [TM1], a
	ld [TM2], a

	; inc NUM2
	ld a, [NUM2]
	inc a
	ld [NUM2], a
	
	; reset if over 9...
	cp $3a
	jp nz, COPIED_MAIN_LOOP
	ld a, $30
	ld [NUM2], a
	
	; ...and inc NUM1
	ld a, [NUM1]
	inc a
	ld [NUM1], a
	
	; reset if over 9
	cp $3a
	jp nz, COPIED_MAIN_LOOP
	ld a, $30
	ld [NUM1], a
	
	jp COPIED_MAIN_LOOP
	nop
	nop
	DB $ca,$fe,$ba,$be

