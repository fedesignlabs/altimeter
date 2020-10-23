;************************************************************************
;                                                                       *
;   Filename:       fsm.asm                                             *
;   Date:           May 12 2010                                         *
;   File Version:   1                                                   *
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
;   Description:    Finite State Machine                                *
;                                                                       *
;                                                                       *
;************************************************************************

        #include    "include\processor.inc"
        #include    "settings.inc"
        #include    "include\util\timer.inc"
        #include    "include\util\delay_time.inc"
        #include    "include\util\delay_short.inc"
        #include    "include\error.inc"
        #include    "include\button.inc"
        #include    "include\actuator\buzzer.inc"
        #include    "include\sensor\mpl115a2.inc"
        #include    "include\dataProcessing.inc"
        #include    "include\math\math.inc"
        #include    "fsm.inc"

        GLOBAL      StateTest

        EXTERN      StateMachine
        EXTERN      WaitButtonRelease


;************************************************************************
TSTVAR              udata_acs

tempPressureH       res 1
tempPressureL       res 1

TSTCODE     CODE
;*******************************************************************
;   StateX: Test
;
;   Description: Tracks the rocket throughout its flight
;
;*******************************************************************
StateTest:

sT_check_button:
        ; Check button press
        call    CheckButton
        btfss   WREG, 0
        bra     sT_button_done

        ; wait for button to be released before continuing
        call    WaitButtonRelease

sT_button_pressed:

        ; turn off unused hardware
        call    ShutdownMpl115a2                    ; turn off pressure sensor
        call    StopTimer                           ; Stop Timer

        bcf     OSCCON, IDLEN                       ; IDLE mode on sleep, disabled

        ; setup state variable
        movlw   STATE_IDLE
        movwf   state

        goto    StateMachine

sT_button_done:

sT_check_pressure:
        ; sample pressure sensor
        call    SamplePressure

        ; update sliding window
        lfsr    FSR2, pressureH
        call    AddToWindow

sT_check_pressure_done:

sT_pressure_change:
        ; // look for pressure change.  If there is none
        ; // for longer than Xs then changed to grounded
        ; // state.
        ; if (avg < x-Delta) || (avg > x+Delta) then            //if the average changes by more then Delta
        ;   x = avg;                                            //save the new average
        ;   time = 0;                                           //kick the watch dog
        ; else
        ;   time++;                                             //increment the watch dog
        ;   if(time == Xs) then                                 //check for watch dog timeout
        ;       state = grounded                                //change state
        ;   end if
        ; end if

        ; if (avg < x-1 or avg > x+1) then
sT_pressure_change_check_lower:
        ; if (avg < x - 1) then
        ; a = avg pressure
        movff   averageSampleH, ACa1
        movff   averageSampleL, ACa0

        ; b = x
        movff   tempPressureH, ACb1
        movff   tempPressureL, ACb0

        ; b = b - FLIGHT_DELTA
        movlw   LOW (TEST_DELTA)                    ; FLIGHT_DELTA_L
        subwf   ACb0, F
        movlw   HIGH (TEST_DELTA)                 ; FLIGHT_DELTA_H
        subwfb  ACb1, F                             ; dest = dest - FLIGHT_DELTA

        ; compare, unsigned compare will not cause issues
        call    CompareU16                          ; return 0 = equal, 1 = a < b, -1 = a > b
        decfsz  WREG, F                             ; skip if avg < x - 1
        bra     sT_pressure_change_check_higher

        call    ShortBeep

        bra     sT_pressure_changed

sT_pressure_change_check_higher:
        ; a = avg pressure
        movff   averageSampleH, ACa1                ; TODO: may not need if ACa is not modified
        movff   averageSampleL, ACa0

        ; b = x
        movff   tempPressureH, ACb1
        movff   tempPressureL, ACb0

        ; b = b + FLIGHT_DELTA
        movlw   LOW (TEST_DELTA)                    ; FLIGHT_DELTA_L
        addwf   ACb0, F
        movlw   HIGH (TEST_DELTA)                 ; FLIGHT_DELTA_H
        addwfc  ACb1, F                             ; b = b + FLIGHT_DELTA

        ; compare, unsigned compare will not cause issues
        call    CompareU16                          ; return 0 = equal, 1 = a < b, -1 = a > b
        incfsz  WREG, F                             ; skip if avg > x + 1
        bra     sT_pressure_change_endif

        call    LongBeep

sT_pressure_changed:
        ;   x = avg;
        movff   averageSampleH, tempPressureH
        movff   averageSampleL, tempPressureL

sT_pressure_change_endif:

        goto    StateMachine


;TESTAPP:
;
;        incf    pressureH, F
;        incf    pressureL, F
;
;        ; update sliding window
;        lfsr    FSR2, pressureH
;        call    AddToWindow
;
;        bra     TESTAPP

        END
