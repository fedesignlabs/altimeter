; TODO: figure out how to best use header files.  Seperate globally accessible functions from internally used defines.
;********** Buzzer PWM signal setup **********
BZR_CCP             EQU 2

; TODO: make a seperate value for each Fosc, greater accuracy
; CCP module info:
;   PWM Period      = (PR2 + 1) * 4 * Tosc * Prescale
;       Pulse Width = (CCPRxL:DCxB<1:0>) * Tosc * Prescale

    if FOSC == FOSC_500KHZ || FOSC == FOSC_2MHZ || FOSC == FOSC_8MHZ
; 4kHz Signal ~ 4.032kHz, 248us
;   Duty Cycle = 15.5, Period = 31
PWM_4KHZ_CCPnCON    EQU b'00101100'     ; 2 lsb of duty cycle = 10 (5:4), pwm mode 11xx (3:0)
PWM_4KHZ_CCPRnL     EQU .15             ; (15 + 1) * Tosc * 4 * 2
PWM_4KHZ_PR2        EQU .30             ; (30 + 1) * Tosc * 4

; 2kHz Signal ~ 1.374kHz, 728us
;   Duty Cycle = 45.5, Period = 91
PWM_2KHZ_CCPnCON    EQU b'00101100'     ; 2 lsb of duty cycle = 10 (5:4), pwm mode 11xx (3:0)
PWM_2KHZ_CCPRnL     EQU .45             ; (? + 1) * Tosc * 4 * 2
PWM_2KHZ_PR2        EQU .90             ; (? + 1) * Tosc * 4
    endif

    if FOSC == FOSC_1MHZ || FOSC == FOSC_4MHZ || FOSC == FOSC_16MHZ
; 4kHz Signal ~ 3.968kHz, 252us
;   Duty Cycle = 31.5, Period = 63
PWM_4KHZ_CCPnCON    EQU b'00101100'     ; 2 lsb of duty cycle = 10 (5:4), pwm mode 11xx (3:0)
PWM_4KHZ_CCPRnL     EQU .31             ; (15 + 1) * Tosc * 4 * 2
PWM_4KHZ_PR2        EQU .62             ; (30 + 1) * Tosc * 4

; 2kHz Signal ~ 1.366kHz, 732us
;   Duty Cycle = 91.5, Period = 183
PWM_2KHZ_CCPnCON    EQU b'00101100'     ; 2 lsb of duty cycle = 10 (5:4), pwm mode 11xx (3:0)
PWM_2KHZ_CCPRnL     EQU .91             ; (45 + 1) * Tosc * 4 * 2
PWM_2KHZ_PR2        EQU .182            ; (90 + 1) * Tosc * 4
    endif

    if  BZR_CCP == 1
CCPnCON             EQU CCP1CON
CCPRnL              EQU CCPR1L
    endif

    if  BZR_CCP == 2
CCPnCON             EQU CCP2CON
CCPRnL              EQU CCPR2L
    endif
