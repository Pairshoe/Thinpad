    .org 0x0
    .global _start
    .text

_start:
    lui   x8, 0x80400
    lui   x9, 0x80400
    addi  x9, x9, 10
    lui   x1, 0x10000

loop1:
    lb    x2, 5(x1)
    andi  x2, x2, 0x1
    bne   x2, x0, read
    jal   x0, loop1

read:
    lb    x3, 0(x1)
    sb    x3, 0(x8)
    addi  x8, x8, 0x1
    bne   x8, x9, loop1
    lui   x8, 0x80400

loop2:
    lb    x2, 5(x1)
    andi  x2, x2, 0x20
    bne   x2, x0, write
    jal   x0, loop2

write:
    lb    x3, 0(x8)
    sb    x3, 0(x1)
    addi  x8, x8, 0x1
    bne   x8, x9, loop2

end:
    beq   x0, x0, end
