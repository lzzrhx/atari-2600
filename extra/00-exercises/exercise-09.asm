    processor 6502
    seg Code
    org $F000
Start:
    LDA #1

Loop:
    CLC
    ADC #1
    CMP #10
    BNE Loop

    org $FFFC
    .word Start
    .word Start
