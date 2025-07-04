    processor 6502

    include "../../incl/vcs.h"
    include "../../incl/macro.h"

    seg code
    org $F000           ; Defines the origin of the rom at $F000

Start:
    CLEAN_START         ; Macro to safely clear memory and TIA


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set a new fram by turning on VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NextFrame:
    lda #2              ; Same as binary value %00000010
    sta VBLANK          ; Turn on VBLANK
    sta VSYNC           ; Turn on VSYNC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate the three lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    sta WSYNC           ; First scanline
    sta WSYNC           ; Second scanline
    sta WSYNC           ; Third scanline
    lda #0
    sta VSYNC           ; Turn off VSYNC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the recommended 37 scanlines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #37             ; X = 37 (to count 37 scanlines)
LoopVBlank:
    sta WSYNC           ; Hit WSYNC and wait for the next scanline
    dex
    bne LoopVBlank      ; Loop while X != 0

    lda #0
    sta VBLANK          ; Turn off VBLANK


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw 192 visible scanlines (kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #192            ; Counter for 192 visible scanlines
LoopVisible:
    stx COLUBK          ; Set the background color
    sta WSYNC           ; Wait for the next scanline
    dex                 ; X--
    bne LoopVisible     ; Loop while X != 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK lines (overscan) to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2              
    sta VBLANK          ; Hit and turn on VBLANK again
    ldx #30             ; Counter for 30 scanlines
LoopOverscan:
    sta WSYNC           ; Wait for the next scanline
    dex                 ; X--
    bne LoopOverscan    ; Loop while X != 0

    jmp NextFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM size to exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC           ; Defines origin to $FFFC
    .word Start         ; Reset vector at $FFFC (where program starts)
    .word Start         ; Interrupt vector at $FFFE (unused in the VCS)

