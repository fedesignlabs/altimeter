
        ; functions
    if BCD_EN == 1
        EXTERN      Convert2BtoBCD
        EXTERN      ConvertU2BtoBCD
        EXTERN      Convert1BtoBCD
        EXTERN      ConvertU1BtoBCD
    endif

        ;  variables
    if BCD_EN == 1
        EXTERN      num1
        EXTERN      num0
    endif

    if BCD_EN == 1
        EXTERN      sign
        EXTERN      tenK
        EXTERN      thou
        EXTERN      hund
        EXTERN      tens
        EXTERN      ones
    endif
