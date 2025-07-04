    processor 6502
    seg Code
    org $F000
Start:
    LDA #1
    LDX #2
    LDY #3
    INX
    INY
    CLC
    ADC #1
    DEX
    DEY
    SEC
    SBC #1

    org $FFFC
    .word Start
    .word Start
