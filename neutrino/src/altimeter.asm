;************************************************************************
;                                                                       *
;   Filename:       battery.asm                                         *
;   Date:           July 16 2010                                        *
;   File Version:   1                                                   *
;       1   initial code                                Jul 16, 2010    *
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
;   Description:    battery monitor                                     *
;                                                                       *
;                                                                       *
;************************************************************************
; TODO: do conversion from pressure to altitude in here, have pressure, p*2, p*4, ... optional inputs.
        #include    "include\processor.inc"
        #include    "settings.inc"
        #include    "options.inc"
        #include    "include\math\math.inc"
        #include    "include\math\bcd.inc"
        #include    "include\actuator\buzzer.inc"

        ; Global
        ; functions
        GLOBAL      SaveAltitudeToEEPROM
        GLOBAL      CalculateAltitudeReached
        GLOBAL      RetrieveMaxAltitude

        GLOBAL      BeepOutAltitude
        GLOBAL      BeepOutPressure
        GLOBAL      BeepOutTemperature

        GLOBAL      ConvertAltitudeToBCD
        GLOBAL      ConvertPressureToBCD
        GLOBAL      ConvertTemperatureToBCD

        ; options
        ;  variables
        EXTERN      options

        ; mp3h6115a/mpl115a2
        ;  functions
        EXTERN      CalcAltitude

        ;  variables
        EXTERN      pressureH
        EXTERN      pressureL
        EXTERN      pressuredaPaH
        EXTERN      pressuredaPaL
        EXTERN      temperature
        EXTERN      altitudeMeterH
        EXTERN      altitudeMeterL

        ; fsm
        ;  variables
        EXTERN      launchPressureH
        EXTERN      launchPressureL
        EXTERN      tempMinPressureH
        EXTERN      tempMinPressureL
        EXTERN      maxAltitudeH
        EXTERN      maxAltitudeL

        ; eeprom
        EXTERN      EepromWrite
        EXTERN      eeAddr

;*******************************************************************
ALTIMETERVAR    udata_acs
numOfWrites     res 1

altitudeFeetH   res 1
altitudeFeetL   res 1

ALTIMETERVARB   udata   0x110
altitudeBCD4    res 1                   ; binary coded decimal, ten thousands
altitudeBCD3    res 1                   ; binary coded decimal, thousands
altitudeBCD2    res 1                   ; binary coded decimal, hundreds
altitudeBCD1    res 1                   ; binary coded decimal, tens
altitudeBCD0    res 1                   ; binary coded decimal, ones

pressureBCD4    res 1                   ; pressure in dPa
pressureBCD3    res 1
pressureBCD2    res 1
pressureBCD1    res 1
pressureBCD0    res 1

celsiusSign     res 1                   ; temperature in degrees celsius
celsiusBCD2     res 1
celsiusBCD1     res 1
celsiusBCD0     res 1

;************************************************************************
ALTMCODE        CODE

BeepOutAltitude:

        btfss   options, OP_METRIC
        bra     boa_feet

boa_meters:
        ; if meters
        lfsr    FSR2, altitudeBCD3              ; pointer to MS digit
        movlw   .4                              ; number of digits
        bra     boa_beepout

boa_feet:
        ; if feet
        lfsr    FSR2, altitudeBCD4              ; pointer to MS digit
        movlw   .5                              ; number of digits

boa_beepout:
        call    UnsignedBeepOut

        return


BeepOutPressure:
        ; get altitude in bcd
        lfsr    FSR2, pressureBCD4              ; pointer to MS digit or sign if signed
        movlw   .5                              ; number of digits

        call    UnsignedBeepOut
        return


BeepOutTemperature:
        ; get altitude in bcd
        lfsr    FSR2, celsiusSign               ; pointer to MS digit or sign if signed
        movlw   .3                              ; number of digits

        call    SignedBeepOut
        return


; ConvertAltitudeToBCD
; ?
ConvertAltitudeToBCD:

        btfss   options, OP_METRIC              ; skip if units = meters
        rcall   ConvertToFeet                   ; convert to feet otherwise

        movf    altitudeMeterH, W
        btfss   options, OP_METRIC
        movf    altitudeFeetH, W
        movwf   num1

        movf    altitudeMeterL, W
        btfss   options, OP_METRIC
        movf    altitudeFeetL, W
        movwf   num0

        call    ConvertU2BtoBCD

        movff   tenK, altitudeBCD4
        movff   thou, altitudeBCD3
        movff   hund, altitudeBCD2
        movff   tens, altitudeBCD1
        movff   ones, altitudeBCD0

        return

; Accurate short delays
; These use timer1 to create an accurate delay
ConvertPressureToBCD:
        movf    pressuredaPaH, W
        movwf   num1

        movf    pressuredaPaL, W
        movwf   num0

        call    ConvertU2BtoBCD

        movff   tenK, pressureBCD4
        movff   thou, pressureBCD3
        movff   hund, pressureBCD2
        movff   tens, pressureBCD1
        movff   ones, pressureBCD0

        return


; Accurate short delays
; These use timer1 to create an accurate delay
ConvertTemperatureToBCD:
        movf    temperature, W
        movwf   num0

        call    Convert1BtoBCD

        movff   sign, celsiusSign
        movff   hund, celsiusBCD2
        movff   tens, celsiusBCD1
        movff   ones, celsiusBCD0

        return


;************************************************************************
;   CalculateAltitudeReached - Calculate altitude reached
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: tempMinPressure and launchPressure contain valid data.
;
;   Postcondition: Variables maxAltitude and altitudeMeter are updated.
;
;   Calculates the altitude reached by subtracting the launch altitude in
;   meters from the maximum altitude reached in meters.
;************************************************************************
CalculateAltitudeReached:
        ; Update the max altitude values
        movff   tempMinPressureH, pressureH
        movff   tempMinPressureL, pressureL

        ; update altitudeMeter
        call    CalcAltitude                        ; Altitude registers are updated

        movff   altitudeMeterH, maxAltitudeH
        movff   altitudeMeterL, maxAltitudeL

        movff   launchPressureH, pressureH
        movff   launchPressureL, pressureL

        ; update altitudeMeter
        call    CalcAltitude                        ; Altitude registers are updated

        ; maxAltitude - launchAltitude
        ; 16 bit subtraction
        movf    altitudeMeterL, W
        subwf   maxAltitudeL, F
        movf    altitudeMeterH, W
        btfss   STATUS, C
        incfsz  altitudeMeterH, W
        subwf   maxAltitudeH                        ; b = b - a, WITH VALID CARRY

        movff   maxAltitudeH, altitudeMeterH
        movff   maxAltitudeL, altitudeMeterL

        return


RetrieveMaxAltitude:
        ; read last altitude data from nvm

        ; EEPROM Memory Address to read
        clrf    EECON1                      ; Point to DATA memory, Access EEPROM
        movlw   0x00                        ; Start Addr <= EEADR + 1
        movwf   EEADR

check_next_ee_addr:
        incf    EEADR, F

        bsf     EECON1, RD                  ; EEPROM Read

        infsnz  EEDATA, W                   ; W = EEDATA + 1
        bra     check_next_ee_addr          ; if W = 0, then the bytes are used up.

        ; pointing to right location
        movff   EEADR, eeAddr           ; save location for future writes to eeprom
        movff   EEDATA, numOfWrites         ; save the number of writes at that location

        incf    EEADR, F                    ; point to altitudeMeterH

        bsf     EECON1, RD                  ; EEPROM Read
        movff   EEDATA, altitudeMeterH      ; altitudeMeterH <= EEDATA

        incf    EEADR, F                    ; point to altitudeMeterL

        bsf     EECON1, RD                  ; EEPROM Read
        movff   EEDATA, altitudeMeterL      ; altitudeMeterL <= EEDATA

        call    ConvertAltitudeToBCD

        return


; save the altitude registers in eeprom
; input: boolean updateCounter
SaveAltitudeToEEPROM:
        movff   eeAddr, EEADR
        btfss   WREG, 0                     ; check if TRUE, do we need to update the counter value
        bra     sate_msb                    ; if false skip count update

        incf    numOfWrites, F
        movff   numOfWrites, EEDATA         ; set data to write

        movlw   b'00000100'                 ; Point to DATA memory, Access EEPROM, Enable writes                    ; EECON1 EEPGD CFGS — FREE WRERR WREN WR RD
        movwf   EECON1

        call    EepromWrite

        ; check if 0xFF was just written if so increment the pointer and start again.
        incfsz  numOfWrites, W
        bra     sate_msb                    ; not equal to zero

        clrf    numOfWrites

        ; switch to next byte
        incf    eeAddr, F                ; increment eeprom pointer
        incf    EEADR, F

        ; if ( eeAddr == 0xFE ) {
        ;   eeAddr = 0x01
        ; }
        movlw   0xFE
        cpfseq  eeAddr
        bra     sate_inc

        ; reset eeprom pointer
        movlw   0x01
        movwf   eeAddr
        movwf   EEADR

sate_inc:
        clrf    EEDATA
        call    EepromWrite

sate_msb:
        ; just incase it wasn't set due to input being false
        movlw   b'00000100'                 ; Point to DATA memory, Access EEPROM, Enable writes                    ; EECON1 EEPGD CFGS — FREE WRERR WREN WR RD
        movwf   EECON1

        ; Write altitudeMeterH
        incf    EEADR, F
        movff   altitudeMeterH, EEDATA      ; set data to write

        call    EepromWrite

        ; Write altitudeMeterL
        incf    EEADR, F
        movff   altitudeMeterL, EEDATA      ; set data to write

        call    EepromWrite

        bcf     EECON1, WREN                ; Disable writes on write complete


        return

; static void ConvertToFeet()
;   altitude[H:L]
;   altitudeFeet[H:L]
;
ConvertToFeet:
        ; convert to feet
        movlw   0x1A
        movwf   arg1H
        movlw   0x3F
        movwf   arg1L

        movff   altitudeMeterH, arg2H
        movff   altitudeMeterL, arg2L

        call    Mul16

        ; convert to exact feet integer
        ; res >> 11, drop LSB and >> 3
        rrcf    res3, F
        rrcf    res2, F
        rrcf    res1, F
        rrcf    res3, F
        rrcf    res2, F
        rrcf    res1, F
        rrcf    res3, F
        rrcf    res2, F
        rrcf    res1, F

        ; res3 is discarded so no need to clean up

        btfss   STATUS, C                   ; if C is set then round up
        bra     done_conv_altitude

        incfsz  res1, F
        bra     done_conv_altitude

        incf    res2, F

done_conv_altitude:
        movff   res2, altitudeFeetH
        movff   res1, altitudeFeetL

        return


        END
