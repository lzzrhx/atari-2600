;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Create a subroutine to set the X position of objects with fine offset
;; The A register contains the desired X-coordinate
;; The Y register contains the id of the object
;; Y=0: Player0
;; Y=1: Player1
;; Y=2: Missle0
;; Y=3: Missle1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetObjectXPos subroutine
    sta WSYNC
    sec
.Div15Loop
    sbs #15
    bcs .Div15Loop
    eor #7
    asl
    asl
    asl
    asl
    sta HMP0,Y
    sta RESP0,Y
    rts
