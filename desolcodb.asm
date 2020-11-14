
; Game main loop
;
L9DDD:
  LD A,(LDB7A)            ; Get Health
  OR A
  JP Z,LB9A2              ; zero => Player is dead
  CALL LADE5              ; Decode current room to LDBF5; HL = LDBF5
  CALL LA88F              ; Display 96 tiles on the screen
  CALL LB96B              ; Display Health
  CALL LB8EA              ; Show look/shoot selection indicator
  CALL LB76B              ; Process shoot
  CALL LB551              ; Process Alien in the room
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
;  XOR A
;  LD (LDB7C),A            ; ??
  JP LA8C6                ; Draw the Player, then go to the Ending of main game loop
;
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
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  jr L9DDD                ; continue main game loop

; Quit menu item selected
L9E51:
  call LBC7D              ; Clear shadow screen and copy on ZX screen
  ld hl,$3014
  ld (L86D7),hl
  ld hl,SQuit
  call LBEDE              ; Show the message
  call ShowShadowScreen
  call WaitAnyKey
  jp LBA3D                ; Return to Menu

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
L9E8D:                    ; loop by B - by rows
  push bc
  ld b,(ix+$01)
  ld d,(ix+$00)
  ld e,$00
  ld a,c
  or a                    ; shift = 0?
  jr z,L9E9D              ; yes => skip all shift ops
L9E96:
  srl b
  rr d
  rr e
  dec a
  jr nz,L9E96
L9E9D:
  ld a,(hl)               ; get 1st byte from the screen
  xor d
  ld (hl),a               ; put byte on the screen
  inc hl
  ld a,(hl)               ; get 2nd byte from the screen
  xor e
  ld (hl),a               ; put byte on the screen
  ld a,(hl)               ; get 1st byte from the screen
  xor b
  ld (hl),a               ; put byte on the screen
  ld de,24-1
  add hl,de               ; to the next line
  inc ix
  inc ix
  pop bc
  djnz L9E8D              ; continue loop by rows
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
  ld (L86D7),a          ; penCol
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
;   DE = tile address; H = column; L = row
;   A = flags: bit7=1 - reflect horz, bit6=1 - reflect vert
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
  BIT 6,A
  CALL NZ,L9EDE_VR        ; Reflect tile vertically
  BIT 7,A
  CALL NZ,L9EDE_HR        ; Reflect tile horizontally
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
; Vertical reflection
L9EDE_VR:
  push af
  ld ix,L9FAF
  ld iy,L9FAF+28
  ld b,8
L9EDE_VR_1:
  ld a,(ix+$00)
  ld (iy+$00),a
  ld a,(ix+$01)
  ld (iy+$01),a
  ld a,(ix+$02)
  ld (iy+$02),a
  ld a,(ix+$03)
  ld (iy+$03),a
  inc ix
  inc ix
  inc ix
  inc ix
  dec iy
  dec iy
  dec iy
  dec iy
  djnz L9EDE_VR_1
  pop af
  ret
; Horizontal reflection
L9EDE_HR:
  push af
  ld ix,L9FAF
  ld b,8
L9EDE_HR_1:
; Exchange bytes 0 <-> 2
  ld a,(ix+$00)
  ld c,(ix+$02)
  call ReflectByte
  ld (ix+$02),a
  ld a,c
  call ReflectByte
  ld (ix+$00),a
; Exchange bytes 1 <-> 3
  ld a,(ix+$01)
  ld c,(ix+$03)
  call ReflectByte
  ld (ix+$03),a
  ld a,c
  call ReflectByte
  ld (ix+$01),a
  inc ix
  inc ix
  inc ix
  inc ix
  djnz L9EDE_HR_1
  pop af
  ret
;
L9FAF:
  DEFS 32,$00
;
; Reflect byte bits of A
ReflectByte:
  push bc
  rlca
  rr c
  rlca
  rr c
  rlca
  rr c
  rlca
  rr c
  rlca
  rr c
  rlca
  rr c
  rlca
  rr c
  rlca
  rr c
  ld a,c
  pop bc
  ret

; Copy shadow screen to ZX screen
;
L9FEA EQU ShowShadowScreen

; Clear shadow screen
;
ClearShadowScreen:
L9FCF:
  ld bc,24*138-1	        ; 64 line pairs + 10 extra lines
  ld hl,ShadowScreen
  ld de,ShadowScreen+1
  ld (hl),$00
  ldir
  ret

; Scan keyboard
; Returns key in A; Z=0 for key, Z=1 for no key
;
LA0F1:
  PUSH BC
  PUSH DE
  PUSH HL
  call ReadKeyboard
  POP HL
  POP DE
  POP BC
  RET

;NOTE: This routine is not used
; Select interrupt frequency
;LA19E:
;
;NOTE: This routine is not used
; Copy screen 1st color onto Screen 2nd color
;LA283:
;
;NOTE: This is not used
;A28F-A58E - screen 1st color
;A58F-A88E - screen 2nd color
;
; Display 96 tiles on the screen
;   HL Address where the 96 tiles are placed
LA88F:
  LD DE,$0000
LA892:
  PUSH HL
  PUSH DE
  LD L,(HL)               ; get tile number
  LD A,L
  OR A                    ; empty tile?
  JR Z,LA8B0              ; yes => skip it
  CP $47                  ; menu background tile?
  CALL Z,LBC29            ; yes => add phase to L
  LD H,$00
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ; now HL = HL * 16
  add hl,hl               ; now HL = HL * 32
  LD BC,Tileset1
  ADD HL,BC
  PUSH HL
  POP IX
  LD A,E
  LD L,D
  CALL L9EAD              ; Put tile on the screen
LA8B0:
  POP DE
  POP HL
  INC HL
  INC E
  LD A,E
  CP $0C                  ; was last column?
  jr NZ,LA892             ; no => continue loop by columns
  LD E,$00
  LD A,$10
  ADD A,D                 ; next tile row
  LD D,A
  CP $80                  ; was last tile row?
  jr NZ,LA892             ; no => continue loop by tile rows
  RET
;
LA8C6:
  XOR A
  LD (LDD54),A            ; clear animation phase
;  JP LA8CD
;
; Draw Player tiles
LA8CD:
  LD C,$00
  LD A,(LDD55)            ; get shooting flag
  OR A                    ; shooting animation?
  JR Z,LA8DF              ; no => jump
  LD HL,LDE87             ; Table with Player's tile numbers
  LD A,(LDB75)            ; Direction/orientation
  ADD A,A
  ADD A,A                 ; now A = Direction * 4
  JR LA8E9
LA8DF:
  LD HL,LDE47             ; Table with Player's tile numbers
  LD A,(LDB75)            ; Direction/orientation
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A                 ; now A = Direction * 16
LA8E9:
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(LDD54)            ; get animation phase
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
  CALL LA956              ; if looking left - set C bit7=1 to reflect tile horizontal
  LD A,C
  CALL L9EDE              ; Draw tile DE at column H row L
  POP BC
  POP HL
  INC HL
  DJNZ LA8F8              ; continue loop by tiles
  LD A,(LDD54)            ; get animation phase 0..3
  CP $03                  ; was last phase?
  JR Z,LA927              ; yes => jump
  INC A                   ; next phase
  LD (LDD54),A            ; set animation phase
  XOR A
  LD (LDD55),A            ; clear shooting flag for player's animation
  JP L9E19                ; Go to ending of main game loop
LA927:
  XOR A
  LD (LDD54),A            ; clear animation phase
  JP L9E19                ; Go to ending of main game loop
;
LA92E:
  INC C
  LD A,(LDB76)            ; get X coord in tiles
  add a,a                 ; now coord in 8px columns
  LD H,A
  LD A,(LDB77)            ; get Y coord in lines
  SUB 16    ; was: $08
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
  inc h
  RET
LA94A:
  DEC H                   ; left
  dec h
  RET
LA94C:
  LD A,16   ; was: $08
  ADD A,L
  LD L,A
  LD A,C
  CP $04
  JR Z,LA941
  RET
;
LA956:
  LD C,$00
  LD A,(LDB75)            ; Direction/orientation
  OR A                    ; down?
  RET Z
  CP $01                  ; up?
  RET Z
  CP $03                  ; right?
  RET Z
  LD C,$80                ; looking left => reflect the tile horizontal
  RET
;
; Move Down
LA966:
  LD A,(LDB75)            ; Direction/orientation
  OR A                    ; down?
  jr Z,LA97C
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01
  jr NZ,LA97C
  XOR A                   ; down
  LD (LDB75),A            ; set Direction/orientation
  JP LA8C6                ; Proceed to Draw the Player
LA97C:
  XOR A                   ; down
  LD (LDB75),A            ; set Direction/orientation
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB77)            ; get Y pixel coord
  PUSH AF
  ADD A,16                ; Down one tile; was: $08
  LD (LDB77),A            ; set Y pixel coord
  LD A,(LDB78)            ; get Y tile coord
  PUSH AF
  INC A
  LD (LDB78),A            ; set Y tile coord
  JR LA9D1
;
; Move Up
LA99B:
  LD A,(LDB75)            ; Direction/orientation
  CP $01                  ; up?
  jr Z,LA9B3
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01                  ; shoot?
  jr NZ,LA9B3
  LD A,$01                ; up
  LD (LDB75),A            ; Direction/orientation
  JP LA8C6                ; Proceed to Draw the Player
LA9B3:
  LD A,$01                ; up
  LD (LDB75),A            ; Direction/orientation
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB77)            ; get Y pixel coord
  PUSH AF
  ADD A,-16               ; Up one tile; was: $F8
  LD (LDB77),A            ; set Y pixel coord
  LD A,(LDB78)            ; get Y tile coord
  PUSH AF
  DEC A
  LD (LDB78),A            ; set Y tile coord
; Moved down or up, check for Alien
LA9D1:
  LD A,(LDB84)
  OR A
  jr Z,LA9E6
  CALL LB72E              ; Get value at offset $2F in the room description
  OR A                    ; do we have the alien?
  jr Z,LA9E6              ; we don't have it => jump
; We have an alien in the room
  CALL LB74C
  OR A
  JP Z,LB07B              ; Decrease Health by 4, restore Y coord
LA9E6:
  POP AF
  POP AF
  JP LA8CD
;
; Move Left
LA9EB:
  LD A,(LDB75)            ; Direction/orientation
  CP $02                  ; looking left?
  jr Z,LAA03
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01                  ; shoot?
  jr NZ,LAA03
  LD A,$02                ; left
  LD (LDB75),A            ; set Direction/orientation
  JP LA8C6                ; Proceed to Draw the Player
LAA03:
  LD A,$02                ; left
  LD (LDB75),A            ; set Direction/orientation
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB76)            ; get X coord in tiles
  PUSH AF
  DEC A                   ; one tile left
  LD (LDB76),A            ; set X coord in tiles
  JR LAA47                ; go to Alien check
;
; Move Right
LAA1A:
  LD A,(LDB75)            ; Direction/orientation
  CP $03                  ; right?
  jr Z,LAA32
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01                  ; shoot?
  jr NZ,LAA32             ; no => jump
  LD A,$03                ; right
  LD (LDB75),A            ; Direction/orientation
  JP LA8C6                ; Proceed to Draw the Player
LAA32:
  LD A,$03                ; right
  LD (LDB75),A            ; Direction/orientation
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB76)            ; get X coord in tiles
  PUSH AF
  INC A                   ; one tile right
  LD (LDB76),A            ; set X coord in tiles
; Moved left or right, check for Alien
LAA47:
  LD A,(LDB84)
  OR A
  jr Z,LAA5C
  CALL LB72E              ; Get value at offset $2F in the room description
  OR A                    ; do we have the alien?
  jr Z,LAA5C              ; we don't have it => jump
; We have an alien in the room
  CALL LB74C
  OR A
  JP Z,LB08D              ; Decrease Health by 4, restore X coord
LAA5C:
  POP AF
  JP LA8CD
;
LAA60:
  CALL LADE5              ; Decode current room to LDBF5; HL = LDBF5
  LD A,(LDB76)            ; get X coord in tiles
  LD E,A
  CALL LAA7D              ; For direction left - dec E, right - inc E
  LD D,$00
  ADD HL,DE
  LD A,(LDB74)            ; $0C - line width in tiles ??
  LD E,A
  LD A,(LDB78)            ; Get Y tile coord
  LD B,A
  CALL LAA8D              ; For direction up - dec B, down - inc B
LAA78:
  ADD HL,DE
  DJNZ LAA78
  LD A,(HL)
  RET
;
; For direction left - dec E, right - inc E
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
; For direction up - dec B, down - inc B
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
; Get room offset in tiles for X = LDB76, Y = LDB78
;   Returns the room offset in E, A, and LDC56
LAA9D:
  LD A,(LDB74)            ; $0C - line width in tiles ??
  LD E,A
  LD A,(LDB78)            ; get Y tile coord
  LD B,A
  LD A,(LDB76)            ; get X tile coord
LAAA8:
  ADD A,E                 ; add a,12
  DJNZ LAAA8
  LD (LDC56),A            ; (LDC56) = Y * 12 + X
  RET
;
; Look / Shoot
LAAAF:
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01                  ; shoot mode?
  JP Z,LB758              ; yes => jump
; Look action
  XOR A
  LD (LDC88),A            ; clear current offset
  CALL LAA9D              ; Get room offset in tiles for X = LDB76, Y = LDB78
  CALL LAE09              ; Decode current room description to LDBF5
LAAC1:
  LD A,(HL)
  LD C,A
  LD A,(LDC56)            ; get offset in the room
  SUB C
  jr Z,LAADD              ; found the action point for the current position
  LD A,(LDC88)            ; get current offset
  CP $31
  jr Z,LAADA              ; => Show the screen, continue the game main loop
  INC A
  LD (LDC88),A            ; set current offset
  INC HL
  jr LAAC1
; Show the screen, continue the game main loop
LAADA:
  JP L9E2E                ; Show the screen, continue the game main loop
; Found the action point for the current position in the room description
LAADD:
  LD A,(LDC88)            ; get current offset in the room description
  OR A
  jr Z,LAB3F
  CP $01
  jr Z,LAB3F
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
;TODO: Replace with call to LADF5
  LD DE,LDBF5             ; Decode to
  CALL LB9F1              ; Decode the screen
  LD HL,LDBF5
  CALL LB177              ; Display screen HL from tiles with Tileset 2
  POP DE
  POP BC
  RET
;
; Found action point at room description offset $00..$01
LAB3F:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0002             ; offset in the room description
  CALL LAC4C              ; Compare byte at (HL+DE) with Direction/orientation LDB75
  JP NZ,LAADA             ; => Show the screen, continue the game main loop
  LD A,(LDB79)            ; Get room number
  CP $1B                  ; room #27?
  jr NZ,LAB7A             ; no => jump
; Room #27
  LD A,(LDCF7)            ; Weapon slot
  OR A                    ; do we have it?
  jr NZ,LAB7A             ; have weapon => jump
  LD A,22   ; was: $0B
  LD (LDCF3),A            ; Left margin size for text
  LD A,14   ; was: $07
  LD (LDCF4),A            ; Line interval for text
  CALL LAB28              ; Show small message popup
  CALL LAB73              ; Set penRow/penCol for small message popup
  LD HL,SE0D5             ; "It is not wise to proceed without a weapon."
  CALL LBEDE              ; Show message char-by-char
  JP LAD8C                ; Show screen and wait for MODE key
;
; Set penRow/penCol for small message popup
LAB73:
  LD HL,$5812
  LD (L86D7),HL           ; Set penRow/penCol
  RET
;
LAB7A:
  LD A,$01
  LD (LDC8A),A
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$001C             ; offset in the room description - access level
LAB85:
  ADD HL,DE
  LD A,(HL)
  LD (LDC8C),A            ; Set Access code level
  LD DE,$0007
  ADD HL,DE               ; HL = $1C+$07=$23 - offset for room number
  LD A,(HL)
  LD (LDC86),A            ; new room number??
  LD DE,$0004
  ADD HL,DE               ; HL = $1C+$07+$04=$27 - offset for Access code slot
  LD A,(HL)
  LD (LDC8B),A            ; set Access code slot number
  LD A,(LDC8C)            ; Get Access code level
  OR A                    ; Level 0?
  JP Z,LB00E              ; yes => Going to the next room
  JP LAE23
;
; Found action point at room description offset $03..$04
LABA4:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0005             ; offset in the room description - direction
  CALL LAC4C              ; Compare byte at (HL+DE) with Direction/orientation LDB75
  JP NZ,LAADA             ; => Show the screen, continue the game main loop
  LD A,$02
  LD (LDC8A),A
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$001D             ; offset in the room description
  jr LAB85
;
; Found action point at room description offset $19..$1A
LABBE:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$001B             ; offset in the room description - direction byte
  CALL LAC4C              ; Compare byte at (HL+DE) with Direction/orientation LDB75
  JP NZ,LAADA             ; => Show the screen, continue the game main loop
  LD A,(LDB79)            ; Get the room number
  CP $21                  ; room #33?
  jr NZ,LABF7
; Room #33
  LD DE,$0004
  CALL LB531              ; Get value (LDB90+DE)
  jr NZ,LABF7
  LD A,16     ; was: $08
  LD (LDCF3),A            ; Left margin size for text
  LD A,14     ; was: $07
  LD (LDCF4),A            ; Line interval for text
  CALL LAB28              ; Show small message popup
  LD HL,$580C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0D7             ; "You cant enter that sector Life-Support is offline."
  CALL LBEDE              ; Show message char-by-char
  JP LAD8C                ; Show screen and wait for MODE key
LABF7:
  LD A,$03
  LD (LDC8A),A
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$001E             ; offset in the room description
  JP LAB85
;
; Found action point at room description offset $21..$22 (possibly an error, should be $20-$21)
LAC05:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0022             ; offset in the room description
  CALL LAC4C              ; Compare byte at (HL+DE) with Direction/orientation LDB75
  JP NZ,LAADA             ; => Show the screen, continue the game main loop
  LD A,(LDB79)            ; Get the room number
  CP $45                  ; room #69?
  jr NZ,LAC3E             ; no => jump
; Room #69
  LD DE,$0005
  CALL LB531              ; Get value (LDB90+DE)
  jr NZ,LAC3E
  LD A,12     ; was: $06
  LD (LDCF3),A            ; Left margin size for text
  LD A,14     ; was: $07
  LD (LDCF4),A            ; Line interval for text
  CALL LAB28              ; Show small message popup
  LD HL,$5814
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0D9             ; "You cant enter until the AirLock is re-pressurised"
  CALL LBEDE              ; Show message char-by-char
  JP LAD8C                ; Show screen and wait for MODE key
LAC3E:
  LD A,$04
  LD (LDC8A),A
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$001F             ; offset in the room description
  JP LAB85
;
; Compare byte at (HL+DE) with Direction/orientation LDB75
LAC4C:
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD A,(LDB75)            ; Direction/orientation
  SUB C
  RET
;
; Found action point at room description offset $06..$07
LAC54:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0008             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD A,(LDB75)            ; Direction/orientation
  SUB C
  JP NZ,LAADA             ; => Show the screen, continue the game main loop
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$000A             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  LD (LDC89),A            ; set as current item
  CALL LAE09              ; Decode current room description to LDBF5 (again?)
  LD DE,$0009             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  CP $01
  jr Z,LAC97
; Found dead body, no items on it
  CALL LAB28              ; Show small message popup
  CALL LAB73              ; Set penRow/penCol for small message popup
  LD HL,SE0C3             ; " Another Dead Person"
  CALL LBEDE              ; Show message char-by-char
  LD HL,$6612
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0C5             ; " Search Reveals Nothing"
  CALL LBEDE              ; Show message char-by-char
  JP LAD8C                ; Show screen and wait for MODE key
; Found dead body with some item on it
LAC97:
  CALL LAD4F              ; Get inventory item flag for item number in LDC89
  CP $01                  ; do we have it already?
  JP Z,LAADA              ; have it => Show the screen, continue the game main loop
  LD A,(LDB79)            ; Get the room number
  OR A                    ; room #0 ?
  jr Z,LACC5              ; yes => Small message popup "OMG! This Person Is DEAD! What Happened Here!?!"
  CALL LAB28              ; Show small message popup
  CALL LAB73              ; Set penRow/penCol for small message popup
  LD HL,SE0C7             ; " This Person is Dead . . ."
  CALL LBEDE              ; Show message char-by-char
  CALL LACB8              ; Show arrow sign as prompt to continue
  JP LAD00
;
; Show arrow sign in bottom-right corner, as a prompt to continue
LACB8:
  LD HL,$66B0
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0B9             ; String with arrow down sign
  jp LBEDE                ; Show message char-by-char
;  RET
;
; Small message popup "OMG! This Person Is DEAD! What Happened Here!?!"
LACC5:
  CALL LAB28              ; Show small message popup
  CALL LAB73              ; Set penRow/penCol for small message popup
  LD HL,SE0BF             ; "OMG! This Person Is DEAD!"
  CALL LBEDE              ; Show message char-by-char
  LD HL,$6612
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0C1             ; "What Happened Here!?!"
  CALL LBEDE              ; Show message char-by-char
  CALL LACB8              ; Show arrow sign as prompt to continue
  jr LAD00
;
; Found action point at room description offset $0B..$0C
LACE3:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$000D             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD A,(LDB75)            ; Direction/orientation
  SUB C
  JP NZ,LAADA             ; => Show the screen, continue the game main loop
  JP LAD5B
;
; Show screen, wait for down key, show small message popup
LACF6:
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  CALL LAD99              ; Wait for Down key
;  CALL LAB28              ; Show small message popup
  jp LAB28
;  RET
;
LAD00:
  CALL LACF6              ; Show screen, wait for down key, show small message popup
  LD HL,$5816
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0C9             ; "They Seem To Be Holding"
  CALL LBEDE              ; Show message char-by-char
  LD HL,$663E
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0CB             ; "Something"
  CALL LBEDE              ; Show message char-by-char
  LD A,(LDBC7)            ; get Items Found count
  INC A
  LD (LDBC7),A            ; set Items Found count
LAD22:
  CALL LACB8
  CALL LACF6
  LD HL,$5830
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0CF             ; "You Picked Up A"
  CALL LBEDE              ; Show message char-by-char
  LD HL,$6612
  LD (L86D7),HL           ; Set penRow/penCol
  CALL LAE19              ; Get inventory item description string
  CALL LBEDE              ; Show message char-by-char
  LD A,(LDC89)            ; get the current item number
  LD H,$00
  LD L,A
  LD DE,LDB9C             ; Inventory table address
  ADD HL,DE               ; HL = item address in my Inventory
  LD (HL),$01             ; Mark that we have the item now
  JP LAD8C                ; Show screen and wait for MODE key
;
; Get inventory item flag for item number in LDC89
LAD4F:
  LD A,(LDC89)            ; get current item number
  LD H,$00
  LD L,A
  LD DE,LDB9C             ; Inventory table address
  ADD HL,DE               ; HL = item address in my Inventory
  LD A,(HL)               ; A = item flag: $00 = not having, $01 = have it
  RET
;
LAD5B:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$000E             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  LD (LDC89),A            ; set as current item
  CP $23                  ; weapon?
  JP Z,LADA9              ; yes => jump
  CALL LAD4F              ; Get inventory item flag for item number in LDC89
  CP $01                  ; do we have it?
  JP Z,LAADA              ; yes => Show the screen, continue the game main loop
  CALL LAB28              ; Show small message popup
  LD HL,$5816
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0CD             ; " Hey Whats This . . . ?"
  CALL LBEDE              ; Show message char-by-char
  LD A,(LDBC7)            ; get Items Found count
  INC A
  LD (LDBC7),A            ; set Items Found count
  JP LAD22
;
; Show screen and wait for MODE key
LAD8C:
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
LAD8F:
  CALL LA0F1              ; Scan keyboard
  CP $37                  ; MODE key?
  JR NZ,LAD8F
  JP L9E2E                ; Show the screen, continue the game main loop
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
  CP $37                  ; MODE key?
  JR NZ,LADA1
  RET
;
; We found the weapon
LADA9:
  LD A,(LDCF7)            ; Weapon slot
  OR A                    ; do we have it already?
  JP NZ,LAADA             ; yes => Show the screen, continue the game main loop
; Picking up the weapon
  CALL LAB28              ; Show small message popup
  LD A,$01
  LD (LDCF7),A            ; We've got the weapon
  LD HL,$581C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0CD             ; "     Hey Whats This  .  .  . ?"
  CALL LBEDE              ; Show message char-by-char
  CALL LACB8
  CALL LACF6
  LD HL,$5830
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0CF             ; "You Picked Up A"
  CALL LBEDE              ; Show message char-by-char
  LD HL,$662C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0B7             ; " Ion Phaser"
  CALL LBEDE              ; Show message char-by-char
  JP LAD8C                ; Show screen and wait for MODE key
;
; Decode current room to LDBF5
;   Returns: HL = LDBF5
LADE5:
  LD A,(LDB79)            ; Get the room number
  LD HL,LDE97             ; List of encoded room addresses
  CALL LADFF              ; now HL = encoded room address
;TODO: Entry point here to decode 96 bytes to LDBF5
  LD BC,$0060             ; decode 96 bytes
;  CALL LADF5              ; Decode the room to LDBF5
;  RET
; Decode the room/screen to LDBF5
;   HL = decode from; BC = tile count to decode
;   Returns: HL = LDBF5
LADF5:
  LD DE,LDBF5             ; Decode to
  CALL LB9F1              ; Decode the room/screen
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
;  CALL LADF5              ; Decode the room description to LDBF5
  jr LADF5
;  RET
;
; Inventory item to item description string
LAE19:
  LD A,(LDC89)            ; get current item number
  LD HL,LDFB7
;  CALL LADFF              ; Get address from table by index A
  jr LADFF
;  RET
;
LAE23:
  LD A,$28
  LD (LDC59),A            ; set delay factor
  LD A,(LDC8B)            ; get Access code slot number
  LD D,$00
  LD E,A
  LD HL,LDCA2             ; Table with Access code slots
  ADD HL,DE
  LD A,(HL)
  CP $01                  ; code was entered already?
  JP Z,LB00E              ; yes => Going to the next room
  LD B,$04
  LD HL,LDC8D             ; Buffer for entering access code
LAE3D:
  LD (HL),$00
  INC HL
  DJNZ LAE3D
  LD BC,$0060             ; decode 96 bytes
  LD HL,LF468             ; Encoded screen: Door access panel popup
  CALL LADF5              ; Decode the screen to DBF5
  CALL LB177              ; Display screen HL from tiles with Tileset 2
  LD A,10     ; was: $05
  LD (LDCF3),A            ; Left margin size for text
  ld a,12     ; was: $06
  LD (LDCF4),A            ; Line interval for text
  CALL LB09B              ; Preparing to draw string with the prompt
  LD HL,SE0DD             ; ": Door Locked :"
  CALL LBEDE              ; Show message char-by-char
  LD HL,$440A
  LD (L86D7),HL           ; Set penRow/penCol
  CALL LAFFE              ; Get "Access code level N required" string by access level in DC8C
  CALL LBEDE              ; Show message HL char-by-char
  LD A,$25
  LD (LDC82),A            ; set Inventory current
  LD A,$A0                ; was: $50
  LD (LDC83),A            ; set X pos
  LD A,$60                ; was: $30
  LD (LDC84),A            ; set Y pos
  LD A,$06
  LD (LDC57),A
LAE80:
;  LD HL,$0020
;  LD DE,Tileset2
;  ADD HL,DE
  ld hl,Tileset3+15*32    ; Selection box tile
  PUSH HL
  POP IX                  ; IX = tile address
  LD B,16   ; was: $08    ; B = height
  LD A,(LDC84)            ; get Y pos
  LD L,A
  LD A,(LDC83)            ; get X pos
  CALL L9E5F              ; Draw tile by XOR operation
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
; Delay and wait for key in Door Lock
LAE99:
  LD B,$0C                ; x12
LAE9B:
  CALL LB2D0              ; Delay by LDC59
  DJNZ LAE9B
  CALL LA0F1              ; Scan keyboard
  CP $36                  ; Select key
  jr Z,LAEBA
  CP $02                  ; left key?
  JP Z,LAF70              ;   Move left
  CP $03                  ; right key?
  JP Z,LAF86              ;   Move right
  CP $37                  ; Escape key?
  jr NZ,LAE99             ;   no => continue the key waiting loop
  JP L9E2E                ; Exit Door Lock - Show the screen, continue the game main loop
; Select key pressed
LAEBA:
  call WaitKeyUp          ; Wait until no key pressed to prevent double-reads of the same key
  LD A,(LDC82)            ; get current selection
  CP $25
  JP Z,LAF14
  LD A,(LDC57)
  DEC A
  CP $01
  jr Z,LAE99              ; Return to Delay and wait for key in Door Lock
  LD (LDC57),A
  LD B,$03
  LD HL,LDC8D             ; Buffer for entering access code
  INC HL
LAED4:
  PUSH HL
  LD A,(HL)
  DEC HL
  LD (HL),A
  POP HL
  INC HL
  DJNZ LAED4
  LD DE,$0003
  LD HL,LDC8D             ; Buffer for entering access code
  ADD HL,DE
  LD A,(LDC82)            ; get current selection
  LD (HL),A
  LD HL,LDC8D             ; Buffer for entering access code
  LD A,4    ; was: $02
  LD C,A
  LD B,$00
LAEEF:
  PUSH HL
  LD L,(HL)               ; get tile number
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  add hl,hl               ; now HL = L * 32
  LD DE,Tileset2
  ADD HL,DE
  PUSH BC
  EX DE,HL                ; now DE = tile address
  LD H,C
  LD L,16   ; was: $08
  XOR A                   ; clear draw flags
  CALL L9EDE              ; Draw tile DE at column H row L
  POP BC
  POP HL
  INC HL
  INC C
  inc c
  LD A,C
  CP 12     ;was: $06
  jr NZ,LAEEF
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  JP LAE99                ; Return to Delay and wait for key in Door Lock
;
LAF14:
  LD A,(LDC57)
  DEC A
  CP $01
  jr Z,LAF2C
; Invalid Code
LAF1D:
  CALL LB09B              ; Preparing to draw string with the result
  LD HL,SE0DF             ; "INVALID CODE"
  CALL LBEDE              ; Show message char-by-char
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  JP LAE99                ; Return to Delay and wait for key in Door Lock
; Code Accepted!
LAF2C:
  LD B,$04
  LD DE,LDC8D             ; Buffer for entering access code
  CALL LAFEC              ; LDC8C access code level -> HL = address from LE015 table
LAF34:
  LD A,(DE)
  LD C,A
  LD A,(HL)
  SUB C
  jr NZ,LAF1D
  INC DE
  INC HL
  DJNZ LAF34
  CALL LB09B              ; Preparing to draw string with the result
  LD HL,SE0E1             ; " Accepted! "
  CALL LBEDE              ; Show message char-by-char
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  LD A,(LDC8B)            ; get Access code slot number
  LD D,$00
  LD E,A
  LD HL,LDCA2             ; Table with Access code slots
  ADD HL,DE
  LD (HL),$01             ; Mark code here was accepted
  JP LB00E                ; Going to the next room
;
LAF5A:
  CALL LAFD2
  LD A,(LDC82)
  INC A
  LD (LDC82),A
  RET
;
LAF65:
  CALL LAFD2
  LD A,(LDC82)
  DEC A
  LD (LDC82),A
  RET
; Door Lock Move left
LAF70:
  LD A,(LDC83)            ; get X pos
  CP $80                  ; was: $40
  jr Z,LAF9C              ; => Move prev row
  CALL LAF65
  LD A,(LDC83)            ; get X pos
  ADD A,-16               ; was: $F8
  LD (LDC83),A            ; set X pos
  JP LAE80
; Door Lock Move right
LAF86:
  LD A,(LDC83)            ; get X pos
  CP $A0      ; was: $50
  jr Z,LAFB7              ; => Move next row
  CALL LAF5A
  LD A,(LDC83)            ; get X pos
  ADD A,16    ; was: $08
  LD (LDC83),A            ; set X pos
  JP LAE80
; Move prev row
LAF9C:
  LD A,(LDC84)            ; get Y pos
  CP $30      ; was: $18
  JP Z,LAE99              ; Return to Delay and wait for key in Door Lock
  CALL LAF65
  LD A,$A0    ; was: $50
  LD (LDC83),A            ; set X pos
  LD A,(LDC84)            ; get Y pos
  ADD A,-16   ; was: $F8
  LD (LDC84),A            ; set Y pos
  JP LAE80
; Move next row
LAFB7:
  LD A,(LDC84)            ; get Y pos
  CP $60      ; was: $30
  JP Z,LAE99              ; Return to Delay and wait for key in Door Lock
  CALL LAF5A
  LD A,$80    ; was: $40
  LD (LDC83),A            ; set X pos
  LD A,(LDC84)            ; get Y pos
  ADD A,16    ; was: $08
  LD (LDC84),A            ; set Y pos
  JP LAE80
;
LAFD2:
;  LD HL,$0020
;  LD DE,Tileset2
;  ADD HL,DE
  ld hl,Tileset3+15*32   ; Gray square to use as selection box
  PUSH HL
  POP IX
  LD B,16     ; was: $08
  LD A,(LDC84)            ; get Y pos
  LD L,A
  LD A,(LDC83)            ; get X pos
  CALL L9E5F              ; Draw tile by XOR operation
;  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  jp ShowShadowScreen
;  RET
;
; LDC8C access code level -> address from LE015 table
LAFEC:
  PUSH DE
  LD A,(LDC8C)            ; Get Access code level
  ADD A,A
  LD E,A
  LD D,$00                ; now DE = Level * 2
  LD HL,LE015             ; Table of addresses
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  POP DE
  RET
;
; LDC8C access code level -> message address from LE01F table
LAFFE:
  LD A,(LDC8C)            ; Get Access code level
  ADD A,A
  LD E,A
  LD D,$00                ; now DE = Level * 2
  LD HL,LE01F             ; Access code messages table
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  RET
;
; Going to the next room
LB00E:
  XOR A
  LD (LDB82),A            ; mark we don't have an alien in the room
  LD A,$40
  LD (LDC59),A            ; set delay factor
  LD A,(LDC8A)
  CP $01
  jr Z,LB03E
  CP $02
  jr Z,LB04F
  CP $03
  jr Z,LB061
  CP $04
  jr Z,LB06E
LB02E:
  LD B,$08
LB030:
  CALL LB2D0              ; Delay
  DJNZ LB030
  LD A,(LDC86)
  LD (LDB79),A            ; set the room number
  JP L9E2E                ; Show the screen, continue the game main loop
LB03E:
  LD A,$30      ; was: $18
  LD (LDB77),A            ; set Y pixel coord
  XOR A
  LD (LDB75),A            ; Direction/orientation
  LD A,$03
  LD (LDB78),A            ; set Y tile coord
  JP LB02E
LB04F:
  LD A,$60      ; was: $30
  LD (LDB77),A            ; set Y pixel coord
  LD A,$01
  LD (LDB75),A            ; Direction/orientation
  LD A,$06
  LD (LDB78),A            ; set Y tile coord
  JP LB02E
LB061:
  LD A,$0A
  LD (LDB76),A            ; set X coord = 10
  LD A,$02
  LD (LDB75),A            ; Direction/orientation
  JP LB02E
LB06E:
  LD A,$01
  LD (LDB76),A            ; set X coord = 1
  LD A,$03
  LD (LDB75),A            ; Direction/orientation
  JP LB02E
;
; Decrease Health by 4, restore Y coord
LB07B:
  LD B,$02
LB07D:
  CALL LB994              ; Decrease Health
  DJNZ LB07D
  POP AF
  LD (LDB78),A            ; set Y tile coord
  POP AF
  LD (LDB77),A            ; set Y pixel coord
  JP LA8CD
;
; Decrease Health by 4, restore X coord
LB08D:
  LD B,$02
LB08F:
  CALL LB994              ; Decrease Health
  DJNZ LB08F
  POP AF                  ; Restore old X coord
  LD (LDB76),A            ; set X coord
  JP LA8CD
;
; Door Lock: Preparing to draw string with prompt/result
LB09B:
  ld hl,$3401             ; line 52 col 1
  ld de,$0C0C             ; 12 rows, 12 cols
  call ClearScreenBlock
  LD HL,$340C
  LD (L86D7),HL           ; set penRow/penCol
  RET
;
; Open the Inventory pop-up
;
LB0A2:
  LD BC,$0060             ; decode 96 bytes
  LD HL,LF329             ; Encoded screen for Inventory/Info popup
  CALL LADF5              ; Decode the screen to DBF5
  CALL LB177              ; Display screen HL from tiles with Tileset 2
  LD A,22     ; was: $0B
  LD (LDCF3),A            ; Left margin size for text
  LD A,12     ; was: $06
  LD (LDCF4),A            ; Line interval for text
  XOR A
  LD (LDCF5),A            ; Data cartridge reader slot??
  LD (LDC59),A            ; set delay factor
  LD (LDC5A),A            ; clear Inventory items count
  LD (LDCF8),A
  LD A,16                 ; was: $08
  LD (LDC83),A            ; set X pos
  LD A,$24                ; was: $12
  LD (LDC84),A            ; set Y pos
  LD HL,$1630
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0BB             ; " - INVENTORY - "
  call DrawString         ; was: CALL LBEDE
  LD HL,LDB9C             ; Inventory table address
  LD B,$1D                ; 29 items
LB0E0:                    ; loop by B
  PUSH HL
  LD A,(HL)               ; get item
  CP $01                  ; do we have the item
  CALL Z,LB12A            ; yes => put in the list and draw
  POP HL
  INC HL                  ; next item in the Inventory
  DJNZ LB0E0              ; continue loop
  LD A,(LDC5A)            ; get Inventory items count
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
  jr Z,LB119              ; yes, exit the loop
  DEC C
  LD HL,LDC5B             ; Inventory list
  LD A,(LDC5A)            ; get Inventory items count
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,$63                ; empty slot marker
  LD (HL),A
  LD A,(LDC5A)            ; get Inventory items count
  INC A                   ; increase Inventory items count
  LD (LDC5A),A
  jr LB0F3                ; continue the loop
LB119:
  JP LB1AA                ; go to Inventory screen loop
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
  add hl,hl
  LD DE,Tileset3+2*32       ; Inventory items, 12 tiles
  ADD HL,DE
  PUSH HL
  POP IX
  CALL LB15D              ; Draw tile by XOR then go to next position
  LD HL,LDC5B             ; Inventory items
  LD A,(LDC5A)            ; get Inventory items count
  LD E,A
  LD D,$00
  ADD HL,DE
  POP AF
  LD (HL),A
  OR A
  CALL Z,LB301            ; => mark we've got Data cartridge reader
  LD A,(LDC5A)            ; get Inventory items count
  INC A                   ; increase Inventory items count
  LD (LDC5A),A
  POP BC
  RET
; Draw tile by XOR using X = (LDC83), Y = (LDC84), then go to next position
LB15D:
  LD A,(LDC84)            ; get Y pos for Inventory
  LD L,A                  ; L = row
  LD A,(LDC83)            ; A = X pos for Inventory
  LD B,16   ; was: $08
  CALL L9E5F              ; Draw tile by XOR operation
  LD A,(LDC83)            ; get X pos
  ADD A,16                ; increase X; was: $08
  LD (LDC83),A            ; set X pos
  CP 176                  ; was: $58
  CALL Z,LB11C
  RET
;
; Display screen from tiles with Tileset 2
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
  jr NZ,LB177_0
  LD C,$00
  ld a,b
  add a,16
  cp 16*8
  ld b,a
  jr NZ,LB177_0
  RET
;
; Clear the bottom area in the Inventory popup
ClearInventoryMesage:
  push hl
  ld hl,$5C01             ; at row 92 col 1
  ld de,$1A16             ; 24 rows, 22 cols
  call ClearScreenBlock
  pop hl
  ret
;
; Inventory
LB1AA:
  XOR A
  LD (LDC82),A            ; clear Inventory current
  LD A,16                 ; was: $08
  LD (LDC83),A            ; set X pos
  LD A,$24                ; was: $12
  LD (LDC84),A            ; set Y pos
  CALL LB2AF              ; Prepare item description string
LB1BB:                    ; Inventory loop starts here
  call ClearInventoryMesage
  call DrawString         ; draw Inventory item description; was: CALL LBEDE;
  CALL LB295              ; draw Inventory selection square
  ld a,$44
  ld (LDC59),a            ; set delay factor
  call LB2D0              ; delay, to make Inventory selection more usable
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
  jr LB1C1                ; continue the loop
LB1DB:
  CALL LB2DE              ; Print string LDCF9
  CALL LB2AF              ; Prepare item description string
  RET
LB1E2:
  CALL LB295              ; Draw Inventory selection square
  LD A,(LDC82)            ; get Inventory current
  DEC A                   ; left
  LD (LDC82),A            ; set Inventory current
  CALL LB1DB              ; Print string LDCF9 and Prepare item description string
  RET
LB1F0:
  CALL LB295              ; Draw Inventory selection square
  LD A,(LDC82)            ; get Inventory current
  INC A                   ; right
  LD (LDC82),A            ; set Inventory current
  CALL LB1DB              ; Print string LDCF9 and Prepare item description string
  RET
LB1FE:                    ; Left key pressed
  LD A,(LDC83)            ; get X pos
  CP 16       ; was: $08
  JP Z,LB25F
  CALL LB1E2
  LD A,(LDC83)            ; get X pos
  ADD A,-16   ; was: $F8
  LD (LDC83),A            ; set X pos
  JP LB1BB                ; continue Inventory loop
LB214:                    ; Right key pressed
  LD A,(LDC83)            ; get X pos
  CP $A0      ; was: $50
  jr Z,LB22A
  CALL LB1F0
  LD A,(LDC83)            ; get X pos
  ADD A,16    ; was: $08
  LD (LDC83),A            ; set X pos
  JP LB1BB                ; continue Inventory loop
LB22A:
  LD A,(LDC84)            ; get Y pos
  CP $4C      ; was: $26
  jr Z,LB245
  CALL LB1F0
  LD A,(LDC84)            ; get Y pos
  ADD A,20    ; was: $0A
  LD (LDC84),A            ; set Y pos
  LD A,16     ; was: $08
  LD (LDC83),A            ; set X pos
  JP LB1BB                ; continue Inventory loop
LB245:
  CALL LB295              ; Draw Inventory selection square
  LD A,16     ; was: $08
  LD (LDC83),A            ; set X pos
  LD A,$24    ; was: $12
  LD (LDC84),A            ; set Y pos
  XOR A
  LD (LDC82),A            ; clear Inventory current
  CALL LB2DE              ; Print string LDCF9
  CALL LB2AF              ; Prepare item description string
  JP LB1BB                ; continue Inventory loop
LB25F:
  LD A,(LDC84)            ; get Y pos
  CP $24      ; was: $12
  jr Z,LB27A
  CALL LB1E2
  LD A,(LDC84)            ; get Y pos
  ADD A,-20   ; was: $F6
  LD (LDC84),A            ; set Y pos
  LD A,$A0    ; was: $50
  LD (LDC83),A            ; set X pos
  JP LB1BB                ; continue Inventory loop
LB27A:
  CALL LB295              ; Draw Inventory selection square
  LD A,$A0    ; was: $50
  LD (LDC83),A            ; set X pos
  LD A,$4C    ; was: $26
  LD (LDC84),A            ; get Y pos
  LD A,$1D
  LD (LDC82),A            ; set Inventory current
  CALL LB2DE              ; Print string LDCF9
  CALL LB2AF              ; Prepare item description string
  JP LB1BB                ; continue Inventory loop
; Draw Inventory selection square
LB295:
;  LD DE,$0020
;  LD HL,Tileset2
;  ADD HL,DE
;  PUSH HL
;  POP IX
  ld ix,Tileset3+15*32
  LD B,16     ; was: $08
  LD A,(LDC84)            ; get Y pos
  LD L,A
  LD A,(LDC83)            ; get X pos
  CALL L9E5F              ; Draw tile by XOR operation
;  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  jp ShowShadowScreen
;  RET
;
; Prepare item description string
;   Returns: HL = item description string
LB2AF:
  LD HL,$6812
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,LDC5B             ; Inventory list
  LD A,(LDC82)            ; get Inventory current
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  CP $63                  ; empty slot?
  jr Z,LB2CC
  LD (LDC89),A            ; set as current item
;  CALL LAE19              ; Get inventory item description string
  jp LAE19
;  RET
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
; Print string LDCF9
LB2DE:
  LD A,(LDCF2)
  CP $01
  jr NZ,LB2EC
  LD HL,$5C0A
  CALL LB2F7
LB2EC:
  LD HL,$680A
  CALL LB2F7
  XOR A
  LD (LDCF2),A
  RET
LB2F7:
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,LDCF9
  jp DrawString
  ;RST $28                 ; rBR_CALL
  ;DEFW $4561              ; _VPutS - Displays a zero (0) terminated string
;  RET
;
; We've got Data cartridge reader
LB301:
  LD A,$01
  LD (LDCF5),A            ; Data cartridge reader slot
  RET
;
; Inventory Look/shoot key pressed
LB307:
  call ClearInventoryMesage
  LD HL,LDC5B             ; Inventory list
  LD A,(LDC82)            ; get Inventory current
  LD D,$00
  LD E,A
  ADD HL,DE               ; HL = addr of current item in the list
  LD A,(HL)               ; get item
  CP $63                  ; empty slot?
  JP Z,LB1C1
  LD (LDC89),A            ; set as current item
  OR A                    ; $00 - Data cartridge reader?
  jr Z,LB33F
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
; Data cartridge reader (or data cartridge) selected in the Inventory
LB33F:
  LD A,$44
  LD (LDC59),A            ; set delay factor
  LD (LDC85),A            ; Use delay and copy screen in LBEDE
  LD BC,$0060             ; decode 96 bytes
  LD HL,LF42F             ; Encoded screen for Data cartridge reader
  CALL LADF5              ; Decode the screen to DBF5
  CALL LB177              ; Display screen HL from tiles with Tileset 2
  LD A,(LDCF8)
  CP $01                  ; was cartridge selected?
  jr Z,LB36C              ; no => jump
  LD A,$21
  LD (LDCF3),A            ; Left margin size for text
  LD HL,$2C16
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE09B             ; "No Data Cartridge Selected"
  jr LB373
LB36C:
  LD HL,$1416
  LD (L86D7),HL           ; Set penRow/penCol
  POP HL                  ; restore the message address
LB373:
  CALL LBEDE              ; Show message char-by-char
  LD A,(LDC89)            ; get current item number
  CP $02
  CALL Z,LB39A            ; Draw level 2 access code
  CP $03
  CALL Z,LB3A1            ; Draw level 3 access code
  CP $04
  CALL Z,LB3A8            ; Draw level 4 access code
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
LB38B:
  CALL LA0F1              ; Scan keyboard
  CP $37
  jr NZ,LB38B
  XOR A
  LD (LDC85),A            ; Skip delay and copy screen in LBEDE
  JP L9DDD                ; return to the main game loop
LB39A:
  LD HL,LDC96             ; Get code address - level 2 access code buffer
;  CALL LBC3C              ; Draw the code
  jp LBC3C
;  RET
LB3A1:
  LD HL,LDC9A             ; Get code address - level 3 access code buffer
;  CALL LBC3C              ; Draw the code
  jp LBC3C
;  RET
LB3A8:
  LD HL,LDC9E             ; Get code address - level 4 access code buffer
;  CALL LBC3C              ; Draw the code
  jp LBC3C
;  RET
;
; Data cartridge selected in the Inventory
LB3AF:
  LD A,(LDCF5)            ; Data cartridge reader
  OR A                    ; do we have the reader?
  jr Z,LB3C8              ; no => jump
  LD A,(LDC89)            ; get current item number
  LD HL,LDFF3             ; Table address for data cartridge messages
  CALL LADFF              ; Get address from table by index A
  PUSH HL                 ; store the message address
  LD A,$01
  LD (LDCF8),A            ; mark that cartridge was selected
  JP LB33F                ; => go like the Data cartridge reader selected
LB3C8:                    ; We don't have data cartridge reader
  CALL LB2DE              ; Print string LDCF9
  LD HL,$5C18
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0E3             ; "You Need A Data Cartridge Reader"
  CALL LB513              ; Show message
  JP LB1C1
;
LB3DA:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0011             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD A,(LDB75)            ; Direction/orientation
  SUB C
  RET
;
; Something other selected in the Inventory
LB3E8:
  CALL LB51F
  LD HL,SE129             ; "You dont seem to be able to use this item here"
  CALL LB513              ; Show message
  JP LB1C1
;
; Power drill selected in the Inventory
LB3F4:
  CALL LB3DA
  jr NZ,LB3E8
  CALL LB538              ; Get value at $13 offset in the room description
  CP $01                  ; is it Generator in the room?
  jr NZ,LB3E8
  LD HL,LDB90+1
;  INC HL                 ; HL = Generator
  LD A,(HL)
  OR A                    ; Generator working?
  jr NZ,LB42E             ; yes => jump
  CALL LB541              ; Get value at $0F offset in the room description
  SUB C                   ; compare current offset in the room with the value
  jr Z,LB41C              ; equal => jump
  INC HL
  LD A,(HL)
  LD C,A
  LD A,(LDC56)            ; get offset in the room
  SUB C
  jr NZ,LB3E8
; Using Power Drill in the proper spot
LB41C:
  CALL LB51F
  LD HL,SE137             ; "You use the Power Drill to Repair the Generator"
  CALL LB513              ; Show message
  LD HL,LDB90+1
;  INC HL                  ; HL = LDB90 + $01
  LD (HL),$01             ; mark the Generator is working now
  JP LB1C1
;
LB42E:
  LD A,10   ; was: $05
  LD (LDCF3),A            ; Left margin size for text
  LD A,12   ; was: $06
  LD (LDCF4),A            ; Line interval for text
  CALL LB2DE              ; Print string LDCF9
  LD HL,$5C0A
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE12D             ; "It doesnt look like you can do anything else here"
  CALL LB513              ; Show message
  JP LB1C1
;
; Life Support Data Disk selected in the Inventory
LB44A:
  CALL LB3DA
  JP NZ,LB3E8
  CALL LB538              ; Get value at $13 offset in the room description
  CP $04
  JP NZ,LB3E8
  LD DE,$0004
  CALL LB531              ; Get value (LDB90+DE)
  jr NZ,LB42E
  CALL LB541              ; Get value at $0F offset in the room description
  SUB C                   ; compare current offset in the room with the value
  jr Z,LB472              ; equal => jump
  INC HL
  LD A,(HL)
  LD C,A
  LD A,(LDC56)            ; get offset in the room
  SUB C
  JP NZ,LB3E8
; Using Life Support Data Disk in the proper spot
LB472:
  CALL LB51F
  LD HL,SE139             ; "Life-Support System has been fully restored"
  CALL LB513              ; Show message
;  LD DE,$0004
  LD HL,LDB90+4
;  ADD HL,DE              ; HL = Life-Support System
  LD (HL),$01             ; mark that Life-Support System is working
  JP LB1C1
;
; Air-Lock Tool selected in the Inventory
LB487:
  CALL LB3DA
  JP NZ,LB3E8
  CALL LB538              ; Get value at $13 offset in the room description
  CP $05
  JP NZ,LB3E8
  LD DE,$0005
  CALL LB531              ; Get value (LDB90+DE)
  JP NZ,LB42E
  CALL LB541              ; Get value at $0F offset in the room description
  SUB C                   ; compare current offset in the room with the value
  jr Z,LB4AF              ; equal => jump
  INC HL
  LD A,(HL)
  LD C,A
  LD A,(LDC56)            ; get offset in the room
  SUB C
  JP NZ,LB3E8
; Using Air-Lock Tool in the proper spot
LB4AF:
  CALL LB51F
  LD HL,SE13B             ; "The Evacuation Deck has been re-pressurised"
  CALL LB513              ; Show message
;  LD DE,$0005
  LD HL,LDB90+5
;  ADD HL,DE
  LD (HL),$01             ; mark that the Evacuation Deck re-pressurised
  JP LB1C1
;
; Box of Power Cells selected in the Inventory
LB4C4:
  CALL LB3DA
  JP NZ,LB3E8
  CALL LB538              ; Get value at $13 offset in the room description
  CP $06
  JP NZ,LB3E8
  LD DE,$0006
  CALL LB531              ; Get value (LDB90+DE)
  JP NZ,LB42E
  CALL LB541              ; Get value at $0F offset in the room description
  SUB C                   ; compare current offset in the room with the value
  jr Z,LB4EC              ; equal => jump
  INC HL
  LD A,(HL)
  LD C,A
  LD A,(LDC56)            ; get offset in the room
  SUB C
  JP NZ,LB3E8
; Using Box of Power Cells in the proper spot
LB4EC:
  CALL LB51F
  LD HL,SE13D             ; "You Insert a Power Cell. Guidance System Online"
  CALL LB513              ; Show message
;  LD DE,$0006
  LD HL,LDB90+6
;  ADD HL,DE
  LD (HL),$01             ; mark we have Guidance System working
  JP LB1C1
;
; Rubik's Cube selected in the Inventory
LB501:
  CALL LB2DE              ; Print string LDCF9
  LD HL,$5E14
  LD (L86D7),HL
  LD HL,SE12B             ; "You dont have any time to play with this now"
  CALL LB513              ; Show message
  JP LB1C1
;
; Show message HL and show the screen
LB513:
  CALL LBEDE              ; Show message char-by-char
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  LD A,$01
  LD (LDCF2),A
  RET
;
LB51F:
  CALL LB2DE              ; Print string LDCF9
  LD HL,$5E12
  LD (L86D7),HL	
  RET
;
LB529:
  OR A
  RET Z
  SUB $11
  RET NC
  LD A,$01
  RET
;
; Get value (LDB90+DE)
LB531:
  LD HL,LDB90
  ADD HL,DE
  LD A,(HL)
  OR A
  RET
;
; Get value at $13 offset in the room description
LB538:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0013             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  RET
;
; Get value at $0F offset in the room description
;   Returns: C = value from the offset; A = LDC56 = offset in the room
LB541:
  CALL LAA9D              ; Get room offset in tiles for X = LDB76, Y = LDB78
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$000F             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD A,(LDC56)            ; get offset in the room
  RET
;
; Process alien in the room
LB551:
  CALL LB72E              ; Get value at offset $2F in the room description
  OR A                    ; do we have the alien?
  RET Z                   ; we don't have it => return
; We have an alien in the room description
  LD A,(LDB82)
  OR A                    ; do we have it already in the room?
  jr NZ,LB57B             ; yes => jump
  DEC HL                  ; now HL = RoomDesc + $2E
  LD A,(HL)
  LD (LDB81),A            ; set Alien type
  DEC HL                  ; now HL = RoomDesc + $2D
  LD A,(HL)
  LD (LDB80),A            ; set Alien Y tile coord
  DEC HL                  ; now HL = RoomDesc + $2C
  LD A,(HL)
  add a,a
  LD (LDB7F),A            ; set Alien Y coord
  DEC HL                  ; now HL = RoomDesc + $2B
  LD A,(HL)
  LD (LDB7E),A            ; set Alien X coord
  LD A,$03
  LD (LDB85),A            ; set alien health = 3
  LD A,$01
  LD (LDB84),A
LB57B:
  LD A,(LDB84)
  OR A
  JP Z,LB622
;  LD B,$08
;  CALL $4086
  call GetRandom8         ; Generate random number 0..7
  OR A
  jr Z,LB59D              ; Alien down
  CP $02
  jr Z,LB5C3              ; Alien up
  CP $04
  JP Z,LB5E9              ; Alien left
  CP $06
  JP Z,LB607              ; Alien right
  JP LB622
LB59D:
;  LD A,$00
  xor a
  LD (LDB86),A            ; set Alien direction/orientation = down
  CALL LB713
  OR A
  JP Z,LB737
  CALL LB6B0
  CP $01
  JP NZ,LB622
  LD A,(LDB7F)            ; get Alien Y coord
  ADD A,16    ; was: $08  ; down one tile
  LD (LDB7F),A            ; set Alien Y coord
  LD A,(LDB80)            ; get Alien Y tile coord
  INC A                   ; down one tile
  LD (LDB80),A            ; set Alien Y tile coord
  JP LB622
LB5C3:
  LD A,$01
  LD (LDB86),A            ; set Alien direction/orientation = up
  CALL LB713
  OR A
  JP Z,LB737
  CALL LB6B0
  CP $01
  JP NZ,LB622
  LD A,(LDB7F)            ; get Alien Y coord
  ADD A,-16   ; was: $F8  ; up one tile
  LD (LDB7F),A            ; set Alien Y coord
  LD A,(LDB80)            ; get Alien Y tile coord
  DEC A                   ; up one tile
  LD (LDB80),A            ; set Alien Y tile coord
  JP LB622
LB5E9:
  LD A,$02
  LD (LDB86),A            ; set Alien direction/orientation = left
  CALL LB713
  OR A
  JP Z,LB737
  CALL LB6B0
  CP $01
  JP NZ,LB622
  LD A,(LDB7E)            ; get Alien X coord
  DEC A                   ; left one tile
  LD (LDB7E),A            ; set Alien X coord
  JP LB622
LB607:
  LD A,$03
  LD (LDB86),A            ; set Alien direction/orientation = right
  CALL LB713
  OR A
  JP Z,LB737
  CALL LB6B0
  CP $01
  jr NZ,LB622
  LD A,(LDB7E)            ; get Alien X coord
  INC A                   ; right one tile
  LD (LDB7E),A            ; set Alien X coord
;
LB622:
  LD A,(LDB7E)            ; get Alien X coord
  add a,a                 ; tile X cord -> 8px column number
  LD H,A                  ; column
  LD A,(LDB7F)            ; get Alien Y coord
  LD L,A                  ; row
;  LD A,$00                ; clear draw flags
  xor a
  CALL LB67B              ; Get alien tile address in DE
  CALL L9EDE              ; Draw tile DE at column H row L
  LD A,$01
  LD (LDB82),A            ; mark that we already have an Alien in the room
  LD A,(LDB83)            ; get Alien tile phase
  INC A                   ; next phase
  CP $01
  CALL NZ,LB676           ; => Clear Alien tile phase
  LD (LDB83),A            ; set Alien tile phase
  LD A,(LDB81)            ; get Alien type
  CP $02                  ; the big one?
  JP Z,LB82B              ; yes => jump to Check if the Bullet hit the Alien
LB64B:
  CALL LB8CA              ; Is the Bullet hit the Alien?
  OR A
  CALL Z,LB71F            ; yes => Killed the Alien
  RET
;
LB653:
  LD A,(LDB84)
  OR A
  RET Z
  CALL LB72E              ; Get value at offset $2F in the room description
  OR A                    ; do we have the alien?
  RET Z                   ; we don't have it => jump
; We have an alien in the room description
  LD A,(LDB81)            ; get Alien type
  CP $02
  RET NZ
; Draw alien type 2
  LD A,(LDB7E)            ; get Alien X coord
  add a,a                 ; tile X cord -> 8px column number
  LD H,A
  LD A,(LDB7F)            ; get Alien Y coord
  ADD A,-16   ; $F8
  LD L,A
;  LD A,$00                ; clear draw flags
  xor a
  CALL LB69D              ; Get alien tile address
;  CALL L9EDE              ; Draw tile DE at column H row L
  jp L9EDE
;  RET
;
; Clear Alien tile phase
LB676:
  XOR A
  LD (LDB83),A            ; clear Alien tile phase
  RET
;
; Get alien tile address
; Returns DE = tile address, A = draw flags
LB67B:
  LD A,(LDB84)
  jr NZ,LB685
  LD DE,Tileset1+$92*32   ; was $EA67 = $E147 + $0920 = tile $92 - Alien dead
  RET
LB685:
  LD A,(LDB81)            ; get Alien type
  CP $02
  jr Z,LB698
  LD DE,Tileset1+$91*32   ; was $EA57 = $E147 + $0910 = tile $91 - small Alien
  LD A,(LDB83)            ; get Alien tile phase
  OR A
  RET Z
  LD A,$40                ; draw flags
  RET
LB698:                    ; Alien type 2
  LD DE,Tileset1+$94*32   ; was $EA87 = $E147 + $0940 = tile $94 - big Alien body
  JR LB6A0
LB69D:
  LD DE,Tileset1+$93*32   ; was $EA77 = $E147 + $0930 = tile $93 - big Alien head
LB6A0:
  LD A,(LDB83)            ; get Alien tile phase
  OR A
  RET Z
  PUSH HL
  LD HL,$0020*2           ; switch to other tile
  ADD HL,DE
  PUSH HL
  POP DE
;  LD A,$00                ; draw flags
  xor a
  POP HL
  RET
;
LB6B0:
  CALL LADE5              ; Decode current room to LDBF5
  LD A,(LDB7E)            ; get Alien X coord
  LD E,A
  CALL LB6CD              ; ?? left/right
  LD D,$00
  ADD HL,DE
  LD A,(LDB74)            ; $0C - line width in tiles ??
  LD E,A
  LD D,$00
  LD A,(LDB80)            ; get Alien Y tile coord
  LD B,A
  CALL LB6DD              ; ?? up/down
  JP LAA78
;
LB6CD:
  LD A,(LDB86)            ; get Alien direction/orientation
  OR A
  RET Z
  CP $01
  RET Z
  CP $02                  ; left?
  JR NZ,LB6DB
  DEC E                   ; one left
  RET
LB6DB:
  INC E                   ; one right
  RET
;
LB6DD:
  LD A,(LDB86)            ; get Alien direction/orientation
  CP $02
  RET Z
  CP $03
  RET Z
  OR A                    ; down?
  JR NZ,LB6EB
  INC B                   ; one down
  RET
LB6EB:
  DEC B                   ; one up
  RET
;
; Get A = Alien position within the room
LB6ED:
  CALL LB6FA              ; Get B=Alien Y tile coord, C=12 line width
  LD A,(LDB7E)            ; get Alien X coord
LB6F3:
  ADD A,C
  DJNZ LB6F3
  LD (LDB87),A            ; A = Alien Y tile coord * 12 + Alien X coord
  RET
; Get B=Alien Y tile coord, C=12 line width
LB6FA:
  LD A,(LDB74)            ; $0C - line width in tiles ??
  LD C,A
  LD A,(LDB80)            ; get Alien Y tile coord
  LD B,A
  RET
;
LB703:
  CALL LB6FA              ; Get B=Alien Y tile coord, C=12 line width
  CALL LB6DD              ; ?? up/down
  LD A,(LDB7E)            ; get Alien X coord
  LD E,A
  CALL LB6CD              ; ?? left/right
  LD A,E
  JR LB6F3
;
LB713:
  CALL LAA9D              ; Get room offset in tiles for X = LDB76, Y = LDB78
  CALL LB703
  LD C,A
  LD A,(LDC56)            ; get offset in the room
  SUB C
  RET
; Killed the alien
LB71F:
  XOR A
  LD (LDB84),A
  CALL LB8DC              ; Clear all Bullet variables
  LD HL,(LDBC5)           ; get Enemies Killed count
  INC HL                  ; one more killed
  LD (LDBC5),HL           ; set Enemies Killed count
  RET
;
; Get value at offset $2F in the room description
;   Returns: A = value
LB72E:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$002F             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  RET
;
LB737:
  XOR A
  LD (LDB8D),A            ; clear shooting process mark
  CALL LB994              ; Decrease Health
  LD A,(LDB81)            ; get Alien type
  CP $02
  JP NZ,LB622
  CALL LB994              ; Decrease Health
  JP LB622
;
LB74C:
  CALL LAA9D              ; Get room offset in tiles for X = LDB76, Y = LDB78
  CALL LB6ED              ; Get A = Alien position within the room
  LD C,A
  LD A,(LDC56)            ; get offset in the room
  SUB C
  RET
;
; Shoot with the Weapon
LB758:
  LD A,(LDB8C)
  CP $01
  jr Z,LB768
  LD A,$01
  LD (LDB8D),A            ; set shooting process flag
  LD (LDD55),A            ; set shooting flag for player's animation
LB768:
  JP L9E2E                ; Show the screen, continue the game main loop
;
; Process shoot within the game main loop
;
LB76B:
  LD A,(LDB8D)            ; get shooting process flag
  OR A                    ; in the process?
  JP Z,LB84A              ; no => jump
  LD A,(LDB8C)
  CP $01
  jr Z,LB797
  LD A,$01
  LD (LDB8D),A            ; set shooting process flag
  LD A,(LDB75)            ; get player Direction/orientation
  LD (LDB8B),A            ; set bullet Direction/orientation
  LD A,(LDB76)            ; get player X coord in tiles
  LD (LDB88),A            ; set bullet X coord in tiles
  LD A,(LDB77)            ; get player Y coord/line on the screen
  LD (LDB89),A            ; set bullet Y coord/line on the screen
  LD A,(LDB78)            ; get player Y coord in tiles
  LD (LDB8A),A            ; set bullet Y coord in tiles
LB797:
  LD A,(LDB8B)            ; get Bullet Direction/orientation
  OR A                    ; down?
  jr Z,LB7AD
  CP $01                  ; up?
  jr Z,LB7C7
  CP $02                  ; left?
  jr Z,LB7E1
  CP $03                  ; right?
  jr Z,LB7F3
; Bullet down
LB7AD:
  CALL LB87C
  CP $01
  JP NZ,LB8D6
  LD A,(LDB89)            ; get Bullet Y coord/line on the screen
  ADD A,16    ; was: $08  ; down 16 rows
  LD (LDB89),A            ; set Bullet Y coord/line on the screen
  LD A,(LDB8A)            ; get Bullet Y coord in tiles
  INC A                   ; down one tile
  LD (LDB8A),A            ; set Bullet Y coord in tiles
  JP LB805
; Bullet up
LB7C7:
  CALL LB87C
  CP $01
  JP NZ,LB8D6
  LD A,(LDB89)            ; get Bullet Y coord/line on the screen
  ADD A,-16   ; was: $F8  ; up 16 rows
  LD (LDB89),A            ; set Bullet Y coord/line on the screen
  LD A,(LDB8A)            ; get Bullet Y coord in tiles
  DEC A                   ; up one tile
  LD (LDB8A),A            ; set Bullet Y coord in tiles
  jr LB805
; Bullet left
LB7E1:
  CALL LB87C
  CP $01
  JP NZ,LB8D6
  LD A,(LDB88)            ; get bullet X coord in tiles
  DEC A                   ; left one tile
  LD (LDB88),A            ; set bullet X coord in tiles
  jr LB805
; Bullet right
LB7F3:
  CALL LB87C
  CP $01
  JP NZ,LB8D6
  LD A,(LDB88)            ; get bullet X coord in tiles
  INC A                   ; right one tile
  LD (LDB88),A            ; set bullet X coord in tiles
;  jr LB805
; 
LB805:
  LD A,(LDB8D)            ; get shooting process flag
  OR A                    ; in the process?
  jr Z,LB84A              ; no => jump
  LD A,(LDB88)            ; get bullet X coord in tiles
  add a,a                 ; tile coord -> column number
  LD H,A
  LD A,(LDB89)            ; get Bullet Y coord/line on the screen
  LD L,A
  CALL LB84F              ; Get tile address in DE and draw flags in A
  CALL L9EDE              ; Draw tile DE at column H row L
  LD A,$01
  LD (LDB8C),A
  LD A,(LDB81)            ; get Alien type
  CP $02                  ; the big one?
  jr Z,LB82B              ; yes => jump to Check if the Bullet hit the Alien
;  CALL LB64B              ; Check Is the Bullet hit the Alien, process the hit
  jp LB64B
;LB82A:
;  RET
;
LB82B:
  CALL LB8CA              ; Is the Bullet hit the Alien?
  OR A
;  jr NZ,LB82A             ; no => return
  ret nz
; Bullet hit the Alien, the big one
  XOR A
  LD (LDB8D),A            ; clear shooting process flag
  LD (LDB88),A            ; clear Bullet X coord in tiles
  LD (LDB89),A            ; clear Bullet Y coord/line on the screen
  LD A,(LDB85)            ; get Alien health
  DEC A
  LD (LDB85),A            ; set Alien health
  OR A
  CALL Z,LB71F            ; => Killed the alien
;  jr LB82A                ; return
  ret
;
LB84A:
  XOR A
  LD (LDB8C),A
  RET
;
; Get tile address and draw flags
;   Returns: DE = tile address; A = draw flags
LB84F:
  LD A,(LDB8B)            ; get Bullet Direction/orientation
  OR A
  jr Z,LB865
  CP $01
  jr Z,LB86A
  CP $02
  jr Z,LB870
  CP $03
  jr Z,LB876
LB865:
  LD DE,Tileset1+$98*32  ; was: $EAC7 = $E147 + $0980 = tile $98 - Bullet vert
  XOR A                   ; no draw flags
  RET
LB86A:
  LD DE,Tileset1+$98*32  ; was: $EAC7 = $E147 + $0980 = tile $98 - Bullet vert
  LD A,$40                ; reflect tile vertically
  RET
LB870:
  LD DE,Tileset1+$97*32  ; was: $EAB7 = $E147 + $0970 = tile $97 - Bullet horz
  LD A,$80                ; reflect tile horizontally
  RET
LB876:
  LD DE,Tileset1+$97*32  ; was: $EAB7 = $E147 + $0970 = tile $97 - Bullet horz
  LD A,$40                ; reflect tile vertically
  RET
;
LB87C:
  CALL LADE5              ; Decode current room to LDBF5
  LD A,(LDB88)            ; get Bullet X coord in tiles
  LD E,A
  CALL LB89B              ; For Bullet direction left: dec E, right: inc E
  LD D,$00
  ADD HL,DE
  LD A,(LDB74)            ; $0C - line width in tiles ??
  LD E,A
  LD D,$00
  LD A,(LDB8A)            ; get Bullet Y coord in tiles
  LD B,A
  CALL LB8AB              ; For Bullet direction up: dec B, down: inc B
LB896:
  ADD HL,DE
  DJNZ LB896
  LD A,(HL)
  RET
;
; For Bullet direction left: dec E, right: inc E
LB89B:
  LD A,(LDB8B)            ; get Bullet Direction/orientation
  OR A
  RET Z
  CP $01
  RET Z
  CP $02                  ; left?
  JR NZ,LB8A9
  DEC E                   ; one left
  RET
LB8A9:
  INC E                   ; one right
  RET
;
; For Bullet direction up: dec B, down: inc B
LB8AB:
  LD A,(LDB8B)            ; get Bullet Direction/orientation
  CP $02
  RET Z
  CP $03
  RET Z
  OR A                    ; down?
  JR NZ,LB8B9
  INC B                   ; one down
  RET
LB8B9:
  DEC B                   ; one up
  RET
;
; Get A = Bullet position within the room
LB8BB:
  LD A,(LDB74)            ; $0C - line width in tiles ??
  LD C,A
  LD A,(LDB8A)            ; get Bullet Y coord in tiles
  LD B,A
  LD A,(LDB88)            ; get Bullet X coord in tiles
LB8C6:
  ADD A,C
  DJNZ LB8C6
  RET                     ; now A = Bullet Y coord * 12 + Bullet X coord
;
; Is the Bullet hit the Alien?
LB8CA:
  CALL LB6ED              ; Get A = Alien position within the room
  CALL LB8BB              ; Get A = Bullet position within the room
  LD C,A
  LD A,(LDB87)            ; get Alien position within the room
  SUB C
  RET
LB8D6:
  CALL LB8DC              ; Clear all Bullet variables
  JP LB805
;
; Clear all Bullet variables
LB8DC:
  XOR A
  LD (LDB8D),A            ; clear shooting process mark
  LD (LDB88),A            ; clear Bullet X coord in tiles
  LD (LDB89),A            ; clear Bullet Y coord/line on the screen
  LD (LDB8A),A            ; clear Bullet Y coord in tiles
  RET
;
; Show look/shoot selection indicator
;
LB8EA:
  LD A,(LDB7D)            ; Get look/shoot switch value
  OR A                    ; look mode?
  jr Z,LB902              ; yes => jump
  CALL LB913              ;
  LD A,$8C                ;
  CALL L9E5F              ; Draw tile by XOR operation
  CALL LB91C              ;
  LD A,$A0                ;
;  CALL L9E5F              ; Draw tile by XOR operation
  jp L9E5F
;  RET                     ;
LB902:
  CALL LB913              ;
  LD A,$76                ;
  CALL L9E5F              ; Draw tile by XOR operation
  CALL LB91C              ;
  LD A,$8A                ;
;  CALL L9E5F              ; Draw tile by XOR operation
  jp L9E5F
;  RET                     ;
LB913:
  LD IX,Tileset3+20       ; Small triange pointing right
  LD B,6                  ; Tile height
  LD L,$04                ; Y pos
  RET                     ;
LB91C:
  LD IX,Tileset3+32+20    ; Small triange pointing left
  LD B,6                  ; Tile height
  LD L,$04                ; Y pos
  RET                     ;
;
LB925:
  LD A,14   ; was: $0B
  LD (LDCF3),A            ; Left margin size for text
  LD A,14   ; was: $07
  LD (LDCF4),A            ; Line interval for text
  RET
;
; Switch Look / Shoot mode
LB930:
  LD A,(LDCF7)            ; Weapon slot
  OR A
  jr NZ,LB94C
  CALL LB925
  CALL LAB28              ; Show small message popup
  LD HL,$582C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0D3             ; "You dont have a Weapon to equip!"
  CALL LBEDE              ; Show message char-by-char
  JP LAD8C                ; Show screen and wait for MODE key
LB94C:
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01                  ; shoot mode?
  jr Z,LB95C              ; yes => jump
  LD A,$01
  LD (LDB7D),A            ; set look/shoot switch = Shoot
  jr LB960
LB95C:
  XOR A
  LD (LDB7D),A            ; set look/shoot switch value = Look
LB960:
  LD A,$96
  LD (LDC59),A            ; set delay factor
  CALL LB2D0              ; Delay
  JP L9E2E                ; Show the screen, continue the game main loop
;
; Display Health
LB96B:
;DEBUG: Show room number at the bottom-left
IF DEFINED CHEAT_SHOW_ROOM_NUMBER
  LD HL,$7610
  ld (L86D7),hl           ; Set penRow/penCol
  ld a,(LDB79)            ; Get the room number
  ld l,a
  ld h,$00
  call DrawNumber3
ENDIF
  LD HL,$012C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,(LDB7A)           ; get Health value
  jp DrawNumber3          ; Show 3-digit decimal number HL
;
; Draw 5-digit number HL at row/col DE, and show the screen
LB97D:
  LD (L86D7),DE           ; set penRow/penCol
  call DrawNumber5
  jp ShowShadowScreen   ; Copy shadow screen to ZX screen
;
; Decrease Health
LB994:
  LD A,(LDB7A)            ; get Health
  SUB $02                 ; Health = Health minus 2
  CALL C,LB9A0
  LD (LDB7A),A            ; set Health
;TODO: Set border to red
  RET
LB9A0:
  XOR A
  RET
;
; Player is dead, Health 0
;
LB9A2:
  CALL ClearShadowScreen
  LD A,$32      ; was: $19
  LD (LDCF3),A            ; Left margin size for text
  LD A,14      ; was: $07
  LD (LDCF4),A            ; Line interval for text
  CALL LAB28              ; Show small message popup
  LD HL,$580E
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0BD             ; "The Desolate has claimed your life too . . ."
  CALL LBEDE              ; Show message char-by-char
  XOR A
  CALL LB9D6              ; Clear player variables
  LD HL,(LDBC3)           ; get Player deaths count
  INC HL                  ;
  LD (LDBC3),HL           ; set Player deaths count
LB9C9:
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  CALL LA0F1              ; Scan keyboard
  CP $37                  ; "MODE" key? TODO: any key
  JP Z,L9E19              ; yes => Go to ending of main game loop
  JR LB9C9                ; continue the waiting loop
;
; Clear player variables
LB9D6:
  LD (LDB79),A            ; set the room number
  LD (LDB75),A            ; Direction/orientation
  LD A,$06
  LD (LDB76),A            ; set X tile coord = 6
  LD A,$30                ; was: $18
  LD (LDB77),A            ; set Y pixel coord = 48
  LD A,$03
  LD (LDB78),A            ; set Y tile coord = 3
  LD A,$64
  LD (LDB7A),A            ; set Health = 100
  RET
;
; Decode the block
;   HL = address decode from (usually encoded room/screen)
;   DE = address decode to
;   BC = number of bytes to decode
LB9F1:
  LD A,(HL)
  CP $FF                  ; repeater?
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
;
; Show titles and show Menu
LBA07:
  LD A,$44
  LD (LDC59),A            ; set delay factor
  LD (LDC85),A            ; Use delay and copy screen in LBEDE
  LD HL,$3A1E
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE09D             ; "MaxCoderz Presents"
  CALL LBEDE              ; Show message char-by-char
  CALL LBA81              ; Delay x40
  CALL LBC7D              ; Clear shadow screen and copy to ZX screen
  CALL LBC34              ; Delay x20
  LD HL,$3A2E
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE09F             ; "a tr1p1ea game"
  CALL LBEDE              ; Show message char-by-char
  CALL LBA81              ; Delay x40
  CALL LBC7D              ; Clear shadow screen and copy to ZX screen
  CALL LBC34              ; Delay x20
  XOR A
  LD (LDC85),A            ; Skip delay and copy screen in LBEDE
;
; Return to Menu
;
LBA3D:
  LD A,(LDC55)            ; get Menu background phase
  INC A
  CP $08
;TODO: Just AND $07
  CALL Z,LBC2F
  LD (LDC55),A            ; set Menu background phase
  DI
  LD HL,LF515             ; Main menu screen moving background, 96 tiles
  CALL LA88F              ; Display 96 tiles on the screen
  LD HL,LF4B5             ; Main menu screen
  EI
  CALL LB177              ; Display screen HL from tiles with Tileset 2
  LD C,$0B                ; left triangle X pos
  LD IX,Tileset3          ; Tile arrow right
  DI
  CALL LBA88              ; Draw menu item selection triangle
  LD C,$4D                ; right triangle X pos
  LD IX,Tileset3+32       ; Tile arrow left
  DI
  CALL LBA88              ; Draw menu item selection triangle
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  CALL LA0F1              ; Scan keyboard
  CP $36                  ; look/shoot key
  jr Z,LBA93              ;   select menu item
  cp $09                  ; Enter key
  jr z,LBA93              ;   select menu item
  CP $04                  ; Up key
  JP Z,LBBCC
  CP $01                  ; Down key
  JP Z,LBBDC
  jr LBA3D
;
;TODO: Move close to LBC34
; Delay x40
LBA81:
  CALL LBC34              ; Delay x20
;  CALL LBC34              ; Delay x20
  jp LBC34
;  RET
;
; Draw menu item selection triangle
LBA88:
  LD A,(LDB8F)            ; get Menu Y pos
  LD L,A                  ; L = Y coord
  LD A,C                  ; A = X coord
  LD B,10                 ; B = tile height
;  CALL L9E5F              ; Draw tile by XOR operation
  jp L9E5F
;  RET
;
; Select on Menu item
LBA93:
  LD A,(LDB8F)            ; get Menu Y pos
  CP $3A
  jr Z,LBAB2              ; New menu item
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
  OR A                    ; do we have current game?
  jr Z,LBADE              ; no => New Game
  CALL LB925
  CALL LAB28              ; Show small message popup
  LD HL,$580E
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0A3             ; "OverWrite Current Game? Enter - Yes :: G - No"
  CALL LBEDE              ; Show message char-by-char
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
LBACE:
  CALL LA0F1              ; Scan keyboard
  CP $0F                  ; Menu button?
  JP Z,LBA3D              ; yes => return to Menu
  CP $09                  ; Enter?
  jr Z,LBADE              ; yes => New Game
  jr LBACE                ; wait some more
;
; New Game
;
LBADE:
  XOR A
  LD (LDCF7),A            ; clear Weapon slot
  LD (LDB7D),A            ; set look/shoot switch value = Look
  LD (LDBC7),A            ; clear Items Found count
  CALL LB9D6              ; Clear player variables
  LD HL,$0000
  LD (LDBC3),HL           ; clear Player deaths count
  LD (LDBC5),HL           ; clear Enemies Killed count
  LD HL,LDB9C             ; Inventory table address
  LD B,$22                ; 34 bytes
LBAF9:
  LD (HL),$00             ; clear
  INC HL
  DJNZ LBAF9
  LD HL,LDC5B             ; Inventory list
  LD B,$22                ; 34 bytes
LBB03:
  LD (HL),$00             ; clear
  INC HL
  DJNZ LBB03
  LD HL,LDB90
  LD B,$09                ; 9 variables to clear
LBB09:
  LD (HL),$00             ; Clear 9 variables about the progress
  INC HL
  DJNZ LBB09
  LD HL,LDCA2             ; Table with Access code slots
  LD B,$48                ; 72 bytes
LBB17:
  LD (HL),$00             ; clear the slot
  INC HL
  DJNZ LBB17
  LD HL,LDC96             ; level 2 access code buffer
  CALL LBC6B              ; Generate random code
  LD HL,LDC9A             ; level 3 access code buffer
  CALL LBC6B              ; Generate random code
  LD HL,LDC9E             ; level 4 access code buffer
  CALL LBC6B              ; Generate random code
  CALL LBC7D              ; Clear shadow screen and copy to ZX screen
  LD A,$44
  LD (LDC59),A            ; set delay factor
  LD (LDC85),A            ; Use delay and copy screen in LBEDE
  LD A,14   ; was: $0E
  LD (LDCF4),A            ; set Line interval for text
  XOR A
  LD (LDCF3),A            ; clear Left margin size for text
  LD HL,$3A14
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE115             ; "In the Distant Future . . ."
  CALL LBEDE              ; Show message char-by-char
  CALL LBA81              ; Delay x40
  CALL LBC7D              ; Clear shadow screen and copy to ZX screen
  CALL LBA81              ; Delay x40
  CALL LBC84              ; Set zero penRow/penCol
  LD HL,SE117             ; "'The Desolate' Space Cruiser leaves orbit. ...
  CALL LBEDE              ; Show message char-by-char
  LD HL,$72B6
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0B9             ; String with arrow down sign
  CALL LBEDE              ; Show message char-by-char
  CALL WaitAnyKey         ; Wait for any (was: Wait for Down key)
  CALL ClearShadowScreen
  CALL LBC84              ; Set zero penRow/penCol
  LD HL,SE119             ; "The ship sustains heavy damage. ...
  CALL LBEDE              ; Show message char-by-char
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
  jr NZ,LBBA4
  LD A,(LDB8F)            ; get Menu Y pos
  ADD A,-24               ; up two steps
  LD (LDB8F),A            ; set Menu Y pos
  JP LBA3D
; Menu up step
LBBA4:
  LD A,(LDB8F)            ; get Menu Y pos
  ADD A,-12               ; up one step
  LD (LDB8F),A            ; set Menu Y pos
  JP LBA3D
LBBAF:
  LD A,(LDB73)
  OR A                    ; do we have the game to continue?
  jr NZ,LBBC1
  LD A,(LDB8F)            ; get Menu Y pos
  ADD A,24                ; down two steps
  LD (LDB8F),A            ; set Menu Y pos
  JP LBA3D
; Menu down step
LBBC1:
  LD A,(LDB8F)            ; get Menu Y pos
  ADD A,12                ; down one step
  LD (LDB8F),A            ; set Menu Y pos
  JP LBA3D
; Menu up key pressed
LBBCC:
  LD A,(LDB8F)            ; get Menu Y pos
  CP $3A                  ; "New Game" selected?
  JP Z,LBA3D              ; yes => continue
  CP $52                  ; "Info" selected?
  jr Z,LBB92
  jr LBBA4
; Menu down key pressed
LBBDC:
  LD A,(LDB8F)            ; get Menu Y pos
  CP $6A                  ; "Quit" selected?
  JP Z,LBA3D
  CP $3A                  ; "New Game" selected?
  jr Z,LBBAF
  jr LBBC1
;
; Info menu item, show Controls
;
LBBEC:
  LD BC,$0060             ; Counter = 96 bytes or tiles
  LD HL,LF329             ; Decode from - Encoded screen for Inventory/Info popup
;TODO: Replace with call to LADF5
  LD DE,LDBF5             ; Where to decode
  CALL LB9F1              ; Decode the screen
  LD HL,LDBF5
  CALL LB177              ; Display screen HL from tiles with Tileset 2
  LD A,10   ; was: $05
  LD (LDCF3),A            ; Left margin size for text
  LD A,14   ; was: $07
  LD (LDCF4),A            ; Line interval for text
  LD HL,$163C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0A5             ; "- Controls -"
  CALL LBEDE              ; Show message char-by-char
  LD HL,$240A
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0A7             ; "2nd = Look / Shoot Alpha = Inventory ..."
  CALL LBEDE              ; Show message char-by-char
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  CALL LADA1              ; Wait for MODE key
  JP LBA3D                ; Return to Menu
;
; Add menu background phase 0..7 to L
LBC29:
  LD A,(LDC55)            ; get Menu background phase
  ADD A,L
  LD L,A
  RET
;
LBC2F:
  XOR A
  LD (LDC55),A            ; clear Menu background phase
  RET
;
; Delay x20
LBC34:
  LD B,$14                ; x20
LBC36:
  CALL LB2D0              ; Delay
  DJNZ LBC36
  RET
;
; Draw access code, 4 chars
;   HL = access code buffer address
LBC3C:
  LD DE,$5038
  LD (L86D7),DE           ; penRow/penCol
  LD B,$04
LBC45:
  PUSH BC
  PUSH HL
  LD A,(HL)
  CP $24                  ; tile number for '-' sign
  JR Z,LBC64
;  SUB $1A
  add a,$30-$1A           ; from tile number to '0'..'9' char
;  RST $28                 ; rBR_CALL
;  DEFW $478C
  call DrawChar
  LD A,$02                ; small space between digits
;  RST $28                 ; rBR_CALL
;  DEFW $4BF7              ; _DispOP1A - Rounds a floating-point number to the current fix setting and display it at the current pen location
  call DrawChar
  LD A,(L86D7)
  DEC A
  DEC A
  LD (L86D7),A
LBC5E:
  POP HL
  INC HL
  POP BC
  DJNZ LBC45
  RET
LBC64:
  LD A,$2D                 ; '-'
;  RST $28                 ; rBR_CALL
;  DEFW $455E              ; _VPutMap - Displays either a small variable width or large 5x7 character at the current pen location and updates penCol.
  call DrawChar
  JR LBC5E
;
; Generate random access code
;   HL = 4-byte buffer address
LBC6B:
  LD B,$04
LBC6D:
  PUSH BC
  PUSH HL
;  LD B,$0B
;  CALL $4086
  call GetRandom11        ; Generate random number 0..10
  ADD A,$1A               ; tile number for '0'
  POP HL
  LD (HL),A
  INC HL
  POP BC
  DJNZ LBC6D              ; continue the loop
  RET
;
; Clear shadow screen and copy to ZX screen
LBC7D:
  CALL ClearShadowScreen
  jp ShowShadowScreen   ; Copy shadow screen to ZX screen
;  RET
;
; Set zero penRow/penCol
ClearPenRowCol:
LBC84:
  LD HL,$0000             ; Left-top corner
  LD (L86D7),HL           ; Set penRow/penCol
  RET
;
; Found action point at room description offset $0F..$10
LBC8B:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0011             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD A,(LDB75)            ; Direction/orientation
  SUB C
  JP NZ,LAADA
  CALL LAB28              ; Show small message popup
  LD A,10     ; was: $05
  LD (LDCF3),A            ; Left margin size for text
  LD A,14     ; was: $07
  LD (LDCF4),A            ; Line interval for text
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0013             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  LD (LDC87),A            ; store RoomDesc[$13] value
  LD E,A
  LD D,$00
  LD HL,LDB90
  ADD HL,DE
  LD A,(HL)
  OR A                    ; do we have it working?
  jr Z,LBCD5
  CALL LBD69              ; Set penRow/penCol = $580A
  LD HL,SE12D             ; " It doesnt look like you can do anything else here"
; Show the message, show screen, wait for key, continue game main loop
LBCC5:
  CALL LBEDE              ; Show message char-by-char
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
LBCCB:
  CALL LA0F1              ; Scan keyboard
  CP $37                  ;   MODE key?
  JR NZ,LBCCB             ; no => wait some more
  JP L9E2E                ; Show the screen, continue the game main loop
;
LBCD5:
  LD A,(LDC87)            ; get RoomDesc[$13] value - important object in the room
  CP $01                  ; the Generator
  jr Z,LBCF6
  CP $02                  ; the Workstation
  jr Z,LBCFF
  CP $04                  ; Life-Support System
  JP Z,LBD4E
  CP $05                  ; Evacuation Deck re-pressure
  JP Z,LBD57
  CP $06                  ; Guidance System
  JP Z,LBD60
  CP $07                  ; the Pod
  JP Z,LBD70
; RoomDesc[$13] == $01 - the Generator
LBCF6:
  CALL LBD69              ; Set penRow/penCol = $580A
  LD HL,SE12F             ; "This Generator is damaged All of the panels are loose"
  JP LBCC5                ; Show the message/screen, wait for key, continue game main loop
; RoomDesc[$13] == $02 - the Workstation
LBCFF:
  LD HL,LDB90+1
;  INC HL                  ; HL = LDB90 + $01
  LD A,(HL)
  OR A                    ; Generator working?
  jr NZ,LBD11             ; yes => jump
  CALL LBD69              ; Set penRow/penCol = $580A
  LD HL,SE131             ; "This Workstation doesnt seem to have any power...?"
  JP LBCC5                ; Show the message/screen, wait for key, continue game main loop
LBD11:
  CALL LAE09              ; Decode current room description to LDBF5
  LD DE,$0030             ; offset in the room description
  ADD HL,DE
  LD A,(HL)
  LD (LDC89),A            ; set the current item
  CALL LBD69              ; Set penRow/penCol = $580A
  LD HL,SE133             ; "The Workstation has now successfully booted up"
  CALL LBEDE              ; Show message char-by-char
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  CALL LAB28              ; Show small message popup
LBD2B:
  CALL LA0F1              ; Scan keyboard
  CP $01                  ;   Down key?
  JR NZ,LBD2B             ; no => wait some more
  LD HL,LDB90+2
;  INC HL
;  INC HL                  ; HL = LDB90 + $02
  LD (HL),$01             ; mark Workstation is working now
  LD A,(LDC89)            ; get the current item number
  LD H,$00
  LD L,A
  LD DE,LDB9C             ; Inventory items
  ADD HL,DE
  LD (HL),$01             ; mark that we have the item now
  CALL LBD69              ; Set penRow/penCol = $580A
  LD HL,SE135             ; "The Workstation Ejected A Data Cartridge 2"
  JP LBCC5                ; Show the message/screen, wait for key, continue game main loop
; RoomDesc[$13] == $04 - Life-Support System
LBD4E:
  CALL LBD69              ; Set penRow/penCol = $580A
  LD HL,SE13F             ; "The Life Support System needs Re-Configuring"
  JP LBCC5                ; Show the message/screen, wait for key, continue game main loop
; RoomDesc[$13] == $05 - Evacuation Deck re-pressurised
LBD57:
  CALL LBD69              ; Set penRow/penCol = $580A
  LD HL,SE141             ; "AirLock Control & Re-Pressurisation Station"
  JP LBCC5                ; Show the message/screen, wait for key, continue game main loop
; RoomDesc[$13] == $06 - Guidance System
LBD60:
  CALL LBD69              ; Set penRow/penCol = $580A
  LD HL,SE143             ; "This MainFrame is missing a Power Cell"
  JP LBCC5                ; Show the message/screen, wait for key, continue game main loop
; Set penRow/penCol = $580A
LBD69:
  LD HL,$580A
  LD (L86D7),HL           ; Set penRow/penCol
  RET
; RoomDesc[$13] == $07 - Pod
LBD70:
;  LD DE,$0006
  LD HL,LDB90+6
;  ADD HL,DE               ; HL = address of Guidance System mark
  LD A,(HL)               ; mark Guidance System working now
  OR A                    ; does it work?
  jr NZ,LBD85             ; yes => Flying away on the Pod
  CALL LBD69              ; Set penRow/penCol = $580A
  LD HL,SE145             ; "This Pod cant naviagate. Guidance System is offline"
  JP LBCC5                ; Show the message/screen, wait for key, continue game main loop
; Flying away on the Pod
LBD85:
  LD A,$44
  LD (LDC59),A            ; set delay factor
  LD (LDC85),A            ; Use delay and copy screen in LBEDE
  XOR A
  LD (LDCF3),A            ; Left margin size for text
  LD (LDBF4),A            ; clear counter of achievements
  LD A,14     ; was: $07
  LD (LDCF4),A            ; Line interval for text
; Showing end-of-story screen
  CALL ClearShadowScreen
  call ClearPenRowCol
;  LD HL,$0000
;  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE11B             ; "The onboard guidance system picks up a ...
  CALL LBEDE              ; Show message char-by-char
  call WaitAnyKey         ; was: Wait for MODE key
; Showing statistics screen
  LD A,$06
  LD (LDCF3),A            ; Left margin size for text
  CALL ClearShadowScreen
  LD HL,$0C0C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0A1             ; "Items Found (/24): Enemies Killed: PlayerDeaths: Awards:
  CALL LBEDE              ; Show message char-by-char
  CALL LBC34              ; Delay x20
  LD DE,$0C8C
  LD A,(LDBC7)            ; get Items Found count
  LD L,A
  LD H,$00
  CALL LB97D              ; Draw 5-digit number HL at row/col DE, and show the screen
  CALL LBC34              ; Delay x20
  LD DE,$1A8C
  LD HL,(LDBC5)           ; get Enemies Killed count
  CALL LB97D              ; Draw 5-digit number HL at row/col DE, and show the screen
  CALL LBC34              ; Delay x20
  LD DE,$288C
  LD HL,(LDBC3)           ; get Player Deaths count
  CALL LB97D              ; Draw 5-digit number HL at row/col DE, and show the screen
  CALL LBC34              ; Delay x20
  LD A,(LDBC7)            ; get Items Found count
  SUB $14                 ; 20 or more?
  jr C,LBE06              ; no => jump
  LD HL,$520C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0AD             ; "Sherlock Holmes" (achievement)
  CALL LBEDE              ; Show message char-by-char
  LD A,(LDBF4)
  INC A                   ; increase counter of achievements
  LD (LDBF4),A
  JR LBE12
LBE06:
  LD HL,$520C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0AB             ; "Sir Miss-A-Lot" (achievement)
  CALL LBEDE              ; Show message char-by-char
LBE12:
  LD DE,$0032             ; 50
  LD HL,(LDBC5)           ; get Enemies Killed count
  call CpHLDE             ; Compare HL and DE
  JR C,LBE32              ; less 50? => jump
  LD HL,$600C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0B1             ; "Terminator" (achievement)
  CALL LBEDE              ; Show message char-by-char
  LD A,(LDBF4)
  INC A                   ; increase counter of achievements
  LD (LDBF4),A
  JR LBE3E
LBE32:
  LD HL,$600C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0AF             ; "Running Scared"
  CALL LBEDE              ; Show message char-by-char
LBE3E:
  LD DE,$0000
  LD HL,(LDBC3)           ; get Player deaths count
  call CpHLDE             ; Compare HL and DE
  JR NZ,LBE5E
  LD HL,$6E0C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0B5             ; "Survivor" (achievement)
  CALL LBEDE              ; Show message char-by-char
  LD A,(LDBF4)
  INC A                   ; increase counter of achievements
  LD (LDBF4),A
  JR LBE6A
LBE5E:
  LD HL,$6E0C
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0B3             ; "Over & Over Again" (achievement)
  CALL LBEDE              ; Show message char-by-char
LBE6A:
  call WaitAnyKey         ; was: Wait for MODE key
  CALL ClearShadowScreen
  LD A,(LDBF4)            ; get counter of achievements
  CP $03                  ; do we have all three of them?
  JR NZ,LBE8A             ; no => skip extended ending
; Extended ending
  XOR A
  LD (LDCF3),A            ; Left margin size for text
  call ClearPenRowCol
;  LD HL,$0000
;  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE11D             ; "System Alert triggered: ..."
  CALL LBEDE              ; Show message char-by-char
  jr LBE9B
LBE8A:
  LD A,30   ; was: $0F
  LD (LDCF3),A            ; Left margin size for text
  LD HL,$3414
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE0A9             ; "Earn 3 Good Awards for an Extended Ending!"
  CALL LBEDE              ; Show message char-by-char
LBE9B:
  call WaitAnyKey         ; was: Wait for MODE key
  CALL ClearShadowScreen
  LD HL,$2E46
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE11F             ; "The End"
  CALL LBEDE              ; Show message char-by-char
  CALL LBC34              ; Delay x20
  JP LBF6F                ; The End
;
;NOTE: This code is not used
;LBEB3:
;
; Draw string on the screen
;   HL = String address
LBEDE:
  ld a,(hl)
  inc hl
  or a
  ret z
  cp $7C	                ; '|' - line end ?
  jr z,LBF1B              ; yes => process line end
  push hl
  call DrawChar
  LD A,(LDC85)            ; get Delay and copy screen flag
  OR A
  JR Z,LBEF9_1            ; Skip delay and copy screen
  CALL LB2D0              ; Delay
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
LBEF9_1:
  pop hl
  jr LBEDE
LBF1B:                    ; Line end
  PUSH BC
  LD A,(L86D8)            ; Get penRow
  LD C,A
  LD A,(LDCF4)            ; Line interval for text
  ADD A,C
  LD (L86D8),A            ; Set penRow
  LD A,(LDCF3)            ; Get left margin size for text
  LD (L86D7),A            ; Set penCol
  POP BC
  jr LBEDE
;
;NOTE: This routine is not used
;LBF31: 
;
;NOTE: This routine is not used
;LBF47: 
;
; Set variables for Credits
LBF54:
  XOR A
  LD (LDD57),A            ; clear Credits line number
  LD (LDD56),A            ; clear Credits counter within one line
  LD (LDC85),A            ; Skip delay and copy screen in LBEDE
  LD A,$96
  LD (LDC59),A            ; set delay factor
  RET
;
; Credits menu item selected
LBF64:
  CALL ClearShadowScreen
  CALL ShowShadowScreen   ; Copy shadow screen to ZX screen
  CALL LBF54              ; Set variables for Credits
  JR LBF81                ; Credits screen text scrolls up
;
; The End
;
LBF6F:
  CALL ClearShadowScreen
  CALL LBF54              ; Set variables for Credits
  LD HL,$2E46
  LD (L86D7),HL           ; Set penRow/penCol
  LD HL,SE11F             ; "The End"
  CALL LBEDE              ; Show message char-by-char
;
; Credits screen text scrolls up
;
LBF81:
  LD A,126                ; To draw new strings on the very bottom
  LD (L86D8),A            ; Set penRow
LBF686:
  jr LBF6F_4
LBF6F_2:
  call ShowShadowScreen   ; Copy shadow screen to ZX screen
  CALL LB2D0              ; Delay
LBF6F_3:
  CALL LA0F1              ; Scan keyboard
;  or a                    ; any key pressed?
  jp nz,LBA3D             ; any key => Return to main Menu
  CALL LBFD5              ; Scroll shadow screen up one line
;  CALL LBFEC
  JR LBF686
LBF6F_4:
  LD A,(LDD56)
  INC A                   ; increase counter within the line
  LD (LDD56),A
  CP 12                   ; last line of the current string?
  jr NZ,LBF6F_2           ; no => continue the scrolling
  XOR A
  LD (LDD56),A            ; clear counter within the line
  ld d,a                  ; clear D
  LD A,(LDD57)
  LD E,A
;  LD D,$00
  LD HL,LDDF2             ; Table of left margins for Credits strings
  ADD HL,DE
  LD A,(HL)               ; now A = left margin for the string
  LD (L86D7),A            ; Set penCol
  LD A,(LDD57)            ; get Credits line number
  LD HL,LDD58             ; Table of Credits strings
  CALL LADFF              ; Get address from table HL by index A
  CALL DrawString         ; Draw string on shadow screen without any delays
  LD A,(LDD57)
  INC A                   ; increase the Credits line counter
  LD (LDD57),A
  CP $47
  jr NZ,LBF6F_3
  JP LBA3D                ; Return to main Menu
; Scroll shadow screen up 1px
LBFD5:
  LD DE,ShadowScreen
  LD HL,ShadowScreen+24
  LD BC,137*24
  LDIR
  RET
;LBFEC:
;  LD DE,$A2D7
;  LD HL,$9340
;  LD BC,$02B8
;  LDIR
;  RET

;----------------------------------------------------------------------------
