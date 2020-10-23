;************************************************************************
;                                                                       *
;   Filename:       mpl115a2.asm                                        *
;   Date:           Sep 14 2010                                         *
;   File Version:   1                                                   *
;       1   Initial Code                                Sep 14, 2010    *
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
;   Description:    Interface to the MPL115A2 pressure sensor           *
;                                                                       *
;                                                                       *
;************************************************************************
; The 10-bit compensated pressure output, Pcomp, is calculated as follows:
;   Pcomp = a0 + (b1 + c11*Padc + c12*Tadc) * Padc + (b2 + c22*Tadc) * Tadc
; Where:
;   Padc is the 10-bit pressure output of the MPL115A2 ADC,                     00,01
;   Tadc is the 10-bit temperature output of the MPL115A2 ADC,                  02,03
;   a0 is the pressure offset coefficient,                                      04,05
;   b1 is the pressure sensitivity coefficient,                                 06,07
;   b2 is the 1st order temperature offset coefficient (TCO),                   08,09
;   c12 is the coefficient for temperature sensitivity coefficient (TCS),       0A,0B
;   c11 is the pressure linearity (2nd order) coefficient,                      0C,0D
;   c22 is the 2nd order temperature offset coefficient.                        0E,0F


; Device address is 0x60


;I2C Write Commands
;   Command                         8-bit Code
;   Start Pressure Conversion       X0010000
;   Start Temperature Conversion    X0010001
;   Start both Conversions          X0010010

;I2C Read Commands
;   Command                         8-bit code
;   Read Pressure Hi byte           X0000000
;   Read Pressure Lo byte           X0000001
;   Read Temperature Hi byte        X0000010
;   Read Temperature Lo byte        X0000011
;************************************************************************

        #include    "include\processor.inc"
        #include    "src\settings.inc"
        #include    "include\util\delay_time.inc"
        #include    "include\util\delay_short.inc"
        #include    "include\error.inc"
        #include    "include\i2c.inc"
        #include    "include\math\math.inc"

        ; Global Functions
        GLOBAL      PowerMpl115a2
        GLOBAL      ShutdownMpl115a2

        GLOBAL      InitMpl115a2

        GLOBAL      SingleSamplePressure
        GLOBAL      SamplePressure

        GLOBAL      CalcAltitude                ; TODO: consider renaming
        GLOBAL      CalculateTemperature
        GLOBAL      CalculatePressure

        ; Global Variables
        GLOBAL      pressureH
        GLOBAL      pressureL

        GLOBAL      pressuredaPaH
        GLOBAL      pressuredaPaL

        GLOBAL      temperature

        GLOBAL      altitudeMeterH
        GLOBAL      altitudeMeterL

; Constants
MPL115A2_ADDR_WR    EQU 0xC0
MPL115A2_ADDR_RD    EQU MPL115A2_ADDR_WR + 1

CONV_P              EQU 0x10
CONV_T              EQU 0x11
CONV_T_P            EQU 0x12

PRESSURE_B0         EQU 0x00
TEMPERATURE_B0      EQU 0x02
COEFFICIENT_B0      EQU 0x04

NUM_COEFFICIENTS    EQU .12

; Defines
;SAMPLE_LOGGING      EQU 1

;*VAR********************************************************************
MPX_AVAR        udata_acs
        ; Raw Data
rawPressureH    res 1                       ; Contains raw pressure sample, MSB
rawPressureL    res 1                       ; Contains raw pressure sample, LSB
rawTempH        res 1                       ; Contains raw temperature sample, MSB >> 6
rawTempL        res 1                       ; Contains raw temperature sample, LSB >> 6

counter         res 1

; modified coefficients
; modified a0
ma0B2           res 1
ma0B1           res 1
ma0B0           res 1
; modified b1
mb1B2           res 1
mb1B1           res 1
mb1B0           res 1

        ; Converted Data
pressureH       res 1
pressureL       res 1

pressuredaPaH   res 1           ; temperature in daPa
pressuredaPaL   res 1

temperature     res 1           ; temperature in degrees celsius

altitudeMeterH  res 1           ; altitude in meters
altitudeMeterL  res 1

    ifdef   CALC_ALTITUDE_INTERPOLATION
yaH             res 1           ; later overlap
yaL             res 1           ; later overlap
ybH             res 1           ; later overlap
ybL             res 1           ; later overlap
    endif

tempValueH      res 1           ; later overlap
tempValueL      res 1           ; later overlap

tA3             res 1
tA2             res 1
tA1             res 1
tA0             res 1

MPX_1VAR        udata   0x120
; coefficients, must be in this order.
a0H             res 1
a0L             res 1
b1H             res 1
b1L             res 1
b2H             res 1
b2L             res 1
c12H            res 1
c12L            res 1
c11H            res 1
c11L            res 1
c22H            res 1
c22L            res 1

;*CODE*******************************************************************
MPLCODE         CODE


GET_BOTH        EQU 1

;** Externalized Function Definitions ***********************************

;************************************************************************
;   PowerMpl115a2 - Power the MPL115A2 pressure sensor
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: Sensor is in a normal operation state.
;
;   Sets SHDN pin on the MPL115A2 sensor to put it into nomral operation
;   mode.
;************************************************************************
PowerMpl115a2:

        bsf     PRESS_SHDN_LATCH, PRESS_SHDN_PIN    ; pressure sensor in normal operation

        return


;************************************************************************
;   ShutdownMpl115a2 - Shutdown the MPL115A2 pressure sensor
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: Sensor is in shutdown mode.
;
;   Clears the SHDN pin on the MPL115A2 sensor to put it into shutdown
;   mode.
;************************************************************************
ShutdownMpl115a2:

        bcf     PRESS_SHDN_LATCH, PRESS_SHDN_PIN    ; disable the pressure sensor

        return


;************************************************************************
;   InitMpl115a2 - Initialize the MPL115A2 pressure sensor
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: Sensor is in shutdown mode.  Coefficients are updated.
;   Could result in a fatal error if it cannot communicate with the
;   pressure sensor.
;
;   Turns on the pressure sensor, gets coefficients from it, and modifies
;   them accordingly.  It will then shutdown the sensor.
;************************************************************************
InitMpl115a2:
        ; steps:
        ; 1. turn on sensor
        ; 2. get coefficients
        ; 3. alert if c11 and c22 are not equal to zero
        ; 4. make necissary modifications to the coefficients
        ; 5. shutdown sensor
    ifdef   SAMPLE_LOGGING
        rcall   InitLogger
    endif

        ; 1. turn on sensor
        rcall   PowerMpl115a2

        movlw   DELAY_3072us
        call    DelayShort

        ; 2. get coefficients
        rcall   GetCoefficients

        ; 3. alert if c11 and c22 are not equal to zero
        ; check c11 and c22
        tstfsz  c11H, BANKED
        bra     nonzero

        tstfsz  c11L, BANKED
        bra     nonzero

        tstfsz  c22H, BANKED
        bra     nonzero

        tstfsz  c22L, BANKED
        bra     nonzero

        ; 4. make necissary modifications to the coefficients
        ; modify coefficients
        ; 2^3 * a0
        clrf    ma0B2
        btfsc   a0H, 7, BANKED
        setf    ma0B2                   ; sign extend
        movff   a0H, ma0B1
        movff   a0L, ma0B0

        bcf     STATUS, C
        ; a0 << 1
        rlcf    ma0B0, F
        rlcf    ma0B1, F
        rlcf    ma0B2, F
        ; a0 << 1
        rlcf    ma0B0, F
        rlcf    ma0B1, F
        rlcf    ma0B2, F
        ; a0 << 1
        rlcf    ma0B0, F
        rlcf    ma0B1, F
        rlcf    ma0B2, F

        ; clean LS bits incase of sign extending
        movlw   0xF8
        andwf   ma0B0, F

        ; modify b1
        ; 2^3 * b1
        clrf    mb1B2
        btfsc   b1H, 7, BANKED
        setf    mb1B2                   ; sign extend
        movff   b1H, mb1B1
        movff   b1L, mb1B0

        bcf     STATUS, C
        ; b1 << 1
        rlcf    mb1B0, F
        rlcf    mb1B1, F
        rlcf    mb1B2, F
        ; b1 << 1
        rlcf    mb1B0, F
        rlcf    mb1B1, F
        rlcf    mb1B2, F
        ; b1 << 1
        rlcf    mb1B0, F
        rlcf    mb1B1, F
        rlcf    mb1B2, F

        ; clean LS bits incase of sign extending
        movlw   0xF8
        andwf   mb1B0, F

        ; 5. shutdown sensor
        rcall   ShutdownMpl115a2

        return

nonzero:
        ; beep
        rcall   ShutdownMpl115a2

        return


;************************************************************************
;   SingleSamplePressure - Gets a single pressure sample
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: Sensor is in shutdown mode.  Variable pressure[H:L] is
;   updated.
;
;   Used to get a single sample from the sensor and then turn it off.  It
;   takes over 20ms.
;
;   Turns on the pressure sensor, gets coefficients from it, and modifies
;   them accordingly.  It will then shutdown the sensor.
;************************************************************************
SingleSamplePressure:
        ; Make sure pressure sensor is on
        rcall   PowerMpl115a2                       ; turn on pressure sensor, needs 3ms before it can be sampled properly

        movlw   DELAY_20ms
        call    Delay

        ; Sample pressure sensor
        rcall   SamplePressure

        rcall   ShutdownMpl115a2                    ; turn off pressure sensor

        return


;************************************************************************
;   SamplePressure - Sample the pressure sensor
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Sensor must be on.
;
;   Postcondition: Variables pressure[H:L] and rawTemp[H:L] are updated.
;
;   Used to get a single sample from the sensor if the sensor is already.
;   on.  It takes over 2ms.
;
;   A sample request is sent to the pressure sensor.  It then waits 2ms
;   before reading the pressure and temperature sample.
;************************************************************************
SamplePressure:
        call    RequestPressureTemperature

        ; 2ms delay, freescale support said 3ms.
        movlw   DELAY_2048us
        call    DelayShort

        call    GetPressureTemperature

        return


;** Static Function Definitions *****************************************

;************************************************************************
;   static RequestPressureTemperature - request temperature and pressure
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Sensor must be on.
;
;   Postcondition: Withing 1 to 3ms the sensor will have samples ready.
;
;   Sends a temperature and pressure sample request to the sensor.
;************************************************************************
RequestPressureTemperature:
        ; Send request

        call    I2cStart

        movlw   MPL115A2_ADDR_WR
        call    I2cTxByte

        movlw   CONV_T_P                    ; command
        call    I2cTxByte

        movlw   0x00                        ; needed after the command
        call    I2cTxByte

        call    I2cStop

        return


    ifdef   GET_PRESSURE
;************************************************************************
;   static GetPressure - Get pressure sample
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Sensor must be on.
;
;   Postcondition: Variable pressure[H:L] are updated.
;
;   ??
;************************************************************************
GetPressure:
        ; Get Sample

        call    I2cStart

        movlw   MPL115A2_ADDR_WR
        call    I2cTxByte

        movlw   PRESSURE_B0
        call    I2cTxByte

        call    I2cRestart

        movlw   MPL115A2_ADDR_RD
        call    I2cTxByte

        bcf     SSPCON2, ACKDT              ; Select to send ACK bit
        call    I2cTxByte                   ; Input data from device

        movwf   rawPressureH

        bsf     SSPCON2, ACKDT              ; Select to send NACK bit
        call    I2cTxByte                   ; Input data from device

        movwf   rawPressureL

        call    I2cStop

        return
    endif


    ifdef   GET_BOTH
;************************************************************************
;   static GetPressureTemperature - Get pressure and temperature samples
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Sensor must be on and request has been sent over 1ms
;   ago.
;
;   Postcondition: Variables pressure[H:L] and rawTemp[H:L] are updated.
;
;   ??
;************************************************************************
GetPressureTemperature:
        ; Get Sample

        call    I2cStart

        movlw   MPL115A2_ADDR_WR
        call    I2cTxByte

        movlw   PRESSURE_B0
        call    I2cTxByte

        call    I2cRestart

        movlw   MPL115A2_ADDR_RD
        call    I2cTxByte

        bcf     SSPCON2, ACKDT              ; Select to send ACK bit
        call    I2cRxByte                   ; Input data from device

        movwf   rawPressureH

        bcf     SSPCON2, ACKDT              ; Select to send ACK bit
        call    I2cRxByte                   ; Input data from device

        movwf   rawPressureL

        bcf     SSPCON2, ACKDT              ; Select to send ACK bit
        call    I2cRxByte                   ; Input data from device

        movwf   rawTempH                    ; reversed to make >> 6 shorter

        bsf     SSPCON2, ACKDT              ; Select to send NACK bit
        call    I2cRxByte                   ; Input data from device

        movwf   rawTempL                    ; reversed to make >> 6 shorter

        call    I2cStop

        ; realign temperature, right justify
        ; rawTemp >> 6

    ifdef   SAMPLE_LOGGING
        call    LogSample
    endif

        bcf     STATUS, C
        ; rawTemp >> 1
        rrcf    rawTempH, F
        rrcf    rawTempL, F
        ; rawTemp >> 1
        rrcf    rawTempH, F
        rrcf    rawTempL, F
        ; rawTemp >> 1
        rrcf    rawTempH, F
        rrcf    rawTempL, F
        ; rawTemp >> 1
        rrcf    rawTempH, F
        rrcf    rawTempL, F
        ; rawTemp >> 1
        rrcf    rawTempH, F
        rrcf    rawTempL, F
        ; rawTemp >> 1
        rrcf    rawTempH, F
        rrcf    rawTempL, F

        call    CalcPressure

        return
    endif


;************************************************************************
;   static GetCoefficients - Get coefficients from the sensor
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Sensor must be on.
;
;   Postcondition: Coefficient variables are updated.
;
;   ??
;************************************************************************
GetCoefficients:
        lfsr    FSR1, a0H

        movlw   NUM_COEFFICIENTS
        movwf   counter

        call    I2cStart

        movlw   MPL115A2_ADDR_WR
        call    I2cTxByte

        tstfsz  WREG
        bra     comm_error

        movlw   COEFFICIENT_B0
        call    I2cTxByte

        call    I2cRestart

        movlw   MPL115A2_ADDR_RD
        call    I2cTxByte

get_next_coef:
        bcf     SSPCON2, ACKDT              ; Select to send ACK bit
        call    I2cRxByte                   ; Input data from device

        movwf   POSTINC1

        decfsz  counter, F
        bra     get_next_coef

        bsf     SSPCON2, ACKDT              ; Select to send NACK bit
        call    I2cRxByte                   ; Input data from device

        movwf   POSTINC1

        call    I2cStop

        return

comm_error:

        movlw   SENSOR_COMM_ERR
        movwf   errorBCD0, BANKED                   ; error code
        movlw   .1                                  ; number of digits
        goto    ErrorHandler


;************************************************************************
;   static CalcPressure - Calculate pressure from the raw data
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Variables rawTemp and rawPressure[H:L] contain valid
;   data.
;
;   Postcondition: Variable pressure[H:L] is updated
;
;   ??
;************************************************************************
CalcPressure:
        ; Step 1:
        ; res[2:1] = b2 * Tr
        movff   b2H, arg1H
        movff   b2L, arg1L

        movff   rawTempH, arg2H
        movff   rawTempL, arg2L

        call    Mul16

        ; Step 2:
        ; tA[2:0] = res[3:0]
        movff   res3, tA3
        movff   res2, tA2
        movff   res1, tA1
        movff   res0, tA0

        ; Step 3:
        ; c12 * Tr
        movff   c12H, arg1H
        movff   c12L, arg1L

        movff   rawTempH, arg2H
        movff   rawTempL, arg2L

        call    Mul16

        ; Step 4:
        ; drop lowest byte and round
        btfss   res0, 7
        bra     done_rounding_a

        incfsz  res1, F
        bra     done_rounding_a

        incfsz  res2, F
        bra     done_rounding_a

        incfsz  res3, F
        bra     done_rounding_a

        goto    ErrorMath

done_rounding_a:

        ; Step 5:
        ; res[3:1] = res[3:1] + mb1[2:0]
        movf    mb1B0, W
        addwf   res1, F

        movf    mb1B1, W
        addwfc  res2, F

        movf    mb1B2, W
        addwfc  res3, F

        ; Step 6:
        ; res[4:0] = res[3:1] * P[1:0]
        movff   res3, arg1U
        movff   res2, arg1H
        movff   res1, arg1L

        movff   rawPressureH, arg2H
        movff   rawPressureL, arg2L

        call    Mul24x16

        ; step 7:
        ; drop lowest byte and round
        btfss   res0, 7
        bra     done_rounding_b

        incfsz  res1, F
        bra     done_rounding_b

        incfsz  res2, F
        bra     done_rounding_b

        incfsz  res3, F
        bra     done_rounding_b

        incfsz  res4, F
        bra     done_rounding_b

        goto    ErrorMath

done_rounding_b:

        ; Step 8:
        ; tA[3:0] + res[4:1]
        movf    tA0, W
        addwf   res1, F

        movf    tA1, W
        addwfc  res2, F

        movf    tA2, W
        addwfc  res3, F

        movf    tA3, W
        addwfc  res4, F

        ; Step 9:
        ; drop lowest byte and round
        btfss   res1, 7
        bra     done_rounding_c

        incfsz  res2, F
        bra     done_rounding_c

        incfsz  res3, F
        bra     done_rounding_c

        incfsz  res4, F
        bra     done_rounding_c

        goto    ErrorMath

done_rounding_c:

        ; Step 10:
        ; res[4:2] = res[4:2] + ma0[2:0]
        movf    ma0B0, W
        addwf   res2, F

        movf    ma0B1, W
        addwfc  res3, F

        movf    ma0B2, W
        addwfc  res4, F

;        btfsc   STATUS, C
;        goto    ErrorMath

        ; Step 11:
        ; pressureH:L = res[3:1] (>> 6)
        movff   res3, pressureH
        movff   res2, pressureL

        return


ErrorMath:

        movlw   CONVERSION_ERR
        movwf   errorBCD0, BANKED                   ; error code
        movlw   .1                                  ; number of digits
        goto    ErrorHandler


    ifdef   CALC_ALTITUDE_INTERPOLATION
;************************************************************************
;   CalcAltitude - Calculate altitude via a lut and interpolation
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Variable pressure[H:L] contains valid data.
;
;   Postcondition: Variable altitude[H:L] is updated
;
;   ??
;
;   More info: lab book 1, page 200
;************************************************************************
CalcAltitude:
        movff   pressureH, tempValueH
        movff   pressureL, tempValueL

        ; get count from count << 6
        ; since 2 bytes are stored at each location in the LUT, mul count by 2, [<< (6 - 1)]

        ; tempValue >> 1
        rrcf    tempValueH, F
        rrcf    tempValueL, F
        ; tempValue >> 1
        rrcf    tempValueH, F
        rrcf    tempValueL, F
        ; tempValue >> 1
        rrcf    tempValueH, F
        rrcf    tempValueL, F
        ; tempValue >> 1
        rrcf    tempValueH, F
        rrcf    tempValueL, F
        ; tempValue >> 1
        rrcf    tempValueH, F
        rrcf    tempValueL, F

        movlw   0x07
        andwf   tempValueH, F
        bcf     tempValueL, 0               ; for alignment

        ; Step 0: Get values of y0 and y1 (only needed if raw is odd)
        ;   Read Program Memory

        movlw   b'10000000'                 ; access flash program memory
        movwf   EECON1

        ; setup address pointers
        ;  Upper
        clrf    TBLPTRU
        ;  High
        movlw   HIGH (ALTLUT_ADDR)
        addwf   tempValueH, W
        movwf   TBLPTRH                     ; Point to location in program memory
        ;  Low
        movff   tempValueL, TBLPTRL

        ; read value
        tblrd*+
        movff   TABLAT, yaL

        tblrd*+
        movff   TABLAT, yaH

        tblrd*+
        movff   TABLAT, ybL

        tblrd*+
        movff   TABLAT, ybH

        ; Step 1: yb - ya
        ;   16 bit subtraction, output signed
        ; yb = yb - ya
        movf    yaL, W                      ; LSB
        subwf   ybL, F                      ;
        movf    yaH, W                      ; MSB
        subwfb  ybH, F                      ; yb = yb - ya

        ; Step 2: Calculate yb * x
        ;   16 bit signed multiplication
        ; res = yb * x

        ; x is only 6 bits
        clrf    arg1H
        movlw   0x3F
        andwf   pressureL, W
        movwf   arg1L

        movff   ybH, arg2H
        movff   ybL, arg2L

        call    Mul16

        ; Step 3: ya * n
        ;   ya << 6 (or) rename and >> 2

        ; setup
        clrf    tempValueL
        bcf     STATUS, C                   ; make sure Carry flag is clear

        ; do >> 2
        ; ya >> 1
        rrcf    yaH, F
        rrcf    yaL, F
        rrcf    tempValueL

        ; ya >> 1
        rrcf    yaH, F
        rrcf    yaL, F
        rrcf    tempValueL

        ; account for possible negative ya
        ; if it was negative bit yaH,5 will be 1
        btfss   yaH, 5
        bra     ca_step4

        ; it is negative, sign extend
        movlw   b'11000000'
        iorwf   yaH, F

ca_step4:
        ; Step 4: ya * n + ( yb - ya ) x
        ;   3 Byte addition ya + res2:0

        movf    tempValueL, W
        addwf   res0, F

        movf    yaL, W
        addwfc  res1, F

        movf    yaH, W
        addwfc  res2, F
        ; will not overflow

        ; Step 5: [ya * n + ( yb - ya ) x] / 4 * n
        ;   free, just need to round
        btfss   res0, 7
        bra     gotAltitude

        infsnz  res1, F
        incf    res2, F
        ; will not overflow

gotAltitude:
        movff   res2, altitudeMeterH
        movff   res1, altitudeMeterL

        return
    endif


    ifdef   CALC_ALTITUDE_FULL
;************************************************************************
;   CalcAltitude - Calculate altitude via a lut
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Variable pressure[H:L] contains valid data.
;
;   Postcondition: Variable altitude[H:L] is updated
;
;   ?? Uses a look up table to calculate Altitude
;************************************************************************
CalcAltitude:
        movff   pressureH, tempValueH
        movff   pressureL, tempValueL

        ; get count from count << 6
        ; since 2 bytes are stored at each location in the LUT, mul count by 2, [<< (6 - 1)]

        ; tempValue >> 1
        rrcf    tempValueH, F
        rrcf    tempValueL, F
        ; tempValue >> 1
        rrcf    tempValueH, F
        rrcf    tempValueL, F
        ; tempValue >> 1
        rrcf    tempValueH, F
        rrcf    tempValueL, F
        ; tempValue >> 1
        rrcf    tempValueH, F
        rrcf    tempValueL, F
        ; tempValue >> 1
        rrcf    tempValueH, F
        rrcf    tempValueL, F

        movlw   0x07
        andwf   tempValueH, F
        bcf     tempValueL, 0               ; for alignment

        ; Step 0: Get values from LUT
        ;   Read Program Memory

        movlw   b'10000000'                 ; access flash program memory
        movwf   EECON1

        ; setup address pointers
        ;  Upper
        clrf    TBLPTRU
        ;  High
        movlw   HIGH (ALTLUT_ADDR)
        addwf   tempValueH, W
        movwf   TBLPTRH                     ; Point to location in program memory
        ;  Low
        movff   tempValueL, TBLPTRL

        ; read value
        tblrd*+
        movff   TABLAT, altitudeMeterL

        tblrd*+
        movff   TABLAT, altitudeMeterH

        ; TODO: no point in storing x4 altitude if the extra precision isn't going to be used.
        ;movff   altitudeH, altitudeMeterH
        ;movff   altitudeL, altitudeMeterL

        ; divide the altitude by 4, round
        rrcf    altitudeMeterH, F
        rrcf    altitudeMeterL, F
        rrcf    altitudeMeterH, F
        rrcf    altitudeMeterL, F

        btfss   STATUS, C                   ; if C is set then round up
        bra     done_get_altitude

        infsnz  altitudeMeterL, F
        incf    altitudeMeterH, F

done_get_altitude:
        ; clear top 2 bits.  Needed due to content of C flag during rrcf
        movlw   0x3F
        andwf   altitudeMeterH, F

        return
    endif


    ; DBG:
    ifdef   SAMPLE_LOGGING
InitLogger:
        lfsr    FSR0, 0x0200
        return

LogSample:
        ; if FSR0H is too high, loop back
        movlw   0x0F
        cpfseq  FSR0H
        bra     ok2log
        movlw   0x02
        movwf   FSR0H

ok2log:
        movff   rawPressureH, POSTINC0
        movff   rawPressureL, POSTINC0
        movff   rawTempH, POSTINC0
        movff   rawTempL, POSTINC0

        return
    endif


;************************************************************************
;   CalculatePressure - Calculate pressure in standard units
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Variable pressure[H:L] contains valid data.
;
;   Postcondition: Variable pressurehPa[H:L] is updated
;
;   ?? Calcultates pressure in hecto Pascals (hPa)
;************************************************************************
CalculatePressure:
        ; x64
        ; degCelsius = ((6500 * 2^16)/1023 * 2^6)Raw)/2^16 + 5000


        ; Coefficient = 6506.35
        ; (6506 x Raw)/2^16 + 5000

        ; Step 1:
        ; res[3:0] = rawCalculatedPressure x 0x196A

        movlw   0x19
        movwf   arg1H
        movlw   0x6A
        movwf   arg1L

        movff   pressureH, arg2H
        movff   pressureL, arg2L

        call    MulU16

        ; Step 2:
        ; res /= 2^16
        ; round

        btfss   res1, 7
        bra     cp_rounding_done

        infsnz  res2, F
        incf    res3, F
        ; will not overflow

cp_rounding_done:

        ; Step 3:
        ; res[3:2] + .5000 (0x1388)
        movlw   0x88
        addwf   res2, F

        movlw   0x13
        addwfc  res3, F
        ; will not overflow

        movff   res3, pressuredaPaH
        movff   res2, pressuredaPaL

        return


;************************************************************************
;   CalculateTemperature - Calculate temperature in standard units
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Variable rawTemp[H:L] contains valid data.
;
;   Postcondition: Variable temperature is updated.
;
;   ?? Calcultates temperature in degrees celsius
;************************************************************************
CalculateTemperature:
        ; degCelsius = (1/-5.35)Raw>>6 + 113.22430
        ; rawTemp is right shifted in the sampling routine.

        ; -0x2FDA x (Raw>>6) + 0x71396C

        ; Step 1:
        ; res[3:0] = rawTemp x 0xD026

        movlw   0xD0
        movwf   arg1H
        movlw   0x26
        movwf   arg1L

        movff   rawTempH, arg2H
        movff   rawTempL, arg2L

        call    Mul16

        ; Step 2:
        ; res[3:0] + 0x71396C
        movlw   0x6C
        addwf   res0, F

        movlw   0x39
        addwfc  res1, F

        movlw   0x71
        addwfc  res2, F

        movlw   0x00
        addwfc  res3, F
        ; will not overflow

        ; Step 4:
        ; res >> 16
        ; round
        btfss   res1, 7
        bra     ct_rounding_done

        infsnz  res2, F
        incf    res3, F
        ; will not overflow

ct_rounding_done:

        ; only one byte in current implementation
        movff   res2, temperature

        return

;*END OF CODE************************************************************
        END
