P18F23K20       EQU 0
P18F26K20       EQU 1

MCU             EQU P18F23K20


    if  MCU == P18F23K20
    LIST        P=18F23k20                  ; directive to define processor
    #include    <P18F23K20.INC>
    endif

    if  MCU == P18F26K20
    LIST        P=18F26k20                  ; directive to define processor
    #include    <P18F26K20.INC>
    endif
