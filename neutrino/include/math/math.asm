;************************************************************************
;                                                                       *
;   Filename:       math.asm                                            *
;   Date:           May 19 2010                                         *
;   File Version:   0.2                                                 *
;       0.1 initial code                                May 17, 2010    *
;       0.2 added conditional output, overflow          May 19, 2010    *
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
;   Description:    various mathematical operations                     *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "src\buildOptions.inc"

    if ADD32_EN == 1 || SUB32_EN == 1
        GLOBAL      ACa3
        GLOBAL      ACa2
    endif
        GLOBAL      ACa1
        GLOBAL      ACa0

    if ADD32_EN == 1 || SUB32_EN == 1
        GLOBAL      ACb3
        GLOBAL      ACb2
    endif
        GLOBAL      ACb1
        GLOBAL      ACb0

    if ADD32_EN == 1 || SUB32_EN == 1
        GLOBAL      Q_sub
        GLOBAL      Q_add
    endif

        GLOBAL      CompareU16

        GLOBAL      Mul24x16
        GLOBAL      MulU24x16

    if MUL16_EN == 1
        GLOBAL      Mul16
    endif
    if MULU16_EN == 1
        GLOBAL      MulU16
    endif

        GLOBAL      arg2H
        GLOBAL      arg2L
        GLOBAL      arg1U
        GLOBAL      arg1H
        GLOBAL      arg1L

        GLOBAL      res4
        GLOBAL      res3
        GLOBAL      res2
        GLOBAL      res1
        GLOBAL      res0

;******************************************************************************
MATHVAR     udata_acs
    if ADD32_EN == 1 || SUB32_EN == 1
ACa3        res 1       ; 32-bit Accumulator a, lsb+3, ms-byte
ACa2        res 1       ; 32-bit Accumulator a, lsb+2
    endif
ACa1        res 1       ; 32-bit Accumulator a, lsb+1
ACa0        res 1       ; 32-bit Accumulator a, ls-byte

    if ADD32_EN == 1 || SUB32_EN == 1
ACb3        res 1       ; 32-bit Accumulator b, lsb+3, ms-byte
ACb2        res 1       ; 32-bit Accumulator b, lsb+2
    endif
ACb1        res 1       ; 32-bit Accumulator b, lsb+1
ACb0        res 1       ; 32-bit Accumulator b, ls-byte

; 16bit Multiplication arguments and result
arg2H       res 1
arg2L       res 1
arg1U       res 1
arg1H       res 1
arg1L       res 1

res4        res 1
res3        res 1
res2        res 1
res1        res 1
res0        res 1

;******************************************************************************
MATHCODE    CODE

;******************************************************************************
;*****       Subroutines.

    if ADD32_EN == 1 || SUB32_EN == 1
;******************************************************************************
;
; Quadruple Precision (32-bit) Addition & Subtraction, adapted from AN526.
; ACa? and ACb? are each four-byte (32-bit) binary accumulators.
; ACa3 and ACb3 are the MS-Bytes, ACa0 and ACb0 are the LS-Bytes.
; Addition (Q_add):    (ACb)+(ACa) --> (ACb), (ACa) is unchanged
; Subtraction (Q_sub): (ACb)-(ACa) --> (ACb), (ACa) is negated
;
Q_sub:
        rcall   neg_ACa         ; First negate ACa, then add
Q_add:
        movf    ACa0,w
        addwf   ACb0,f          ; Add lsb
        btfss   STATUS,C        ; Test for carry
        bra     q_2             ;  go if no carry
        incf    ACb1,f          ; Add carry to lsb+1
        btfss   STATUS,Z        ; Test for carry ripple (FF --> 00)
        bra     q_2             ;  and go if no carry
        incf    ACb2,f          ; Add carry to lsb+2
        btfsc   STATUS,Z        ; Test for carry ripple
        incf    ACb3,f          ;  add carry to lsb+3, msb
q_2:
        movf    ACa1,w
        addwf   ACb1,f          ; Add lsb+1
        btfss   STATUS,C        ; Test for carry
        bra     q_4             ;  go if no carry
        incf    ACb2,f          ; Add carry to lsb+2
        btfsc   STATUS,Z        ; Test for carry ripple
        incf    ACb3, F         ;  add carry to lsb+3, msb
q_4:
        movf    ACa2, W
        addwf   ACb2, F         ; Add lsb+2
        btfsc   STATUS, C       ; Test for carry
        incf    ACb3, F         ;  add carry to lsb+3, msb
        movf    ACa3, W
        addwf   ACb3, F         ; Add msb
        btfsc   STATUS, C       ; Test for carry
        retlw   .1              ; send w = 1 incase of overflow
        retlw   .0


neg_ACa:
        comf    ACa0, F         ; complement (ACa)
        comf    ACa1, F
        comf    ACa2, F
        comf    ACa3, F
        incf    ACa0, F         ; add one
        btfss   STATUS, Z
        retlw   0
        incf    ACa1, F
        btfss   STATUS, Z
        retlw   0
        incf    ACa2, F
        btfss   STATUS, Z
        retlw   0
        incf    ACa3, F
        retlw   0
    endif

    if ADD16_EN == 1
;----------------------------
; 16-bit addition
;       SourceH:SourceL - Number to be subtracted
;       Carry - NOT( Borrow to be subtracted )
;       DestH:DestL - Number to be subtracted FROM
;Out    DestH:DestL - Result
;       Carry - NOT( Borrow result)
Add16:

        movf    ACa0, W
        addwf   res1, F

        movf    ACa1, W
        addwfc  res2, F

        return
    endif

    if SUB16_EN == 1
;----------------------------
; 16-bit subtraction-with-Borrow
;       SourceH:SourceL - Number to be subtracted
;       Carry - NOT( Borrow to be subtracted )
;       DestH:DestL - Number to be subtracted FROM
;Out    DestH:DestL - Result
;       Carry - NOT( Borrow result)
;       b = b - a, WITH VALID CARRY
; (although the Z flag is not valid).
Sub16:

        movf    ACa0, W
        subwf   ACb0, F
        movf    ACa1, W
        subfwb  ACb1                ; F - W - nC


        return
    endif

; *** Compare 16bit

CompareU16:
    movf    ACa1, W
    subwf   ACb1, W         ; subtract b-a

    ; Are they equal ?
    btfss   STATUS, Z
    bra     results16       ; not equal

    ; yes, they are equal -- compare lo
    movf    ACa0, W
    subwf   ACb0, W         ; subtract b-a

    btfsc   STATUS, Z
    retlw   0x00            ; return, a == b

results16:
    ; if a=b then now Z=1.
    ; if b<a then now C=0.
    ; if a<=b then now C=1.

    btfss   STATUS, C
    retlw   0xFF            ; return, a > b
    retlw   0x01            ; return, a < b


MulU24x24:
;res4:res0  =   arg1U:arg1H:arg1L • arg2U:arg2H:arg2L
;           =   (arg1U • arg2U • 2^32) +
;               (arg1U • arg2H • 2^24) +
;               (arg1U • arg2L • 2^16) +
;               (arg1H • arg2U • 2^24) +
;               (arg1H • arg2H • 2^16) +
;               (arg1H • arg2L • 2^8) +
;               (arg1L • arg2U • 2^16) +
;               (arg1L • arg2H • 2^8) +
;               (arg1L • arg2L)

MulU24x16:

;res4:res0  =   arg1U:arg1H:arg1L • arg2H:arg2L
;           =   (arg1U • arg2H • 2^24) +
;               (arg1U • arg2L • 2^16) +
;               (arg1H • arg2H • 2^16) +
;               (arg1H • arg2L • 2^8) +
;               (arg1L • arg2H • 2^8) +
;               (arg1L • arg2L)
        clrf    res4                        ; initialize res4

        call    MulU16

        movf    arg1U, W
        mulwf   arg2L                       ; arg1U * arg2L-> PRODH:PRODL

        movf    PRODL, W                    ;
        addwf   res2, F                     ; Add cross
        movf    PRODH, W                    ; products
        addwfc  res3, F                     ;
        clrf    WREG                        ;
        addwfc  res4, F                     ;

        movf    arg1U, W
        mulwf   arg2H                       ; arg1U * arg2H-> PRODH:PRODL

        movf    PRODL, W                    ;
        addwf   res3, F                     ; Add cross
        movf    PRODH, W                    ; products
        addwfc  res4, F                     ;
;       clrf    WREG                        ;
;       addwfc  res5, F                     ;

        return

    if MUL16_EN == 1 || MULU16_EN == 1
; 16 bit unsigned multiplication
; 28 cycles

MulU16:

;res3:res0  =   arg1H:arg1L • arg2H:arg2L
;           =   (arg1H • arg2H • 2^16) +
;               (arg1H • arg2L • 2^8) +
;               (arg1L • arg2H • 2^8) +
;               (arg1L • arg2L)

        movf    arg1L, W
        mulwf   arg2L                       ; arg1L * arg2L-> PRODH:PRODL

        movff   PRODH, res1                 ;
        movff   PRODL, res0                 ;

        movf    arg1H, W
        mulwf   arg2H                       ; arg1H * arg2H-> PRODH:PRODL
        movff   PRODH, res3 ;
        movff   PRODL, res2 ;

        movf    arg1L, W
        mulwf   arg2H                       ; arg1L * arg2H-> PRODH:PRODL

        movf    PRODL, W                    ;
        addwf   res1, F                     ; Add cross
        movf    PRODH, W                    ; products
        addwfc  res2, F                     ;
        clrf    WREG                        ;
        addwfc  res3, F                     ;

        movf    arg1H, W                    ;
        mulwf   arg2L                       ; arg1H * arg2L-> PRODH:PRODL

        movf    PRODL, W                    ;
        addwf   res1, F                     ; Add cross
        movf    PRODH, W                    ; products
        addwfc  res2, F                     ;
        clrf    WREG                        ;
        addwfc  res3, F                     ;

        return
    endif

    if MUL16_EN == 1
; 16 bit signed multiplication
; 40 cycles

Mul16:

;res3:res0  =   arg1H:arg1L • arg2H:arg2L
;           =   (arg1H • arg2H • 2^16) +
;               (arg1H • arg2L • 2^8) +
;               (arg1L • arg2H • 2^8) +
;               (arg1L • arg2L) +
;               (-1 • arg2H<7> • arg1H:arg1L • 2^16) +
;               (-1 • arg1H<7> • arg2H:arg2L • 2^16)

        call    MulU16

sign_arg1:
        btfss   arg1H, 7                    ; arg1H:arg1L neg?
        bra     sign_arg2                   ; no, move on
        movf    arg2L, W                    ;
        subwf   res2                        ;
        movf    arg2H, W                    ;
        subwfb  res3                        ;

sign_arg2:
        btfss   arg2H, 7                    ; arg1H:arg1L neg?
        return                              ; no, done
        movf    arg1L, W                    ;
        subwf   res2                        ;
        movf    arg1H, W                    ;
        subwfb  res3                        ;

        return
    endif


Mul24x16:

;res3:res0  =   arg1H:arg1L • arg2H:arg2L
;           =   (arg1H • arg2H • 2^16) +
;               (arg1H • arg2L • 2^8) +
;               (arg1L • arg2H • 2^8) +
;               (arg1L • arg2L) +
;               (-1 • arg2H<7> • arg1U:arg1H:arg1L • 2^16) +
;               (-1 • arg1U<7> • arg2H:arg2L • 2^24)

        call    MulU24x16

tsign_arg1:
        btfss   arg1U, 7                    ; arg1H:arg1L neg?
        bra     tsign_arg2                   ; no, move on
        movf    arg2L, W                    ;
        subwf   res3                        ;
        movf    arg2H, W                    ;
        subwfb  res4                        ;

tsign_arg2:
        btfss   arg2H, 7                    ; arg1H:arg1L neg?
        return                              ; no, done
        movf    arg1L, W                    ;
        subwf   res2                        ;
        movf    arg1H, W                    ;
        subwfb  res3                        ;
        movf    arg1U, W                    ;
        subwfb  res4                        ;

        return

    END
