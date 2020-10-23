        #include    "src\buildOptions.inc"

    if ADD32_EN == 1 || SUB32_EN == 1
        EXTERN      ACa3
        EXTERN      ACa2
    endif
        EXTERN      ACa1
        EXTERN      ACa0

    if ADD32_EN == 1 || SUB32_EN == 1
        EXTERN      ACb3
        EXTERN      ACb2
    endif
        EXTERN      ACb1
        EXTERN      ACb0

    if ADD32_EN == 1 || SUB32_EN == 1
        EXTERN      Q_sub
        EXTERN      Q_add
    endif

        EXTERN      CompareU16

        EXTERN      Mul24x16
        EXTERN      MulU24x16

    if MUL16_EN == 1
        EXTERN      Mul16
    endif
    if MULU16_EN == 1
        EXTERN      MulU16
    endif

        EXTERN      arg2H
        EXTERN      arg2L
        EXTERN      arg1U
        EXTERN      arg1H
        EXTERN      arg1L

        EXTERN      res4
        EXTERN      res3
        EXTERN      res2
        EXTERN      res1
        EXTERN      res0
