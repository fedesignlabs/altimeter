;************************************************************************
;                                                                       *
;   Filename:       timer.asm                                           *
;   Date:           September 12 2010                                   *
;   File Version:   1                                                   *
;       1   initial code                                Sep 12, 2010    *
;   Author:         Peter A Farkas                                      *
;   Company:        Farkas Engineering                                  *
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
;   Description:    control the sample timer                            *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "src\settings.inc"

        ; Global Functions
        GLOBAL      StartTimer
        GLOBAL      StopTimer
        GLOBAL      ResetTimer
        GLOBAL      ClearTimer

        ; Global Variables
        GLOBAL      time_B0
        GLOBAL      time_B1
        GLOBAL      time_B2
        GLOBAL      time_B3

;*******************************************************************
TMRVAR          udata_acs
time_B0         res 1                           ; timestamp byte 0
time_B1         res 1                           ; timestamp byte 1
time_B2         res 1                           ; timestamp byte 2
time_B3         res 1                           ; timestamp byte 3

;************************************************************************
TMRCODE     CODE

; ?
ClearTimer:
        bcf     T1CON, TMR1ON                       ; Stop Timer

        movlw   iTMRH                               ; Preload for 10ms overflow
        movwf   TMR1H
        movlw   iTMRL
        movwf   TMR1L

        clrf    time_B0
        clrf    time_B1
        clrf    time_B2
        clrf    time_B3

        return

ResetTimer:
        rcall   ClearTimer

        bsf     T1CON, TMR1ON                       ; Start Timer

        return

StopTimer:
        bcf     T1CON, TMR1ON                       ; Stop Timer

        return

StartTimer:
        bsf     T1CON, TMR1ON                       ; Start Timer

        return

        END
