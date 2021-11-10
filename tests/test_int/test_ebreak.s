.section .text
.globl _start
_start:
    ebreak
    li s0, 30
    li a0, 0x4F
    ecall
    ecall
_end:
    j _end
