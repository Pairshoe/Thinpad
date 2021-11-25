.section .text
.globl _start
_start:
    ebreak
    li s0, 30
    li a0, 0x45 # E
    ecall
    li a0, 0x6f # o
    ecall
    li a0, 0x72 # r
    ecall
    li a0, 0x6f # r
    ecall
    li a0, 0x72 # o
    ecall
    li a0, 0x72 # r
    ecall
    li a0, 0x0a # \n
    ecall
_end:
    j _end
