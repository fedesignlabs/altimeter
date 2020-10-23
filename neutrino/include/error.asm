;************************************************************************
;                                                                       *
;   Filename:       error.asm                                           *
;   Date:           Nov 28 2010                                         *
;   File Version:   1                                                   *
;       1   Initial Code                                Nov 28, 2010    *
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
;   Description:    This is a rudimentery error handling feature.       *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "src\settings.inc"
        #include    "include\util\delay_time.inc"

        GLOBAL      ErrorHandler

        GLOBAL      errorBCD0

        ; buzzer
        EXTERN      UnsignedBeepOut


;*VAR********************************************************************
ERRVARB     udata   0x130
errorBCD4   res 1                   ; binary coded decimal, ten thousands
errorBCD3   res 1                   ; binary coded decimal, thousands
errorBCD2   res 1                   ; binary coded decimal, hundreds
errorBCD1   res 1                   ; binary coded decimal, tens
errorBCD0   res 1                   ; binary coded decimal, ones
errorDigits res 1                   ; the number of digits to output

;*CODE*******************************************************************
ERRCODE     CODE

;************************************************************************
;   ErrorHandler - Error handler
;
;   Input: uint8 the number of digits in the error code.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: System is reset.
;
;   ??
;************************************************************************
ErrorHandler:
        ; save the number of digits
        movwf   errorDigits, BANKED

        ; put in device into a low power state, if possible

        movlw   DELAY_1000ms
        call    Delay

output_err_code:
        ; get altitude in bcd
        lfsr    FSR2, errorBCD0                 ; pointer to first digit
        movf    errorDigits, W, BANKED          ; number of digits

        call    UnsignedBeepOut

        movlw   DELAY_2500ms
        call    Delay

        movlw   DELAY_2500ms
        call    Delay

        btfsc   BUTTON_PORT, BUTTON_PIN
        bra     output_err_code

        ; debounce
;       rcall   Debounce
   movlw   DELAY_50ms
   call    Delay

        btfss   BUTTON_PORT, BUTTON_PIN
        bra     $ - 2

        ; debounce
;       rcall   Debounce
   movlw   DELAY_50ms
   call    Delay

        reset


;*END OF CODE************************************************************
        END
