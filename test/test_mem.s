    .org 0x0
    .global _start
    .text

# sram test
_start:
    lui   x1, 0x80100      # base_ram
    lui   x2, 0x80400      # ext_ram
    lui   x3, 0xf00f0
    sw    x3, 0(x1)
    addi  x3, x3, 0x111
    sw    x3, 0(x2)
    sb    x3, 4(x2)
    sb    x3, 5(x2)
    sb    x3, 6(x2)
    sb    x3, 7(x2)
    lb    x4, 2(x1)        # x4 = 0x0000000f
    lw    x5, 0(x1)        # x5 = 0xf00f0000
    lw    x6, 0(x2)        # x6 = 0xf00f0111
    lw    x7, 4(x2)        # x7 = 0x11111111

# uart test: send ascii characters from 0x21 to 0x7f
    addi  x8, x0, 0x21
    addi  x9, x0, 0x7f

serial:
    lui   x1, 0x10000
.test:
    lb    x2, 5(x1)
    andi  x2, x2, 0x20
    bne   x2, x0, .write
    jal   x0, .test
.write:
    sb    x8, 0(x1)

finish:
    addi  x8, x8, 1
    bne   x8, x9, serial

end: 
    beq   x0, x0, end
