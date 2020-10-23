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
;   Description:    This is a rudimentery error handling feature.       *
;                   Of special note, the values are stored little endian *
;                                                                       *
;                                                                       *
;************************************************************************
; TODO: make the window variable sized

        #include    "include\processor.inc"
        #include    "src\settings.inc"
        #include    "include\error.inc"

        GLOBAL      InitWindow
        GLOBAL      AddToWindow

        GLOBAL      averageSampleH
        GLOBAL      averageSampleL


;*VAR********************************************************************
DATAVARA        udata_acs; TODO make this banked    0x130
averageSampleU      res 1                       ; used to average the sliding window
averageSampleH      res 1
averageSampleL      res 1

windowIndex         res 1

DATAVARB        udata   0x140
windowPtrH          res 1
windowPtrL          res 1

tempValueH          res 1
tempValueL          res 1

DATAVAR2        udata   0x150
slidingWindow       res SLIDING_WINDOW_SIZE * 2


;*CODE*******************************************************************
DATACODE     CODE

;************************************************************************
;   InitWindow - Initilize sliding window
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: Variable averageSample[H:L] contains valid data.
;
;   Postcondition: Every element of the sliding window contains the value
;   in averageSample[H:L].
;
;   ??
;************************************************************************
InitWindow:
        ; setup slideing window
        clrf    averageSampleU

        movff   POSTINC2, averageSampleH
        movff   POSTINC2, averageSampleL

        movlw   SLIDING_WINDOW_SIZE
        movwf   windowIndex

        movlw   HIGH slidingWindow
        movwf   FSR2H
        movwf   windowPtrH, BANKED          ; initialize window pointer (MSB)

        movlw   LOW slidingWindow
        movwf   FSR2L
        movwf   windowPtrL, BANKED          ; initialize window pointer (LSB)

iw_set:
        movff   averageSampleL, POSTINC2
        movff   averageSampleH, POSTINC2
        decfsz  windowIndex, F
        bra     iw_set

        return


;************************************************************************
;   AddToWindow - Add element to sliding window
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: FSR2 points to element.
;
;   Postcondition: The sliding window is updated to contain the new
;   element.
;
;   ??
;************************************************************************
AddToWindow:
        movff   POSTINC2, tempValueH
        movff   POSTINC2, tempValueL

        ; setup pointer
        movff   windowPtrH, FSR2H           ; put pointer into FSR2
        movff   windowPtrL, FSR2L           ; put pointer into FSR2

        ; copy value
        movff   tempValueL, POSTINC2        ; copy new sample to sliding window
        movff   tempValueH, POSTINC2        ; copy new sample to sliding window

        ; test if buffer pointer needs to wrap around to beginning of buffer memory
        movlw   HIGH (slidingWindow+SLIDING_WINDOW_SIZE*2)  ; get last address of buffer
        cpfseq  FSR2H                       ; and compare with end pointer
        bra     atw_update_ptr              ; skip low bytes if high bytes not equal
        movlw   LOW (slidingWindow+SLIDING_WINDOW_SIZE*2)   ; get last address of buffer
        cpfseq  FSR2L                       ; and compare with end pointer
        bra     atw_update_ptr              ; go save new pointer if not at end
        lfsr    FSR2, slidingWindow         ; point to beginning of buffer if at end

atw_update_ptr:
        movff   FSR2H, windowPtrH           ; save new EndPointer high byte
        movff   FSR2L, windowPtrL           ; save new EndPointer low byte

        ; done adding, now average
        rcall   AverageWindow               ; INGENIOUS: might be faster to just find the difference between the added value and the old value, divide by size and add that to the average

        return


;** Static ??

;************************************************************************
;   static AverageWindow - Average all the elements in the sliding window
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: averageSample[U:L] contains the average of all of the
;   elements contained in the sliding window.
;
;   ??
;************************************************************************
AverageWindow:
        ; average window

        ; avg = 0
        clrf    averageSampleL
        clrf    averageSampleH
        clrf    averageSampleU

        movlw   SLIDING_WINDOW_SIZE
        movwf   windowIndex

        lfsr    FSR2, slidingWindow         ; point to beginning of window

        ; do {
        ;   avg += *sample++
        ; } while( --windowIndex > 0 );
aw_add:
        ; avg += sample
        movf    POSTINC2, W
        addwf   averageSampleL, F

        movf    POSTINC2, W
        addwfc  averageSampleH, F

        clrf    WREG
        addwfc  averageSampleU, F

        decfsz  windowIndex, F
        bra     aw_add


        ; avg /= LOG_SLIDING_WINDOW_SIZE

        movlw   LOG_SLIDING_WINDOW_SIZE
        movwf   windowIndex

aw_div:
        ; avg >> 1
        bcf     STATUS, C                               ; make sure carry flag is 0
        rrcf    averageSampleU, F
        rrcf    averageSampleH, F
        rrcf    averageSampleL, F

        decfsz  windowIndex, F
        bra     aw_div

        ; round properly
        btfss   STATUS, C                           ; decfsz does not affect any status bits, so this is a valid check
        return

        incfsz  averageSampleL, F
        return
        incfsz  averageSampleH, F
        return
        incf    averageSampleU, F

        ; Error
        movlw   SAMPLE_AVG_ERR
        movwf   errorBCD0, BANKED                   ; error code
        movlw   .1                                  ; number of digits
        goto    ErrorHandler


        END
