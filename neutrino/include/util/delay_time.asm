;************************************************************************
;                                                                       *
;   Filename:       delay.asm                                           *
;   Date:           May 20 2010                                         *
;   File Version:   4                                                   *
;       1   initial code                                May 20, 2010    *
;       2   migrating to timer1                         May 30, 2010    *
;       3   uses timer2, 1MHz clock                     Jul 21, 2010    *
;       4   overhauled to use time                      Sep 13, 2010    *
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
;   Description:                                                        *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "src\settings.inc"
        #include    "include\util\timer.inc"

        ; Global Functions
        GLOBAL      Delay

;*******************************************************************
DELAYVAR        udata_acs
tempTime        res 1


;************************************************************************
DELAYCODE       CODE

; Delay routine, will delay for 10ms x WREG
Delay:
        ; take the current time and add the requested delay
        addwf   time_B0, W
        movwf   tempTime

delay_wait:
        sleep

        ; check if time == tempTime
        movf    tempTime, W
        xorwf   time_B0, W
        btfss   STATUS, Z               ; skip if equal
        bra     delay_wait              ; loop until equal

        return


        END
