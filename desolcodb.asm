
;  ORG $9DBE

; Game main loop
;
L9DDD:
  LD A,(LDB7A)            ; Get Health
  OR A
  JP Z,LB9A2              ; Player is dead
  CALL LADE5              ; Decode current room
  CALL LA88F              ; Display 96 tiles on the screen
  CALL LB96B              ; Display Health
  CALL LB8EA
  CALL LB76B
  CALL LB551
  CALL LA0F1              ; Scan keyboard
  CP $0F                  ; CLEAR
  JP Z,LBA3D
  CP $04                  ; Up
  JP Z,LA99B
  CP $01                  ; Down
  JP Z,LA966
  CP $02                  ; Left
  JP Z,LA9EB
  CP $03                  ; Right
  JP Z,LAA1A
  XOR A                   ; Not a valid key
  LD (LDB7C),A
  JP LA8C6

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

; Copy screen 9340/9872 to A28F/A58F
;
L9FEA:
  ret ;STUB

; Clear screen 9340/9872
;
L9FCF:
  jp ClearScreen

; Scan keyboard; returns key in A
;
LA0F1:
  PUSH BC
  PUSH DE
  PUSH HL
  call ReadKeyboard
;TODO: Protect from reading same key several times
  POP HL
  POP DE
  POP BC
  RET

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

LA8C6:
  ret ;STUB

LA966:
  ret ;STUB

LA99B:
  ret ;STUB

LA9EB:
  ret ;STUB

LAA1A:
  ret ;STUB

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

; Wait for Down key
;
LAD99:
  CALL LA0F1              ; Scan keyboard
  CP $01                  ; Down key?
  JR NZ,LAD99
  RET

; Wait for MODE key
;
LADA1:
  CALL LA0F1              ; Scan keyboard
  CP $37
  JR NZ,LADA1
  RET

; Decode current room
;
LADE5:
  LD A,(LDB79)            ; Get the room number
  LD HL,LDE97             ; List of encoded room addresses
  CALL LADFF              ; now HL = encoded room
  LD BC,$0060             ; decode 96 bytes
  CALL LADF5              ; Decode the room to DBF5
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
;
; Get address from table
;
; A Element number
; HL Table address
LADFF:
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  RET


; Open Inventory
;
LB0A2:
  LD BC,$0060             ; Titles count to decode
  LD HL,LF329             ; Encoded screen for Inventory popup
  CALL LADF5              ; Decode the room to DBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  LD A,$16
  LD (LDCF3),A            ; Left margin size for text
  LD A,$06
  LD (LDCF4),A            ; Line interval for text
  XOR A
  LD (LDCF5),A            ; Data cartridge reader slot
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

LB551:
  ret ;STUB

LB76B:
  ret ;STUB

LB8EA:
  ret ;STUB

; Display Health
;
LB96B:
  LD HL,$012C
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,(LDB7A)           ; Get Health
  jp DrawNumber3

LB9A2:
  ret ;STUB

LB9D6:
  ret ;STUB

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

; New Game
;
; Used by the routine at LBA93.
LBADE:
  XOR A
  LD ($DCF7),A            ; Weapon slot
  LD ($DB7D),A
  LD ($DBC7),A
  CALL LB9D6
  LD HL,$0000
  LD ($DBC3),HL
  LD ($DBC5),HL
  LD HL,$DB9C
  LD B,$22
LBADE_0:
  LD (HL),$00
  INC HL
  DJNZ LBADE_0
  LD HL,$DC5B
  LD B,$22
LBADE_1:
  LD (HL),$00
  INC HL
  DJNZ LBADE_1
  LD HL,$DB90
  LD B,$09
LBADE_2:
  LD (HL),$00
  INC HL
  DJNZ LBADE_2
  LD HL,$DCA2
  LD B,$48
LBADE_3:
  LD (HL),$00
  INC HL
  DJNZ LBADE_3
  LD HL,$DC96
  CALL LBC6B
  LD HL,$DC9A
  CALL LBC6B
  LD HL,$DC9E
  CALL LBC6B
  CALL LBC7D              ; Clear screen 9340/9872 and copy to A28F/A58F
  LD A,$44
  LD (LDC59),A
  LD (LDC85),A
  LD A,$0E
  LD (LDCF4),A            ; Line interval for text
  XOR A
  LD (LDCF3),A            ; Left margin size for text
  LD HL,$3A14
  LD ($86D7),HL
  LD HL,SE115             ; "In the Distant Future . . ."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81
  CALL LBC7D              ; Clear screen 9340/9872 and copy to A28F/A58F
  CALL LBA81
  CALL LBC84              ; Set zero penRow/penCol
  LD HL,SE117             ; "'The Desolate' Space Cruiser|leaves orbit. ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$72B6
  LD ($86D7),HL
  LD HL,SE0B9             ; String with arrow down sign
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL WaitAnyKey         ; Wait for any (was: Wait for Down key)
  CALL L9FCF              ; Clear screen 9340/9872
  CALL LBC84              ; Set zero penRow/penCol
  LD HL,SE119             ; "The ship sustains heavy|damage. ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL WaitAnyKey         ; Wait for any key (was: Wait for MODE key)
;
; Game start
;
LBB7E:
  XOR A
  LD (LDC85),A
; Continue menu item selected
LBB7E_0:
  LD A,$01
  LD (LDB73),A
  LD A,$FF
  LD (LDC59),A
  CALL LB2D0              ; Delay
  JP L9DDD

; Info menu item, show Controls
;
LBBEC:
  LD BC,$0060             ; Counter = 96 bytes or tiles
  LD HL,LF329             ; Decode from - Encoded screen for Inventory popup
  LD DE,LDBF5             ; Where to decode
  CALL LB9F1              ; Decode the room
  LD HL,LDBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  LD A,$0A
  LD (LDCF3),A            ; Left margin size for text
  LD A,$0E
  LD (LDCF4),A            ; Line interval for text
  LD HL,$183C
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0A5             ; "- Controls -"
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$2A0A
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0A7             ; "2nd = Look / Shoot|Alpha = Inventory ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL L9FEA              ; Copy screen 9340/9872 to A28F/A58F
  CALL LADA1              ; Wait for MODE key
  JP LBA3D                ; Return to Menu

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

LBC6B:
  ret ;STUB

LBC7D:
  call L9FCF
  ret ;STUB

; Set zero penRow/penCol
;
LBC84:
  LD HL,$0000
  LD ($86D7),HL           ; Set penRow/penCol
  RET

; Draw string  on the screen using FontProto
;   HL = String address
LBEDE:
  ld a,(hl)
  inc hl
  or a
  ret z
  cp $7C	; '|'
  jr z,LBEDE_1
  push hl
  call DrawChar
  pop hl
  jr LBEDE
LBEDE_1:
  PUSH BC
  LD A,($86D8)
  LD C,A
  LD A,(LDCF4)            ; Line interval for text
  ADD A,C
  LD ($86D8),A
  LD A,(LDCF3)            ; Get left margin size for text
  LD ($86D7),A
  POP BC
  jr LBEDE

; Routine??
;
LBF54:
  XOR A
  LD ($DD57),A
  LD ($DD56),A
  LD ($DC85),A
  LD A,$96
  LD ($DC59),A
  RET

; The End
;
LBF6F:
  CALL L9FCF              ; Clear screen 9340/9872
  CALL LBF54
  LD HL,$2E46
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE11F             ; "The End"
  CALL LBEDE              ; Load archived string and show message char-by-char
;
; Credits screen text scrolls up
;
LBF81:

  ret ;STUB


