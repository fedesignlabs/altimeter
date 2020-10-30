;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
;                                                                       *
;    Filename: main.asm                                                 *
;    Date: March 10, 2009                                               *
;    File Version: 2.0                                                  *
;       1   Initial Code                                May 06, 2010    *
;       2   post fc101 drop off                         Aug 16, 2010    *
;    Project: neutrino                                                  *
;    Author:  Peter Farkas                                              *
;                                                                       *
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
;                                                                       *
;    Files required:        processor.inc                               *
;                           config.inc                                  *
;                                                                       *
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
;
;   Purpose:
;
;   This application note...
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
;   Program Description:
;
;   This is a specialized datalogger used for rockets.  It captures sensor
;   data at a high rate and stores it into nonvolotile memory which can be retreaved later.
;   It also actuates a buzzer to help locate the rocket (after it detects that the rocket has landed, or during descent, or a time period after landing).
;   It also can control the lighting of igniters for the rocket engines.
;   It can also deploy the parachute using an acuator
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        #include    "include\processor.inc"     ; processor specific variable definitions
        #include    "config.inc"                ; microcontroller configiguration settings
        #include    "include\altitudeLut.inc"

        ; External
        ; setup
        EXTERN      MainSetup

        ; controller
        EXTERN      InitController

;******************************************************************************
;EEPROM data
; Data to be programmed into the Data EEPROM is defined here

EE_INIT ORG     0xf00000

        ; Initial option and atlitude bytes
    if DEFAULT_UNIT == METER
        DE      0x01, 0x00, 0x00, 0x00
    else
        DE      0x00, 0x00, 0x00, 0x00
    endif


;******************************************************************************
;Reset vector
; This code will start executing when a reset occurs.

RSTCODE ORG     0x0000                          ; Re-map Reset vector

        movlb   0x01                            ; set it for all non access ram variables 0x100 -> 0x1FF (BANKED variables)
        goto    boot

BOOTCODE    CODE
boot:
        call    MainSetup                       ; call setup
		goto    InitController                  ; jumps to main program

        END
