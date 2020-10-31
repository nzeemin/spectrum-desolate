
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

L9E19:
  CALL LB653
  CALL LA0F1              ; Scan keyboard
  CP $36                  ; Yellow "2nd" key
  JP Z,LAAAF              ; Look / Shoot
  CP $28                  ; "XT0n" key
  JP Z,LB930              ; Look / Shoot Mode
  CP $30                  ; "ALPHA" key
  JP Z,LB0A2              ; Open the Inventory
L9E2E:
  CALL L9FEA              ; Copy screen 9340/9872 to A28F/A58F
  JP L9DDD

; Put tile on the screen (NOT aligned to 8px column), 16x8 -> 16x16 on ZX screen
; NOTE: we're using masked tiles here but ignoring the mask
;   L = row; A = column; B = height; IX = tile address
L9E5F:
  ld ($86D7),a  ; penCol
  ld a,l  ; row
  sra b                   ; B <- B / 2: working with line pairs
L9E5F_1:                  ; loop by B
  push af
  call GetScreenAddr	; now HL = screen addr
;  push bc
; Draw 1st line
  ld a,(ix+$01)
  ;TODO

  pop af
  add a,2
  ld de,$0004
  add ix,de
  djnz L9E5F_1
  ret

; Put tile on the screen (aligned to 8px column), 16x8 -> 16x16 on shadow screen
; NOTE: we're using masked tiles here but ignoring the mask
;   L = row; E = 8px column; IX = tile address
L9EAD:
  ld a,e
  add a,a
  add a,a
  add a,a
  add a,a
  ld ($86D7),a          ; penCol
  ld a,l                ; penRow
  ld b,8                ; 8 row pairs
  call GetScreenAddr    ; now HL = screen addr
L9EAD_1:
  push bc
; Draw 1st line
  ld a,(ix+$01)
  ld (hl),a             ; write 1st byte
  inc hl
  ld c,a
  ld a,(ix+$03)
  ld (hl),a             ; write 2nd byte
  ld b,a
  ld de,24-1
  add hl,de             ; to the 2nd line
; Draw 2nd line
  ld (hl),c             ; write 1st byte
  inc hl
  ld (hl),b             ; write 2nd byte
  pop bc
  ld de,24-1
  add hl,de             ; to the next line
  ld de,$0004
  add ix,de
  djnz L9EAD_1
  ret

L9EDE:
  ret ;STUB

; Copy shadow screen to ZX screen
;
L9FEA:
  jp ShowShadowScreen

; Clear shadow screen
;
L9FCF:
  ld bc,24*138-1	        ; 64 line pairs
  ld hl,ShadowScreen
  ld e,l
  ld d,h
  inc de
  xor a
  ld (hl),a
  ldir
  ret

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
  XOR A
  LD (LDD54),A
  JP LA8CD
;
LA8CD:
  LD C,$00
  LD A,(LDD55)
  OR A
  JR Z,LA8DF
  LD HL,LDE87
  LD A,(LDB75)            ; Direction/orientation??
  ADD A,A
  ADD A,A
  JR LA8E9
LA8DF:
  LD HL,LDE47
  LD A,(LDB75)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
LA8E9:
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(LDD54)
  ADD A,A
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD B,$04
LA8F8:
  PUSH HL
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,$E8E7     ; ???
  ADD HL,DE
  EX DE,HL
  CALL LA92E
  PUSH BC
  CALL LA956
  LD A,C
  CALL L9EDE
  POP BC
  POP HL
  INC HL
  DJNZ LA8F8
  LD A,(LDD54)
  CP $03
  JR Z,LA927
  INC A
  LD (LDD54),A
  XOR A
  LD (LDD55),A
  JP L9E19
LA927:
  XOR A
  LD (LDD54),A
  JP L9E19
LA92E:

LA956:
  ret ;STUB

LA966:
  ret ;STUB

LA99B:
  ret ;STUB

LA9EB:
  ret ;STUB

LAA1A:
  ret ;STUB

LAAAF:
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
  LD (LDC59),A
  LD (LDC5A),A
  LD (LDCF8),A
  LD A,$08
  LD (LDC83),A
  LD A,$12
  LD (LDC84),A
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
  DEC D
  JP NZ,LB2D0_1
  DEC C
  JP NZ,LB2D0_0
  RET

LB551:
  ret ;STUB

LB653
  ret ;STUB

LB76B:
  ret ;STUB

LB8EA:
  ret ;STUB

; Switch Look / Shoot mode
LB930:
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
  LD (LDC85),A
  LD HL,$3A1E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE09D             ; "MaxCoderz Presents"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81
  CALL LBC7D              ; Clear shadow screen and copy to A28F/A58F
  CALL LBC34
  LD HL,$3A2E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE09F             ; "a tr1p1ea game"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81
  CALL LBC7D              ; Clear shadow screen and copy to A28F/A58F
  CALL LBC34
  XOR A
  LD (LDC85),A

; Return to Menu
;
LBA3D:
  LD A,(LDC55)
  INC A
  CP $08
  CALL Z,LBC2F
  LD (LDC55),A
  DI
  LD HL,LF515
  CALL LA88F              ; Display 96 tiles on the screen
  LD HL,LF4B5             ; Main menu screen
  EI
  CALL LB177              ; Display screen from tiles with Tileset #2
  LD C,$03
  LD IX,Tileset3          ; Tile arrow right
  DI
  CALL LBA88
  LD C,$25
  LD IX,Tileset3+16       ; Tile arrow left
  DI
  CALL LBA88
  CALL L9FEA              ; Copy screen 9340/9872 to A28F/A58F
  CALL LA0F1              ; Scan keyboard
  CP $36
  JP Z,LBA93
  CP $04                  ; Up key
  JP Z,LBBCC
  CP $01                  ; Down key
  JP Z,LBBDC
  JP LBA3D

LBA81:
  CALL LBC34	
  CALL LBC34	
  RET

; Routine??
;
LBA88:
  LD A,(LDB8F)
  LD L,A
  LD A,C
  LD B,$08
  CALL L9E5F
  RET

LBA93:
  ret ;STUB

; New Game
;
LBADE:
  XOR A
  LD (LDCF7),A            ; Weapon slot
  LD (LDB7D),A
  LD (LDBC7),A
  CALL LB9D6
  LD HL,$0000
  LD (LDBC3),HL
  LD (LDBC5),HL
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
  CALL LBC7D              ; Clear shadow screen and copy to A28F/A58F
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
  CALL LBC7D              ; Clear shadow screen and copy to A28F/A58F
  CALL LBA81
  CALL LBC84              ; Set zero penRow/penCol
  LD HL,SE117             ; "'The Desolate' Space Cruiser|leaves orbit. ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$72B6
  LD ($86D7),HL
  LD HL,SE0B9             ; String with arrow down sign
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL WaitAnyKey         ; Wait for any (was: Wait for Down key)
  CALL L9FCF              ; Clear shadow screen
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
;
LBB92:
  LD A,(LDB73)
  OR A
  JP NZ,LBBA4
  LD A,(LDB8F)
  ADD A,$0C
  LD (LDB8F),A
  JP LBA3D
; Menu up step
LBBA4:
  LD A,(LDB8F)
  ADD A,$FA
  LD (LDB8F),A
  JP LBA3D
LBBAF:
  LD A,(LDB73)
  OR A
  JP NZ,LBBC1
  LD A,(LDB8F)
  ADD A,$0C
  LD (LDB8F),A
  JP LBA3D
; Menu down step
LBBC1:
  LD A,(LDB8F)
  ADD A,$06
  LD (LDB8F),A
  JP LBA3D
; Menu up key pressed
LBBCC:
  LD A,(LDB8F)
  CP $1D
  JP Z,LBA3D
  CP $29
  JP Z,LBB92
  JP LBBA4
; Menu down key pressed
LBBDC:
  LD A,(LDB8F)
  CP $35
  JP Z,LBA3D
  CP $1D
  JP Z,LBBAF
  JP LBBC1
;
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
  LD HL,$163C
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0A5             ; "- Controls -"
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$240A
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0A7             ; "2nd = Look / Shoot|Alpha = Inventory ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL L9FEA              ; Copy screen 9340/9872 to A28F/A58F
  CALL LADA1              ; Wait for MODE key
  JP LBA3D                ; Return to Menu
;
LBC29:
  LD A,(LDC55)
  ADD A,L
  LD L,A
  RET
;
LBC2F:
  XOR A
  LD (LDC55),A
  RET
;
LBC34:
  LD B,$14
LBC36:
  CALL LB2D0              ; Delay
  DJNZ LBC36
  RET

LBC6B:
  ret ;STUB

LBC7D:
  CALL L9FCF              ; Clear shadow screen
  CALL L9FEA              ; Copy screen 9340/9872 to A28F/A58F
  RET

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
  CALL LB2D0              ; Delay
  CALL L9FEA              ; Show shadow screen
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

; Set variables for Credits
;
LBF54:
  XOR A
  LD (LDD57),A
  LD (LDD56),A
  LD (LDC85),A
  LD A,$96
  LD (LDC59),A
  RET
;
; The End
;
LBF6F:
  CALL L9FCF              ; Clear shadow screen
  CALL LBF54
  LD HL,$2E46
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE11F             ; "The End"
  CALL LBEDE              ; Load archived string and show message char-by-char
;
; Credits screen text scrolls up
;
LBF81:
  LD A,126                ; To draw new strings on the very bottom
  LD ($86D8),A            ; penRow
LBF686:
  JP LBF6F_4
LBF6F_2:
  call L9FEA              ; Show shadow screen
  CALL LB2D0              ; Delay
LBF6F_3:
  CALL LA0F1              ; Scan keyboard
  or a                    ; any key pressed?
  jp nz,LBA3D             ; Return to main Menu
  CALL LBFD5              ; Scroll shadow screen up one line
;  CALL LBFEC
  JR LBF686
LBF6F_4:
  LD A,(LDD56)
  INC A
  LD (LDD56),A
  CP 12
  JP NZ,LBF6F_2
  XOR A
  LD (LDD56),A
  LD A,(LDD57)
  LD E,A
  LD D,$00
  LD HL,LDDF2
  ADD HL,DE
  LD A,(HL)
  LD ($86D7),A
  LD A,(LDD57)
  LD HL,LDD58
  CALL LADFF              ; Get address from table
  CALL DrawString         ; Draw string on shadow screen without any delays
  LD A,(LDD57)
  INC A                   ; increase the counter
  LD (LDD57),A
  CP $47
  JP NZ,LBF6F_3
  JP LBA3D                ; Return to main Menu
LBFD5:
  LD DE,ShadowScreen
  LD HL,ShadowScreen+24
  LD BC,137*24
  LDIR
  RET
LBFEC:
;  LD DE,$A2D7
;  LD HL,$9340
;  LD BC,$02B8
;  LDIR
  RET


