;************************************************************************
;                                                                       *
;   Filename:       bcd.asm                                             *
;   Date:           Dec 11 2010                                         *
;   File Version:   0.1                                                 *
;       0.1 seperated from math.asm                     Dec 11, 2010    *
;   Author:         Peter Farkas                                        *
;                                                                       *
;************************************************************************
;                                                                       *
;   Architecture:   PIC18F                                              *
;                                                                       *
;************************************************************************
;                                                                       *
;   Files required: none                                                *
;                                                                       *
;************************************************************************
;                                                                       *
;   Description:    binary coded decimal conversion routines            *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "src\buildOptions.inc"

    if BCD_EN == 1
        GLOBAL      Convert2BtoBCD
        GLOBAL      ConvertU2BtoBCD
        GLOBAL      Convert1BtoBCD
        GLOBAL      ConvertU1BtoBCD
    endif

    if BCD_EN == 1
        GLOBAL      num1
        GLOBAL      num0
    endif

    if BCD_EN == 1
        GLOBAL      sign
        GLOBAL      tenK
        GLOBAL      thou
        GLOBAL      hund
        GLOBAL      tens
        GLOBAL      ones
    endif

;******************************************************************************
BCDVARA     udata_acs

    if BCD_EN == 1
;input
;=A3*16^3 + A2*16^2 + A1*16^1 + A0*16^0
;=A3*4096 + A2*256 + A1*16 + A0
num1        res 1       ;A3*16+A2
num0        res 1       ;A1*16+A0

;share variables
;=B4*10^4 + B3*10^3 + B2*10^2 + B1*10^1 + B0*10^0
sign        res 1       ; 0:+, 1:-
tenK        res 1       ;B4
thou        res 1       ;B3
hund        res 1       ;B2
tens        res 1       ;B1
ones        res 1       ;B0
    endif

;******************************************************************************
BCDCODE CODE


;Takes hex number in num[1:0]  Returns decimal in ;tenK:thou:hund:tens:ones

;;input
;;=A3*16^3 + A2*16^2 + A1*16^1 + A0*16^0
;;=A3*4096 + A2*256 + A1*16 + A0
;num1            EQU AD3M        ;A3*16+A2
;num0            EQU AD3L   ;A1*16+A0
;;share variables
;;=B4*10^4 + B3*10^3 + B2*10^2 + B1*10^1 + B0*10^0
;tenK            EQU 1      ;B4
;thou            EQU 1      ;B3
;hund            EQU D1     ;B2
;tens            EQU R2     ;B1
;ones            EQU R1     ;B0


    if BCD_EN == 1
; *** BCD
; TODO: clean this up, maybe make short routines for 1B BCD conversions.
Convert1BtoBCD:
        clrf    sign

        clrf    num1
        btfss   num0, 7
        bra     ConvertU2BtoBCD

        ; negative value
        setf    num1
        bra     Convert2BtoBCD

ConvertU1BtoBCD:
        clrf    num1                            ; MSB is 0x00
        bra     ConvertU2BtoBCD


Convert2BtoBCD:
        ; step 1:
        ; if (num < 0) then 2's complement the number and set the sign bit
step_1:
        clrf    sign                            ; sign <= +
        btfss   num1, 7
        bra     step_2

        ; number was negative
        bsf     sign, 0                         ; sign <= -

        ; 2's compliment
        comf    num1, F
        comf    num0, F

        infsnz  num0, F
        incf    num1, F

ConvertU2BtoBCD:
step_2:
        swapf   num1, W                         ; W = A2,A3
        iorlw   0xF0                            ; W = 0xF,A3
        movwf   thou                            ; B3 = A3-16
        addwf   thou, F                         ; B3 = 2*(A3-16) = 2A3 - 32
        addlw   .226                            ; W = A3-16 - 30 = A3-46
        movwf   hund                            ; B2 = A3-46
        addlw   .50                             ; W = A3-46 + 50 = A3+4
        movwf   ones                            ; B0 = A3+4

        movf    num1, W                         ; W = A3*16+A2
        andlw   0x0F                            ; W = A2
        addwf   hund, F                         ; B2 = A3-46 + A2 = A3+A2-46
        addwf   hund, F                         ; B2 = A3+A2-46  + A2 = A3+2A2-46
        addwf   ones, F                         ; B0 = A3+4 + A2 = A3+A2+4
        addlw   .233                            ; W = A2 - 23
        movwf   tens                            ; B1 = A2-23
        addwf   tens, F                         ; B1 = 2*(A2-23)
        addwf   tens, F                         ; B1 = 3*(A2-23) = 3A2-69

        swapf   num0, W                         ; W = A0*16+A1
        andlw   0x0F                            ; W = A1
        addwf   tens, F                         ; B1 = 3A2-69 + A1 = 3A2+A1-69 range -69...-9
        addwf   ones, F                         ; B0 = A3+A2+4 + A1 = A3+A2+A1+4 and Carry = 0 (thanks NG)

        rlcf    tens, F                         ; B1 = 2*(3A2+A1-69) + C = 6A2+2A1-138 and Carry is now 1 as tens register had to be negitive
        rlcf    ones, F                         ; B0 = 2*(A3+A2+A1+4) + C = 2A3+2A2+2A1+9 (+9 not +8 due to the carry from prev line)
        comf    ones, F                         ; B0 = ~(2A3+2A2+2A1+9) = -2A3-2A2-2A1-10 (ones complement plus 1 is twos complement.)

        rlcf    ones, F                         ; B0 = 2*(-2A3-2A2-2A1-10) = -4A3-4A2-4A1-20

        movf    num0, W                         ; W = A1*16+A0
        andlw   0x0F                            ; W = A0
        addwf   ones, F                         ; B0 = -4A3-4A2-4A1-20 + A0 = A0-4(A3+A2+A1)-20 range -215...-5 Carry=0
        rlcf    thou, F                         ; B3 = 2*(2A3 - 32) = 4A3 - 64

        movlw   0x07                            ; W = 7
        movwf   tenK                            ; B4 = 7

;B0 = A0-4(A3+A2+A1)-20 ;-5...-200
;B1 = 6A2+2A1-138       ;-18...-138
;B2 = A3+2A2-46         ;-1...-46
;B3 = 4A3-64            ;-4...-64
;B4 = 7                 ;7
; At this point, the original number is
; equal to tenK*10000+thou*1000+hund*100+tens*10+ones
; if those entities are regarded as two's compliment
; binary.  To be precise, all of them are negative
; except tenK.  Now the number needs to be normal-
; ized, but this can all be done with simple byte
; arithmetic.

        movlw   .10                             ; W = 10
Lb1:            ;do
        decf    tens, F                         ; B1 -= 1
        addwf   ones, F                         ; B0 += 10
        btfss   STATUS, C
    ;skip no carry
        bra     Lb1                             ; while B0 < 0
    ;jmp carry

Lb2:            ;do
        decf    hund, F                         ; B2 -= 1
        addwf   tens, F                         ; B1 += 10
        btfss   STATUS, C
        bra     Lb2                             ; while B1 < 0

Lb3:            ;do
        decf    thou, F                         ; B3 -= 1
        addwf   hund, F                         ; B2 += 10
        btfss   STATUS, C
        bra     Lb3                             ; while B2 < 0

Lb4:            ;do
        decf    tenK, F                         ; B4 -= 1
        addwf   thou, F                         ; B3 += 10
        btfss   STATUS, C
        bra     Lb4                             ; while B3 < 0

        retlw   0
    endif

        END
