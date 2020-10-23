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
;   Description:    This is a ??        *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "src\settings.inc"
        #include    "include\typedef.inc"
        #include    "include\util\delay_short.inc"

        GLOBAL      CheckButton
        GLOBAL      Debounce


;*CODE*******************************************************************
BTTNCODE     CODE

;************************************************************************
;   CheckButton - Check state of the button
;
;   Input: None.
;
;   Output: bool, 0-not pressed, 1-pressed.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   ??
;************************************************************************
CheckButton:
        ; if ( !PRESSED ) {
        ;   return (0);
        ; } else {
        ;   Debounce();
        ;   return (1);
        ; }

        btfsc   BUTTON_PORT, BUTTON_PIN
        retlw   FALSE

        ; debounce button press
        rcall   Debounce

        retlw   TRUE


;************************************************************************
;   Debounce - Debounce the button event
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   Wait 6ms for the signal to stabilize.
;************************************************************************
Debounce:
        ; wait around 6ms for the button input to stabilize
        movlw   DELAY_6144us
        call    DelayShort

        return

        END
