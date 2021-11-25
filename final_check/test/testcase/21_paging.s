.globl _start
.text
_start:
    li s0, 30
    li a0, 0x50 # P
    ecall
    li a0, 0x61 # a
    ecall
    li a0, 0x67 # g
    ecall
    li a0, 0x69 # i
    ecall
    li a0, 0x6e # n
    ecall
    li a0, 0x67 # g
    ecall
    li a0, 0x20 # space
    ecall
    li a0, 0x69 # i
    ecall
    li a0, 0x73 # s
    ecall
    li a0, 0x20 # space
    ecall
    li a0, 0x77 # w
    ecall
    li a0, 0x6f # o
    ecall
    li a0, 0x72 # r
    ecall
    li a0, 0x6b # k
    ecall
    li a0, 0x69 # i
    ecall
    li a0, 0x6e # n
    ecall
    li a0, 0x67 # g
    ecall
    li a0, 0x21 # !
    ecall
    li a0, 0x0a # \n 
    ecall
_end:
    jr ra
