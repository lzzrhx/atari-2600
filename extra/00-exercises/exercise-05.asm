    processor 6502
    seg Code
    org $F000
Start:
    LDA #$A
    LDX #%1010
    STA $80
    STX $81
    LDA #10
    CLC
    ADC $80
    ADC $81
    STA $82

    org $FFFC
    .word Start
    .word Start
