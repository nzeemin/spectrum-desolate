
;  ORG $9DBE

; Put tile on the screen, 16x8 -> 16x16 on ZX screen
; NOTE: we're using masked tiles here but ignoring the mask
;   L = penRow; E = column; IX = Tile address
L9EAD:
  ld a,e
  add a,a
  add a,a
  add a,a
  add a,a
  ld ($86D7),a  ; penCol
  ld a,l	; penRow
  ld b,8	; 8 row pairs
L9EAD_1:
  push af
  call GetScreenAddr	; now HL = screen addr
  push bc
; Draw 1st line
  ld a,(ix+$01)
  ld (hl),a	; write 1st byte
  inc hl
  ld c,a
  ld a,(ix+$03)
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
  djnz L9EAD_1
  ret

; Display 96 tiles on the screen
;   HL Address where the 96 tiles are placed
LA88F:
  LD DE,$0000
LA88F_0:
  PUSH HL
  PUSH DE
  LD L,(HL)
  LD A,L
  OR A
  JR Z,LA88F_1
  CP $47
  CALL Z,LBC29
  LD H,$00
  ADD HL,HL               ; HL <- HL * 16
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  add hl,hl	; HL <- HL * 32
  LD BC,Tileset1
  ADD HL,BC
  PUSH HL
  POP IX
  LD A,E
  LD L,D
  CALL L9EAD              ; Put tile on the screen
LA88F_1:
  POP DE
  POP HL
  INC HL
  INC E
  LD A,E
  CP $0C
  JP NZ,LA88F_0
  LD E,$00
  LD A,$10
  ADD A,D
  LD D,A
  CP $80
  JP NZ,LA88F_0
  RET

; Show small message popup
;
LAB28:
  PUSH BC
  PUSH DE
  LD BC,$0060
  LD HL,LEB27             ; Decode from: Small message popup
  LD DE,LDBF5             ; Decode to
  CALL LB9F1              ; Decode the room
  LD HL,LDBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  POP DE
  POP BC
  RET

; Decode the room to DBF5
;
; HL Decode from
; BC Tile count to decode
LADF5:
  LD DE,LDBF5             ; Decode to
  CALL LB9F1              ; Decode the room
  LD HL,LDBF5
  RET

; Open Inventory
;
; Used by the routine at L9DDD.
LB0A2:
  LD BC,$0060             ; Titles count to decode
  LD HL,LF329             ; Encoded screen for Inventory popup
  CALL LADF5              ; Decode the room to DBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  LD A,$0B
  LD ($DCF3),A
  LD A,$06
  LD ($DCF4),A
  XOR A
  LD ($DCF5),A            ; Data cartridge reader slot
  LD ($DC59),A
  LD ($DC5A),A
  LD ($DCF8),A
  LD A,$08
  LD ($DC83),A
  LD A,$12
  LD ($DC84),A
  LD HL,$1630
  LD ($86D7),HL
  LD HL,SE0BB             ; " - INVENTORY - "
  CALL LBEDE              ; Load archived string and show message char-by-char

  ret ;STUB

; Display screen from tiles with Tileset #2
;
; HL Screen in tiles, usually $DBF5
LB177:
  LD BC,$0000
LB177_0:
  PUSH HL
  PUSH BC
  ld a,(hl)
  ld l,a
  dec a
  JR Z,LB177_1
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  add hl,hl	; * 32
  LD DE,Tileset2
  add hl,de
  ex de,hl
  ld ixl,e
  ld ixh,d
  ld l,b
  ld e,c
  call DrawTileMasked
LB177_1:
  POP BC
  POP HL
  INC HL
  ld a,c
  add a,16
  cp 12*16
  ld c,a
  JP NZ,LB177_0
  LD C,$00
  ld a,b
  add a,16
  cp 16*8
  ld b,a
  JP NZ,LB177_0
  RET

; Delay by DC59
LB2D0:
  LD A,(LDC59)
  LD C,A
LB2D0_0:
  LD D,A
LB2D0_1:
  nop
  nop
  DEC D
  JP NZ,LB2D0_1
  DEC C
  JP NZ,LB2D0_0
  RET

; Decode the room/screen
;
; HL Decode from
; BC Decode to
LB9F1:
  LD A,(HL)
  CP $FF
  JR Z,LB9F1_1
  LDI
LB9F1_0:
  RET PO
  JR LB9F1
LB9F1_1:
  INC HL
  LD A,(HL)
  INC HL
  INC HL
LB9F1_2:
  DEC HL
  DEC A
  LDI
  JR NZ,LB9F1_2
  JR LB9F1_0

; Show titles and show Menu
LBA07:
  LD A,$44
  LD (LDC59),A
  LD ($DC85),A
  LD HL,$3A1E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE09D             ; "MaxCoderz Presents"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81
  CALL LBC7D              ; Clear screen 9340/9872 and copy to A28F/A58F
  CALL LBC34
  LD HL,$3A2E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE09F             ; "a tr1p1ea game"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81
  CALL LBC7D              ; Clear screen 9340/9872 and copy to A28F/A58F
  CALL LBC34
  XOR A
  LD ($DC85),A

; Return to Menu
;
LBA3D:
  LD A,($DC55)
  INC A
  CP $08
  CALL Z,LBC2F
  LD ($DC55),A
  DI
  LD HL,LF515
  CALL LA88F              ; Display 96 tiles on the screen
  LD HL,LF4B5             ; Main menu screen
  EI
  CALL LB177              ; Display screen from tiles with Tileset #2

  ret ;STUB

LBA81:
  CALL LBC34	
  CALL LBC34	
  RET

LBC29:
  LD A,($DC55)
  ADD A,L
  LD L,A
  RET

LBC2F:
  ret ;STUB

LBC34:
  LD B,$14
LBC36:
  CALL LB2D0              ; Delay
  DJNZ LBC36
  RET

LBC7D:
  call ClearScreen
  ret ;STUB

; Load archived string and show message char-by-char
;   HL Address of archived string offset
LBEDE:
  jp DrawString


