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
Score           byte            ; 2-digit score stored as BCD
Timer           byte            ; 2-digit timer stored as BCD
OnesDigitOffset word            ; 
TensDigitOffset word            ; Lookup table offset for the 10's digit
JetXPos         byte            ; player0 x-pos
JetYPos         byte            ; player0 y-pos
BomberXPos      byte            ; player1 x-pos
BomberYPos      byte            ; player1 y-pos
JetSpritePtr    word            ; Pointer to player0 sprite lookup table
JetColorPtr     word            ; Pointer to player0 color lookup table
BomberSpritePtr word            ; Pointer to player1 sprite lookup table
BomberColorPtr  word            ; Pointer to player1 color lookup table
JetAnimOffset   byte            ; player0 sprite frame offset for animation
Random          byte            ; Random number generated to set bomber X-position
Temp            byte            ; Temporary value
ScoreSprite     byte            ; Store the sprite bit pattern for the score
TimerSprite     byte            ; Store the sprite bit pattern for the timer
TerrainColor    byte            ; Store the color of the terrain
RiverColor      byte            ; Store the color of the river
FrameCount      byte


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JET_HEIGHT = 9                  ; player0 sprite height
BOMBER_HEIGHT = 9               ; player1 sprite height
DIGITS_HEIGHT = 5               ; Scoreboard height


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start ROM code segment (at $F000)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000
Reset:
    CLEAN_START                 ; Macro to clean memory and TIA


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize RAM variables and TIA registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #10
    sta JetYPos                 ; Set JetYPos
    lda #60
    sta JetXPos                 ; Set JetxPos
    lda #83
    sta BomberYPos              ; Set BomberYPos
    lda #62
    sta BomberXPos              ; Set BomberXPos
    lda #%11010100
    sta Random                  ; Set Random
    sed
    lda #$00
    sta Score                   ; Set Score
    lda #$99
    sta Timer                   ; Set Timer
    cld
    lda #0
    sta FrameCount


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize the pointers to the correct lookup table addresses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #<JetSprite
    sta JetSpritePtr            ; Lo-byte pointer for jet sprite lookup table
    lda #>JetSprite
    sta JetSpritePtr+1          ; Hi-byte pointer for jet sprite lookup table

    lda #<JetColor
    sta JetColorPtr             ; Lo-byte pointer for jet color lookup table
    lda #>JetColor
    sta JetColorPtr+1           ; Hi-byte pointer for jet color lookup table

    lda #<BomberSprite
    sta BomberSpritePtr         ; Lo-byte pointer for bomber sprite lookup table
    lda #>BomberSprite
    sta BomberSpritePtr+1       ; Hi-byte pointer for bomber sprite lookup table

    lda #<BomberColor
    sta BomberColorPtr          ; Lo-byte pointer for bomber color lookup table
    lda #>BomberColor
    sta BomberColorPtr+1        ; Hi-byte pointer for bomber color lookup table


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The the main display loop and frame rendering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Decrement the timer every second
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    inc FrameCount
    lda #60
    cmp FrameCount
    bne NotSecond
    sed
    lda Timer
    sec
    sbc #$1
    sta Timer                   ; Timer ++
    cld
    lda #0
    sta FrameCount
NotSecond:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display VSYNC (3) and VBLANK (37)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK                  ; Turn VBLANK on
    sta VSYNC                   ; Turn VSYNC on
    REPEAT 3
        sta WSYNC               ; First three VSYNC scanlines
    REPEND
    lda #0
    sta VSYNC                   ; Turn VSYNC off
    REPEAT 33
        sta WSYNC               ; VBLANK lines
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations and tasks performed in the pre-VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda JetXPos
    ldy #0
    jsr SetObjectXPos           ; Set player0 horizontal position
    lda BomberXPos
    ldy #1
    jsr SetObjectXPos           ; Set player1 horizontal position
    jsr CalculateDigitOffset    ; Calulcate the scoreboard digit lookup table offset 
    sta WSYNC
    sta HMOVE                   ; Apply the previously set horizontal offsets
    lda #0
    sta VBLANK                  ; Turn VBLANK off


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display the scoreboard lines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #0                      ; Clear TIA registers
    sta COLUBK
    sta PF0
    sta PF1
    sta PF2
    sta GRP0
    sta GRP1
    sta CTRLPF
    lda #$0C                    ; Set scoreboard color to white
    sta COLUPF
    ldx #DIGITS_HEIGHT          ; Start the X counter with the digit height
.ScoreDigitLoop:
    ldy TensDigitOffset         ; Get the tens digit offset for the Score
    lda Digits,Y                ; Load the bit pattern from lookup table
    and #$F0                    ; Mask the graphics for the ones digit
    sta ScoreSprite             ; Save the Score tens digit pattern in a variable
    ldy OnesDigitOffset         ; Get the ones digit offset for the Score
    lda Digits,Y                ; Load the bit pattern from lookup table
    and #$0F                    ; Mask the graphics for the tens digit
    ora ScoreSprite             ; Merge it with the saved tens digit sprite
    sta ScoreSprite             ; Save the final sprite
    sta WSYNC                   ; Wait for the end of the scanline
    sta PF1                     ; Update the playfield to display the Score sprite
    ldy TensDigitOffset+1       ; Get the tens digit offset for the Timer
    lda Digits,Y                ; Load the bit pattern from lookup table
    and #$F0                    ; Mask the graphics for the ones digit
    sta TimerSprite             ; Save the Timer tens digit pattern in a variable
    ldy OnesDigitOffset+1       ; Get the ones digit offset for the Timer
    lda Digits,Y                ; Load the bit pattern from lookup table
    and #$0F                    ; Mask the graphics for the tens digit
    ora TimerSprite             ; Merge it with the saved tens digit sprite
    sta TimerSprite             ; Save the final sprite
    jsr Sleep12Cycles           ; Waste some cycles
    sta PF1                     ; Update the playfield for Timer display
    ldy ScoreSprite             ; Preload for the next scanline
    sta WSYNC                   ; Wait for the next scanline
    sty PF1                     ; Update playfield for the score display
    inc TensDigitOffset         ; Increment all digits for the next line of data
    inc TensDigitOffset+1       ; Increment all digits for the next line of data
    inc OnesDigitOffset         ; Increment all digits for the next line of data
    inc OnesDigitOffset+1       ; Increment all digits for the next line of data
    jsr Sleep12Cycles           ; Waste some cycles
    dex                         ; X--
    sta PF1                     ; Update the playfield to display the Timer sprite
    bne .ScoreDigitLoop         ; If dex != 0, then branch to ScoreDigitLoop
    sta WSYNC
    lda #0
    sta PF0
    sta PF1
    sta PF2
    sta WSYNC
    sta WSYNC
    sta WSYNC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 84 visible scanlines (2-line kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameVisibleLines:
    lda TerrainColor
    sta COLUPF                  ; Set playfield color
    lda RiverColor
    sta COLUBK                  ; Set background color
    lda #%00000001
    sta CTRLPF
    lda #%11110000
    sta PF0                     ; Set PF0 bit pattern
    lda #%11111100
    sta PF1                     ; Set PF1 bit pattern
    lda #%00000000
    sta PF2                     ; Set PF2 bit pattern
    ldx #85                     ; X counts the number of remaining scanlines
.GameLineLoop:
.InsideJetSprite:
    txa                         ; Transfer X to A
    sec                         ; Set carry flag before subtraction
    sbc JetYPos                 ; Subtract sprite Y-coordinate
    cmp JET_HEIGHT              ; Check if scanline is inside the sprite bounds
    bcc .DrawJetSprite          ; If the result < SpriteHeight, call the draw routine
    lda #0                      ; Else, set lookup index to zero
.DrawJetSprite
    clc                         ; Clear carry flag before addition
    adc JetAnimOffset           ; Jump to the correct sprite frame address in memory
    tay                         ; Load Y to work with the pointer
    lda (JetSpritePtr),Y        ; Load player0 bitmap data from the lookup table
    sta WSYNC                   ; Wait for the scanline
    sta GRP0                    ; Set graphics for player0
    lda (JetColorPtr),Y         ; Load player color0 from the lookup table
    sta COLUP0                  ; Set color for player0
.InsideBomberSprite:
    txa                         ; Transfer X to A
    sec                         ; Set carry flag before subtraction
    sbc BomberYPos              ; Subtract sprite Y-coordinate
    cmp BOMBER_HEIGHT           ; Check if scanline is inside the sprite bounds
    bcc .DrawBomberSprite       ; If the result < SpriteHeight, call the draw routine
    lda #0                      ; Else, set lookup index to zero
.DrawBomberSprite
    tay                         ; Load Y to work with the pointer
    lda #%00000101
    sta NUSIZ1                  ; Stretch player1 sprite
    lda (BomberSpritePtr),Y     ; Load player1 bitmap data from the lookup table
    sta WSYNC                   ; Wait for the scanline
    sta GRP1                    ; Set graphics for player1
    lda (BomberColorPtr),Y      ; Load player1 color from the lookup table
    sta COLUP1                  ; Set color for player1
    dex                         ; X--
    bne .GameLineLoop           ; Repeat next main game scanline until finished

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK overscan lines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK                  ; Turn VBLANK on
    REPEAT 30
        sta WSYNC               ; Display 30 lines of VBLANK overscan
    REPEND
    lda #0
    sta VBLANK                  ; Turn off VBLANK


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Joystick input for Player 0 (P0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #0
    sta JetAnimOffset           ; Reset jet animation frame to zero each frame
CheckP0Up:
    lda #%00010000              ; Up
    bit SWCHA
    bne CheckP0Down
    lda #30
    cmp JetYPos
    bcc CheckP0Down
    inc JetYPos

CheckP0Down:
    lda #%00100000              ; Down
    bit SWCHA
    bne CheckP0Left
    lda #3
    cmp JetYPos
    bcs CheckP0Left
    dec JetYPos

CheckP0Left:
    lda #%01000000              ; Left
    bit SWCHA
    bne CheckP0Right
    lda #31
    cmp JetXPos
    bcs CheckP0Right
    dec JetXPos
    lda JET_HEIGHT
    sta JetAnimOffset           ; Set animation offset to the second frame

CheckP0Right:
    lda #%10000000              ; Right
    bit SWCHA
    bne EndInput
    lda #101
    cmp JetXPos
    bcc EndInput
    inc JetXPos
    lda JET_HEIGHT
    sta JetAnimOffset           ; Set animation offset to the second frame

EndInput:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Check for object collision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckCollisionP0P1:
    lda #%10000000              ; Bit 7 detects P0 and P1 collision
    bit CXPPMM                  ; Check CXPPMM register bit 7
    bne .CollisionP0P1          ; If collision P0 / P1 happened, game over
    jsr SetTerrainRiverColor
    jmp EndCollisionCheck       ; Else, skip to next check
.CollisionP0P1:
    jsr GameOver                ; Call gameover subroutine on collision
EndCollisionCheck:
    sta CXCLR                   ; Clear all collision flags before the next frame


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations to update position for next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UpdateBomberPosition:
    lda BomberYPos
    clc
    cmp #0                      ; Compare bomber Y-position with 0
    bmi .ResetBomberPosition    ; If it is <0, then reset Y-position to the top
    dec BomberYPos              ; Else, decrement bomber Y-position for the next frame
    jmp .EndBomberPositionUpdate
.ResetBomberPosition
    jsr GetRandomBomberPos      ; Call subroutine for random X-position
.SetScoreValues:
    sed                         ; Set decimal mode (BCD) for score and time values
    lda #1
    clc
    adc Score                   ; Score ++
    sta Score
    cld

.EndBomberPositionUpdate:       ; Fallback for the position update code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame              ; Continue to display next frame


SetTerrainRiverColor subroutine
    lda #$94
    sta RiverColor
    lda #$C4
    sta TerrainColor
    rts

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
;; Game Over subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameOver subroutine
    lda #$30
    sta TerrainColor            ; Set terrain color to red
    sta RiverColor              ; Set river color to red
    lda #0
    sta Score                   ; Score = 0
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to spawn the bomber at a random position
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetRandomBomberPos subroutine
    lda Random                  ; Load starting random seed
    asl                         ; Arithmetic shift-left
    eor Random                  ; XOR A with Random
    asl                         ; Arithmetic shift-left
    eor Random                  ; XOR A with Random
    asl                         ; Arithmetic shift-left
    asl                         ; Arithmetic shift-left
    eor Random                  ; XOR A with Random
    asl                         ; Arithmetic shift-left
    rol Random                  ; Rotate left
    lsr                         ; Shift right to divide by 2
    lsr                         ; Shift right to divide by 2
    sta BomberXPos
    lda #30
    ;clc                        ; Clear carry flag before addition
    adc BomberXPos              ; Add 30 to compensate for the left green playfield
    sta BomberXPos
    lda #96
    sta BomberYPos
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to handle scoreboard digits to be displayed on the screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Convert the giht and low nibbles of the variable Score and Timer
;; into the offsets of digits lookup table so the values can be displayed.
;; Each digit has a height of 5 bytes in the lookup table
;;
;; For the low nibble we need to multiply by 5
;;   + We can use left shifts to perform multiplication by 2
;;   + For any number N, the value of N*5 = (N*2*2)+N
;;
;; For the upper nibble, since its already times 16, we need to divite it
;; and then multiply by 5:
;;   + We can use right shifts to perform division by 2
;;   + For any number N, the value of (N/16)*5 = (N/2/2)+(N/2/2/2/2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalculateDigitOffset subroutine
    ldx #1                      ; X register is the loop counter
.PrepareScoreLoop               ; This will loop twice, first X=1, and then X=0
    lda Score,X                 ; Load A with the value Timer (X=1) or Score (X=0)
    and #$0F                    ; Remove the tens digit by masking 4 bits 00001111
    sta Temp                    ; Save the value of A into Temp
    asl                         ; Shift left (N*2)
    asl                         ; Shift left (N*4)
    adc Temp                    ; Add the value saved in Temp (N*5)
    sta OnesDigitOffset,X       ; Save A in OnesDigitOffset+1 or OnesDigitOffset
    lda Score,X                 ; Load A with the value Timer (X=1) or Score (X=0)
    and #$F0                    ; Remove the ones digit by masking 4 bits 11110000
    sta Temp                    ; Save the value of A into Temp
    lsr                         ; Shift right (N/2)
    lsr                         ; Shift right (N/4)
    sta Temp                    ; Save the value of A into Temp
    lsr                         ; Shift right (N/8)
    lsr                         ; Shift right (N/16)
    adc Temp                    ; Add the value saved in Temp (N/16+N/4)
    sta TensDigitOffset,X       ; Save A in TensDigitOffset+1 or TensDigitOffset
    dex                         ; X--
    bpl .PrepareScoreLoop       ; While X >= 0, loop to pass a second time
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to waste 12 cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; jsr takes 6 cycles
;; rts takes 6 cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Sleep12Cycles subroutine
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare ROM lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Digits:
    .byte %01110111             ; ### ###
    .byte %01010101             ; # # # #
    .byte %01010101             ; # # # #
    .byte %01010101             ; # # # #
    .byte %01110111             ; ### ###

    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #

    .byte %01110111             ; ### ###
    .byte %00010001             ;   #   #
    .byte %01110111             ; ### ###
    .byte %01000100             ; #   #
    .byte %01110111             ; ### ###

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00110011          ;  ##  ##
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %00100010          ;  #   #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01100110          ; ##  ##
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01100110          ; ##  ##
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01100110          ; ##  ##

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01100110          ; ##  ##
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #

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

