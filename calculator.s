.text
.align 2
.global main

@add r2 + r3
addition:
    STMFD sp!, {lr}
    @store result in r1
    ADD r1, r2, r3

    LDMFD sp!, {lr}
    MOV pc, r14

@sub r2 - r3
subtraction:
    STMFD sp!, {lr}
    @store result in r1
    SUB r1, r2, r3

    LDMFD sp!, {lr}
    MOV pc, r14

@reverse the bits stored in r2 and result in r1
reverse:
    STMFD sp!, {r2-r4, lr}
    @r4 count from 0 ~ 31
    @r3 is a buffer
    MOV r1, #0

    reverse_loop:
        AND r3, r2, #1
        LSR r2, r2, #1
        ADD r1, r3, r1, LSL #1

        @next r4
        ADD r4, r4, #1

        @check r4 = 32
        CMP r4, #32
        BNE reverse_loop

    LDMFD sp!, {r2-r4, lr}
    MOV pc, r14

@divid num in r2 with r3 
@quotient = r1; remainder = r0
division:
    @check if divided zero
    CMP r3, #0
    BEQ error_div_zero

    STMFD sp!, {r2, r3, lr}
    @set r1 to 0
    MOV r1, #0
    MOV r0, r2
    @
    divid_loop:
        SUBS r2, r2, r3
        MOVGE r0, r2
        ADDGE r1, r1, #1
        BGT divid_loop

    LDMFD sp!, {r2, r3, lr}
    MOV pc, r14
@max{r2, r3}
maximum:
    STMFD sp!, {lr}
    @
    CMP r2, r3
    MOVGE r1, r2
    MOVLT r1, r3

    LDMFD sp!, {lr}
    MOV pc, r14
@r2^r3 result in r1
exponent:
    STMFD sp!, {r2, r3, lr}
    @
    MOV r1, #1
    CMP r3, #0
    BEQ exop_end
        expo_loop:
            MUL r1, r2, r1
            SUBS r3, r3, #1
            BNE expo_loop
    exop_end:    
    LDMFD sp!, {r2, r3, lr}
    MOV pc, r14
@gcd(r2, r3), result in r1
gcd:
    STMFD sp!, {r0, r2, r3, lr}
    @exe
    gcd_loop:
        BL division
        MOV r2, r3
        MOVS r3, r0
        BNE gcd_loop
    MOV r1, r2

    LDMFD sp!, {r0, r2, r3, lr}
    MOV pc, r14
@mult r2, r3
@return result in r1
multiplication:
    STMFD sp!, {r0, r2, r3, lr}
    @
    MUL r1, r2, r3
    @
    LDMFD sp!, {r0, r2, r3, lr}
    MOV pc, r14
@lcm(r2, r3) result in r1
lcm:   
    STMFD sp!, {r0, r2, r3, r4, r5, lr}

    @r4 is a buffer
    BL gcd
    MOV r5, r1
    @we have gcd(r2, r3) in r5
    @cmp r2 < r3  if false swap(to aviod int overflow)
    CMP r2, r3
    MOVGE r4, r3

    MOVLT r4, r2
    MOVLT r2, r3
    MOV r3, r5
    @do division
    BL division
    @we have bigger_num / gcd(r2, r3) in r1
    MUL r1 ,r4, r1

    LDMFD sp!, {r0, r2, r3, r4, r5, lr}
    MOV pc, r14

@mult ten in r0 
MULT_TEN:
    STMFD sp!, {r1, r2}
    @
    MOV r1, #10
    MOV r2, r0
    MUL r0, r1, r2

    LDMFD sp!, {r1, r2}
    MOV pc, r14
@input string in r0
@output int in r0
INTO_INT:
    STMFD sp!, {r1, r2, lr}
    @copy string to r2
    MOV r2, r0
    LSL r6, #1
    MOV r0, #0
    into_int_loop:
        @first char in string in r1
        LDRB r1, [r2], #1  

        @check if is a number
        CMP r1, #'0'
        ADDLT r6, r6, #1
        BLT input_error
        CMP r1, #'9'
        ADDGT r6, r6, #1
        BGT input_error

        @into int
        SUB r1, r1, #'0'

        BL MULT_TEN
        ADD r0, r0, r1
        @loop
        @test if it is at the end char
        LDRB r1, [r2]

        CMP r1, #0
        BNE into_int_loop
    
    input_error:
    @back
        LDMFD sp!, {r1, r2, lr}
        MOV pc, r14

@arithm opnd1 opnd2 op
@=====> [r2]  [r3] [r4]
main:
    @if error happend r6 will be 1
    MOV r6, #0
    STMFD sp!, {r0, r1, fp, lr}
    @check argc
    CMP r0, #4
    BNE error_argc
    @ body
    @step1
    LDR r0, [r1, #4]    @read argv[1] to r0
    BL INTO_INT
    @store opnd1 in r2
    MOV r2, r0

    @step2
    LDR r0, [r1, #8]    @read argv[2] to r0
    BL INTO_INT
    @store opnd2 in r3
    MOV r3, r0

    @step3(jump table)
    LDR r0, [r1, #12]   @read argv[3] to r0
    BL INTO_INT
    @store op in r4
    MOV r4, r0

    @check if there is input error
    CMP r6, #0
    @jump error list 
    ADRNE r5, error_list
    LDRNE pc, [r5, r6, LSL #2]

    @jump
    ADR r5, functions
    CMP r4, #8
    BGT error_type1
    MOVLE lr, pc
    LDRLE pc, [r5, r4, LSL #2]

    @string address
    ADR r0, answer_list
    LDR r0, [r0, r4, LSL #2]
    @r5 = ans back up
    MOV r5, r1
    @the correct order for printf
    MOV r1, r4

    BL printf
    @reload ans
    MOV r1, r5
    ADR r0, number
    BL printf
    BAL end

error_type1:
    LDR r1, [r1, #12]
    ADR r0, error_msg3
    BL printf
    BAL end
error_type2:
    LDR r1, [r1, #8]
    ADR r0, error_msg4
    BL printf
    BAL end
error_type3:
    LDR r2, [r1, #12]
    LDR r1, [r1, #8]
    ADR r0, error_msg5
    BL printf
    BAL end
error_type4:
    LDR r1, [r1, #4]
    ADR r0, error_msg4
    BL printf
    BAL end
error_type5:
    LDR r2, [r1, #12]
    LDR r1, [r1, #4]
    ADR r0, error_msg5
    BL printf
    BAL end
error_type6:
    LDR r2, [r1, #8]
    LDR r1, [r1, #4]
    ADR r0, error_msg2
    BL printf
    BAL end
error_type7:
    LDR r3, [r1, #12]
    LDR r2, [r1, #8]
    LDR r1, [r1, #4]
    ADR r0, error_msg6
    BL printf
    BAL end
error_div_zero:
    ADR r0, error_msg1
    BL printf
    BAL end
error_argc:
    ADR r0, error_msg7
    BL printf
    BAL end
end:
    LDMFD sp!, {r0, r1, fp, lr}
    BX lr

@branches
functions:
    .word addition
    .word subtraction
    .word reverse
    .word division
    .word maximum
    .word exponent
    .word gcd
    .word multiplication
    .word lcm
    .align 2
error_list:
    .word end
    .word error_type1
    .word error_type2
    .word error_type3
    .word error_type4
    .word error_type5
    .word error_type6
    .word error_type7
    .align 2
number:
    .ascii "%d\0"
    .align 2
answer_list:
    .word ans_msg1
    .word ans_msg2
    .word ans_msg3
    .word ans_msg4
    .word ans_msg5
    .word ans_msg6
    .word ans_msg7
    .word ans_msg8
    .word ans_msg9
    .align 2
ans_msg1:
    .ascii "Function %d: %d + %d is \0"
    .align 2
ans_msg2:
    .ascii "Function %d: %d - %d is \0"
    .align 2
ans_msg3:
    .ascii "Function %d: bit-reverse of %d is \0"
    .align 2
ans_msg4:
    .ascii "Function %d: %d / %d is \0"
    .align 2
ans_msg5:
    .ascii "Function %d: maximum of %d and %d is \0"
    .align 2
ans_msg6:
    .ascii "Function %d: %d to the power of %d is \0"
    .align 2
ans_msg7:
    .ascii "Function %d: greatest common divisor of %d and %d is \0"
    .align 2
ans_msg8:
    .ascii "Function %d: multiplication of %d and %d is \0"
    .align 2
ans_msg9:
    .ascii "Function %d: least common multiply of %d and %d is \0"
    .align 2
error_msg1:
    .ascii "ERROR : divided zero\0"
    .align 2  
error_msg2:
    .ascii "Invalid input operands : %s, %s\0"
    .align 2
error_msg3:
    .ascii "Invalid input operator : %s\0"
    .align 2    
error_msg4:
    .ascii "Invalid input operand : %s\0"
    .align 2
error_msg5:
    .ascii "Invalid input operand : %s\nInvalid input operator : %s\0"
    .align 2
error_msg6:
    .ascii "Invalid input operands : %s, %s\nInvalid input operator : %s\0"
    .align 2
error_msg7:
    .ascii "Invalid number of inputs\0"
    .align 2
