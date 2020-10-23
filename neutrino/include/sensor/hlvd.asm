;************************************************************************
;                                                                       *
;   Filename:       hlvd.asm                                            *
;   Date:           Nov 14 2010                                         *
;   File Version:   1                                                   *
;       1   initial code                                Jul 16, 2010    *
;       2   renamed and moved to library                Nov 14, 2010    *
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
;                   may make and analog supervisor circuit, no need     *
;                   for code                                            *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "src\settings.inc"

        GLOBAL      CheckBattery

;*******************************************************************
;HLVDVAR            udata_acs


;************************************************************************
HLVDCODE        CODE

;************************************************************************
;   CheckBattery - Check for low battery voltage
;
;   Input: None.
;
;   Output: bool, 0-nominal voltage, 1-low volyage.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   Uses onchip PLVD to detect low voltage.
;************************************************************************
CheckBattery:
        bsf     HLVDCON, HLVDEN             ; enable PLVD circuit

        bcf     PIR2, HLVDIF

        ; wait for circuit to stabalize
        btfss   HLVDCON, IRVST
        bra     $ - 2

        bcf     HLVDCON, HLVDEN             ; disable PLVD circuit

        ; now check if tripped.
        btfss   PIR2, HLVDIF
        retlw   0x00                        ; Power nominal
        retlw   0x01                        ; Power low

        END
;                  min  typ  max
;HLVDL<3:0> = 0000 1.70 1.85 2.00 V
;HLVDL<3:0> = 0001 1.80 1.95 2.10 V
;HLVDL<3:0> = 0010 1.91 2.06 2.21 V
;HLVDL<3:0> = 0011 2.02 2.17 2.32 V
;HLVDL<3:0> = 0100 2.15 2.30 2.45 V
;HLVDL<3:0> = 0101 2.22 2.37 2.52 V
;HLVDL<3:0> = 0110 2.38 2.53 2.68 V
;HLVDL<3:0> = 0111 2.46 2.61 2.76 V
;HLVDL<3:0> = 1000 2.55 2.70 2.85 V
;HLVDL<3:0> = 1001 2.65 2.80 2.95 V
;HLVDL<3:0> = 1010 2.75 2.90 3.05 V
;HLVDL<3:0> = 1011 2.87 3.02 3.17 V
;HLVDL<3:0> = 1100 2.98 3.13 3.28 V
;HLVDL<3:0> = 1101 3.26 3.41 3.56 V
;HLVDL<3:0> = 1110 3.42 3.57 3.72 V
