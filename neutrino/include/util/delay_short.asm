;************************************************************************
;                                                                       *
;   Filename:       delay_short.asm                                     *
;   Date:           Nov 14 2010                                         *
;   File Version:   1                                                   *
;       1   initial code                                Nov 14, 2010    *
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
;   Description:   Uses timer0 to generate short delays, less than 10ms *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "src\settings.inc"

        ; Global Functions
        GLOBAL      DelayShort

;*******************************************************************
DELAY_SHORT_VAR        udata_acs
tempTime        res 1


;************************************************************************
DELAYSCODE      CODE

; Delay routine, will delay for 64us x WREG
DelayShort:
        movwf   TMR0L                       ; setup delay time

        bsf     T0CON, TMR0ON               ; start timer

ds_idle:
        sleep                               ; switch to idle mode until timer0 overflows
        nop                                 ; probably needed due to timer read after wake up
        btfsc   T0CON, TMR0ON               ; check if timer still running
        bra     ds_idle

        return


        END
