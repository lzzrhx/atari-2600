;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set processor model
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    processor 6502


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with register mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    include "../incl/vcs.h"
    include "../incl/macro.h"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start an uninitialized segment (at $80) for variable declaration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80
JetXPos         byte        ; player0 x-pos
JetYPos         byte        ; player0 y-pos
BomberXPos      byte        ; player1 x-pos
BomberYPos      byte        ; player1 y-pos
JetSpritePtr    word        ; Pointer to player0 sprite lookup table
JetColorPtr     word        ; Pointer to player0 color lookup table
BomberSpritePtr word        ; Pointer to player1 sprite lookup table
BomberColorPtr  word        ; Pointer to player1 color lookup table
JetAnimOffset   byte        ; player0 sprite frame offset for animation
Random          byte        ; Random number generated to set bomber X-position


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start ROM code segment (at $F000)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000
Reset:
    CLEAN_START             ; Macro to clean memory and TIA


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize RAM variables and TIA registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #10
    sta JetYPos             ; Set JetYPos
    lda #60
    sta JetXPos             ; Set JetxPos
    lda #83
    sta BomberYPos          ; Set BomberYPos
    lda #54
    sta BomberXPos          ; Set BomberXPos
    lda #%11010100
    sta Random              ; Set Random


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize the pointers to the correct lookup table addresses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #<JetSprite
    sta JetSpritePtr        ; Lo-byte pointer for jet sprite lookup table
    lda #>JetSprite
    sta JetSpritePtr+1      ; Hi-byte pointer for jet sprite lookup table

    lda #<JetColor
    sta JetColorPtr         ; Lo-byte pointer for jet color lookup table
    lda #>JetColor
    sta JetColorPtr+1       ; Hi-byte pointer for jet color lookup table

    lda #<BomberSprite
    sta BomberSpritePtr     ; Lo-byte pointer for bomber sprite lookup table
    lda #>BomberSprite
    sta BomberSpritePtr+1   ; Hi-byte pointer for bomber sprite lookup table

    lda #<BomberColor
    sta BomberColorPtr      ; Lo-byte pointer for bomber color lookup table
    lda #>BomberColor
    sta BomberColorPtr+1    ; Hi-byte pointer for bomber color lookup table


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JET_HEIGHT = 9              ; player0 sprite height
BOMBER_HEIGHT = 9           ; player1 sprite height


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The the main display loop and frame rendering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations and tasks performed in the pre-VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda JetXPos
    ldy #0
    jsr SetObjectXPos       ; Set player0 horizontal position
    lda BomberXPos
    ldy #1
    jsr SetObjectXPos       ; Set player1 horizontal position
    sta WSYNC
    sta HMOVE               ; Apply the previously set horizontal offsets

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display VSYNC (3) and VBLANK (37)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK              ; Turn VBLANK on
    sta VSYNC               ; Turn VSYNC on
    REPEAT 3
        sta WSYNC           ; First three VSYNC scanlines
    REPEND
    lda #0
    sta VSYNC               ; Turn VSYNC off
    REPEAT 37
        sta WSYNC           ; VBLANK lines
    REPEND
    sta VBLANK              ; Turn VBLANK off


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 96 visible scanlines (2-line kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameVisibleLines:
    lda #$84
    sta COLUBK              ; Set background color
    lda #$C2
    sta COLUPF              ; Set playfield color
    lda #%00000001
    sta CTRLPF
    lda #%11110000
    sta PF0                 ; Set PF0 bit pattern
    lda #%11111100
   sta PF1                 ; Set PF1 bit pattern
    lda #%00000000
    sta PF2                 ; Set PF2 bit pattern
    ldx #96                 ; X counts the number of remaining scanlines

.GameLineLoop:

.InsideJetSprite:
    txa                     ; Transfer X to A
    sec                     ; Set carry flag before subtraction
    sbc JetYPos             ; Subtract sprite Y-coordinate
    cmp JET_HEIGHT          ; Check if scanline is inside the sprite bounds
    bcc .DrawJetSprite      ; If the result < SpriteHeight, call the draw routine
    lda #0                  ; Else, set lookup index to zero
.DrawJetSprite
    clc                     ; Clear carry flag before addition
    adc JetAnimOffset       ; Jump to the correct sprite frame address in memory
    tay                     ; Load Y to work with the pointer
    lda (JetSpritePtr),Y    ; Load player0 bitmap data from the lookup table
    sta WSYNC               ; Wait for the scanline
    sta GRP0                ; Set graphics for player0
    lda (JetColorPtr),Y     ; Load player color0 from the lookup table
    sta COLUP0              ; Set color for player0

.InsideBomberSprite:
    txa                     ; Transfer X to A
    sec                     ; Set carry flag before subtraction
    sbc BomberYPos          ; Subtract sprite Y-coordinate
    cmp BOMBER_HEIGHT       ; Check if scanline is inside the sprite bounds
    bcc .DrawBomberSprite   ; If the result < SpriteHeight, call the draw routine
    lda #0                  ; Else, set lookup index to zero
.DrawBomberSprite
    tay                     ; Load Y to work with the pointer
    lda #%00000101
    sta NUSIZ1              ; Stretch player1 sprite
    lda (BomberSpritePtr),Y ; Load player1 bitmap data from the lookup table
    sta WSYNC               ; Wait for the scanline
    sta GRP1                ; Set graphics for player1
    lda (BomberColorPtr),Y  ; Load player1 color from the lookup table
    sta COLUP1              ; Set color for player1

    dex                     ; X--
    bne .GameLineLoop       ; Repeat next main game scanline until finished

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK overscan lines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK              ; Turn VBLANK on
    REPEAT 30
        sta WSYNC           ; Display 30 lines of VBLANK overscan
    REPEND
    lda #0
    sta VBLANK              ; Turn off VBLANK


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Joystick input for Player 0 (P0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #0
    sta JetAnimOffset       ; Reset jet animation frame to zero each frame
CheckP0Up:
    lda #%00010000          ; Up
    bit SWCHA
    bne CheckP0Down
    inc JetYPos

CheckP0Down:
    lda #%00100000          ; Down
    bit SWCHA
    bne CheckP0Left
    dec JetYPos

CheckP0Left:
    lda #%01000000          ; Left
    bit SWCHA
    bne CheckP0Right
    dec JetXPos
    lda JET_HEIGHT
    sta JetAnimOffset       ; Set animation offset to the second frame

CheckP0Right:
    lda #%10000000          ; Right
    bit SWCHA
    bne EndInput
    inc JetXPos
    lda JET_HEIGHT
    sta JetAnimOffset       ; Set animation offset to the second frame

EndInput:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations to update position for next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UpdateBomberPosition:
    lda BomberYPos
    clc
    cmp #0                  ; Compare bomber Y-position with 0
    bmi .ResetBomberPosition; If it is <0, then reset Y-position to the top
    dec BomberYPos          ; Else, decrement bomber Y-position for the next frame
    jmp .EndBomberPositionUpdate
.ResetBomberPosition
    jsr GetRandomBomberPos  ; Call subroutine for random X-position
.EndBomberPositionUpdate:   ; Fallback for the position update code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame          ; Continue to display next frame


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to set the X position of objects with fine offset
;; The A register contains the desired X-coordinate
;; Y contains the id of the object (0:Player0 / 1:Player1 / 2: Missle0 / 3: Missle1)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetObjectXPos subroutine
    sta WSYNC
    sec
.Div15Loop
    sbc #15
    bcs .Div15Loop
    eor #7
    asl
    asl
    asl
    asl
    sta HMP0,Y
    sta RESP0,Y
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to spawn the bomber at a random position
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetRandomBomberPos subroutine
    lda Random              ; Load starting random seed
    asl                     ; Arithmetic shift-left
    eor Random              ; XOR A with Random
    asl                     ; Arithmetic shift-left
    eor Random              ; XOR A with Random
    asl                     ; Arithmetic shift-left
    asl                     ; Arithmetic shift-left
    eor Random              ; XOR A with Random
    asl                     ; Arithmetic shift-left
    rol Random              ; Rotate left
    lsr                     ; Shift right to divide by 2
    lsr                     ; Shift right to divide by 2
    sta BomberXPos
    lda #30
    ;clc                     ; Clear carry flag before addition
    adc BomberXPos          ; Add 30 to compensate for the left green playfield
    sta BomberXPos
    lda #96
    sta BomberYPos

    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to generate a random bit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GenerateRandomBit subroutine
;    lda Rand4 
;    asl
;    asl
;    asl
;    eor Rand4
;    asl
;    asl
;    rol Rand1
;    rol Rand2
;    rol Rand3
;    rol Rand4
;    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to generate a random byte
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GenerateRandomByte subroutine
;    ldx #8                  ; x = 8
;.RandomByteLoop
;    jsr GenerateRandomBit   ; Call routine to generate random bit
;    dex                     ; X--
;    bne .RandomByteLoop     ; Repeat 8 times
;    lda Randl               ; Load a with the result
;    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare ROM lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JetSprite:
    .byte #%00000000         ;
    .byte #%00010100         ;   # #
    .byte #%01111111         ; #######
    .byte #%00111110         ;  #####
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #

JetSpriteTurn:
    .byte #%00000000         ;
    .byte #%00001000         ;    #
    .byte #%00111110         ;  #####
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #

BomberSprite:
    .byte #%00000000         ;
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00101010         ;  # # #
    .byte #%00111110         ;  #####
    .byte #%01111111         ; #######
    .byte #%00101010         ;  # # #
    .byte #%00001000         ;    #
    .byte #%00011100         ;   ###

JetColor:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$BA
    .byte #$0E
    .byte #$08

JetColorTurn:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$0E
    .byte #$0E
    .byte #$08

BomberColor:
    .byte #$00
    .byte #$32
    .byte #$32
    .byte #$0E
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC               ; Move to position $FFFC
    .word Reset             ; Write 2 bytes with the program reset vector
    .word Reset             ; Write 2 bytes with the interruption vector

