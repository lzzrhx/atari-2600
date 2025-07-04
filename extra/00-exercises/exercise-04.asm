    processor 6502
    seg Code
    org $F000
Start:
    LDA #100
    CLC
    ADC #5
    SEC
    SBC #10

    org $FFFC
    .word Start
    .word Start

