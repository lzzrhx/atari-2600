    processor 6502

    include "../../incl/vcs.h"
    include "../../incl/macro.h"

    seg code
    org $F000           ; Defines the origin of the rom at $F000

START:
    CLEAN_START         ; Macro to safely clear the memory


LOOP:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set the background luminosity color to yellow
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #$1E            ; Load color into A ($1E is NTSC yellow)
    sta COLUBK          ; Store A to BackgroundColor address $09
    jmp LOOP            ; Repeat from LOOP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM size to exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC           ; Defines origin to $FFFC
    .word START         ; Reset vector at $FFFC (where program starts)
    .word START         ; Interrupt vector at $FFFE (unused in the VCS)

