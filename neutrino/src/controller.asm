        #include    "include\processor.inc"
        #include    "include\button.inc"
        #include    "include\util\timer.inc"
        #include    "include\util\delay_time.inc"
        #include    "include\actuator\buzzer.inc"
        #include    "include\eeprom.inc"
        #include    "src\altimeter.inc"
        #include    "options.inc"

        ; Global
        ; functions
        GLOBAL      InitController

        ; variables
        GLOBAL      options

        EXTERN      ButtonPressed
        EXTERN      TransToIdle

;************************************************************************
OPTVAR              udata_acs
options             res 1                       ; Keeps track of what the upcoming read will want
buttonDuration      res 1                       ; keeps track of button press duration

;CONTROLLER_OVR      access_ovr
oldOptions          res 1

CONTROLLER_CODE        CODE

InitController:
        ; enable idle mode to keep timer running.
        call    ResetTimer
        bsf     OSCCON, IDLEN                       ; IDLE mode on sleep, to keep timer running

        movff   options, oldOptions

        ; check if button is pressed, if so handle Unit Selection
        call    CheckButton
        btfss   WREG, 0
        rcall   UnitSelect

        ; button was not pressed
        goto    TransToIdle

;************************************************************************
;   static UnitSelect
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: Unit option and EEPROM updated to match user selection.
;
;************************************************************************
UnitSelect:
        movlw   DELAY_2000ms
        call    Delay

        ; button is pressed, get a selection from the user
        movlw   .3
        call    ButtonPressed
        movwf   buttonDuration

        movlw   DELAY_500ms
        call    Delay

        ; jump to selection handler
        movlw   0x00                                ; no change
        cpfsgt  buttonDuration
        bra     us_option_0

        movlw   0x01                                ; feet
        cpfsgt  buttonDuration
        bra     us_option_1

        movlw   0x02                                ; meters
        cpfsgt  buttonDuration
        bra     us_option_2

us_option_0:
        ; didn't hold down long enough to make a selection
        return

us_option_1:
        ; set units to feet
        bcf     options, OP_METRIC

        ; beep to notify setup complete
        call    ShortBeep
        call    ShortBeep
        call    ShortBeep

        bra     us_update

us_option_2:
        ; set units to meters
        bsf     options, OP_METRIC

        ; beep to notify setup complete
        call    LongBeep
        call    LongBeep
        call    LongBeep

us_update:
        ; redo conversion to make sure right output is used
        call    ConvertAltitudeToBCD

        ; only write to non volatile memory if options have changed
        movf    options, W
        cpfseq  oldOptions
        bra     us_nvm
        return

us_nvm:
        clrf    EEADR                       ; set address to 0x00
        movff   options, EEDATA             ; set data to write

        movlw   b'00000100'                 ; Point to DATA memory, Access EEPROM, Enable writes
        movwf   EECON1

        call    EepromWrite

        return

        END