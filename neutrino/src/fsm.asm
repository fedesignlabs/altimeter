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
        #include    "options.inc"
        #include    "include\util\timer.inc"
        #include    "include\util\delay_time.inc"
        #include    "include\util\delay_short.inc"
        #include    "include\error.inc"
        #include    "include\button.inc"
        #include    "include\actuator\buzzer.inc"
        #include    "include\sensor\mpl115a2.inc"
        #include    "include\dataProcessing.inc"
        #include    "include\typedef.inc"

        ; Global
        ; functions
        GLOBAL      StateMachine
        GLOBAL      InitFsm
        GLOBAL      StateUnitSelect

        ; variables
        GLOBAL      state
        GLOBAL      tempMinPressureH
        GLOBAL      tempMinPressureL
        GLOBAL      launchPressureH
        GLOBAL      launchPressureL
        GLOBAL      maxAltitudeH
        GLOBAL      maxAltitudeL

        ; External
        ; options
        ;  variables
        EXTERN      options

        ; math
        ;  functions
        EXTERN      CompareU16

        ;  variables
        EXTERN      ACa1
        EXTERN      ACa0
        EXTERN      ACb1
        EXTERN      ACb0

        ; battery
        ;  functions
        EXTERN      CheckBattery

        ; altimeter
        ;  functions
        EXTERN      BeepOutAltitude
        EXTERN      ConvertAltitudeToBCD
        EXTERN      BeepOutPressure
        EXTERN      ConvertPressureToBCD
        EXTERN      BeepOutTemperature
        EXTERN      ConvertTemperatureToBCD
        EXTERN      SaveAltitudeToEEPROM
        EXTERN      CalculateAltitudeReached


        ; eeprom
        EXTERN      EepromWrite

                ; DBG: hack
                GLOBAL  WaitButtonRelease
                EXTERN  StateTest

;******************************************************************************
;Bit Definitions for state flag
;TODO: this needs to be fixed, only fsm.inc should contain these defines

STATE_IDLE          EQU     .0
STATE_LAUNCH        EQU     .1
STATE_FLIGHT        EQU     .2

STATE_GROUNDED      EQU     .5
STATE_BEACON        EQU     .6
STATE_SLEEP         EQU     .7

STATE_UNIT_SELECT   EQU     .8

STATE_TEST          EQU     .9

;******************************************************************************
;Bit Definitions for flightStatus flag

NEW_MAX_ALT         EQU     .0                  ; indicates that a new max altitude reached
ALTITUDE_SAVED      EQU     .1                  ; indicates that an altitude has been saved to eeprom


;************************************************************************
FSMVAR              udata_acs
    ; common
state               res 1                       ; uint8; keeps track of the next state in the FSM

    ; ButtonPressed
tempTime            res 1
selections          res 1                       ; uint8; number of selections available
option              res 1                       ; uint8; selection chosen
limitedSelections   res 1                       ; bool; signal an end of options if true TODO: could put this into an FSM flags

    ; ?
counterH            res 1                       ; uint16 (B1); flight counter
counterL            res 1                       ; uint16 (B0);

counter             res 1                       ; free flight sub-state counter, rocket flight time since apogee counter
flightStatus        res 1                       ; rocket flight mode max altitude write, free flight new sample indicator

launchPressureH     res 1                       ; uint16 (B1); saved before entering launch mode.  Raw sensor data
launchPressureL     res 1                       ; uint16 (B0);

tempMinPressureH    res 1
tempMinPressureL    res 1
maxAltitudeH        res 1                       ; holds the maximum altitude reached
maxAltitudeL        res 1

launchTimeoutH      res 1                       ; has its own variables because it can be changed in settings, otherwise could just use literals
launchTimeoutL      res 1

stateTimeoutH       res 1                       ; s2, s5, s9, t2ff; used in free flight and grounded
stateTimeoutL       res 1

;FSMOVR             access_ovr
tempAltitudeH       res 1                       ; s0, shadow registers.  Used in mode3, for checking the
tempAltitudeL       res 1                       ;  altitude without modifying the max altitude value

tempIndex           res 1                       ; temporary index variable

FSMOVR              access_ovr
tempPressureH       res 1                       ; s1, s2
tempPressureL       res 1

FSMOVR              access_ovr
oldOptions          res 1


;************************************************************************
FSMCODE         CODE

;************************************************************************
;   InitFsm - Initialize the finite state machine
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: State machine is initialized to IDLE.  Settings flags
;   setup.
;
;   Initializes the finite state machine.
;************************************************************************
InitFsm:
        movlw   STATE_IDLE
        movwf   state

        ; do not limit length of long button press
        clrf    limitedSelections

        ; set time out registers
        movlw   LAUNCH_TIMEOUT_H                        ; TODO: later get a value from eeprom, can be modified from settings mode
        movwf   launchTimeoutH
        movlw   LAUNCH_TIMEOUT_L
        movwf   launchTimeoutL

        return


;************************************************************************
;   static StateMachine - State machine
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: The state variable contains the next state.
;
;   Postcondition: Control jumps to the selected state.
;
;   Sleeps until an event occurs, in this case a button press or more
;   likely a timer interrupt.  Then control jumps to the next state.
;   This function is never called, it is jumped to.
;************************************************************************
StateMachine:

        ; sleep until an event occurs
        bsf     INTCON, RBIE                        ; Enable port b interrupt-on-change flag
        sleep
        bcf     INTCON, RBIE                        ; Disable port b interrupt-on-change flag

        ; jump to the next state
        movlw   STATE_IDLE
        cpfsgt  state
        bra     StateIdle

        movlw   STATE_LAUNCH
        cpfsgt  state
        bra     StateLaunch

        movlw   STATE_FLIGHT
        cpfsgt  state
        bra     StateFlight

        movlw   STATE_GROUNDED
        cpfsgt  state
        bra     StateGrounded

        movlw   STATE_BEACON
        cpfsgt  state
        bra     StateBeacon

        movlw   STATE_SLEEP
        cpfsgt  state
        bra     StateSleep

        movlw   STATE_UNIT_SELECT
        cpfsgt  state
        bra     StateUnitSelect

        movlw   STATE_TEST
        cpfsgt  state
        goto    StateTest


        ; Unknown State - fatal error
        movlw   INVALID_STATE_ERR
        movwf   errorBCD0, BANKED                   ; error code
        movlw   .1                                  ; number of digits
        goto    ErrorHandler


;************************************************************************
;   static StateIdle - State0: Idle
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   Starts by reseting the timer, and enabling idle mode so that the
;   timer will continue to run in sleep mode.  It then checks to see if
;   the battery is low, in which case it limits the user to only be able
;   to get an altitude read out.  It then handles button presses.
;   Finally if there will be no state change it disables idle mode to
;   conserve power.
;************************************************************************
StateIdle:

        ; reset timer and enable idle mode to keep timer running.
        call    ResetTimer
        bsf     OSCCON, IDLEN                       ; IDLE mode on sleep, to keep timer running

        ; check battery level
s0_check_battery:
        call    CheckBattery
        btfss   WREG, 0
        bra     s0_check_button

        ; battery is low
s0_battery_low:
        ; since battery is too low to turn on the sensor, only allow beep outs
        call    CheckButton
        btfss   WREG, 0
        bra     s0_button_done

        ; wait for button to be released before continuing
        rcall   WaitButtonRelease
        bra     s0_option_0
s0_check_battery_done:

        ; handle button press
s0_check_button:
        ; check if button is pressed
        call    CheckButton
        btfss   WREG, 0

        ; button was not pressed
        bra     s0_button_done

        ; button is pressed, get a selection from the user
    ifdef DEVELOPER_LOAD
        movlw   .7
    else
        movlw   .2
    endif
        rcall   ButtonPressed

        ; jump to selection handler
        movlw   0x00
        cpfsgt  option
        bra     s0_option_0

        movlw   0x01
        cpfsgt  option
        bra     s0_option_1

        movlw   0x02
        cpfsgt  option
        bra     s0_option_2

        movlw   0x03
        cpfsgt  option
        bra     s0_option_3

        movlw   0x04
        cpfsgt  option
        bra     s0_option_4

        movlw   0x05
        cpfsgt  option
        bra     s0_option_5

        movlw   0x06
        cpfsgt  option
        bra     s0_option_6

        bra     s0_button_done                      ; invalid option, ignore button press

        ; short button press
s0_option_0:
        ; beep out max altitude for the last rocket flight
        call    BeepOutAltitude

        bra     s0_button_done

        ; long x1 duration press
s0_option_1:
        ; transition to launch
        bra     TransToLaunch

        ; long x2 duration press
s0_option_2:
        ; beep out current pressure

        ; wait a bit of time since the state has been beeped out
        movlw   DELAY_500ms
        call    Delay

        ; Get a single sample from the pressure sensor
        call    SingleSamplePressure

        ; Calculate altitude
        call    CalculatePressure

        ; Update BCD altitude
        call    ConvertPressureToBCD

        ;  beep out altitude
        call    BeepOutPressure

        bra     s0_button_done

        ; long x3 duration press
s0_option_3:
        ; beep out current altitude

        ; wait a bit of time since the state has been beeped out
        movlw   DELAY_500ms
        call    Delay

        ; save the current altitude
        movff   altitudeMeterH, tempAltitudeH
        movff   altitudeMeterL, tempAltitudeL

        ; Get a single sample from the pressure sensor
        call    SingleSamplePressure

        ; Calculate altitude
        call    CalcAltitude

        ; Update BCD altitude
        call    ConvertAltitudeToBCD

        ;  beep out altitude
        call    BeepOutAltitude

        ; replace the old altitude
        movff   tempAltitudeH, altitudeMeterH
        movff   tempAltitudeL, altitudeMeterL

        ; Update BCD altitude
        call    ConvertAltitudeToBCD

        bra     s0_button_done

        ; long x4 duration press
s0_option_4:
        ; beep out current temperature

        ; wait a bit of time since the state has been beeped out
        movlw   DELAY_500ms
        call    Delay

        ; Get a single sample from the pressure sensor
        call    SingleSamplePressure

        ; Calculate altitude
        call    CalculateTemperature

        ; Update BCD altitude
        call    ConvertTemperatureToBCD

        ;  beep out altitude
        call    BeepOutTemperature

        bra     s0_button_done

        ; long x5 duration press
s0_option_5:
        ; beep out every thing

        ; Make sure pressure sensor is on
        call    PowerMpl115a2                       ; turn on pressure sensor, needs 20ms before it can be sampled properly

        movlw   DELAY_20ms
        call    Delay

        ; Sample pressure sensor, and update launch pressure
        call    SamplePressure

        ; setup slideing window
        lfsr    FSR2, pressureH
        call    InitWindow

        movlw   STATE_TEST
        movwf   state

        bra     StateMachine

        ; long x6 duration press
s0_option_6:
        ; change altitude output units
        ; beep out the current selection: - meter, --- feet

        ; delay so that the beeps are not too close together
        movlw   DELAY_500ms
        call    Delay

        ; toggle the selection
        btg     options, OP_METRIC

        ; output the current selection
        btfss   options, OP_METRIC
        bra     s0_op6_feet

        call    ShortBeep               ; indicate that it is meters

        bra     s0_button_done

s0_op6_feet:
        call    LongBeep                ; indicate that it is feet

        bra     s0_button_done

s0_button_done:

        bcf     OSCCON, IDLEN                       ; SLEEP mode on sleep, to reduce power

        bra     StateMachine


;************************************************************************
;   static StateLaunch - State1: Launch
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   Starts by checking to see if the battery is low, in which case it
;   will exit to the idle state.  It then checks to see if the button is
;   pressed, if so it either exits to idle state, or reenters launch
;   state.  It will then sample the pressure sensor and add the sample to
;   the sliding window.  It then checks for a launch, if found it will
;   setup variables for the flight state.  If not launch is detected it
;   will check to see if a timeout has occured, in which case it will
;   exit to the idle state.  While in the state it will continuously beep
;   every 2.56 seconds to indicate that it is in launch mode.
;************************************************************************
StateLaunch:

s1_check_battery:
        call    CheckBattery
        btfss   WREG, 0
        bra     s1_check_button

s1_battery_low:
        ; since battery is too low to turn on the sensor, exit to idle mode.
        call    DeactivateBuzzer                    ; no longer in rocket flight mode

        call    LongBeep
        call    ShortBeep
        call    LongBeep

        bra     TransToIdle

s1_check_button:
        ; Check button press
        call    CheckButton
        btfss   WREG, 0
        bra     s1_button_done

        movlw   .2
        rcall   ButtonPressed
        btfsc   option, 7                           ; check if it was an invalid option
        bra     s1_button_done                      ; if so, ignore button press

        btfss   option, 0                           ; Check if long or short press
        bra     s1_short_press
        bra     s1_long_press

s1_short_press:
        ; if short duration press, exiting before launch
        call    DeactivateBuzzer                    ; no longer in rocket flight mode

        ; send a signal to notify no altitude recorded
        call    LongBeep
        call    ShortBeep
        call    LongBeep

        bra     TransToIdle

s1_long_press:
        ; if long duration press
        call    DeactivateBuzzer                    ; no longer in rocket flight mode

        bra     TransToLaunch

s1_button_done:

s1_get_pressure:
        ; sample pressure sensor
        call    SamplePressure

        ; update sliding window
        lfsr    FSR2, pressureH
        call    AddToWindow

s1_get_pressure_done:

s1_launch_detection:
        ; TODO: update launch pressure maybe.

        ; if (pressure < launchPressure - X)
        ;   launchDetected()
        ; endif

        ; a = pressure
        movff   averageSampleH, ACa1
        movff   averageSampleL, ACa0

        ; b = launchPressure
        movff   launchPressureH, ACb1
        movff   launchPressureL, ACb0

        ; b -= LAUNCH_SENSITIVITY
        movlw   LOW (LAUNCH_SENSITIVITY)            ; LSB of LAUNCH_SENSITIVITY
        subwf   ACb0, F
        movlw   HIGH (LAUNCH_SENSITIVITY)           ; MSB of LAUNCH_SENSITIVITY
        subwfb  ACb1, F                             ; subtract

        ; if (a < b) launch detected
        call    CompareU16                          ; return 0 = equal, 1 = a < b, -1 = a > b
        decfsz  WREG, F                             ; skip if raw < launchPressureL - 1
        bra     s1_launch_not_detected

s1_launch_detected:
        ; start transition to flight mode
        call    DeactivateBuzzer                    ; turn off launch mode buzzer output

        movff   pressureH, tempMinPressureH
        movff   pressureL, tempMinPressureL

        movff   pressureH, tempPressureH
        movff   pressureL, tempPressureL

        ; initialize counter
        clrf    counter

        movlw   STATE_FLIGHT
        movwf   state

        bra     StateMachine

        ; end if

s1_launch_not_detected:

s1_timeout_check:
        ; check for timeout
        ; if (time > timeout) then
        ;  longBeep         ; to notify user of exit from launch mode
        ;  state = idle
        ; end if

        ; if (time == timeout)
        movf    launchTimeoutH, W
        cpfseq  time_B2
        bra     s1_timeout_done                     ; timeoutH is not equal to time_B2

        movf    launchTimeoutL, W
        cpfseq  time_B1
        bra     s1_timeout_done                     ; timeoutL is not equal to time_B1

        ; timed out
        call    DeactivateBuzzer                    ; no longer in rocket flight mode

        ; notify user of timeout
        call    LongBeep
        call    ShortBeep
        call    LongBeep

        bra     TransToIdle                         ; Return to idle

s1_timeout_done:

s1_buzzer:
        ; beep every 2.56 seconds, buzzer is on for 80ms

        ; if (time_B0 == 0x00) then
        ;   buzzerOn
        ; else
        ;   if (time_B0 == 0x08) then
        ;     buzzerOff
        ;   end if
        ; end if

s1_buzzer_on:
        tstfsz  time_B0
        bra     s1_buzzer_off

        ; time to turn on
        call    ActivateBuzzer2kHz                  ; turn on buzzer
        bra     s1_buzzer_done

s1_buzzer_off:
        movlw   LAUNCH_BEEP_DUTY_CYCLE
        cpfseq  time_B0
        bra     s1_buzzer_done

        ; time to turn off
        call    DeactivateBuzzer                    ; turn off buzzer

s1_buzzer_done:

        bra     StateMachine


;************************************************************************
;   static StateFlight - State2: Flight
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   It does not check the battery voltage here, since a flight shouldn't
;   last too long.  It starts by checking to see if the button is
;   pressed, which can only occur if the rocket was recovered before the
;   state could switch to grounded, or if there was a false launch
;   detection.  Either way it will treat it like a complete flight, save
;   the data and beep it out, then return to idle.  It will then sample
;   the pressure sensor and add the sample to the sliding window.  It
;   updates the minimum pressure variable if necessary.  It will save the
;   new minimum pressure if no new minimum pressure is found within 2.56
;   seconds.  It will look for changes in pressure inorder to detect a
;   landing.  Once a landing has been detected the pressure sensor will
;   be turned off, and the grounded state will be setup.
;************************************************************************
StateFlight:

s2_check_button:
        ; Check button press
        call    CheckButton
        btfss   WREG, 0
        bra     s2_button_done

        ; wait for button to be released before continuing
        rcall   WaitButtonRelease

s2_button_pressed:
        ; code doesn't expect to get here unless flight not properly traced, or picked up soon after landing

        ; Calculate height above ground
        call    CalculateAltitudeReached

        ; save value to eeprom
        movlw   FALSE
        btfss   flightStatus, ALTITUDE_SAVED                    ; check if an altitude has been previously saved
        movlw   TRUE
        call    SaveAltitudeToEEPROM

        bsf     flightStatus, ALTITUDE_SAVED                    ; an altitude has been saved

        ; Update the max altitude bcd values
        call    ConvertAltitudeToBCD

        ; beep out maximum altitude
        call    BeepOutAltitude                     ; beep out max altitude reached

        bra     TransToIdle

s2_button_done:

s2_check_pressure:
        ; sample pressure sensor
        call    SamplePressure

        ; update sliding window
        lfsr    FSR2, pressureH
        call    AddToWindow

s2_check_pressure_done:

s2_max_altitude:
        ; if (pressure < tempMinPressure) {
        ;   tempMinPressure = pressure;
        ; }
        ; a = pressure
        movff   pressureH, ACa1
        movff   pressureL, ACa0

        ; b = tempMinPressure
        movff   tempMinPressureH, ACb1
        movff   tempMinPressureL, ACb0

        ; compare, unsigned compare will not cause issues
        call    CompareU16                          ; return 0 = equal, 1 = a < b, -1 = a > b
        decfsz  WREG, F                             ; skip if pressure < tempMinPressure
        bra     s2_max_altitude_else

        ;  update temp minimum pressure
        movff   pressureH, tempMinPressureH
        movff   pressureL, tempMinPressureL

        clrf    counter                             ; reset counter since a new maximum altitude was recorded.
        bsf     flightStatus, NEW_MAX_ALT           ; raise NEW_MAX_ALT flag to save pressure to eeprom

        bra     s2_max_altitude_endif

s2_max_altitude_else:
        btfss   flightStatus, NEW_MAX_ALT           ; check status bit NEW_MAX_ALT, if set then there is new data to write to eeprom.
        bra     s2_max_altitude_endif

        incfsz  counter, F                          ; count down the 2.56s
        bra     s2_max_altitude_endif

        bcf     flightStatus, NEW_MAX_ALT           ; clear flag, since we are handling it.
        ; most likely in descent, since no max altitude for over 2.5seconds
        ; now is a good time to save data.

        ; Calculate height above ground
        call    CalculateAltitudeReached

        ; save value to eeprom
        movlw   FALSE
        btfss   flightStatus, ALTITUDE_SAVED                    ; check if an altitude has been previously saved
        movlw   TRUE
        call    SaveAltitudeToEEPROM

        bsf     flightStatus, ALTITUDE_SAVED                    ; an altitude has been saved

s2_max_altitude_endif:


s2_pressure_change:
        ; // look for pressure change.  If there is none
        ; // for longer than Xs then change to grounded
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
s2_pressure_change_check_lower:
        ; if (avg < x - 1) then
        ; a = avg pressure
        movff   averageSampleH, ACa1
        movff   averageSampleL, ACa0

        ; b = x
        movff   tempPressureH, ACb1
        movff   tempPressureL, ACb0

        ; b = b - FLIGHT_DELTA
        movlw   LOW (FLIGHT_DELTA)                  ; FLIGHT_DELTA_L
        subwf   ACb0, F
        movlw   HIGH (FLIGHT_DELTA)                 ; FLIGHT_DELTA_H
        subwfb  ACb1, F                             ; dest = dest - FLIGHT_DELTA

        ; compare, unsigned compare will not cause issues
        call    CompareU16                          ; return 0 = equal, 1 = a < b, -1 = a > b
        decfsz  WREG, F                             ; skip if avg < x - 1
        bra     s2_pressure_change_check_higher
        bra     s2_pressure_changed

s2_pressure_change_check_higher:
        ; a = avg pressure
        movff   averageSampleH, ACa1                ; TODO: may not need if ACa is not modified
        movff   averageSampleL, ACa0

        ; b = x
        movff   tempPressureH, ACb1
        movff   tempPressureL, ACb0

        ; b = b + FLIGHT_DELTA
        movlw   LOW (FLIGHT_DELTA)                  ; FLIGHT_DELTA_L
        addwf   ACb0, F
        movlw   HIGH (FLIGHT_DELTA)                 ; FLIGHT_DELTA_H
        addwfc  ACb1, F                             ; b = b + FLIGHT_DELTA

        ; compare, unsigned compare will not cause issues
        call    CompareU16                          ; return 0 = equal, 1 = a < b, -1 = a > b
        incfsz  WREG, F                             ; skip if avg > x + 1
        bra     s2_pressure_change_else

        ; pressure change detected
s2_pressure_changed:
        ; tempAvg = avg;
        movff   averageSampleH, tempPressureH
        movff   averageSampleL, tempPressureL

        ; reset counter
        clrf    counterH
        clrf    counterL

        bra     s2_pressure_change_endif

        ; else
        ; no change detected
s2_pressure_change_else:

        ; increment counter
        infsnz  counterL, F
        incf    counterH, F

        ; if(time == FLIGHT_TIMEOUT) then
        movlw   FLIGHT_TIMEOUT_H
        cpfseq  counterH
        bra     s2_pressure_change_endif

        movlw   FLIGHT_TIMEOUT_L
        cpfseq  counterL
        bra     s2_pressure_change_endif

        ; exit flight, switch to grounded state
        call    LongBeep                            ; not needed

        ; turn off pressure sensor
        call    ShutdownMpl115a2                    ; turn off sensor

        ; setup gounded state
        ; setup time out
        movlw   GROUND_TIMEOUT_H
        movwf   stateTimeoutH

        movlw   GROUND_TIMEOUT_L
        movwf   stateTimeoutL

        ; calculate grounded timeout time
        movf    time_B0, W
        addwf   stateTimeoutL, F

        movf    time_B1, W
        addwfc  stateTimeoutH, F

        ; Update the max altitude bcd values
        call    ConvertAltitudeToBCD

        movlw   STATE_GROUNDED
        movwf   state

        bra     StateMachine
        ;   end if
        ; end if

s2_pressure_change_endif:

        bra     StateMachine


;************************************************************************
;   static StateGrounded - State5: Grounded
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   It does not check the battery voltage here, since the time in the
;   grounded state is limited.  It starts by checking to see if the
;   button is pressed, signifying recovery.  If it is pressed, the
;   altitude will be beeped out and the state will change to idle.  If it
;   is not pressed it will look for a timeout, which if found will cause
;   the state to switch to beacon.
;************************************************************************
StateGrounded:

        ; Check button press
s5_check_button:
        call    CheckButton
        btfss   WREG, 0
        bra     s5_button_done

        ; button has been pressed
s5_button_pressed:
        ; wait for button to be released before continuing
        rcall   WaitButtonRelease

        ; beep out maximum altitude
        call    BeepOutAltitude

        bra     TransToIdle

s5_button_done:

s5_timeout_check:
        ; if (timeElapsed >= W min) then
        ; a = timeout value
        movff   stateTimeoutH, ACa1
        movff   stateTimeoutL, ACa0

        ; b = time
        movff   time_B1, ACb1
        movff   time_B0, ACb0

        ; compare, unsigned compare may cause an issue if timeout overflows, can only use equal
        call    CompareU16                          ; return 0 = equal, 1 = a < b, -1 = a > b
        tstfsz  WREG                                ; skip if time == timeout
        bra     s5_timeout_done

        movlw   STATE_BEACON
        movwf   state

        bra     StateMachine
        ; end if

s5_timeout_done:

        bra     StateMachine


;************************************************************************
;   static StateBeacon - State6: Beacon
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   It checks the battery voltage here, if low it will switch to idle
;   state.  It then checks to see if the button is pressed, signifying
;   recovery.  If it is pressed, the altitude will be beeped out and the
;   state will change to idle.  If it is not pressed it will countinously
;   beep out a distress beacon.
;************************************************************************
StateBeacon:

        ; check battery voltage
s6_check_battery:
        call    CheckBattery
        btfss   WREG, 0
        bra     s6_check_button

        ; battery voltage is low
s6_battery_low:
        ; since battery is too low, exit to idle mode.
        call    LongBeep
        call    ShortBeep
        call    LongBeep

        bra     TransToIdle

        ; check button press
s6_check_button:
        call    CheckButton
        btfss   WREG, 0
        bra     s6_button_done

        ; button has been pressed so stop beacon
        call    DeactivateBuzzer                                ; Deactivate buzzer

        ; wait for button to be released before continuing
        rcall   WaitButtonRelease

s6_button_pressed:
        ; beep out maximum altitude
        call    BeepOutAltitude

        bra     TransToIdle

s6_button_done:

s6_buzzer:
        ; if (timeB1, 0) then
        ;   buzzer <= on
        ; else
        ;   buzzer <= off
        ; end if

        ; buzzer output waveform, period is 2.56s, duty cycle is 50%
        ;      ____      ____      ____
        ;     |    |    |    |    |    |
        ; ____|    |____|    |____|    |____
        ; 00XX 01XX 00XX 01XX 00XX 01XX 00XX
        ; timer[1:0]
        ; control buzzer based on the timestamp registers
        btfss   time_B1, 0                          ; will cycle ever 2.56 seconds
        bra     s6_buzzer_off

        ; Activate buzzer
        call    ActivateBuzzer4kHz

        bra     s6_buzzer_done

s6_buzzer_off
        ; Deactivate buzzer
        call    DeactivateBuzzer

s6_buzzer_done:

        bra     StateMachine


;*******************************************************************
;   State7: Sleep
;
;   Description:
;
;*******************************************************************
StateSleep:

        call    ShutdownMpl115a2                    ; turn off pressure sensor

        bcf     OSCCON, IDLEN                       ; IDLE mode on sleep, disabled

        bcf     INTCON, GIE                         ; Disable interrupts

        ; wait for input to change state
        sleep
        bra     $ - 2


;************************************************************************
;   static StateUnitSelect - State8: UnitSelection
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: None.
;
;   ?
;************************************************************************
StateUnitSelect:
        ; enable idle mode to keep timer running.
        call    ResetTimer
        bsf     OSCCON, IDLEN                       ; IDLE mode on sleep, to keep timer running

        movff   options, oldOptions

s8_check_button:
        ; check if button is pressed
        call    CheckButton
        btfss   WREG, 0

        ; button was not pressed
        bra     s8_done

        movlw   DELAY_2000ms
        call    Delay

        ; button is pressed, get a selection from the user
        movlw   .3
        rcall   ButtonPressed

        movlw   DELAY_500ms
        call    Delay

        ; jump to selection handler
        movlw   0x00                                ; no change
        cpfsgt  option
        bra     s8_option_0

        movlw   0x01                                ; feet
        cpfsgt  option
        bra     s8_option_1

        movlw   0x02                                ; meters
        cpfsgt  option
        bra     s8_option_2

s8_option_0:
        ; didn't hold down long enough to make a selection
        bra     s8_done

s8_option_1:
        ; set units to feet
        bcf     options, OP_METRIC

        ; redo conversion to make sure right output is used
        call    ConvertAltitudeToBCD

        ; beep to notify setup complete
        call    ShortBeep
        call    ShortBeep
        call    ShortBeep

        bra     s8_update_nvm

s8_option_2:
        ; set units to meters
        bsf     options, OP_METRIC

        ; redo conversion to make sure right output is used
        call    ConvertAltitudeToBCD

        ; beep to notify setup complete
        call    LongBeep
        call    LongBeep
        call    LongBeep

        bra     s8_update_nvm

s8_update_nvm:
        ; TODO, only write if options has changed.

        movf    options, W
        cpfseq  oldOptions
        bra     s8_nvm
        bra     s8_done

s8_nvm:
        clrf    EEADR                       ; set address to 0x00
        movff   options, EEDATA             ; set data to write

        movlw   b'00000100'                 ; Point to DATA memory, Access EEPROM, Enable writes
        movwf   EECON1

        call    EepromWrite

s8_done:

        bra     TransToIdle

;** State Transitions ***************************************************

;************************************************************************
;   static TransToIdle - Transition to idle state
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: Next state is idle. Sensor is off. Timer is stopped.
;   Idle sleep mode is enabled.
;
;   It sets up the idle state, and sets up a low power settings.
;************************************************************************
TransToIdle:
        ; turn off unused hardware
        call    ShutdownMpl115a2                    ; turn off pressure sensor
        call    StopTimer                           ; Stop Timer

        bcf     OSCCON, IDLEN                       ; IDLE mode on sleep, disabled

        ; setup state variable
        movlw   STATE_IDLE
        movwf   state

        bra     StateMachine


;************************************************************************
;   static TransToLaunch - Transition to launch state
;
;   Input: None.
;
;   Output: None.
;
;   Precondition: None.
;
;   Postcondition: Next state is launch. Sensor is on. Timer is reset.
;   launch pressure is saved.  Sliding window is reset.
;
;   It sets up the launch state.
;************************************************************************
TransToLaunch:
        ; mode 1
        call    ShortBeep

        ; Make sure pressure sensor is on
        call    PowerMpl115a2                       ; turn on pressure sensor, needs 20ms before it can be sampled properly

        call    LongBeep

        ; clear flight flags
        clrf    flightStatus

        ; reset the timer
        call    ResetTimer

        ; Sample pressure sensor, and update launch pressure
        call    SamplePressure
        movff   pressureH, launchPressureH
        movff   pressureL, launchPressureL

        ; setup slideing window
        lfsr    FSR2, pressureH
        call    InitWindow

        ; setup state variable
        movlw   STATE_LAUNCH
        movwf   state

        bra     StateMachine


;** Common Functions ****************************************************

;*******************************************************************
;   void ButtonPressed(byte selections, bool limitedSelections)
;
;   input:  byte: number of available options
;           bool: true - limited number of options, will signal invalid option and reset.
;
;   output: none.
;
;   precondition:
;
;   postcondition:  option register contains the selection chosen
;
;   Description: monitors the button input to determine the length of a button press.  It beeps between options.
;
;*******************************************************************

;************************************************************************
;   static ButtonPressed - Button has been pressed, get selection
;
;   Input: (W) byte selection - the number of options available.
;
;   Output: byte option - the option selected.
;
;   Precondition: Register W contains the number of options available to
;   the user.  The boolean limitedSelections is initialized.
;
;   Postcondition: None.
;
;   It handles button presses by beeping out at certain intervals buring
;   a button press inorder to allow the user to make a selection.
;************************************************************************
ButtonPressed:
        ; save the number of available selections
        movwf   selections

        ; get current time, everything will be compared to it.
        ; just need LSB since it counts 256 * 10ms = 2.56s

setup_sel_0:
        movlw   .0
        movwf   option

        ; Wait for it to be released.
        ; setup 1.5s mark in tempTime
        movf    time_B0, W
        addlw   .148                                ; 1500ms - the 20ms debounce time
        movwf   tempTime

        bra     check_sel

setup_sel:
        incf    option, F                           ; update option

        call    ShortBeep                           ; option beep

        movff   option, tempIndex

        ; while (--tempIndex > 0) {
        ;   delay 100ms
        ;   beep
        ; }
bp_beep_selection:
        dcfsnz  tempIndex, F
        bra     bp_beep_done

        movlw   DELAY_100ms
        call    Delay
        call    ShortBeep

        bra     bp_beep_selection

bp_beep_done:

        movf    time_B0, W
        addlw   .100                                ; 1000ms
        movwf   tempTime

check_sel:
        btfsc   BUTTON_PORT, BUTTON_PIN
        bra     button_released                     ; wait for button to be released

        bsf     INTCON, RBIE                        ; Enable port b interrupt-on-change flag
        sleep
        bcf     INTCON, RBIE                        ; Disable port b interrupt-on-change flag

        ; check if at the mark
        ; time == tempTime
        movf    tempTime, W
        xorwf   time_B0, W                          ; tempTime == time ?
        btfss   STATUS, Z                           ; skip if tempTime == time
        bra     check_sel                           ; not yet

        dcfsnz  selections, F                       ; update selections
        bra     end_of_options
        bra     setup_sel

end_of_options:
        ; if(limitedSelections) {
        ;     LongBeep()
        ;     option = 0xFF
        ; }
        ;
        ; WaitButtonRelease()
        btfss   limitedSelections, 0
        bra     eoo_endif

        call    LongBeep                            ; beep at 5s mark - invalid
        setf    option

eoo_endif:
        rcall   WaitButtonRelease

        return

        ; button released
button_released:
        ; debounce button release
        call    Debounce

        return                                      ; return with duration in WREG


WaitButtonRelease:
; takes care of debouncing, and goes to sleep until complete
        bcf     OSCCON, IDLEN                       ; disable idle, allow sleep mode
wbr_wait:
        bsf     INTCON, RBIE                        ; Enable port b interrupt-on-change flag
        sleep                                       ; go to sleep until button is released
        bcf     INTCON, RBIE                        ; Disable port b interrupt-on-change flag

        btfss   BUTTON_PORT, BUTTON_PIN
        bra     wbr_wait                            ; loop until button released

        bsf     OSCCON, IDLEN                       ; back to idle on sleep, only needed if it was removed, maybe it always can go into sleep mode in these cases

        ; debounce button release
        call    Debounce

        return


        END
