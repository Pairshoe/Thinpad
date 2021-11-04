    .org 0x0
    .global _start
    .text

_start:
    lui   x1, 0xf00f0     # x1 = 0xf00f0000
    ori   x2, x1, 0x0f0   # x2 = 0xf00f00f0
    and   x3, x1, x2      # x3 = 0xf00f0000
    xor   x4, x1, x2      # x4 = 0x000000f0
    lui   x1, 0x0fff0     # x1 = 0x0fff0000
    addi  x1, x1, -1      # x1 = 0x0ffeffff
    add   x5, x1, x4      # x5 = 0x0fff00ef
    or    x6, x5, x4      # x6 = 0x0fff00ff
    andi  x6, x6, -4      # x6 = 0x0fff00fc
    lui   x7, 0xfffff     # x7 = 0xfffff000
    srli  x7, x7, 16      # x7 = 0x0000ffff
    slli  x7, x7, 28      # x7 = 0xf0000000

end:
    beq   x0, x0, end
