;************************************************************************
;                                                                       *
;   Filename:       buzzer_PKLCS1212E4001.asm                           *
;   Date:           Nov 13 2010                                         *
;   File Version:   3                                                   *
;       1   initial code                                Jun 01, 2010    *
;       2   specific to 18F2xK20                        Nov 08, 2010    *
;       3   cleaned up                                                  *
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
;   Description:    interface to the on board buzzer                    *
;                                                                       *
;                                                                       *
;************************************************************************
;                                                                       *
;   ToDo:           Consider changing short buzzer on time to 20ms      *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "src\settings.inc"
        #include    "include\util\delay_time.inc"
        #include    "include\actuator\buzzer_PKLCS1212E4001.inc"

        GLOBAL      ExtraLongBeep
        GLOBAL      LongBeep
        GLOBAL      ShortBeep

        GLOBAL      ActivateBuzzer4kHz
        GLOBAL      ActivateBuzzer2kHz
        GLOBAL      DeactivateBuzzer

        GLOBAL      SignedBeepOut
        GLOBAL      UnsignedBeepOut

;*******************************************************************
BZVAR           access_ovr
value           res 1
count           res 1
freq            res 1

;*******************************************************************
BZCODE          CODE

;************************************************************************
;   ExtraLongBeep - Beep the buzzer for an extra long duration
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   Beep the buzzer for 1250ms at sound frequency of 2kHz.  Then delay
;   100ms before returning.
;************************************************************************
ExtraLongBeep:
        ; beep the buzzer for a long duration (1250ms, 2Hz) at 2kHz
        movlw   .250                        ; constant = (duration x buzzer period) / postscale
        movwf   freq                        ; 250 = (1.25s * 2kHz) / 10

        rcall   ActivateBuzzer2kHz

xlong_beep_wait:
        ; Poll timer2 flag
        btfss   PIR1, TMR2IF                ; Poll TMR2 interrupt flag
        bra     xlong_beep_wait

        bcf     PIR1, TMR2IF                ; Clear TMR2 interrupt flag

        decfsz  freq, F
        bra     xlong_beep_wait

        rcall   DeactivateBuzzer

        movlw   DELAY_100ms
        call    Delay                       ; short delay, before next beep

        return


;************************************************************************
;   LongBeep - Beep the buzzer for a long duration
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   Beep the buzzer for 500ms at sound frequency of 2kHz.  Then delay
;   100ms before returning.
;************************************************************************
LongBeep:
        ; beep the buzzer for a long duration (500ms, 2Hz) at 2kHz
        movlw   .100                        ; constant = (duration x buzzer period) / postscale
        movwf   freq                        ; 100 = (0.5s * 2kHz) / 10

        rcall   ActivateBuzzer2kHz

long_beep_wait:
        ; Poll timer2 flag
        btfss   PIR1, TMR2IF                ; Poll TMR2 interrupt flag
        bra     long_beep_wait

        bcf     PIR1, TMR2IF                ; Clear TMR2 interrupt flag

        decfsz  freq, F
        bra     long_beep_wait

        rcall   DeactivateBuzzer

        movlw   DELAY_100ms
        call    Delay                       ; short delay, before next beep

        return


;************************************************************************
;   ShortBeep - Beep the buzzer for a short duration
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   Beep the buzzer for 40ms at sound frequency of 2kHz.  Then delay
;   100ms before returning.
;************************************************************************
ShortBeep:
        ; beep the buzzer for a short duration (40ms, 25Hz) at 2kHz
        movlw   .8                          ; constant = (duration x buzzer period) / postscale
        movwf   freq                        ; 8 = (0.04s * 2kHz) / 10

        rcall   ActivateBuzzer2kHz

short_beep_wait:
        ; Poll timer2 flag
        btfss   PIR1, TMR2IF                ; Poll TMR2 interrupt flag
        bra     short_beep_wait

        bcf     PIR1, TMR2IF                ; Clear TMR2 interrupt flag

        decfsz  freq, F
        bra     short_beep_wait

        rcall   DeactivateBuzzer

        movlw   DELAY_100ms
        call    Delay                       ; short delay, before next beep

        return


;************************************************************************
;   ActivateBuzzer4kHz - Activate the buzzer at 4kHz
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   ??
;************************************************************************
ActivateBuzzer4kHz:
        ; Disable the PWM output
        bsf     BUZZER_TRIS, BUZZER_PIN

        ; enable the ccp module for pwm mode
        movlw   PWM_4KHZ_CCPnCON                    ; 2 lsb of duty cycle, pwm mode 11xx
        movwf   CCPnCON

        ; setup duty cycle
        movlw   PWM_4KHZ_CCPRnL
        movwf   CCPRnL

        ; Configure and start timer2
    if FOSC == FOSC_8MHZ || FOSC == FOSC_16MHZ
        movlw   b'01010010'                         ; x10 postscale, x16 prescale, off
    endif
    if FOSC == FOSC_2MHZ || FOSC == FOSC_4MHZ
        movlw   b'01010001'                         ; x10 postscale, x4 prescale, off
    endif
    if FOSC == FOSC_500KHZ || FOSC == FOSC_1MHZ
        movlw   b'01010000'                         ; x10 postscale, x1 prescale, off
    endif
        movwf   T2CON

        movlw   PWM_4KHZ_PR2                        ; Set PR2 register
        movwf   PR2                                 ; Flag set on TMR2 - PR2 match
        clrf    TMR2

        bcf     PIR1, TMR2IF                        ; Clear TMR2 interrupt flag

        ;  Enable timer2
        bsf     T2CON, TMR2ON                       ; turn on timer2

        ; Enable the PWM output
        bcf     BUZZER_TRIS, BUZZER_PIN

        return


;************************************************************************
;   ActivateBuzzer2kHz - Activate the buzzer at 2kHz
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   ??
;************************************************************************
ActivateBuzzer2kHz:
        ; Disable the PWM output
        bsf     BUZZER_TRIS, BUZZER_PIN

        ; enable the ccp module for pwm mode
        movlw   PWM_2KHZ_CCPnCON                    ; 2 lsb of duty cycle, pwm mode 11xx
        movwf   CCPnCON

        ; setup duty cycle
        movlw   PWM_2KHZ_CCPRnL
        movwf   CCPRnL

        ; Configure and start timer2
    if FOSC == FOSC_8MHZ || FOSC == FOSC_16MHZ
        movlw   b'01010010'                         ; x10 postscale, x16 prescale, off
    endif
    if FOSC == FOSC_2MHZ || FOSC == FOSC_4MHZ
        movlw   b'01010001'                         ; x10 postscale, x4 prescale, off
    endif
    if FOSC == FOSC_500KHZ || FOSC == FOSC_1MHZ
        movlw   b'01010000'                         ; x10 postscale, x1 prescale, off
    endif
        movwf   T2CON

        movlw   PWM_2KHZ_PR2                        ; Set PR2 register
        movwf   PR2                                 ; Flag set on TMR2 - PR2 match
        clrf    TMR2

        bcf     PIR1, TMR2IF                        ; Clear TMR2 interrupt flag

        ;  Enable timer2
        bsf     T2CON, TMR2ON                       ; turn on timer2

        ; Enable the PWM output
        bcf     BUZZER_TRIS, BUZZER_PIN

        return


;************************************************************************
;   DeactivateBuzzer - Deactivate the buzzer
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: Timer2 is off.  CCP is disabled.
;
;   Turns off the buzzer.
;************************************************************************
DeactivateBuzzer:
        bcf     T2CON, TMR2ON                       ; turn off timer2
        clrf    CCPnCON                             ; disable ccp module
        bcf     BUZZER_LATCH, BUZZER_PIN            ; set buzzer output to 0, if high it will wearout the buzzer

        return


;void BeepOut(byte *data, byte size) {
;    for(int i = 0; i < size; i++) {
;        if(*(data+i) == 0) {
;            ShortBeep();
;        } else {
;            SendValue();
;        }
;    }
;}

;************************************************************************
;   SignedBeepOut - Beep out a signed value
;
;   Input: (W) byte count - the number of digits to beep out.
;
;   Output: None.
;
;   Precondition: FSR2 points to the bcd digits to output.
;
;   Postcondition: None.
;
;   ??
;************************************************************************
SignedBeepOut:
        ; intitailize index
        incf    WREG, F                             ; add 1 to input value
        movwf   count

        ; check sign
        btfss   POSTINC2, 0                         ; look at the sign
        bra     beep1                               ; positive number, so nothing to handle

        ; negative number
        rcall   ExtraLongBeep                       ; indicate that is is negative with an extra long beep

        bra     beep1


;************************************************************************
;   UnsignedBeepOut - Beep out an unsigned value
;
;   Input: (W) byte count - the number of digits to beep out.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   ??
;************************************************************************
UnsignedBeepOut:
        ; intitailize index
        incf    WREG, F                             ; add 1 to input value
        movwf   count

beep1:
        movlw   DELAY_500ms
        call    Delay

        bra     send_wo_delay

send_next:
        ; delay between values
        movlw   DELAY_1500ms
        call    Delay

send_wo_delay:
        movff   POSTINC2, value

        dcfsnz  count, F
        return

        ; beep out bcd values
        tstfsz  value
        bra     sendValue
        bra     sendZero


sendValue:
        ; send value
sv_1
        rcall   LongBeep


        decfsz  value, F
        bra     sv_1

        bra     send_next


sendZero:
        rcall   ShortBeep

        bra     send_next

        END
