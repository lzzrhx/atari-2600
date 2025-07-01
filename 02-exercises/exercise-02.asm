    processor 6502
    seg Code
    org $F000
Start:
    LDA #$A
    LDX #%11111111
    STA $80
    STX $81

    org $FFFC
    .word Start
    .word Start

