;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
;                                                                       *
;    Filename: setup.asm                                                *
;    Date: August 17, 2010                                              *
;    File Version: 1                                                    *
;       1   Initial Code                                Aug 17, 2010    *
;       2   I2C sensor, 23K20                           Sep 13, 2010    *
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
        #include    "options.inc"
        #include    "include\util\timer.inc"
        #include    "include\sensor\mpl115a2.inc"

        GLOBAL      MainSetup

        ; External
        ; options
        ;  variables
        EXTERN      options

        ; fsm
        ;  functions
        EXTERN      StateMachine
        EXTERN      InitFsm
        EXTERN      StateUnitSelect

        ; altimeter
        ;  functions
        EXTERN      RetrieveMaxAltitude

        ; DBG:
        ; settings_fsm
        EXTERN      SettingsFsm

;******************************************************************************
SETUPCODE   CODE

MainSetup:
; *********************** Hardware Setup **************************************
; Setup Clock
        ; 16MHz
    if FOSC == FOSC_16MHZ
        bsf     OSCCON, IRCF2                   ; OSCCON: x111xxxx
        bsf     OSCCON, IRCF1                   ; 001: 250 kHz, 010: 500 kHz, 011:   1 MHz, 100:   2 MHz
        bsf     OSCCON, IRCF0                   ; 101:   4 MHz, 110:   8 MHz, 111:  16 MHz
    endif
        ; 8MHz
    if FOSC == FOSC_8MHZ
        bsf     OSCCON, IRCF2                   ; OSCCON: x111xxxx
        bsf     OSCCON, IRCF1                   ; 001: 250 kHz, 010: 500 kHz, 011:   1 MHz, 100:   2 MHz
        bcf     OSCCON, IRCF0                   ; 101:   4 MHz, 110:   8 MHz, 111:  16 MHz
    endif
        ; 4MHz
    if FOSC == FOSC_4MHZ
        bsf     OSCCON, IRCF2                   ; OSCCON: x111xxxx
        bcf     OSCCON, IRCF1                   ; 001: 250 kHz, 010: 500 kHz, 011:   1 MHz, 100:   2 MHz
        bsf     OSCCON, IRCF0                   ; 101:   4 MHz, 110:   8 MHz, 111:  16 MHz
    endif
        ; 2MHz
    if FOSC == FOSC_2MHZ
        bsf     OSCCON, IRCF2                   ; OSCCON: x111xxxx
        bcf     OSCCON, IRCF1                   ; 001: 250 kHz, 010: 500 kHz, 011:   1 MHz, 100:   2 MHz
        bcf     OSCCON, IRCF0                   ; 101:   4 MHz, 110:   8 MHz, 111:  16 MHz
    endif
        ; 1MHz
    if FOSC == FOSC_1MHZ
        bcf     OSCCON, IRCF2                   ; OSCCON: x111xxxx
        bsf     OSCCON, IRCF1                   ; 001: 250 kHz, 010: 500 kHz, 011:   1 MHz, 100:   2 MHz
        bsf     OSCCON, IRCF0                   ; 101:   4 MHz, 110:   8 MHz, 111:  16 MHz
    endif
        ; 500KHz
    if FOSC == FOSC_500KHZ
        bcf     OSCCON, IRCF2                   ; OSCCON: x111xxxx
        bsf     OSCCON, IRCF1                   ; 001: 250 kHz, 010: 500 kHz, 011:   1 MHz, 100:   2 MHz
        bcf     OSCCON, IRCF0                   ; 101:   4 MHz, 110:   8 MHz, 111:  16 MHz
    endif

        ;bcf    OSCCON, IDLEN                   ; IDLE mode on sleep, disabled
        bsf     OSCCON, IDLEN                   ; IDLE mode on sleep, to keep timer running

        bcf     OSCTUNE, PLLEN                  ; PLL enabled bit for 32 and 64 MHz, DISABLED

; *****************************************************************************
; Setup Timer: TIMER0
;  Used for sub 10ms idles

    ; Initialize T0CON, 8 bit and 64us resolution (10ms is 156.25 cycles)
        ; 16MHz
    if FOSC == FOSC_16MHZ
        movlw   b'01000111'                     ; Stop Timer, 8bit, 256x prescaler
    endif
        ; 8MHz
    if FOSC == FOSC_8MHZ
        movlw   b'01000110'                     ; Stop Timer, 8bit, 128x prescaler
    endif
        ; 4MHz
    if FOSC == FOSC_4MHZ
        movlw   b'01000101'                     ; Stop Timer, 8bit, 64x prescaler
    endif
        ; 2MHz
    if FOSC == FOSC_2MHZ
        movlw   b'01000100'                     ; Stop Timer, 8bit, 32x prescaler
    endif
        ; 1MHz
    if FOSC == FOSC_1MHZ
        movlw   b'01000011'                     ; Stop Timer, 8bit, 16x prescaler
    endif
        ; 500KHz
    if FOSC == FOSC_500KHZ
        movlw   b'01000010'                     ; Stop Timer, 8bit, 8x prescaler
    endif

        movwf   T0CON

        ; Interrupts
        bcf     INTCON, TMR0IF                  ; Clear TMR0 interrupt flag
        bsf     INTCON, TMR0IE                  ; Enable TMR0 Overflow Interrupts

; *****************************************************************************
; Setup Timer: TIMER1
;  Used to keep time, interrupts every 10ms

        movlw   b'10000000'                     ; 16b read, no prescaler, t1osc off, stopped
        movwf   T1CON

        movlw   iTMRH                           ; Preload for timer
        movwf   TMR1H
        movlw   iTMRL
        movwf   TMR1L

        ; Interrupts
        bcf     PIR1, TMR1IF                    ; Clear TMR1 interrupt flag
        bsf     PIE1, TMR1IE                    ; Enable TMR1 Overflow Interrupts

; *****************************************************************************
; Setup Ports
        ; Default settings
        clrf    LATA                            ; clear output data latches PORT A
        clrf    LATB                            ; clear output data latches PORT B
        clrf    LATC                            ; clear output data latches PORT C

        clrf    ANSEL                           ; all ports digital
        clrf    ANSELH

        ; should all be output inorder to reduce power. If an input pin is left floating it will consume power.
        setf    TRISA                           ; Set PORT A Direction - all input
        setf    TRISB                           ; Set PORT B Direction - all input
        setf    TRISC                           ; Set PORT C Direction - all input

        clrf    SLRCON                          ; standard slew rate

        ; Enable weak pull up resistors
        bcf     INTCON2, NOT_RBPU               ; Enable bit for weak pull-up resistors for Port B, ENABLED

        ; Disable CCP
        clrf    CCP2CON                         ; Turn CCP module off

        ; Custom settings

        ; Button
        bsf     BUTTON_TRIS, BUTTON_PIN         ; Button pin is an input
        bsf     WPUB, BUTTON_WPUB               ; Enable week pull up on button input.
        bsf     IOCB, BUTTON_IOCB               ; Interrupt-on-change

        ; Buzzer
        bcf     BUZZER_TRIS, BUZZER_PIN         ; Buzzer pin is an output
        bcf     BUZZER_LATCH, BUZZER_PIN        ; Initialize to 0, buzzer off

        ; Pressure Sensor
        ; Shutdown
        bcf     PRESS_SHDN_TRIS, PRESS_SHDN_PIN ; Pressure power pin is an output
        bcf     PRESS_SHDN_LATCH, PRESS_SHDN_PIN    ; Initialize to 0, sensor is shutdown

; *****************************************************************************
; Setup ADC - off
        bcf     ADCON0, ADON                    ; turn off

; *****************************************************************************
; Setup I2C - 7bit Master Mode
        ; Set I2C pins as inputs
        bsf     TRISC, SCL                      ; SCL - Serial Clock: input - Pin RC3
        bsf     TRISC, SDA                      ; SDA - Serial Data : input - Pin RC4

        clrf    SSPSTAT                         ; SSPSTAT <= 10__ ____
        bsf     SSPSTAT,SMP                     ; Disable SMBus inputs, Disable slew rate control

        ; Load I2C Clock Rate
        ; sets the I2C bus speed to the maximum the mcu can handle
    if FOSC >= FOSC_8MHZ
        movlw   .3                              ; (fosc/4) / 4
    else
        movlw   .2                              ; (fosc/4) / 3
    endif

        movwf   SSPADD                          ; Set I2C clock
        movlw   0x28
        movwf   SSPCON1                         ; Enable SSP, select I2C Master mode
        clrf    SSPCON2                         ; Clear control bits
        bcf     PIE1, SSPIE                     ; Disable MSSP interrupt
        bcf     PIR1, SSPIF                     ; Clear SSP interrupt flag
        bcf     PIR2, BCLIF                     ; Clear Bit Collision flag

; *****************************************************************************
; Setup PLVD
        movlw   b'00001000'                     ; configure for low voltage detect
        movwf   HLVDCON                         ; below 2.70 V

; *****************************************************************************
; Initilize Variables

        ; set option to byte0 in eeprom
        ; EEPROM Memory Address to read
        clrf    EECON1                      ; Point to DATA memory, Access EEPROM
        clrf    EEADR                       ; Addr <= 0x00

        bsf     EECON1, RD                  ; EEPROM Read
        movff   EEDATA, options             ; save to options register

        ; State
        call    InitFsm

        ; Time
        call    ClearTimer

        ; Last max altitude
        call    RetrieveMaxAltitude

; *****************************************************************************
; Setup Interrupts
        bsf     INTCON, GIE                     ; Global Interrupt Enable
        bsf     INTCON, PEIE                    ; Peripheral Interrupt Enable

; *****************************************************************************
; Initilize Devices

        ; Pressure Sensor
        call    InitMpl115a2

        ; DBG:
        btfss   BUTTON_PORT, BUTTON_PIN
        call    SettingsFsm

; *****************************************************************************
; Start Execution
        ; start in sleep mode
        bcf     OSCCON, IDLEN                   ; IDLE mode on sleep, disabled
        bcf     INTCON, RBIE                    ; Disable port b interrupt-on-change flag

        goto    StateUnitSelect
        goto    StateMachine                    ; Jumps to main program

;******************************************************************************
;End of setup

        END
