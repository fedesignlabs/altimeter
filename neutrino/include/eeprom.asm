;************************************************************************
;                                                                       *
;   Filename:       eeprom.asm                                          *
;   Date:           May 20 2010                                         *
;   File Version:   0.2                                                 *
;                                                                       *
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
;   Description:                                                        *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"

        ; Global Functions
        GLOBAL      EepromWriteByte
        GLOBAL      EepromReadByte

        GLOBAL      EepromEnableWrite
        GLOBAL      EeepromDisableWrite
        GLOBAL      EepromWrite

        ; Global Variables
    ifdef EEADRH
        GLOBAL      eeAddrH
    endif
        GLOBAL      eeAddr


;*******************************************************************
EEPROMVAR       udata_acs
    ifdef EEADRH
eeAddrH         res 1                       ; MS Address Byte
    endif
eeAddr          res 1                       ; LS Address Byte

;                access_ovr
eeData          res 1                       ; Data byte for read or write           * CONFIRMED

;************************************************************************
EEPROMCODE      CODE

; TODO: expand on these
EepromEnableWrite:
        movlw   b'00000100'                 ; Point to DATA memory, Access EEPROM, Enable writes                    ; EECON1 EEPGD CFGS — FREE WRERR WREN WR RD
        movwf   EECON1

        return

EeepromDisableWrite:
        bcf     EECON1, WREN                ; Disable writes on write complete

        return

; void EepromWriteByte(data)

EepromWriteByte:
        movwf   eeData

    ifdef EEADRH
        movff   eeAddrH, EEADRH             ; set address
    endif
        movff   eeAddr, EEADR

        movff   eeData, EEDATA              ; set data to write

        movlw   b'00000100'                 ; Point to DATA memory, Access EEPROM, Enable writes                    ; EECON1 EEPGD CFGS — FREE WRERR WREN WR RD
        movwf   EECON1

        bcf     INTCON, GIE                 ; Disable Interrupts

        movlw   0x55                        ; Unlock
        movwf   EECON2
        movlw   0xAA
        movwf   EECON2

        bsf     EECON1, WR                  ; Start the write
        bsf     INTCON, GIE                 ; Enable Interrupts

        btfsc   EECON1, WR                  ; Wait
        bra     $ - 2

        bcf     EECON1, WREN                ; Disable writes on write complete

        return

; setup and postprocessing done else where.  This just writes the byte in EEDATA to the address pointed to by EEADR
EepromWrite:
        bcf     INTCON, GIE                 ; Disable Interrupts

        movlw   0x55                        ; Unlock
        movwf   EECON2
        movlw   0xAA
        movwf   EECON2

        bsf     EECON1, WR                  ; Start the write
        bsf     INTCON, GIE                 ; Enable Interrupts

        btfsc   EECON1, WR                  ; Wait
        bra     $ - 2

        return

; byte EepromReadByte()

EepromReadByte:

    ifdef EEADRH
        movff   eeAddrH, EEADRH             ; set address
    endif
        movff   eeAddr, EEADR

        bsf     EECON1, RD                  ; EEPROM Read

        movf    EEDATA, W

        return

        END
