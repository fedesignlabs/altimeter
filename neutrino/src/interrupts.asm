;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
;                                                                       *
;    Filename: interrupts.asm                                           *
;    Date: August 17, 2010                                              *
;    File Version: 1.0                                                  *
;       1   Initial Code                                Aug 17, 2010    *
;    Project: Flight Computer 10X                                       *
;    Author:  Peter Farkas                                              *
;    Company: Farkas Engineering                                        *
;                                                                       *
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
;                                                                       *
;    Files required:        processor.inc                               *
;                           settings.inc                                *
;                                                                       *
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

        #include    "include\processor.inc"             ; processor specific variable definitions
        #include    "settings.inc"              ; contains configurations
        #include    "include\util\timer.inc"

;******************************************************************************
ISRCODE         CODE    0x8

;******************************************************************************
; Interrupt vector
; This code will start executing when an interrupt occurs.
;******************************************************************************
InterruptVector:

        ; if timer1 interrupt
        btfsc   PIR1, TMR1IF                    ; Check for timer1 overflow
        bra     tmr1_isr                        ; if TMR1IF is set, run timer1 isr

        ; if I2C interrupt
        btfsc   PIR1, SSPIF                     ; test for SSPIF i2c interrupt flag
        bra     i2c_isr                         ; if SSPIF is set, run i2c isr

        ; if port b interrupt
        btfsc   INTCON, RBIF                    ; Check for port b change
        bra     rb_isr                          ; if RBIF is set, run port b isr

        ; if timer0 interrupt
        btfsc   INTCON, TMR0IF                  ; Check for timer0 overflow
        bra     tmr0_isr                        ; if TMR0IF is set, run timer0 isr

        retfie  FAST                            ; exit isr


;****TMR0*********************************************************
tmr0_isr:
        bcf     INTCON, TMR0IF                  ; Clear interrupt flag
        bcf     T0CON, TMR0ON                   ; Stop Timer0

        retfie  FAST

;****TMR1*********************************************************
tmr1_isr:
        movlw   iTMRH                           ; Preload for 10ms overflow
        movwf   TMR1H                           ;
        movlw   iTMRL                           ;
        movwf   TMR1L

        bcf     PIR1, TMR1IF                    ; Clear interrupt flag

        ; Increment Time bytes
        incfsz  time_B0, F                      ; Increment Time Stamp byte0
        bra     tmr1_updated                    ; exit if no rollover   (0xXXXXXXFF -> 0xXXXXXX00)

        incfsz  time_B1, F                      ; Increment Time Stamp byte1
        bra     tmr1_updated                    ; exit if no rollover   (0xXXXXFFFF -> 0xXXXX0000)

        incfsz  time_B2, F                      ; Increment Time Stamp byte2
        bra     tmr1_updated                    ; exit if no rollover   (0xXXFFFFFF -> 0xXX000000)

        incf    time_B3, F                      ; Increment Time Stamp byte2

tmr1_updated:

        retfie  FAST

;****I2C*********************************************************
i2c_isr:
        bcf     PIR1, SSPIF                 ; Clear SSP interrupt flag

        retfie  FAST

;****RB***********************************************************
rb_isr:
        movf    PORTB, W

        bcf     INTCON, RBIF                    ; Clear interrupt flag

        retfie  FAST

;*****************************************************************

        END
