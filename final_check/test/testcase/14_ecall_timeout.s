.section .text
.globl _start
_start:
    li s0, 30
    li a0, 0x55 # U
    ecall
    li a0, 0x63 # c
    ecall
    li a0, 0x6f # o
    ecall
    li a0, 0x72 # r
    ecall
    li a0, 0x65 # e
    ecall
    li a0, 0x20 # space
    ecall
    li a0, 0x69 # i
    ecall
    li a0, 0x73 # s
    ecall
    li a0, 0x20 # space
    ecall
    li a0, 0x72 # r
    ecall
    li a0, 0x75 # u
    ecall
    li a0, 0x6e # n
    ecall
    li a0, 0x6e # n
    ecall
    li a0, 0x69 # i
    ecall
    li a0, 0x6e # n
    ecall
    li a0, 0x67 # g
    ecall
    li a0, 0x2e # .
    ecall
    li a0, 0x2e # .
    ecall
    li a0, 0x2e # .
    ecall
    li a0, 0x0a # \n 
    ecall
_end:
    j _end
