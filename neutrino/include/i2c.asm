;************************************************************************
;                                                                       *
;   Filename:       i2c.asm                                             *
;   Date:           Nov 06 2010                                         *
;   File Version:   3                                                   *
;       1   Initial Code                                Aug 21, 2008    *
;       2   datai is now an internal variable           Aug 18, 2010    *
;       3   cleanup                                     Nov 06, 2010    *
;    Author:        Peter Farkas                                        *
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
;   Description:    I2C Subroutines                                     *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"

        GLOBAL      I2cStart
        GLOBAL      I2cRestart
        GLOBAL      I2cStop
        GLOBAL      I2cTxByte
        GLOBAL      I2cRxByte


;************************************************************************
I2CCODE         CODE

;*******************Start bit subroutine**************************
;           This routine generates a Start condition
;           (high-to-low transition of SDA while SCL
;           is still high.
;*****************************************************************
I2cStart
        bcf     PIR1, SSPIF                 ; Clear SSP interrupt flag
        bsf     SSPCON2, SEN                ; Generate Start condition

        btfss   PIR1, SSPIF                 ; Check if operation completed
        bra     $ - 2                       ; If not, keep checking

        return

;*******************Restart bit subroutine**************************
;           This routine generates a Repeated Start
;           condition (high-to-low transition of SDA
;           while SCL is still high.
;*****************************************************************
I2cRestart
        bcf     PIR1, SSPIF                 ; Clear SSP interrupt flag
        bsf     SSPCON2, RSEN               ; Generate Restart condition

        btfss   PIR1, SSPIF                 ; Check if operation completed
        bra     $ - 2                       ; If not, keep checking

        return

;*******************Stop bit subroutine***************************
;           This routine generates a Stop condition
;           (low-to-high transition of SDA while SCL
;           is still high.
;*****************************************************************
I2cStop
        bcf     PIR1, SSPIF                 ; Clear SSP interrupt flag
        bsf     SSPCON2, PEN                ; Generate Stop condition

        btfss   PIR1, SSPIF                 ; Check if operation completed
        bra     $ - 2                       ; If not, keep checking

        return

;*******************Data transmit subroutine**********************
;           This routine transmits the byte of data
;           stored in 'WREG' to the serial EEPROM
;           device. Instructions are also in place
;           to check for an ACK bit, if desired.
;           Just replace the 'bra' instruction,
;           or create an 'ackfailed' label, to provide
;           the functionality.
;*****************************************************************
I2cTxByte
        bcf     PIR1, SSPIF                 ; Clear SSP interrupt flag
        movwf   SSPBUF                      ; Write byte out to device

        btfss   PIR1, SSPIF                 ; Check if operation completed
        bra     $ - 2                       ; If not, keep checking

        btfsc   SSPCON2, ACKSTAT            ; Check if ACK bit was received
        retlw   0x01                        ; Indicate NACK received

        retlw   0x00                        ; Indicate ACK received

;*******************Data receive subroutine***********************
;           This routine reads in one byte of data, and
;           stores it in WREG and datai. It then responds
;           with either an ACK or a NACK bit, depending
;           on the value of 'ACKDT' in 'SSPCON2'.
;*****************************************************************
I2cRxByte
        bcf     PIR1, SSPIF                 ; Clear SSP interrupt flag
        bsf     SSPCON2, RCEN               ; Initiate reception of byte

        btfss   PIR1, SSPIF                 ; Check if operation completed
        bra     $ - 2                       ; If not, keep checking
        movf    SSPBUF, W                   ; Copy byte to WREG
        bcf     PIR1, SSPIF                 ; Clear SSP interrupt flag
        bsf     SSPCON2, ACKEN              ; Generate ACK/NACK bit
        btfss   PIR1, SSPIF                 ; Check if operation completed
        bra     $ - 2                       ; If not, keep checking

        return                              ; return with rx byte in WREG


        END
