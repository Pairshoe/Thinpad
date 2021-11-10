.section .text
.globl _start
_start:
    li s0, 30
    li a0, 0x4F
    ecall
    li a0, 0x4B
    ecall
_end:
    j _end