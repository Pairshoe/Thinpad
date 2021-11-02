    .org 0x0
    .global _start
    .text

_start:
    lui   x1, 0
    bne   x1, x0, end
    ori   x1, x0, 10
    add   x2, x0, x0
    add   x5, x0, x0

prepare:
    auipc x9, 0x12345
    auipc x3, 0
    addi  x3, x3, 28

jstart:
    jalr  x4, 0(x3)
    addi  x3, x3, 4
    addi  x2, x2, 1
    bne   x1, x2, jstart
    beq   x0, x0, next

jend:
    addi  x5, x5, 1
    addi  x5, x5, 1
    addi  x5, x5, 1
    addi  x5, x5, 1
    addi  x5, x5, 1
    addi  x5, x5, 1
    addi  x5, x5, 1
    addi  x5, x5, 1
    addi  x5, x5, 1
    jalr  x6, 0(x4)

next:
    jal   x7, 88
    auipc x8, 0

# assert x5 = 45 and x7 = x8
end:
    beq   x0, x0, end
