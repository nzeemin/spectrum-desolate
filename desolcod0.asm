
; This code block placed at $B2F9
; LZSA encoded block starts at $B300
; $FFE0-$B300 = $4CE0 = 19680 bytes

  ORG $B2F9     ; = 45817

  di
  ld sp,$5FB4
  jp Decompress

lzsaStart:
  INCBIN "desolcode.lzsa"

Decompress:
; Decompress the encoded block from $B300 to $5FB4
  ld hl,lzsaStart
  ld de,$5FB4
  call unlzsa1

; Start the main code
  ei
  jp $5FB4

; Size-optimized LZSA1 decompressor by spke & uniabis (67 bytes)
; https://github.com/emmanuel-marty/lzsa/blob/master/asm/z80/unlzsa1_small.asm
unlzsa1:
    ld b,0
ReadToken:
    ld a,(hl)
    inc hl
    push af
    and #70
    jr z,NoLiterals
    rrca
    rrca
    rrca
    rrca
    cp #07
    call z,ReadLongBA
    ld c,a
    ldir
NoLiterals:
    pop af
    push de
    ld e,(hl)
    inc hl
    ld d,#FF
    or a
    jp p,ShortOffset
LongOffset:
    ld d,(hl)
    inc hl
ShortOffset:
    and #0F
    add a,3
    cp 15+3
    call z,ReadLongBA
    ld c,a
    ex (sp),hl
    ex de,hl
    add hl,de
    ldir
    pop hl
    jr ReadToken
ReadLongBA:
    add a,(hl)
    inc hl
    ret nc
.code1:
    ld b,a
    ld a,(hl)
    inc hl
    ret nz
.code0:
    ld c,a
    ld b,(hl)
    inc hl
    or b
    ld a,c
    ret nz
    pop de
    pop de
    ret
