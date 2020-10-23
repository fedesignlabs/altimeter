;************************************************************************
;                                                                       *
;   Filename:       settings_fsm.asm                                    *
;   Date:           Nov 18 2010                                         *
;   File Version:   1                                                   *
;                                                                       *
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
;   Description:    Settings Finite State Machine                       *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "settings.inc"
        #include    "include\util\timer.inc"
        #include    "include\util\delay_time.inc"
        #include    "include\util\delay_short.inc"

        GLOBAL      SettingsFsm

;******************************************************************************
;Bit Definitions for state flag

STATE_PRESSED       EQU     .0
STATE_START         EQU     .1
STATE_SETTING1      EQU     .2
STATE_SETTING2      EQU     .3


;************************************************************************
SFSMVAR             udata_acs
    ; common
state               res 1                       ; Keeps track of what the upcoming read will want

;************************************************************************
SFSMCODE            CODE

;*******************************************************************
;   Initialize FiniteStateMachine
;
;   Description: Sets initial state to idle
;
;*******************************************************************
SettingsFsm:
        movlw   STATE_PRESSED
        movwf   state

            ;DBG:
            return
    ;   bra     StateMachine


        END
