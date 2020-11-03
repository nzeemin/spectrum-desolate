
;  ORG $9DBE

; Game main loop
;
L9DDD:
  LD A,(LDB7A)            ; Get Health
  OR A
  JP Z,LB9A2              ; Player is dead
  CALL LADE5              ; Decode current room; HL = LDBF5
  CALL LA88F              ; Display 96 tiles on the screen
  CALL LB96B              ; Display Health
  CALL LB8EA              ; Show look/shoot selection indicator
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

; Ending of main game loop
L9E19:
  CALL LB653
  CALL LA0F1              ; Scan keyboard
  CP $36                  ; Yellow "2nd" key
  JP Z,LAAAF              ;   Look / Shoot
  CP $28                  ; "XT0n" key
  JP Z,LB930              ;   Look / Shoot Mode
  CP $30                  ; "ALPHA" key
  JP Z,LB0A2              ;   Open the Inventory
; Show the screen, continue the game main loop
L9E2E:
  CALL L9FEA              ; Copy shadow screen to ZX screen
  JP L9DDD                ; continue main game loop

; Quit menu item selected
L9E51:
  ret ;STUB

; Put tile on the screen (NOT aligned to 8px column), 16x8 -> 16x16 on shadow screen
; Uses XOR operation so it is revertable.
;   L = row; A = X coord; B = height; IX = tile address
L9E5F:
  ld e,l
  ld h,$00
  ld d,h
  add hl,de               ; now HL = L * 2
  add hl,de               ; now HL = L * 3
  add hl,hl
  add hl,hl               ; now HL = L * 12
  add hl,hl               ; now HL = L * 24
  ld e,a
  and $07
  ld c,a                  ; C = offset within 8px column
  srl e
  srl e
  srl e                   ; E = number of 8px column
  add hl,de               ; now HL = offset on the shadow screen
  ld de,ShadowScreen
  add hl,de               ; HL = address in the shadow screen
L9E8D:                  ; loop by B
  ld d,(ix+$00)
  ld e,$00
  ld a,c
  or a
  jr z,L9E9D
L9E96:
  srl d
  rr e
  dec a
  jr nz,L9E96
L9E9D:
  ld a,(hl)
  xor d
  ld (hl),a
  inc hl
  ld a,(hl)
  xor e
  ld (hl),a
  ld de,24-1
  add hl,de               ; to the next line
  inc ix
  inc ix
  djnz L9E8D
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

; Draw tile
;   DE = tile address; A = ??; H = column; L = row
L9EDE:
  PUSH HL
  PUSH AF
  AND $3F
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  add hl,hl
  ADD HL,DE               ; now HL = source tile address
  LD DE,L9FAF
  LD BC,32
  LDIR                    ; get the tile data to the buffer
  POP AF
;  BIT 6,A
;  CALL NZ,L9EDE_1         ; Reflect tile
;  BIT 7,A
;  CALL NZ,L9EDE_4         ; Reflect tile
  LD IX,L9FAF
  POP HL
  LD A,H
  LD H,$00
  LD B,H
  LD C,L                  ; get row
  ADD HL,BC
  ADD HL,BC
  ADD HL,HL
  ADD HL,HL
  add hl,hl               ; now HL = row * 24
  LD C,A
  ADD HL,BC               ; now HL = offset on the shadow screen
  ld bc,ShadowScreen
  ADD HL,BC
  LD B,$08                ; 8 line pairs
L9EDE_0:                  ; loop by B
  PUSH BC
; Process 1st line
  ld a,(ix+$00)           ; get mask byte
  and (hl)
  or (ix+$01)             ; use pixels byte
  ld (hl),a
  inc hl
  ld a,(ix+$02)           ; get mask byte
  and (hl)
  or (ix+$03)             ; use pixels byte
  ld (hl),a
  ld bc,24-1
  add hl,bc               ; next line
; Process 2nd line
  ld a,(ix+$00)           ; get mask byte
  and (hl)
  or (ix+$01)             ; use pixels byte
  ld (hl),a
  inc hl
  ld a,(ix+$02)           ; get mask byte
  and (hl)
  or (ix+$03)             ; use pixels byte
  ld (hl),a
  ld bc,24-1
  add hl,bc               ; next line
; Increase tile address
  ld bc,$0004
  add ix,bc
  POP BC
  DJNZ L9EDE_0
  RET
L9EDE_1:
  ret ;STUB

L9FAF:
  DEFS 32,$00


; Copy shadow screen to ZX screen
;
L9FEA EQU ShowShadowScreen

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
  LD A,(LDB75)            ; Direction/orientation
  ADD A,A
  ADD A,A                 ; now A = A * 4
  JR LA8E9
LA8DF:
  LD HL,LDE47
  LD A,(LDB75)            ; Direction/orientation
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A                 ; now A = A * 16
LA8E9:
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(LDD54)
  ADD A,A
  ADD A,A                 ; now A = A * 4
  LD E,A
  LD D,$00
  ADD HL,DE
  LD B,$04                ; 4 tiles
LA8F8:                    ; loop by B
  PUSH HL
  LD L,(HL)               ; get tile number
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL               ; HL = L * 16
  add hl,hl               ; HL = L * 32
  LD DE,Tileset1+$7A*32   ; was: $E8E7
  ADD HL,DE
  EX DE,HL                ; DE = tile address
  CALL LA92E
  PUSH BC
  CALL LA956
  LD A,C
  CALL L9EDE              ; Draw tile DE at column H row L
  POP BC
  POP HL
  INC HL
  DJNZ LA8F8              ; continue loop by tiles
  LD A,(LDD54)
  CP $03
  JR Z,LA927
  INC A
  LD (LDD54),A
  XOR A
  LD (LDD55),A
  JP L9E19                ; Go to ending of main game loop
LA927:
  XOR A
  LD (LDD54),A
  JP L9E19                ; Go to ending of main game loop
LA92E:
  INC C
  LD A,(LDB76)            ; Get X coord in tiles
  add a,a                 ; now coord in 8px columns
  LD H,A
  LD A,(LDB77)            ; Get Y coord in lines
  SUB 16                  ; was: $08
  LD L,A
  LD A,C
  CP $01
  RET Z
  CP $02
  JR NZ,LA94C
LA941:
  LD A,(LDB75)            ; Direction/orientation
  CP $02                  ; left?
  JR Z,LA94A
  INC H                   ; right
  RET
LA94A:
  DEC H                   ; left
  RET
LA94C:
  LD A,16                 ; was: $08
  ADD A,L
  LD L,A
  LD A,C
  CP $04
  JR Z,LA941
  RET
LA956:
  LD C,$00
  LD A,(LDB75)            ; Direction/orientation
  OR A                    ; down?
  RET Z
  CP $01                  ; up?
  RET Z
  CP $03                  ; right?
  RET Z
  LD C,$80
  RET

; Move Down
LA966:
  LD A,(LDB75)            ; Direction/orientation
  OR A                    ; down?
  JP Z,LA97C
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01
  JP NZ,LA97C
  XOR A                   ; down
  LD (LDB75),A            ; Direction/orientation
  JP LA8C6
LA97C:
  XOR A                   ; down
  LD (LDB75),A            ; Direction/orientation
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB77)            ; Get Y pixel coord
  PUSH AF
  ADD A,16                ; Down one tile; was: $08
  LD (LDB77),A            ; Set Y pixel coord
  LD A,(LDB78)            ; Get Y tile coord
  PUSH AF
  INC A
  LD (LDB78),A            ; Set Y tile coord
  JR LA9D1
;
; Move Up
LA99B:
  LD A,(LDB75)            ; Direction/orientation
  CP $01                  ; up?
  JP Z,LA9B3
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01                  ; shoot?
  JP NZ,LA9B3
  LD A,$01                ; up
  LD (LDB75),A            ; Direction/orientation
  JP LA8C6
LA9B3:
  LD A,$01                ; up
  LD (LDB75),A            ; Direction/orientation
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB77)            ; Get Y pixel coord
  PUSH AF
  ADD A,-16               ; Up one tile; was: $F8
  LD (LDB77),A            ; Set Y pixel coord
  LD A,(LDB78)            ; Get Y tile coord
  PUSH AF
  DEC A
  LD (LDB78),A            ; Set Y tile coord
LA9D1:
  LD A,(LDB84)
  OR A
  JP Z,LA9E6
  CALL LB72E
  OR A
  JP Z,LA9E6
  CALL LB74C
  OR A
  JP Z,LB07B           ; Decrease Health by 4, restore Y coord
LA9E6:
  POP AF
  POP AF
  JP LA8CD
;
; Move Left
LA9EB:
  LD A,(LDB75)            ; Direction/orientation
  CP $02                  ; left?
  JP Z,LAA03
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01
  JP NZ,LAA03
  LD A,$02                ; left
  LD (LDB75),A            ; Direction/orientation
  JP LA8C6
LAA03:
  LD A,$02                ; left
  LD (LDB75),A            ; Direction/orientation
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB76)            ; Get X coord in tiles
  PUSH AF
  DEC A                   ; X = X - 1
  LD (LDB76),A
  JR LAA47
;
; Move Right
LAA1A:
  LD A,(LDB75)            ; Direction/orientation
  CP $03                  ; right?
  JP Z,LAA32
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01                  ; shoot?
  JP NZ,LAA32             ; no => jump
  LD A,$03                ; right
  LD (LDB75),A            ; Direction/orientation
  JP LA8C6
LAA32:
  LD A,$03                ; right
  LD (LDB75),A            ; Direction/orientation
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB76)            ; Get X coord in tiles
  PUSH AF
  INC A                   ; X = X + 1
  LD (LDB76),A
LAA47:
  LD A,(LDB84)
  OR A
  JP Z,LAA5C
  CALL LB72E
  OR A
  JP Z,LAA5C
  CALL LB74C
  OR A
  JP Z,LB08D              ; Decrease Health by 4, restore X coord
LAA5C:
  POP AF
  JP LA8CD
;
LAA60:
  CALL LADE5              ; Decode current room; HL = LDBF5
  LD A,(LDB76)            ; Get X coord in tiles
  LD E,A
  CALL LAA7D
  LD D,$00
  ADD HL,DE
  LD A,(LDB74)
  LD E,A
  LD A,(LDB78)            ; Get Y tile coord
  LD B,A
  CALL LAA8D
;
LAA78:
  ADD HL,DE
  DJNZ LAA78
  LD A,(HL)
  RET
;
LAA7D:
  LD A,(LDB75)            ; Direction/orientation
  OR A                    ; down?
  RET Z
  CP $01                  ; up?
  RET Z
  CP $02                  ; left?
  JR NZ,LAA8B
  DEC E                   ; going left 1 tile
  RET
LAA8B:
  INC E                   ; going right 1 tile
  RET
;
LAA8D:
  LD A,(LDB75)            ; Direction/orientation
  CP $02                  ; left
  RET Z
  CP $03                  ; right?
  RET Z
  OR A                    ; down?
  JR NZ,LAA9B
  INC B                   ; going down 1 tile
  RET
LAA9B:
  DEC B                   ; going up 1 tile
  RET
;
LAA9D:
  LD A,(LDB74)
  LD E,A
  LD A,(LDB78)            ; Get Y tile coord
  LD B,A
  LD A,(LDB76)            ; Get X tile coord
LAAA8:
  ADD A,E
  DJNZ LAAA8
  LD (LDC56),A
  RET
;
; Look / Shoot
LAAAF:
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01                  ; shoot mode?
  JP Z,LB758              ; yes => jump
; Look action
  XOR A
  LD (LDC88),A
  CALL LAA9D
  CALL LAE09              ; Decode current room description to LDBF5
LAAC1:
  LD A,(HL)
  LD C,A
  LD A,(LDC56)
  SUB C
  JP Z,LAADD
  LD A,(LDC88)
  CP $31
  JP Z,LAADA              ; => Show the screen, continue the game main loop
  INC A
  LD (LDC88),A
  INC HL
  JP LAAC1
; Show the screen, continue the game main loop
LAADA:
  JP L9E2E                ; Show the screen, continue the game main loop
LAADD:
  LD A,(LDC88)
  OR A
  JP Z,LAB3F
  CP $01
  JP Z,LAB3F
  CP $03
  JP Z,LABA4
  CP $04
  JP Z,LABA4
  CP $19
  JP Z,LABBE
  CP $1A
  JP Z,LABBE
  CP $21
  JP Z,LAC05
  CP $22
  JP Z,LAC05
  CP $06
  JP Z,LAC54
  CP $07
  JP Z,LAC54
  CP $0B
  JP Z,LACE3
  CP $0C
  JP Z,LACE3
  CP $0F
  JP Z,LBC8B
  CP $10
  JP Z,LBC8B
  JP L9E2E                ; Show the screen, continue the game main loop
;
; Show small message popup
LAB28:
  PUSH BC
  PUSH DE
  LD BC,$0060             ; Number of bytes to decode = 96
  LD HL,LEB27             ; Decode from: Small message popup
  LD DE,LDBF5             ; Decode to
  CALL LB9F1              ; Decode the screen
  LD HL,LDBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  POP DE
  POP BC
  RET
;
LAB3F:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0002
  CALL LAC4C
  JP NZ,LAADA             ; => Show the screen, continue the game main loop
  LD A,(LDB79)            ; Get room number
  CP $1B
  JP NZ,LAB7A
  LD A,(LDCF7)            ; Weapon slot
  OR A
  JP NZ,LAB7A             ; have weapon => jump
  LD A,$0B
  LD (LDCF3),A            ; Left margin size for text
  LD A,$07
  LD (LDCF4),A            ; Line interval for text
  CALL LAB28              ; Show small message popup
  CALL LAB73              ; Set penRow/penCol for small message popup
  LD HL,SE0D5             ; -> "It is not wise to proceed without a weapon."
  CALL LBEDE              ; Load archived string and show message char-by-char
  JP LAD8C
;
; Set penRow/penCol for small message popup
LAB73:
  LD HL,$5812
  LD ($86D7),HL           ; Set penRow/penCol
  RET
;
LAB7A:
  LD A,$01
  LD (LDC8A),A
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$001C
LAB85:
  ADD HL,DE
  LD A,(HL)
  LD (LDC8C),A            ; Set Access code level
  LD DE,$0007
  ADD HL,DE
  LD A,(HL)
  LD (LDC86),A
  LD DE,$0004
  ADD HL,DE
  LD A,(HL)
  LD (LDC8B),A
  LD A,(LDC8C)            ; Get Access code level
  OR A
  JP Z,LB00E
  JP LAE23
;
LABA4:
  CALL LAE09
  LD DE,$0005
  CALL LAC4C
  JP NZ,LAADA              ; => Show the screen, continue the game main loop
  LD A,$02
  LD (LDC8A),A
  CALL LAE09
  LD DE,$001D
  JP LAB85
;
LABBE:
  ret ;STUB

LAC05:
  ret ;STUB

LAC4C:
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD A,(LDB75)
  SUB C
  RET

LAC54:
  CALL LAE09
  LD DE,$0008
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD A,(LDB75)
  SUB C
  JP NZ,LAADA              ; => Show the screen, continue the game main loop
  CALL LAE09
  LD DE,$000A
  ADD HL,DE
  LD A,(HL)
  LD (LDC89),A
  CALL LAE09
  LD DE,$0009
  ADD HL,DE
  LD A,(HL)
  CP $01
  JP Z,LAC97
  CALL LAB28              ; Show small message popup
  CALL LAB73              ; Set penRow/penCol for small message popup
  LD HL,SE0C3             ; " Another Dead Person"
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$3309
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0C5             ; " Search Reveals Nothing"
  CALL LBEDE              ; Load archived string and show message char-by-char
  JP LAD8C
LAC97:
  CALL LAD4F
  CP $01
  JP Z,LAADA              ; => Show the screen, continue the game main loop
  LD A,(LDB79)            ; Get the room number
  OR A                    ; room #0 ?
  JP Z,LACC5              ; yes => Small message popup "OMG! This Person Is DEAD! What Happened Here!?!"
  CALL LAB28              ; Show small message popup
  CALL LAB73              ; Set penRow/penCol for small message popup
  LD HL,SE0C7             ; " This Person is Dead . . ."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LACB8              ; Show arrow sign as prompt to continue
  JP LAD00
;
; Show arrow sign as prompt to continue
LACB8:
  LD HL,$66B0
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0B9             ; String with arrow down sign
  CALL LBEDE              ; Load archived string and show message char-by-char
  RET
;
; Small message popup "OMG! This Person Is DEAD! What Happened Here!?!"
LACC5:
  CALL LAB28              ; Show small message popup
  CALL LAB73              ; Set penRow/penCol for small message popup
  LD HL,SE0BF             ; "OMG! This Person Is DEAD!"
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$6612
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0C1             ; "What Happened Here!?!"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LACB8              ; Show arrow sign as prompt to continue
  JP LAD00
;
LACE3:
  ret ;STUB

; Show screen, wait for down key, show small message popup
LACF6:
  CALL L9FEA              ; Copy shadow screen to ZX screen
  CALL LAD99              ; Wait for Down key
  CALL LAB28              ; Show small message popup
  RET
;
LAD00:
  CALL LACF6              ; Show screen, wait for down key, show small message popup
  LD HL,$5816
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0C9             ; "They Seem To Be Holding"
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$663E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0CB             ; "Something"
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD A,(LDBC7)
  INC A
  LD (LDBC7),A
LAD22:
  CALL LACB8
  CALL LACF6
  LD HL,$5830
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0CF             ; "You Picked Up A"
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$6612
  LD ($86D7),HL           ; Set penRow/penCol
  CALL LAE19              ; Get inventory item description string
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD A,(LDC89)
  LD H,$00
  LD L,A
  LD DE,LDB9C
  ADD HL,DE
  LD (HL),$01
  JP LAD8C
;
; ??
LAD4F:
  LD A,(LDC89)
  LD H,$00
  LD L,A
  LD DE,LDB9C
  ADD HL,DE
  LD A,(HL)
  RET
;
LAD5B:
  ret ;STUB

LAD8C:
  CALL L9FEA              ; Copy shadow screen to ZX screen
LAD8F:
  CALL LA0F1              ; Scan keyboard
  CP $37                  ; Mode key?
  JR NZ,LAD8F
  JP L9E2E
;
; Wait for Down key
LAD99:
  CALL LA0F1              ; Scan keyboard
  CP $01                  ; Down key?
  JR NZ,LAD99
  RET
;
; Wait for MODE key
LADA1:
  CALL LA0F1              ; Scan keyboard
  CP $37
  JR NZ,LADA1
  RET

; Decode current room
;   Returns: HL = LDBF5
LADE5:
  LD A,(LDB79)            ; Get the room number
  LD HL,LDE97             ; List of encoded room addresses
  CALL LADFF              ; now HL = encoded room
  LD BC,$0060             ; decode 96 bytes
  CALL LADF5              ; Decode the room to DBF5
  RET
;
; Decode the room to DBF5
;   HL = decode from
;   BC = tile count to decode
;   Returns: HL = LDBF5
LADF5:
  LD DE,LDBF5             ; Decode to
  CALL LB9F1              ; Decode the room
  LD HL,LDBF5
  RET
;
; Get address from table
;   A = Element number
;   HL = Table address
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
;
; Decode current room description to LDBF5
;   Returns: HL = LDBF5
LAE09:
  LD A,(LDB79)            ; Get room number
  LD HL,LDF27             ; Table of adresses for room descriptions
  CALL LADFF              ; Get address from table by index A
  LD BC,$0031             ; decode 49 bytes
  CALL LADF5              ; Decode the room description to LDBF5
  RET
;
; Inventory item to item description string
LAE19:
  LD A,(LDC89)
  LD HL,LDFB7
  CALL LADFF              ; Get address from table by index A
  RET

LAE23:
  LD A,$28
  LD (LDC59),A            ; set delay factor
  LD A,(LDC8B)
  LD D,$00
  LD E,A
  LD HL,LDCA2
  ADD HL,DE
  LD A,(HL)
  CP $01
  JP Z,LB00E
  LD B,$04
  LD HL,LDC8D
LAE3D:
  LD (HL),$00
  INC HL
  DJNZ LAE3D
  LD BC,$0060             ; decode 96 bytes
  LD HL,LF468             ; Encoded screen: Door access panel popup
  CALL LADF5              ; Decode the room to DBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  LD A,10                 ; was: $05
  LD (LDCF3),A            ; Left margin size for text
  ld a,12
  LD (LDCF4),A            ; Line interval for text
  CALL LB09B
  LD HL,SE0DD             ; ": Door Locked :"
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$440A
  LD ($86D7),HL           ; Set penRow/penCol
  CALL LAFFE              ; Get "Access code level N required" string by access level in DC8C
  CALL LBEDE              ; Load archived string and show message char-by-char

  ret ;STUB

LAFFE
  ret ;STUB

LB00E:
  ret ;STUB

; Decrease Health by 4, restore Y coord
LB07B:
  LD B,$02
LB07D:
  CALL LB994              ; Decrease Health
  DJNZ LB07D
  POP AF
  LD (LDB78),A            ; Set Y tile coord
  POP AF
  LD (LDB77),A            ; Set Y pixel coord
  JP LA8CD
;
; Decrease Health by 4, restore X coord
LB08D:
  LD B,$02
LB08F:
  CALL LB994              ; Decrease Health
  DJNZ LB08F
  POP AF                  ; Restore old X coord
  LD (LDB76),A            ; Set X coord
  JP LA8CD
;
LB09B:
  LD HL,$3410
  LD ($86D7),HL           ; Set penRow/penCol
  RET
;
; Open the Inventory pop-up
;
LB0A2:
  LD BC,$0060             ; decode 96 bytes
  LD HL,LF329             ; Encoded screen for Inventory/Info popup
  CALL LADF5              ; Decode the screen to DBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  LD A,22                 ; was: $0B
  LD (LDCF3),A            ; Left margin size for text
  LD A,12                 ; was: $06
  LD (LDCF4),A            ; Line interval for text
  XOR A
  LD (LDCF5),A            ; Data cartridge reader slot??
  LD (LDC59),A            ; set delay factor
  LD (LDC5A),A            ; Inventory items count = 0
  LD (LDCF8),A
  LD A,16                 ; was: $08
  LD (LDC83),A            ; set X pos
  LD A,$24                ; was: $12
  LD (LDC84),A            ; set Y pos
  LD HL,$1630
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0BB             ; " - INVENTORY - "
  call DrawString         ; was: CALL LBEDE
;
  LD HL,LDB9C             ; Inventory items??
  LD B,$1D                ; 29 items
LB0E0:                    ; loop by B
  PUSH HL
  LD A,(HL)               ; get item
  CP $01                  ; do we have the item
  CALL Z,LB12A            ; yes => put in the list and draw
  POP HL
  INC HL                  ; next item
  DJNZ LB0E0              ; continue loop
;
  LD A,(LDC5A)            ; Inventory items count
  LD C,A
  LD A,$1D                ; 29 items
  SUB C
  LD C,A                  ; C = count of empty slots
LB0F3:
  PUSH BC
  LD IX,Tileset3+14*32    ; Tile gray dot in the center - placeholder
  CALL LB15D              ; Draw tile by XOR then go to next position
  POP BC
  LD A,C
  OR A                    ; last item?
  JP Z,LB119              ; yes, exit the loop
  DEC C
  LD HL,LDC5B             ; Inventory list
  LD A,(LDC5A)
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,$63
  LD (HL),A
  LD A,(LDC5A)
  INC A                   ; increase Inventory items count
  LD (LDC5A),A
  JP LB0F3                ; continue the loop
LB119:
  JP LB1AA
;
LB11C:
  LD A,16                 ; was: $08
  LD (LDC83),A            ; set X pos
  LD A,(LDC84)            ; get Y pos
  ADD A,20                ; 10 lines lower; was: $0A
  LD (LDC84),A            ; set Y pos
  RET
;
LB12A:
  PUSH BC
  LD C,B
  LD A,$1D                ; 29 items
  SUB C
  PUSH AF
  CALL LB529
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL               ; HL = A * 16
  LD DE,Tileset3+32       ; Inventory items, 12 tiles
  ADD HL,DE
  PUSH HL
  POP IX
  CALL LB15D              ; Draw tile by XOR then go to next position
  LD HL,LDC5B             ; Inventory items
  LD A,(LDC5A)
  LD E,A
  LD D,$00
  ADD HL,DE
  POP AF
  LD (HL),A
  OR A
  CALL Z,LB301
  LD A,(LDC5A)
  INC A                   ; increase Inventory items count
  LD (LDC5A),A
  POP BC
  RET
; Draw tile by XOR using X = (LDC83), Y = (LDC84), then go to next position
LB15D:
  LD A,(LDC84)            ; get Y pos for Inventory
  LD L,A                  ; L = row
  LD A,(LDC83)            ; A = X pos for Inventory
  LD B,$08
  CALL L9E5F              ; Draw tile by XOR operation
  LD A,(LDC83)            ; get X pos
  ADD A,16                ; increase X; was: $08
  LD (LDC83),A            ; set X pos
  CP 176                  ; was: $58
  CALL Z,LB11C
  RET
;
; Display screen from tiles with Tileset #2
;   HL = Screen in tiles, usually LDBF5
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
  call DrawTileMasked     ; was: CALL L9EDE
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

; Inventory
LB1AA:
  XOR A
  LD (LDC82),A            ; clear Inventory current
  LD A,16                 ; was: $08
  LD (LDC83),A            ; set X pos
  LD A,$24                ; was: $12
  LD (LDC84),A            ; set Y pos
  CALL LB2AF
LB1BB:                    ; Inventory loop starts here
  call DrawString         ; was: CALL LBEDE
  CALL LB295              ; Draw Inventory selection square
; Inventory item selection
LB1C1:
  CALL LA0F1              ; Scan keyboard
  CP $37                  ; Escape key? (close any popups)
  JP Z,L9DDD              ;   yes => return to the game main loop
  CP $36                  ; Look/shoot key?
  JP Z,LB307
  CP $02                  ; Left key?
  JP Z,LB1FE
  CP $03                  ; Right key?
  JP Z,LB214
  JP LB1C1                ; continue the loop
LB1DB:
  CALL LB2DE
  CALL LB2AF
  RET
LB1E2:
  CALL LB295
  LD A,(LDC82)            ; get Inventory current
  DEC A                   ; left
  LD (LDC82),A            ; set Inventory current
  CALL LB1DB
  RET
LB1F0:
  CALL LB295
  LD A,(LDC82)            ; get Inventory current
  INC A                   ; right
  LD (LDC82),A            ; set Inventory current
  CALL LB1DB
  RET
LB1FE:                    ; Left key pressed
  LD A,(LDC83)            ; get X pos
  CP 16                   ; was: $08
  JP Z,LB25F
  CALL LB1E2
  LD A,(LDC83)            ; get X pos
  ADD A,-16               ; was: $F8
  LD (LDC83),A            ; set X pos
  JP LB1BB                ; continue Inventory loop
LB214:                    ; Right key pressed
  LD A,(LDC83)            ; get X pos
  CP $A0                  ; was: $50
  JP Z,LB22A
  CALL LB1F0
  LD A,(LDC83)            ; get X pos
  ADD A,16                ; was: $08
  LD (LDC83),A            ; set X pos
  JP LB1BB                ; continue Inventory loop
LB22A:
  LD A,(LDC84)            ; get Y pos
  CP $4C                  ; was: $26
  JP Z,LB245
  CALL LB1F0
  LD A,(LDC84)            ; get Y pos
  ADD A,20                ; was: $0A
  LD (LDC84),A            ; set Y pos
  LD A,16                 ; was: $08
  LD (LDC83),A            ; set X pos
  JP LB1BB                ; continue Inventory loop
LB245:
  CALL LB295
  LD A,16                 ; was: $08
  LD (LDC83),A            ; set X pos
  LD A,$24                ; was: $12
  LD (LDC84),A            ; set Y pos
  XOR A
  LD (LDC82),A            ; clear Inventory current
  CALL LB2DE
  CALL LB2AF
  JP LB1BB                ; continue Inventory loop
LB25F:
  LD A,(LDC84)            ; get Y pos
  CP $24                  ; was: $12
  JP Z,LB27A
  CALL LB1E2
  LD A,(LDC84)            ; get Y pos
  ADD A,-20               ; was: $F6
  LD (LDC84),A            ; set Y pos
  LD A,$A0                ; was: $50
  LD (LDC83),A            ; set X pos
  JP LB1BB                ; continue Inventory loop
LB27A:
  CALL LB295
  LD A,$A0                ; was: $50
  LD (LDC83),A            ; set X pos
  LD A,$4C                ; was: $26
  LD (LDC84),A            ; get Y pos
  LD A,$1D
  LD (LDC82),A            ; set Inventory current
  CALL LB2DE
  CALL LB2AF
  JP LB1BB                ; continue Inventory loop
; Draw Inventory selection square
LB295:
;  LD DE,$0020
;  LD HL,Tileset2
;  ADD HL,DE
;  PUSH HL
;  POP IX
  ld ix,Tileset3+15*32
  LD B,16                 ; was: $08
  LD A,(LDC84)            ; get Y pos
  LD L,A
  LD A,(LDC83)            ; get X pos
  CALL L9E5F              ; Draw tile by XOR operation
  CALL L9FEA              ; Copy shadow screen to ZX screen
  RET
;
; Prepare item description string
;   Returns: HL = item description string
LB2AF:
  LD HL,$6812
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,LDC5B             ; Inventory list
  LD A,(LDC82)            ; get Inventory current
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  CP $63                  ; empty slot?
  JP Z,LB2CC
  LD (LDC89),A
  CALL LAE19              ; Get inventory item description string
  RET
LB2CC:
  LD HL,SE0DB             ; "---- N o  I t e m ----"
  RET
;
; Delay by LDC59
LB2D0:
  LD A,(LDC59)            ; get delay factor
  LD C,A
LB2D0_0:
  LD D,A
LB2D0_1:
  DEC D
  JP NZ,LB2D0_1
  DEC C
  JP NZ,LB2D0_0
  RET
;
LB2DE:
  ret ;STUB

; We've got Data cartridge reader
LB301:
  LD A,$01
  LD (LDCF5),A            ; Data cartridge reader slot
  RET
;
; Inventory Look/shoot key pressed
LB307:
  LD HL,LDC5B             ; Inventory list
  LD A,(LDC82)            ; get Inventory current
  LD D,$00
  LD E,A
  ADD HL,DE               ; HL = addr of current item in the list
  LD A,(HL)               ; get item
  CP $63                  ; empty slot?
  JP Z,LB1C1
  LD (LDC89),A
  OR A                    ; $00 - Data cartridge reader?
  JP Z,LB33F
  CP $13                  ; Power Drill?
  JP Z,LB3F4
  CP $14                  ; Life Support Data Disk?
  JP Z,LB44A
  CP $15                  ; Air-Lock Tool?
  JP Z,LB487
  CP $16                  ; Box of Power Cells?
  JP Z,LB4C4
  CP $19                  ; Rubik's Cube?
  JP Z,LB501
  SUB $11                 ; Data cartridge?
  JP C,LB3AF
  JP LB3E8                ; smth other
LB33F:
  LD A,$44
  LD (LDC59),A            ; set delay factor
  LD (LDC85),A            ; Use delay and copy screen in LBEDE
  LD BC,$0060             ; decode 96 bytes
  LD HL,LF42F             ; Data cartridge reader screen
  CALL LADF5              ; Decode the screen to DBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  LD A,(LDCF8)
  CP $01
  JP Z,LB36C
  LD A,$21
  LD (LDCF3),A            ; Left margin size for text
  LD HL,$2C16
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE09B             ; "No Data Cartridge Selected"
  JP LB373
LB36C:
  LD HL,$1416
  LD ($86D7),HL           ; Set penRow/penCol
  POP HL
LB373:
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD A,(LDC89)
  CP $02
  CALL Z,LB39A
  CP $03
  CALL Z,LB3A1
  CP $04
  CALL Z,LB3A8
  CALL L9FEA              ; Copy shadow screen to ZX screen
LB38B:
  CALL LA0F1              ; Scan keyboard
  CP $37
  JP NZ,LB38B
  XOR A
  LD (LDC85),A            ; Skip delay and copy screen in LBEDE
  JP L9DDD                ; return to the main game loop
LB39A:
  LD HL,LDC96
  CALL LBC3C
  RET
LB3A1:
  LD HL,LDC9A
  CALL LBC3C
  RET
LB3A8:
  LD HL,LDC9E
  CALL LBC3C
  RET
;
; Data cartridge selected in the Inventory
LB3AF:
  LD A,(LDCF5)            ; Data cartridge reader
  OR A                    ; do we have the reader?
  JP Z,LB3C8              ; no => jump
  LD A,(LDC89)
  LD HL,LDFF3             ; Table address
  CALL LADFF              ; Get address from table by index A
  PUSH HL
  LD A,$01
  LD (LDCF8),A
  JP LB33F
LB3C8:                    ; We don't have data cartridge reader
  CALL LB2DE
  LD HL,$2E0C
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0E3             ; "You Need A Data Cartridge Reader"
  CALL LB513              ; Show message
  JP LB1C1
LB3DA:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0011
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD A,(LDB75)
  SUB C
  RET
; Something other selected in the Inventory
LB3E8:
  ret ;STUB

; Power drill selected in the Inventory
LB3F4:
  ret ;STUB

; Life Support Data Disk selected in the Inventory
LB44A:
  ret ;STUB

LB487:
  ret ;STUB

LB4C4:
  ret ;STUB

; Rubik's Cube selected in the Inventory
LB501:
  ret ;STUB

; Show message HL
LB513:
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL L9FEA              ; Copy shadow screen to ZX screen
  LD A,$01
  LD (LDCF2),A
  RET

LB529:
  OR A
  RET Z
  SUB $11
  RET NC
  LD A,$01
  RET

LB551:
  ret ;STUB

LB653
  ret ;STUB

LB72E:
  ret ;STUB

LB74C:
  ret ;STUB

; Shoot with the Weapon
LB758:
  ret ;STUB

LB76B:
  ret ;STUB

; Show look/shoot selection indicator
;
LB8EA:
  LD A,(LDB7D)            ; Get look/shoot switch value
  OR A                    ; 
  JP Z,LB902              ;
  CALL LB913              ;
  LD A,$8C                ;
  CALL L9E5F              ; Draw tile by XOR operation
  CALL LB91C              ;
  LD A,$A0                ;
  CALL L9E5F              ; Draw tile by XOR operation
  RET                     ;
LB902:
  CALL LB913              ;
  LD A,$76                ;
  CALL L9E5F              ; Draw tile by XOR operation
  CALL LB91C              ;
  LD A,$8A                ;
  CALL L9E5F              ; Draw tile by XOR operation
  RET                     ;
LB913:
  LD IX,Tileset3+1        ; Small triange pointing right
  LD B,12                 ; Tile height
  LD L,$00                ; Y pos
  RET                     ;
LB91C:
  LD IX,Tileset3+32+1     ; Small triange pointing left
  LD B,12                 ; Tile height
  LD L,$00                ; Y pos
  RET                     ;

LB925:
  ret ;STUB

; Switch Look / Shoot mode
LB930:
  LD A,(LDCF7)            ; Weapon slot
  OR A
  JP NZ,LB94C
  CALL LB925
  CALL LAB28              ; Show small message popup
  LD HL,$582C
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0D3             ; "You dont have a Weapon to equip!"
  CALL LBEDE              ; Load archived string and show message char-by-char
  JP LAD8C
LB94C:
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01
  JP Z,LB95C
  LD A,$01
  LD (LDB7D),A
  JP LB960
LB95C:
  XOR A
  LD (LDB7D),A
LB960:
  LD A,$96
  LD (LDC59),A            ; set delay factor
  CALL LB2D0              ; Delay
  JP L9E2E
;
; Display Health
LB96B:
  LD HL,$012C
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,(LDB7A)           ; get Health
  jp DrawNumber3          ; Show 3-digit decimal number HL

; Decrease Health
LB994:
  LD A,(LDB7A)            ; get Health
  SUB $02                 ; Health = Health minus 2
  CALL C,LB9A0
  LD (LDB7A),A            ; set Health
  RET
LB9A0:
  XOR A
  RET
;
; Player is dead, Health 0
;
LB9A2:
  CALL L9FCF              ; Clear shadow screen
  LD A,$32
  LD (LDCF3),A            ; Left margin size for text
  LD A,$0E
  LD (LDCF4),A            ; Line interval for text
  CALL LAB28              ; Show small message popup
  LD HL,$580E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0BD             ; "The Desolate has claimed your life too . . ."
  CALL LBEDE              ; Load archived string and show message char-by-char
  XOR A
  CALL LB9D6
  LD HL,(LDBC3)
  INC HL
  LD (LDBC3),HL
LB9C9:
  CALL L9FEA              ; Copy shadow screen to ZX screen
  CALL LA0F1              ; Scan keyboard
  CP $37                  ; "MODE" key? TODO: any key
  JP Z,L9E19              ; yes => Go to ending of main game loop
  JR LB9C9
;
LB9D6:
  LD (LDB79),A            ; set the room number
  LD (LDB75),A            ; Direction/orientation
  LD A,$06
  LD (LDB76),A            ; Set X tile coord = 6
  LD A,$30                ; was: $18
  LD (LDB77),A            ; Set Y pixel coord = 48
  LD A,$03
  LD (LDB78),A            ; Set Y tile coord = 3
  LD A,$64
  LD (LDB7A),A            ; Set Health = 100
  RET

; Decode the block
;   HL = address decode from (usually encoded room/screen)
;   DE = address decode to
;   BC = number of bytes to decode
LB9F1:
  LD A,(HL)
  CP $FF
  JR Z,LB9FB
  LDI
LB9F8:
  RET PO
  JR LB9F1
LB9FB:
  INC HL
  LD A,(HL)
  INC HL
  INC HL
LB9FF:
  DEC HL
  DEC A
  LDI
  JR NZ,LB9FF
  JR LB9F8

; Show titles and show Menu
LBA07:
  LD A,$44
  LD (LDC59),A            ; set delay factor
  LD (LDC85),A            ; Use delay and copy screen in LBEDE
  LD HL,$3A1E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE09D             ; "MaxCoderz Presents"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81              ; Delay x2
  CALL LBC7D              ; Clear shadow screen and copy to ZX screen
  CALL LBC34
  LD HL,$3A2E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE09F             ; "a tr1p1ea game"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81              ; Delay x2
  CALL LBC7D              ; Clear shadow screen and copy to ZX screen
  CALL LBC34
  XOR A
  LD (LDC85),A            ; Skip delay and copy screen in LBEDE

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
  LD C,$09                ; left triangle X pos
  LD IX,Tileset3          ; Tile arrow right
  DI
  CALL LBA88
  LD C,$4D                ; right triangle X pos
  LD IX,Tileset3+32       ; Tile arrow left
  DI
  CALL LBA88
  CALL L9FEA              ; Copy shadow screen to ZX screen
  CALL LA0F1              ; Scan keyboard
  CP $36                  ; look/shoot key
  JP Z,LBA93              ;   select menu item
  cp $09                  ; Enter key
  jp z,LBA93
  CP $04                  ; Up key
  JP Z,LBBCC
  CP $01                  ; Down key
  JP Z,LBBDC
  JP LBA3D

LBA81:
  CALL LBC34	
  CALL LBC34	
  RET
;
; Draw menu item selection triangles
LBA88:
  LD A,(LDB8F)
  LD L,A                  ; L = Y coord
  LD A,C                  ; A = X coord
  LD B,16                 ; 8 = tile height
  CALL L9E5F              ; Draw tile by XOR operation
  RET
;
LBA93:
  LD A,(LDB8F)
  CP $3A
  JP Z,LBAB2              ; New menu item
  CP $46
  JP Z,LBB82              ; Continue menu item
  CP $52
  JP Z,LBBEC              ; Info menu item
  CP $5E
  JP Z,LBF64              ; Credits menu item
  CP $6A
  JP Z,L9E51              ; Quit menu item
  JP LBA3D
;
; New menu item selected
LBAB2:
  LD A,(LDB73)
  OR A
  JP Z,LBADE
  CALL LB925
  CALL LAB28              ; Show small message popup
  LD HL,$2C07
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0A3             ; "OverWrite Current Game? Alpha = Yes :: Clear = No"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL L9FEA              ; Copy shadow screen to ZX screen
LBACE:
  CALL LA0F1              ; Scan keyboard
  CP $0F
  JP Z,LBA3D
  CP $30
  JP Z,LBADE
  JP LBACE
;
; New Game
;
LBADE:
  XOR A
  LD (LDCF7),A            ; Weapon slot
  LD (LDB7D),A            ; Get look/shoot switch value
  LD (LDBC7),A
  CALL LB9D6
  LD HL,$0000
  LD (LDBC3),HL
  LD (LDBC5),HL
  LD HL,LDB9C
  LD B,$22
LBADE_0:
  LD (HL),$00
  INC HL
  DJNZ LBADE_0
  LD HL,LDC5B             ; Inventory list
  LD B,$22
LBADE_1:
  LD (HL),$00
  INC HL
  DJNZ LBADE_1
  LD HL,LDB90
  LD B,$09
LBADE_2:
  LD (HL),$00
  INC HL
  DJNZ LBADE_2
  LD HL,LDCA2
  LD B,$48
LBADE_3:
  LD (HL),$00
  INC HL
  DJNZ LBADE_3
  LD HL,LDC96
  CALL LBC6B
  LD HL,LDC9A
  CALL LBC6B
  LD HL,LDC9E
  CALL LBC6B
  CALL LBC7D              ; Clear shadow screen and copy to ZX screen
  LD A,$44
  LD (LDC59),A            ; set delay factor
  LD (LDC85),A            ; Use delay and copy screen in LBEDE
  LD A,$0E
  LD (LDCF4),A            ; Line interval for text
  XOR A
  LD (LDCF3),A            ; Left margin size for text
  LD HL,$3A14
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE115             ; "In the Distant Future . . ."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81              ; Delay x2
  CALL LBC7D              ; Clear shadow screen and copy to ZX screen
  CALL LBA81              ; Delay x2
  CALL LBC84              ; Set zero penRow/penCol
  LD HL,SE117             ; "'The Desolate' Space Cruiser leaves orbit. ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$72B6
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0B9             ; String with arrow down sign
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL WaitAnyKey         ; Wait for any (was: Wait for Down key)
  CALL L9FCF              ; Clear shadow screen
  CALL LBC84              ; Set zero penRow/penCol
  LD HL,SE119             ; "The ship sustains heavy damage. ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL WaitAnyKey         ; Wait for any key (was: Wait for MODE key)
;
; Game start
;
LBB7E:
  XOR A
  LD (LDC85),A            ; Skip delay and copy screen in LBEDE
; Continue menu item selected
LBB82:
  LD A,$01
  LD (LDB73),A
  LD A,$FF
  LD (LDC59),A            ; set delay factor
  CALL LB2D0              ; Delay
  JP L9DDD                ; return to the main game loop
;
LBB92:
  LD A,(LDB73)
  OR A                    ; do we have the game to continue?
  JP NZ,LBBA4
  LD A,(LDB8F)
  ADD A,-24               ; up two steps
  LD (LDB8F),A
  JP LBA3D
; Menu up step
LBBA4:
  LD A,(LDB8F)
  ADD A,-12
  LD (LDB8F),A
  JP LBA3D
LBBAF:
  LD A,(LDB73)
  OR A                    ; do we have the game to continue?
  JP NZ,LBBC1
  LD A,(LDB8F)
  ADD A,24                ; down two steps
  LD (LDB8F),A
  JP LBA3D
; Menu down step
LBBC1:
  LD A,(LDB8F)
  ADD A,12
  LD (LDB8F),A
  JP LBA3D
; Menu up key pressed
LBBCC:
  LD A,(LDB8F)
  CP $3A                  ; "New Game" selected?
  JP Z,LBA3D              ; yes => continue
  CP $52                  ; "Info" selected?
  JP Z,LBB92
  JP LBBA4
; Menu down key pressed
LBBDC:
  LD A,(LDB8F)
  CP $6A                  ; "Quit" selected?
  JP Z,LBA3D
  CP $3A                  ; "New Game" selected?
  JP Z,LBBAF
  JP LBBC1
;
; Info menu item, show Controls
;
LBBEC:
  LD BC,$0060             ; Counter = 96 bytes or tiles
  LD HL,LF329             ; Decode from - Encoded screen for Inventory/Info popup
  LD DE,LDBF5             ; Where to decode
  CALL LB9F1              ; Decode the screen
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
  LD HL,SE0A7             ; "2nd = Look / Shoot Alpha = Inventory ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL L9FEA              ; Copy shadow screen to ZX screen
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
; Looooooooong delay
LBC34:
  LD B,$14                ; x20
LBC36:
  CALL LB2D0              ; Delay
  DJNZ LBC36
  RET

LBC3C:
  ret ;STUB

LBC6B:
  ret ;STUB

; Clear shadow screen and copy to ZX screen
LBC7D:
  CALL L9FCF              ; Clear shadow screen
  CALL L9FEA              ; Copy shadow screen to ZX screen
  RET

; Set zero penRow/penCol
LBC84:
  LD HL,$0000             ; Left-top corner
  LD ($86D7),HL           ; Set penRow/penCol
  RET
;
LBC8B:
  ret ;STUB

; Draw string on the screen using FontProto
;   HL = String address
LBEDE:
  ld a,(hl)
  inc hl
  or a
  ret z
  cp $7C	                ; '|'
  jr z,LBF1B
  push hl
  call DrawChar
  LD A,(LDC85)            ; get Delay and copy screen flag
  OR A
  JR Z,LBEF9_1            ; Skip delay and copy screen
  CALL LB2D0              ; Delay
  CALL L9FEA              ; Copy shadow screen to ZX screen
LBEF9_1:
  pop hl
  jr LBEDE
LBF1B:
  PUSH BC
  LD A,($86D8)            ; Get penRow
  LD C,A
  LD A,(LDCF4)            ; Line interval for text
  ADD A,C
  LD ($86D8),A            ; Set penRow
  LD A,(LDCF3)            ; Get left margin size for text
  LD ($86D7),A            ; Set penCol
  POP BC
  jr LBEDE

; Set variables for Credits
;
LBF54:
  XOR A
  LD (LDD57),A
  LD (LDD56),A
  LD (LDC85),A            ; Skip delay and copy screen in LBEDE
  LD A,$96
  LD (LDC59),A            ; set delay factor
  RET
;
; Credits menu item selected
LBF64:
  CALL L9FCF              ; Clear shadow screen
  CALL L9FEA              ; Copy shadow screen to ZX screen
  CALL LBF54
  JR LBF81
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
  LD ($86D8),A            ; Set penRow
LBF686:
  JP LBF6F_4
LBF6F_2:
  call L9FEA              ; Copy shadow screen to ZX screen
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
  LD ($86D7),A           ; Set penCol
  LD A,(LDD57)
  LD HL,LDD58
  CALL LADFF              ; Get address from table by index A
  CALL DrawString         ; Draw string on shadow screen without any delays
  LD A,(LDD57)
  INC A                   ; increase the counter
  LD (LDD57),A
  CP $47
  JP NZ,LBF6F_3
  JP LBA3D                ; Return to main Menu
; Scroll shadow screen up 1px
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
