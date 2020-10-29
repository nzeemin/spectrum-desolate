
  ORG $5E00

start:
  call LBA07
;  jp L9DBE

;  call LB0A2	; Inventory

;  call ShowScreen

;  call ClearScreen

;  LD HL,LF515
;  CALL LA88F
;  LD HL,LF4B5
;  CALL LB177

;  call LAB28	; Show small message popup

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

;  ld hl,$3A14
;  ld ($86D7),hl
;  ld hl,SE115
;  call DrawString
;  call WaitAnyKey
;  call ClearScreen
;  call ClearPenRowCol
;  ld hl,SE117
;  call DrawString
;  ld hl,$72B6
;  ld ($86D7),hl
;  ld a,$60
;  call DrawChar
;  call WaitAnyKey
;  call ClearScreen
;  call ClearPenRowCol
;  ld hl,SE119
;  call DrawString

  call WaitAnyKey
  call ClearScreen
  jp start


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

; Source: http://www.breakintoprogram.co.uk/computers/zx-spectrum/keyboard
;TODO: Set Z=0 for key, Z=1 for no key
ReadKeyboard:          
  LD HL,ReadKeyboard_map  ; Point HL at the keyboard list
  LD D,8                ; This is the number of ports (rows) to check
  LD C,&FE              ; C is always FEh for reading keyboard ports
ReadKeyboard_0:        
  LD B,(HL)             ; Get the keyboard port address from table
  INC HL                ; Increment to list of keys
  IN A,(C)              ; Read the row of keys in
  AND &1F               ; We are only interested in the first five bits
  LD E,5                ; This is the number of keys in the row
ReadKeyboard_1:        
  SRL A                 ; Shift A right; bit 0 sets carry bit
  JR NC,ReadKeyboard_2  ; If the bit is 0, we've found our key
  INC HL                ; Go to next table address
  DEC E                 ; Decrement key loop counter
  JR NZ,ReadKeyboard_1  ; Loop around until this row finished
  DEC D                 ; Decrement row loop counter
  JR NZ,ReadKeyboard_0  ; Loop around until we are done
  AND A                 ; Clear A (no key found)
  RET
ReadKeyboard_2:
  LD A,(HL)             ; We've found a key at this point; fetch the character code!
  RET
ReadKeyboard_map:
  DB &FE,"#","Z","X","C","V"
  DB &FD,"A","S","D","F","G"
  DB &FB,"Q","W","E","R","T"
  DB &F7,"1","2","3","4","5"
  DB &EF,"0","9","8","7","6"
  DB &DF,"P","O","I","U","Y"
  DB &BF,"#","L","K","J","H"
  DB &7F," ","#","M","N","B"

ScreenAddrs:
  DW $40A4,$42A4,$44A4,$46A4,$40C4,$42C4,$44C4,$46C4
  DW $40E4,$42E4,$44E4,$46E4,$4804,$4A04,$4C04,$4E04
  DW $4824,$4A24,$4C24,$4E24,$4844,$4A44,$4C44,$4E44
  DW $4864,$4A64,$4C64,$4E64,$4884,$4A84,$4C84,$4E84
  DW $48A4,$4AA4,$4CA4,$4EA4,$48C4,$4AC4,$4CC4,$4EC4
  DW $48E4,$4AE4,$4CE4,$4EE4,$5004,$5204,$5404,$5604
  DW $5024,$5224,$5424,$5624,$5044,$5244,$5444,$5644
  DW $5064,$5264,$5464,$5664,$5084,$5284,$5484,$5684

; Get ZX screen address using penCol in $86D7
;   A = penRow
; Returns HL = address
GetScreenAddr:
  push bc
  sra a		; shift right, bit 0 -> carry
  push af
  sla a		; shift left
  ld c,a
  ld b,0
  ld hl,ScreenAddrs
  add hl,bc
  ld a,(hl)	; get line addr
  inc hl	;
  ld h,(hl)	;
  ld l,a	;
  pop af
  jr nc,GetScreenAddr_1
  ld bc,$0100
  add hl,bc
GetScreenAddr_1:
  ld a,($86D7)	; get penCol
  srl a		; shift right
  srl a		;
  srl a		; now A = column
  ld c,a
  ld b,$00
  add hl,bc
  pop bc
  ret

; Draw tile 16x16 -> 16x16 on ZX screen; see 9EAD in original
;   L = penRow; E = penCol; IX = Tile address
DrawTile:
  ld a,e
  ld ($86D7),a  ; penCol
  ld a,l	; penRow
  ld b,8	; 8 row pairs
DrawTile_1:
  push af
  call GetScreenAddr	; now HL = screen addr
; Draw 1st line
  ld a,(ix+0)
  inc ix
  ld (hl),a	; write 1st byte
  inc hl
  ld a,(ix+0)
  inc ix
  ld (hl),a	; write 2nd byte
  ld de,$0100-1
  add hl,de	; to the 2nd line
; Draw 2nd line
  ld a,(ix+0)
  inc ix
  ld (hl),a	; write 1st byte
  inc hl
  ld a,(ix+0)
  inc ix
  ld (hl),a	; write 2nd byte
  pop af
  add a,2
  djnz DrawTile_1
  ret

; Draw tile with mask 16x8 -> 16x16 on ZX screen
;   L = penRow; E = penCol; IX = Tile address
DrawTileMasked:
  ld a,e
  ld ($86D7),a  ; penCol
  ld a,l	; penRow
  ld b,8	; 8 row pairs
DrawTileMasked_1:
  push af
  call GetScreenAddr	; now HL = screen addr
  push bc
; Draw 1st line
  ld a,(ix+$00)	; get mask
  and (hl)
  or (ix+$01)
  ld (hl),a	; write 1st byte
  inc hl
  ld c,a
  ld a,(ix+$02)	; get mask
  and (hl)
  or (ix+$03)
  ld (hl),a	; write 2nd byte
  ld b,a
  ld de,$0100-1
  add hl,de	; to the 2nd line
; Draw 2nd line
  ld (hl),c	; write 1st byte
  inc hl
  ld (hl),b	; write 2nd byte
  pop bc
  pop af
  add a,2
  ld de,$0004
  add ix,de
  djnz DrawTileMasked_1
  ret

; Clear ZX screen
ClearScreen:
  ld hl,ScreenAddrs
  ld b,64	; 64 line pairs
ClearScreen_1:	; loop with 2-line steps
; 1st pass for even line
  ld e,(hl)
  inc hl
  ld d,(hl)
  inc hl
  push hl	; store table addr
  push de	; save screen addr for 2nd pass
  ld h,d
  ld l,e
  dec hl
  ld (hl),$00
  push bc
  ld bc,25
  ldir
  pop bc
; 2nd pass for odd line
  pop hl	; restoring screen addr
  ld de,$100
  add hl,de	; to the next line
  ld d,h
  ld e,l
  dec hl
  ld (hl),$00
  push bc
  ld bc,25
  ldir
  pop bc
  pop hl	; restore table addr
  djnz ClearScreen_1
  ret

; Set penRow/penCol to 0; same as BC84 in original
ClearPenRowCol:
  ld hl,$0000
  ld ($86D7),hl
  ret

; Draw string  on the screen using FontProto
;   HL = string addr
DrawString:
  ld a,(hl)
  inc hl
  or a
  ret z
  cp $7C	; '|'
  jr nz,DrawString_1
  xor a
  ld ($86D7),a
  ld a,($86D8)
  add a,$0E
  ld ($86D8),a
  jp DrawString
DrawString_1:
  push hl
  call DrawChar
  pop hl
  jp DrawString

; Draw character on the screen using FontProto
;   A = character to show
DrawChar:
  push hl
  push bc
  cp $20	; space char?
  jr nz, DrawChar_0
  ld a,$01	; space char gap size
  ld (DrawChar_width),a
  jp DrawChar_fin
DrawChar_0:
  cp $2C	; char less than ','?
  jr nc, DrawChar_1
  add a,$15	; for '&' amp '(' ')' chars
DrawChar_1:
  cp $60
  jr c,DrawChar_2
  sub $05	; skip the 5-char gap for lower letters
DrawChar_2:
  sub $2C	; font starts from ','
  ld e,a	; calculating the symbol address
  ld l,a	;
  ld h,$00	;
  ld d,h	;
  add hl,hl	; now hl = a * 2
  add hl,hl	; now hl = a * 4
  add hl,de	; now hl = a * 5
  add hl,hl	; now hl = a * 10
  add hl,de	; now hl = a * 11
  ld de,FontProto
  add hl,de	; now hl = addr of the symbol
  ex de,hl	; now de=symbol addr
  ld a,($86D8)	; get penRow
  ld (DrawChar_row),a
  ld a,(de)     ; get flag/width byte
  inc de
  bit 7,a	; lowered symbol?
  jr z,DrawChar_3
  ld hl,DrawChar_row
  inc (hl)	; start on the next line
DrawChar_3:
  and $0f	; keep width 1..8
  ld (DrawChar_width),a
  ld a,(DrawChar_row)
  call GetScreenAddr
  push hl	; store addr on the screen
  push de	; store symbol data addr
  ld a,($86D7)	; get penCol
  and $07	; shift 0..7
  inc a
  ld c,a
  ld b,$0a	; 10 lines
DrawChar_4:	; loop by lines
  push bc	; save counter
  ld a,(de)
  inc de
DrawChar_5:	; loop for shift
  dec c
  jr z, DrawChar_6
  srl a		; shift right
  jp DrawChar_5
DrawChar_6:
  or (hl)
  ld (hl),a	; put on the screen
  ld a,(DrawChar_row)
  inc a
  ld (DrawChar_row),a
  call GetScreenAddr
  pop bc	; restore counter and shift
  djnz DrawChar_4
  pop de	; restore symbol data addr
  pop hl	; restore addr on the screen
  ld a,($86D7)	; get penCol
  and $7	; shift 0..7
  ld b,a
  ld a,(DrawChar_width)
  add a,b
  cp $08	; shift + width <= 8 ?
  jr c,DrawChar_fin	; yes => no need for 2nd pass
; Second pass
  ld a,($86D7)	; get penCol
  and $07	; shift 1..7
  sub $08
  neg		; a = 8 - shift; result is 1..7
  inc a
  ld c,a
  ld a,(DrawChar_row)
  add a,$F6	; -10
  ld (DrawChar_row),a
;  call GetScreenAddr
  inc hl
  ld b,$0a	; 10 lines
DrawChar_8:	; loop by lines
  push bc	; save counter
  ld a,(de)
  inc de
DrawChar_9:	; loop for shift
  dec c
  jr z, DrawChar_A
  sla a		; shift left
  jp DrawChar_9
DrawChar_A:
  or (hl)
  ld (hl),a	; put on the screen
  ld a,(DrawChar_row)
  inc a
  ld (DrawChar_row),a
  call GetScreenAddr
  inc hl
  pop bc	; restore counter
  djnz DrawChar_8
; All done, finalizing
DrawChar_fin:
  ld hl,$86D7	; penCol
  ld a,(DrawChar_width)
  add a,(hl)
  add a,$02	; gap 2px between symbols
  ld (hl),a	; updating penCol
  pop bc
  pop hl
  ret
DrawChar_width: DB 0	; Saved symbol width
DrawChar_row0:	DB 0	; Saved first row number
DrawChar_row:	DB 0	; Saved current row number

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

;----------------------------------------------------------------------------

  INCLUDE "desolcodb.asm"

;  ORG $63CB
  INCLUDE "desolfont.asm"

;  ORG $66F9
  INCLUDE "desolstrs.asm"

  INCLUDE "desoldata.asm"

;----------------------------------------------------------------------------

