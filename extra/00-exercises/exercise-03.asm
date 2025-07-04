    processor 6502
    seg Code
    org $F000
Start:
    LDA #15
    TAX
    TAY
    TXA
    TYA
    LDX #6
    TXA
    TAY

    org $FFFC
    .word Start
    .word Start

