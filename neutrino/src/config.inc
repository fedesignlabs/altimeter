;******************************************************************************
;Configuration bits

;   Oscillator Selection bits:
;   CONFIG  FOSC  = LP                  ; LP Oscillator
;   CONFIG  FOSC  = XT                  ; XT Oscillator
;   CONFIG  FOSC  = HS                  ; HS Oscillator
;   CONFIG  FOSC  = RC                  ; External RC oscillator, CLKO function on RA6
;   CONFIG  FOSC  = EC                  ; EC oscillator, CLKO function on RA6
;   CONFIG  FOSC  = ECIO6               ; EC oscillator, port function on RA6
;   CONFIG  FOSC  = HSPLL               ; HS oscillator, PLL enabled (Clock Frequency = 4 x FOSC1)
;   CONFIG  FOSC  = RCIO6               ; External RC oscillator, port function on RA6
    CONFIG  FOSC  = INTIO67             ; Internal oscillator block, port function on RA6 and RA7
;   CONFIG  FOSC  = INTIO7              ; Internal oscillator block, CLKO function on RA6, port function on RA7

;   Fail-Safe Clock Monitor Enable bit:
    CONFIG  FCMEN = OFF                 ; Fail-Safe Clock Monitor disabled
;   CONFIG  FCMEN = ON                  ; Fail-Safe Clock Monitor enabled

;   Internal/External Oscillator Switchover bit:
    CONFIG  IESO = OFF                  ; Oscillator Switchover mode disabled
;   CONFIG  IESO = ON                   ; Oscillator Switchover mode enabled

;   Power-up Timer Enable bit:
    CONFIG  PWRT = ON                   ; PWRT enabled
;   CONFIG  PWRT = OFF                  ; PWRT disabled

;   Brown-out Reset Enable bits:
    CONFIG  BOREN = OFF                 ; Brown-out Reset disabled in hardware and software
;   CONFIG  BOREN = ON                  ; Brown-out Reset enabled and controlled by software (SBOREN is enabled)
;   CONFIG  BOREN = NOSLP               ; Brown-out Reset enabled in hardware only and disabled in Sleep mode (SBOREN is disabled)
;   CONFIG  BOREN = SBORDIS             ; Brown-out Reset enabled in hardware only (SBOREN is disabled)

;   Brown-out Reset Voltage bits:
;   CONFIG  BORV = 30                   ; VBOR set to 3.0 V nominal
;   CONFIG  BORV = 27                   ; VBOR set to 2.7 V nominal
;   CONFIG  BORV = 22                   ; VBOR set to 2.2 V nominal
    CONFIG  BORV = 18                   ; VBOR set to 1.8 V nominal

;   Watchdog Timer Enable bit:
    CONFIG  WDTEN = OFF                 ; WDT disabled (control is placed on the SWDTEN bit)
;   CONFIG  WDTEN = ON                  ; WDT enabled

;   Watchdog Timer Postscale Select bits:
;   CONFIG  WDTPS = 1               ; 1:1
;   CONFIG  WDTPS = 2               ; 1:2
;   CONFIG  WDTPS = 4               ; 1:4
;   CONFIG  WDTPS = 8               ; 1:8
;   CONFIG  WDTPS = 16              ; 1:16
;   CONFIG  WDTPS = 32              ; 1:32
;   CONFIG  WDTPS = 64              ; 1:64
;   CONFIG  WDTPS = 128             ; 1:128
;   CONFIG  WDTPS = 256             ; 1:256
;   CONFIG  WDTPS = 512             ; 1:512
;   CONFIG  WDTPS = 1024            ; 1:1024
;   CONFIG  WDTPS = 2048            ; 1:2048
;   CONFIG  WDTPS = 4096            ; 1:4096
;   CONFIG  WDTPS = 8192            ; 1:8192
;   CONFIG  WDTPS = 16384           ; 1:16384
    CONFIG  WDTPS = 32768           ; 1:32768

;   MCLR Pin Enable bit:
    CONFIG  MCLRE = OFF             ; RE3 input pin enabled; MCLR disabled
;   CONFIG  MCLRE = ON              ; MCLR pin enabled; RE3 input pin disabled

;   HF-INTOSC Fast Startup:
    CONFIG HFOFST = OFF             ; The system clock is held off until the HF-INTOSC is stable.
;   CONFIG HFOFST = ON              ; HF-INTOSC starts clocking the CPU without waiting for the oscillator to stablize.

;   Low-Power Timer1 Oscillator Enable bit:
;   CONFIG  LPT1OSC = OFF           ; Timer1 configured for higher power operation
    CONFIG  LPT1OSC = ON            ; Timer1 configured for low-power operation

;   Background Debugger Enable bit:
;   CONFIG  DEBUG = ON              ; Background debugger enabled, RB6 and RB7 are dedicated to In-Circuit Debug
    CONFIG  DEBUG = OFF             ; Background debugger disabled, RB6 and RB7 configured as general purpose I/O pins


;   PORTB A/D Enable bit:
    CONFIG  PBADEN = OFF            ; PORTB<4:0> pins are configured as digital I/O on Reset
;   CONFIG  PBADEN = ON             ; PORTB<4:0> pins are configured as analog input channels on Reset

;   CCP2 Mux bit:
;   CONFIG  CCP2MX = PORTBE         ; CCP2 input/output is multiplexed with RB3
    CONFIG  CCP2MX = PORTC          ; CCP2 input/output is multiplexed with RC1

;   Stack Full/Underflow Reset Enable bit:
;   CONFIG  STVREN = OFF            ; Stack full/underflow will not cause Reset
    CONFIG  STVREN = ON             ; Stack full/underflow will cause Reset

;   Single-Supply ICSP Enable bit:
    CONFIG  LVP = OFF               ; Single-Supply ICSP disabled
;   CONFIG  LVP = ON                ; Single-Supply ICSP enabled

;   Extended Instruction Set Enable bit:
    CONFIG  XINST = OFF             ; Instruction set extension and Indexed Addressing mode disabled (Legacy mode)
;   CONFIG  XINST = ON              ; Instruction set extension and Indexed Addressing mode enabled

;   Code Protection bit Block 0:
;   CONFIG  CP0 = ON                ; Block 0 (000800-001FFFh) code-protected
    CONFIG  CP0 = OFF               ; Block 0 (000800-001FFFh) not code-protected

;   Code Protection bit Block 1:
;   CONFIG  CP1 = ON                ; Block 1 (002000-003FFFh) code-protected
    CONFIG  CP1 = OFF               ; Block 1 (002000-003FFFh) not code-protected

    if  MCU == P18F26K20
;   Code Protection bit Block 1:
;   CONFIG  CP2 = ON                ; Block 2 (004000-005FFFh) code-protected
    CONFIG  CP2 = OFF               ; Block 2 (004000-005FFFh) not code-protected

;   Code Protection bit Block 3:
;   CONFIG  CP3 = ON                ; Block 3 (006000-007FFFh) code-protected
    CONFIG  CP3 = OFF               ; Block 3 (006000-007FFFh) not code-protected
    endif

;   Boot Block Code Protection bit:
;   CONFIG  CPB = ON                ; Boot block (000000-0007FFh) code-protected
    CONFIG  CPB = OFF               ; Boot block (000000-0007FFh) not code-protected

;   Data EEPROM Code Protection bit:
;   CONFIG  CPD = ON                ; Data EEPROM code-protected
    CONFIG  CPD = OFF               ; Data EEPROM not code-protected

;   Write Protection bit Block 0:
;   CONFIG  WRT0 = ON               ; Block 0 write-protected
    CONFIG  WRT0 = OFF              ; Block 0 not write-protected

;   Write Protection bit Block 1:
;   CONFIG  WRT1 = ON               ; Block 1 write-protected
    CONFIG  WRT1 = OFF              ; Block 1 not write-protected

    if  MCU == P18F26K20
;   Write Protection bit Block 1:
;   CONFIG  WRT2 = ON               ; Block 2 (008000-00BFFFh) write-protected
    CONFIG  WRT2 = OFF              ; Block 2 (008000-00BFFFh) not write-protected

;   Write Protection bit Block 3:
;   CONFIG  WRT3 = ON               ; Block 3 (006000-007FFFh) write-protected
    CONFIG  WRT3 = OFF              ; Block 3 (006000-007FFFh) not write-protected
    endif

;   Configuration Register Write Protection bit:
;   CONFIG  WRTC = ON               ; Configuration registers (300000-3000FFh) write-protected
    CONFIG  WRTC = OFF              ; Configuration registers (300000-3000FFh) not write-protected

;   Boot Block Write Protection bit:
;   CONFIG  WRTB = ON               ; Boot block (000000-0007FFh) write-protected
    CONFIG  WRTB = OFF              ; Boot block (000000-0007FFh) not write-protected

;   Data EEPROM Write Protection bit:
;   CONFIG  WRTD = ON               ; Data EEPROM write-protected
    CONFIG  WRTD = OFF              ; Data EEPROM not write-protected

;   Table Read Protection bit Block 0:
;   CONFIG  EBTR0 = ON              ; Block 0 protected from table reads executed in other blocks
    CONFIG  EBTR0 = OFF             ; Block 0 not protected from table reads executed in other blocks

;   Table Read Protection bit Block 1:
;   CONFIG  EBTR1 = ON              ; Block 1 protected from table reads executed in other blocks
    CONFIG  EBTR1 = OFF             ; Block 1 not protected from table reads executed in other blocks

    if  MCU == P18F26K20
;   Table Read Protection bit Block 2:
;   CONFIG  EBTR2 = ON              ; Block 2 protected from table reads executed in other blocks
    CONFIG  EBTR2 = OFF             ; Block 2 not protected from table reads executed in other blocks

;   Table Read Protection bit Block 3:
;   CONFIG  EBTR3 = ON              ; Block 3 (006000-007FFFh) protected from table reads executed in other blocks
    CONFIG  EBTR3 = OFF             ; Block 3 (006000-007FFFh) not protected from table reads executed in other blocks
    endif

;   Boot Block Table Read Protection bit:
;   CONFIG  EBTRB = ON              ; Boot block protected from table reads executed in other blocks
    CONFIG  EBTRB = OFF             ; Boot block not protected from table reads executed in other blocks

