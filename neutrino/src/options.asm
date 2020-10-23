;************************************************************************
;                                                                       *
;   Filename:       fsm.asm                                             *
;   Date:           May 12 2010                                         *
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
;   Description:    Finite State Machine                                *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "settings.inc"
        #include    "options.inc"


        ; Global
        ; functions

        ; variables
        GLOBAL      options

;************************************************************************
OPTVAR          udata_acs

options         res 1                       ; Keeps track of what the upcoming read will want

;************************************************************************
OPTCODE         CODE

                END
