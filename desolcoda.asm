

;CHEAT_SHOW_ROOM_NUMBER  EQU 1
;CHEAT_ALL_ACCESS        EQU 1
;CHEAT_ALL_INVENTORY     EQU 1
;CHEAT_HAVE_WEAPON       EQU 1
;CHEAT_HEALTH_999        EQU 1


;TODO:  ORG $5FB4   ; = 24500
  ORG $5E00

start:
  call LBA07  ; Show titles and go to Menu

; Cheat code to get all door access codes
IF DEFINED CHEAT_ALL_ACCESS
  LD HL,LDCA2
  LD B,$48
start_1:
  LD (HL),$01
  INC HL
  DJNZ start_1
ENDIF

; Cheat code to have all inventory items
IF DEFINED CHEAT_ALL_INVENTORY
  LD HL,LDB9C
  LD B,26
start_2:
  LD (HL),$01
  INC HL
  DJNZ start_2
ENDIF

; Cheat code to have the weapon
IF DEFINED CHEAT_HAVE_WEAPON
  ld a,$01
  ld (LDCF7),a
ENDIF

IF DEFINED CHEAT_HEALTH_999
  ld hl,999
  ld (LDB7A),hl
ENDIF

;  call LB0A2  ; Inventory
;  call LBBEC  ; Info menu item, show Controls
;  call LBADE  ; New game
;  call LBB7E  ; Game start
;  call LB9A2  ; Player is dead
;  call LBD85  ; Final
;  call LBF6F  ; The End

;  call ShowScreen
;  call ClearScreen

;  ld ix,Tileset3+32*2
;  ld e,0
;  ld l,0
;  call DrawTile

;  ld ix,Tileset2+32*$20
;  ld e,0
;  ld l,0
;  call DrawTileMasked

;  call ClearPenRowCol
;  ld hl,87
;  call DrawNumber5
;  call WaitAnyKey

;  call ShowShadowScreen

;  call WaitAnyKey
;  call ClearShadowScreen
;  call ShowShadowScreen
  jp start

;----------------------------------------------------------------------------

  INCLUDE "desolfont.asm"

  INCLUDE "desolstrs.asm"

  INCLUDE "desoldata.asm"

;----------------------------------------------------------------------------
DesolateCodeBeg:

; Wait for any key
WaitAnyKey:
  call ReadKeyboard
  or a
  jr nz,WaitAnyKey	; Wait for unpress
WaitAnyKey_1:
  call ReadKeyboard
  or a
  jr z,WaitAnyKey_1	; Wait for press
  ret

; Wait until no key pressed - to put after ReadKeyboard calls to prevent double-reads of the same key
WaitKeyUp:
  call ReadKeyboard
  or a
  jr nz,WaitKeyUp	; Wait for unpress
  ret

; Source: http://www.breakintoprogram.co.uk/computers/zx-spectrum/keyboard
; Returns: A=key code, $00 no key; Z=0 for key, Z=1 for no key
; Key codes: Down=$01, Left=$02, Right=$03, Up=$04, Look/shoot=$05
;            Inventory=$06, Escape=$07, Switch look/shoot=$08, Enter=$09, Menu=$0F
ReadKeyboard:
  LD HL,ReadKeyboard_map  ; Point HL at the keyboard list
  LD D,8                ; This is the number of ports (rows) to check
  LD C,$FE              ; C is always FEh for reading keyboard ports
ReadKeyboard_0:        
  LD B,(HL)             ; Get the keyboard port address from table
  INC HL                ; Increment to list of keys
  IN A,(C)              ; Read the row of keys in
  AND $1F               ; We are only interested in the first five bits
  LD E,5                ; This is the number of keys in the row
ReadKeyboard_1:        
  SRL A                 ; Shift A right; bit 0 sets carry bit
  JR NC,ReadKeyboard_2  ; If the bit is 0, we've found our key
  INC HL                ; Go to next table address
  DEC E                 ; Decrement key loop counter
  JR NZ,ReadKeyboard_1  ; Loop around until this row finished
  DEC D                 ; Decrement row loop counter
  JR NZ,ReadKeyboard_0  ; Loop around until we are done
  xor a                 ; Clear A (no key found)
  RET
ReadKeyboard_2:
  LD A,(HL)             ; We've found a key at this point; fetch the character code!
  or a
  RET
; Mapping:
;   QAOP/1234/6789 - arrows, Space/B/M/N/Z/0/5 - look/shoot
;   S/D - switch look/shoot, W/E - escape, U/I - inventory; G - menu, Enter=Enter
ReadKeyboard_map:
  DB &FE, $00,$05,$00,$00,$00   ; Shift,"Z","X","C","V"
  DB &FD, $01,$08,$08,$00,$0F   ;   "A","S","D","F","G"
  DB &FB, $04,$07,$07,$00,$00   ;   "Q","W","E","R","T"
  DB &F7, $02,$03,$01,$04,$05   ;   "1","2","3","4","5"
  DB &EF, $06,$04,$01,$03,$02   ;   "0","9","8","7","6"
  DB &DF, $03,$02,$06,$06,$00   ;   "P","O","I","U","Y"
  DB &BF, $09,$00,$00,$00,$00   ; Enter,"L","K","J","H"
  DB &7F, $05,$00,$05,$05,$05   ; Space,Sym,"M","N","B"

; ZX screen address list used to copy shadow screen lines on the ZX screen
ScreenAddrs:
  DW $40A4,$42A4,$44A4,$46A4,$40C4,$42C4,$44C4,$46C4
  DW $40E4,$42E4,$44E4,$46E4,$4804,$4A04,$4C04,$4E04
  DW $4824,$4A24,$4C24,$4E24,$4844,$4A44,$4C44,$4E44
  DW $4864,$4A64,$4C64,$4E64,$4884,$4A84,$4C84,$4E84
  DW $48A4,$4AA4,$4CA4,$4EA4,$48C4,$4AC4,$4CC4,$4EC4
  DW $48E4,$4AE4,$4CE4,$4EE4,$5004,$5204,$5404,$5604
  DW $5024,$5224,$5424,$5624,$5044,$5244,$5444,$5644
  DW $5064,$5264,$5464,$5664,$5084,$5284,$5484,$5684

; Compare HL and DE
CpHLDE:
  push hl
  or a
  sbc hl,de
  pop hl
  ret

; Get shadow screen address using penCol in L86D7
;   A = row 0..137
;   (L86D7) = penCol
; Returns HL = address
GetScreenAddr:
  push de
  ld l,a
  ld h,$00      ; now HL = A
  add hl,hl     ; now HL = A * 2
  ld e,l
  ld d,h        ; now DE = A * 2
  add hl,hl     ; now HL = A * 4
  add hl,de     ; now HL = A * 6
  add hl,hl     ; now HL = A * 12
  add hl,hl     ; now HL = A * 24
  ld de,ShadowScreen
  add hl,de
  ld a,(L86D7)  ; get penCol
  srl a         ; shift right
  srl a         ;
  srl a         ; now A = column
  ld e,a
  ld d,$00
  add hl,de     ; now HL = line address + column
  pop de
  ret

; Draw tile 16x16 -> 16x16 on shadow screen; see 9EAD in original
;   L = penRow; E = penCol; IX = Tile address
DrawTile:
  ld a,e
  ld (L86D7),a  ; penCol
  ld a,l        ; penRow
  ld b,16       ; 16 rows
  call GetScreenAddr  ; now HL = screen addr
DrawTile_1:
  ld a,(ix+0)
  inc ix
  ld (hl),a     ; write 1st byte
  inc hl
  ld a,(ix+0)
  inc ix
  ld (hl),a     ; write 2nd byte
  ld de,24-1
  add hl,de     ; to the 2nd line
  djnz DrawTile_1
  ret

; Draw tile with mask 16x8 -> 16x16 on ZX screen
;   L = penRow; E = penCol; IX = tile address
DrawTileMasked:
  ld a,e
  ld (L86D7),a  ; penCol
  ld a,l        ; penRow
  ld b,8        ; 8 row pairs
  call GetScreenAddr	; now HL = screen addr
DrawTileMasked_1:
  push bc
; Draw 1st line
  ld a,(ix+$00) ; get mask
  and (hl)
  or (ix+$01)
  ld (hl),a     ; write 1st byte
  inc hl
  ld c,a
  ld a,(ix+$02) ; get mask
  and (hl)
  or (ix+$03)
  ld (hl),a     ; write 2nd byte
  ld b,a
  ld de,24-1
  add hl,de     ; to the 2nd line
; Draw 2nd line
  ld (hl),c     ; write 1st byte
  inc hl
  ld (hl),b     ; write 2nd byte
  ld de,24-1
  add hl,de     ; to the next line
  pop bc
  ld de,$0004
  add ix,de
  djnz DrawTileMasked_1
  ret

; Draw string  on shadow screen using FontProto
;   HL = string addr
DrawString:
  ld a,(hl)
  inc hl
  or a
  ret z
  push hl
  call DrawChar
  pop hl
  jr DrawString

; Draw character on the screen using FontProto
;   A = character to show: $00-$1F space with A width; $20 space
DrawChar:
  push hl
  push bc
  cp $20        ; $00-$1F ?
  jr c,DrawChar_00  ; yes => set char width and process like space char
  jr nz,DrawChar_0  ; not space char => jump
  ld a,$03      ; space char gap size
DrawChar_00:
  ld (DrawChar_width),a
  jp DrawChar_fin
DrawChar_0:
  cp $27        ; char less than apostroph?
  jr nc,DrawChar_1
  add a,$3A     ; for '!', quotes, '#' '$' '%' '&'
  jr DrawChar_2
DrawChar_1:
  cp $2A        ; char less than '*'?
  jr nc,DrawChar_2
  add a,$15     ; for apostroph, '(' ')' chars
DrawChar_2:
  sub $2C       ; font starts from ','
  ld e,a        ; calculating the symbol address
  ld l,a        ;
  ld h,$00      ;
  ld d,h        ;
  add hl,hl     ; now hl = a * 2
  add hl,hl     ; now hl = a * 4
  add hl,de     ; now hl = a * 5
  add hl,hl     ; now hl = a * 10
  add hl,de     ; now hl = a * 11
  ld de,FontProto
  add hl,de     ; now hl = addr of the symbol
  ex de,hl      ; now de=symbol addr
  ld a,(L86D8)  ; get penRow
  ld (DrawChar_row),a
  ld a,(de)     ; get flag/width byte
  inc de
  bit 7,a       ; lowered symbol?
  jr z,DrawChar_3
  ld hl,DrawChar_row
  inc (hl)      ; start on the next line
DrawChar_3:
  and $0f       ; keep width 1..8
  add a,$02     ; gap 2px after the symbol
  ld (DrawChar_width),a
  ld a,(DrawChar_row)
  call GetScreenAddr
  push hl       ; store addr on the screen
  push de       ; store symbol data addr
  ld a,(L86D7)	; get penCol
  and $07       ; shift 0..7
  inc a
  ld c,a
  ld b,10       ; 10 lines
DrawChar_4:     ; loop by lines
  push bc       ; save counter
  ld a,(de)
  inc de
DrawChar_5:     ; loop for shift
  dec c
  jr z, DrawChar_6
  srl a         ; shift right
  jr DrawChar_5
DrawChar_6:
  or (hl)
  ld (hl),a     ; put on the screen
  ld a,(DrawChar_row)
  inc a
  ld (DrawChar_row),a
  call GetScreenAddr
  pop bc        ; restore counter and shift
  djnz DrawChar_4
  pop de        ; restore symbol data addr
  pop hl        ; restore addr on the screen
  ld a,(L86D7)  ; get penCol
  and $7        ; shift 0..7
  ld b,a
  ld a,(DrawChar_width)
  add a,b
  cp $08        ; shift + width <= 8 ?
  jr c,DrawChar_fin	; yes => no need for 2nd pass
; Second pass
  ld a,(L86D7)  ; get penCol
  and $07       ; shift 1..7
  sub $08
  neg           ; a = 8 - shift; result is 1..7
  inc a
  ld c,a
  ld a,(DrawChar_row)
  add a,-10
  ld (DrawChar_row),a
;  call GetScreenAddr
  inc hl
  ld b,10       ; 10 lines
DrawChar_8:     ; loop by lines
  push bc       ; save counter
  ld a,(de)
  inc de
DrawChar_9:     ; loop for shift
  dec c
  jr z, DrawChar_A
  sla a         ; shift left
  jr DrawChar_9
DrawChar_A:
  or (hl)
  ld (hl),a     ; put on the screen
  ld a,(DrawChar_row)
  inc a
  ld (DrawChar_row),a
  call GetScreenAddr
  inc hl
  pop bc        ; restore counter
  djnz DrawChar_8
; All done, finalizing
DrawChar_fin:
  ld hl,L86D7   ; penCol address
  ld a,(DrawChar_width)
  add a,(hl)
  ld (hl),a     ; updating penCol
  pop bc
  pop hl
  ret
DrawChar_width:   DB 0    ; Saved symbol width
DrawChar_row0:    DB 0    ; Saved first row number
DrawChar_row:     DB 0    ; Saved current row number

; Draw decimal number HL in 5 digits
DrawNumber5:
	ld	bc,-10000
	call	DrawNumber_1
	ld	bc,-1000
	call	DrawNumber_1
; Draw decimal number HL in 3 digits
DrawNumber3:
	ld	bc,-100
	call	DrawNumber_1
	ld	c,-10
	call	DrawNumber_1
	ld	c,-1
DrawNumber_1:
	ld	a,'0'-1
DrawNumber_2:
	inc	a
	add	hl,bc
	jr	c,DrawNumber_2
	sbc	hl,bc
	call DrawChar
	ret 

; Copy shadow screen 24*128=3072 bytes to ZX screen using pop/push
; DRAFT version
; See: https://chuntey.wordpress.com/2013/10/02/how-to-write-zx-spectrum-games-chapter-13/
ShowShadowScreen:
  di
  ld (ShowShadowScreen_sp),sp   ; saving SP till the end of the procedure
  ld ix,ScreenAddrs             ; table with ZX line addresses
  ld hl,ShadowScreen            ; shadow screen address
  ld (ShowShadowScreen_src),hl
  ld a,64                       ; 64 line pairs = 128 lines
ShowShadowScreen_1:             ; loop by A
; Calculate and set address arguments for ZX screen lines
  ld l,(ix+$00)
  ld h,(ix+$01)                 ; HL = start of first ZX screen line
  ld bc,12
  add hl,bc                     ; HL = end of 1st half of first ZX screen line
  ld (ShowShadowScreen_3+1),hl  ; set argument
  add hl,bc                     ; HL = end of 2nd half of first ZX screen line
  ld (ShowShadowScreen_5+1),hl  ; set argument
  ld de,$0100-12
  add hl,de                     ; HL = end of 1st half of second ZX screen line
  ld (ShowShadowScreen_7+1),hl  ; set argument
  add hl,bc                     ; HL = end of 2nd half of second ZX screen line
  ld (ShowShadowScreen_9+1),hl  ; set argument
  inc ix
  inc ix
; Calculate and set address arguments for shadow screen lines
  ld hl,(ShowShadowScreen_src)  ; HL = start of first shadow screen line
  ld (ShowShadowScreen_2+1),hl  ; set argument
  add hl,bc                     ; HL = start of 2nd half of first shadow screen line
  ld (ShowShadowScreen_4+1),hl  ; set argument
  add hl,bc                     ; HL = start of second shadow screen line
  ld (ShowShadowScreen_6+1),hl  ; set argument
  add hl,bc                     ; HL = start of 2nd half of second shadow screen line
  ld (ShowShadowScreen_8+1),hl  ; set argument
  add hl,bc                     ; HL = shadow screen line for the next iteration
  ld (ShowShadowScreen_src),hl

; Copy 1st half of the first line
ShowShadowScreen_2:
  ld sp,$F000                   ; start of shadow screen line
  pop bc
  pop de
  pop hl
  exx
  pop bc
  pop de
  pop hl
ShowShadowScreen_3:
  ld sp,$4000                   ; end of 1st half of ZX screen line
  push hl
  push de
  push bc
  exx
  push hl
  push de
  push bc
; Copy 2nd half of the first line
ShowShadowScreen_4:
  ld sp,$F000                   ; start of 2nd half of shadow screen line
  pop bc
  pop de
  pop hl
  exx
  pop bc
  pop de
  pop hl
ShowShadowScreen_5:
  ld sp,$4000                   ; end of 2nd half of ZX screen line
  push hl
  push de
  push bc
  exx
  push hl
  push de
  push bc

; Copy 1st half of the second line
ShowShadowScreen_6:
  ld sp,$F000                   ; start of shadow screen line
  pop bc
  pop de
  pop hl
  exx
  pop bc
  pop de
  pop hl
ShowShadowScreen_7:
  ld sp,$4000                   ; end of 1st half of ZX screen line
  push hl
  push de
  push bc
  exx
  push hl
  push de
  push bc
; Copy 2nd half of the second line
ShowShadowScreen_8:
  ld sp,$F000                   ; start of 2nd half of shadow screen line
  pop bc
  pop de
  pop hl
  exx
  pop bc
  pop de
  pop hl
ShowShadowScreen_9:
  ld sp,$4000                   ; end of 2nd half of ZX screen line
  push hl
  push de
  push bc
  exx
  push hl
  push de
  push bc

  dec a                         ; loop counter for line pairs
  jp nz,ShowShadowScreen_1      ; continue the loop

  ld sp,(ShowShadowScreen_sp)   ; restoring SP
  ei
  ret
ShowShadowScreen_sp: DW 0
ShowShadowScreen_src: DW 0

; Clear block on the shadow screen
;   HL=row/col, DE=rows/cols
;   columns are 8px wide; row=1..128, row=0..127; col=0..23, cols=1..24
ClearScreenBlock:
  push bc
  ld a,l    ; column
  ld c,h    ; row
  ld l,h    ; row
  ld h,$00
  ld b,h
  add hl,hl               ; now HL = row * 2
  add hl,bc               ; now HL = row * 3
  add hl,hl
  add hl,hl
  add hl,hl               ; now HL = row * 24
  ld c,a
  add hl,bc               ; now HL = row * 12 + col
  ld bc,ShadowScreen
  add hl,bc               ; now HL = start address
  ld c,24                 ; line width in columns
  xor a
;  ld a,$55   ;DEBUG
ClearScreenBlock_1        ; loop by rows
  push hl
  ld b,e    ; cols
ClearScreenBlock_2:       ; loop by columns
  ld (hl),a
  inc hl
  djnz ClearScreenBlock_2
  pop hl
  add hl,bc               ; next line
  dec d     ; rows
  jr nz,ClearScreenBlock_1
  pop bc
  ret

; 8-bit random number generator using Refresh Register (R)
; See http://www.cpcwiki.eu/index.php/Programming:Random_Number_Generator
GetRandomByte:
  ld hl,(GetRandomByte_seed)
  ld a,r
  ld d,a
  ld e,a
  add hl,de
  xor l
  add a,a
  xor h
  ld l,a
  ld (GetRandomByte_seed),hl
  ret
GetRandomByte_seed: DEFW 12345
;
; Get random number 0..7
GetRandom8:
  call GetRandomByte
  and $07
  ret
;
; Get random number 0..10 for door access codes
; value 10 is for '-' char and we made its probability lower by 1/3
GetRandom11:
  call GetRandomByte
  and $1F                 ; 0..31
GetRandom11_1:
  cp 11                   ; less than 11?
  ret c                   ; yes => return 0..10
  sub 11                  ; 0..20, then 0..9
  jr GetRandom11_1

;----------------------------------------------------------------------------

  INCLUDE "desolcodb.asm"

;----------------------------------------------------------------------------
DesolateCodeEnd:

; Shadow screen, 192 x 138 pixels
;   12*2*(64*2+10) = 3312 bytes
ShadowScreen EQU $F300
;ShadowScreen:
;  DEFS 3312,$00

IF DesolateCodeEnd > ShadowScreen
  .ERROR DesolateCodeEnd overlaps ShadowScreen
ENDIF

;----------------------------------------------------------------------------

END
