;#define DEVELOPER_LOAD         ; when defined extra options will be available


; Default altitude units
METER           EQU 1
FEET            EQU 0

DEFAULT_UNIT    EQU FEET

ALTLUT_ADDR     EQU 0x1800

; Pressure Sensor
MP3H6115A       EQU 0
MPL115A2        EQU 1

PRESSURE_SENSOR EQU MPL115A2

; Clock frequency
FOSC_64MHZ      EQU 8
FOSC_32MHZ      EQU 7
FOSC_16MHZ      EQU 6
FOSC_8MHZ       EQU 5
FOSC_4MHZ       EQU 4
FOSC_2MHZ       EQU 3
FOSC_1MHZ       EQU 2
FOSC_500KHZ     EQU 1
FOSC_250KHZ     EQU 0

FOSC            EQU FOSC_1MHZ


; ***********************************************************************
;Pins
; Pressure  - Sensor
; Connect to pin 4 of MPL115A2, SHDN
; Shutdown
; Connect to GND to disable the device. When in shut down the part draws
; 1 µA supply current and all communications pins (RST/CS, SCL/SCLK,
; SDA/DOUT, NC/DIN) are high impedance. Connect to VDD for normal
; operation.
PRESS_SHDN_TRIS     EQU TRISC
PRESS_SHDN_LATCH    EQU LATC
PRESS_SHDN_PIN      EQU 7

; Buzzer    - Actuator
BUZZER_TRIS     EQU TRISC
BUZZER_LATCH    EQU LATC
BUZZER_PIN      EQU 1

CCP2_C1         EQU 0
CCP2_B3         EQU 1

CCP2_MUX        EQU CCP2_C1

; Button    - Input
BUTTON_TRIS     EQU TRISB
BUTTON_PORT     EQU PORTB
BUTTON_PIN      EQU 5
BUTTON_WPUB     EQU WPUB5
BUTTON_IOCB     EQU IOCB5

; *****************************************************************************
;Constants

FREE_FLIGHT_PERIOD  EQU .10                 ; 10Hz sampling during free flight


; Timer
        ; Interrupt Timer Value
; 2.5ms overflow (10,000 cycles) - travel of 27cm @ 400km/h
;iTMR0H             EQU 0xD9                ; sub 26 from calculated D924 -> D90A
;iTMR0L             EQU 0x0A                ; Calculated = 0xD924
;
;; 2ms overflow (8,000 cycles) - travel of 22cm @ 400km/h
;iTMR0H             EQU 0xD9                ; sub 26 from calculated D924 -> D90A
;iTMR0L             EQU 0x0A                ; Calculated = 0xD924
;
; 1ms overflow (4,000 cycles) - travel of 11cm @ 400km/h
;iTMR0H             EQU 0xF0                ; sub 26 from calculated F060 -> D90A
;iTMR0L             EQU 0x60                ; Calculated = 0xF060

; 8MHz
    if FOSC == FOSC_8MHZ
; 10ms overflow (20,000 cycles)
iTMRH               EQU 0xB1                ; sub 26 from calculated F060 -> D90A
iTMRL               EQU 0xE0                ; Calculated = 0xB1E0
    endif

; 4MHz
    if FOSC == FOSC_4MHZ
; 10ms overflow (10,000 cycles)
iTMRH               EQU 0xD8                ; sub 26 from calculated F060 -> D90A
iTMRL               EQU 0xF0                ; Calculated = 0xD8F0
    endif

; 2MHz
    if FOSC == FOSC_2MHZ
; 10ms overflow (5,000 cycles)
iTMRH               EQU 0xEC                ; sub 26 from calculated F060 -> D90A
iTMRL               EQU 0x78                ; Calculated = 0xEC78
    endif

; 1MHz
    if FOSC == FOSC_1MHZ
; 10ms overflow (2,500 cycles)
iTMRH               EQU 0xF6                ; sub 26 from calculated F060 -> D90A
iTMRL               EQU 0x3C                ; Calculated = 0x09C4
    endif

; 500kHz
    if FOSC == FOSC_500KHZ
; 10ms overflow (1,250 cycles)
iTMRH               EQU 0xFB                ; sub 26 from calculated F060 -> D90A
iTMRL               EQU 0x1E                ; Calculated = 0x09C4
    endif

; TimeOut - Fosc independant
; Minutes
; 60min     00 05 7E 40
TIMEOUT_60mH        EQU 0x05                ; b2
TIMEOUT_60mL        EQU 0x7E                ; b1
; 30min     00 02 BF 20
TIMEOUT_30mH        EQU 0x02                ; b2
TIMEOUT_30mL        EQU 0xBF                ; b1
; 20min     00 01 D4 C0
TIMEOUT_20mH        EQU 0x01                ; b2
TIMEOUT_20mL        EQU 0xD4                ; b1
; 10min     00 00 EA 60
TIMEOUT_10mH        EQU 0x00                ; b2
TIMEOUT_10mL        EQU 0xEA                ; b1

; Seconds
; 60sec     00 00 17 70
TIMEOUT_60sH        EQU 0x17                ; b1
TIMEOUT_60sL        EQU 0x70                ; b0

; 30sec     00 00 0B B8
TIMEOUT_30sH        EQU 0x0B                ; b1
TIMEOUT_30sL        EQU 0xB8                ; b0

; 20sec     00 00 07 D0
TIMEOUT_20sH        EQU 0x07                ; b1
TIMEOUT_20sL        EQU 0xD0                ; b0

; 10sec     00 00 03 E8
TIMEOUT_10sH        EQU 0x03                ; b1
TIMEOUT_10sL        EQU 0xE8                ; b0

; *******************************************

; Choosen values
; Launch Timeout - minutes
LAUNCH_TIMEOUT_H    EQU TIMEOUT_10mH
LAUNCH_TIMEOUT_L    EQU TIMEOUT_10mL

; Flight Timeout
FLIGHT_TIMEOUT_H    EQU TIMEOUT_20sH
FLIGHT_TIMEOUT_L    EQU TIMEOUT_20sL

; Grounded Timeout
GROUND_TIMEOUT_H    EQU TIMEOUT_60sH
GROUND_TIMEOUT_L    EQU TIMEOUT_60sL

; FreeFlight Timeout
FFLIGHT_TIMEOUT_H   EQU TIMEOUT_60mH
FFLIGHT_TIMEOUT_L   EQU TIMEOUT_60mL

; Data Processing
SLIDING_WINDOW_SIZE     EQU .16
LOG_SLIDING_WINDOW_SIZE EQU .4


; *******************************************
; Misc TODO: organize this better
LAUNCH_BEEP_DUTY_CYCLE  EQU .8              ; 8ms on time for each 2.56s interval

DELTA_32M           EQU 0x0200
DELTA_24M           EQU 0x0180
DELTA_16M           EQU 0x0100
DELTA_15M           EQU 0x00C0
DELTA_10M           EQU 0x0080
DELTA_08M           EQU 0x0070
DELTA_07M           EQU 0x0060
DELTA_05M           EQU 0x0040
DELTA_04M           EQU 0x0030
DELTA_02M           EQU 0x0020


LAUNCH_SENSITIVITY  EQU DELTA_24M

FLIGHT_DELTA        EQU DELTA_15M

TEST_DELTA          EQU DELTA_07M

;#define    CALC_PRESSURE
#define     CALC_ALTITUDE_INTERPOLATION
;#define        CALC_ALTITUDE_FULL

;******************************************
; I2C Clock Freq (with FOSC == 2 MHz)
SSPADD_100k         EQU .4      ; 100 kHz -> .4
SSPADD_125k         EQU .3      ; 100 kHz -> .3

; Define NVM size (number of bytes)
MEMORY_SIZE_3       EQU 0                   ; 1 Mbit, 128kB
MEMORY_SIZE_2       EQU 2
MEMORY_SIZE_1       EQU 0
MEMORY_SIZE_0       EQU 0
