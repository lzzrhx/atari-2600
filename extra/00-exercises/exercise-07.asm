    processor 6502
    seg Code
    org $F000
Start:
    LDA #10
    STA $80
    INC $80
    DEC $80

    org $FFFC
    .word Start
    .word Start
