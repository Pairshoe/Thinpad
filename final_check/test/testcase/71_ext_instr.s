.section .text
.globl _start
_start:
    # XOR
    ori  t1, x0, 5     # t1 = 0b101
    ori  t2, x0, 2     # t2 = 0b010
    xor  t3, t1, t2    # t3 = 0x00000007
    # LH & SH
    lui  t0, 0x7fc10   # t0 = 0x7fc10000
    ori  t4, x0, -1    # t4 = 0xffffffff
    sw   t4, (t0)      # (0x7fc10000) = 0xffffffff
    lh   t5, (t0)      # t5 = 0x0000ffff
    sh   t0, (t0)      # (0x7fc10000) = 0xffff0000
    lw   t6, (t0)      # t6 = 0xffff0000
    # BLT
    ori  s1, x0, 1     # s1 = 1
    ori  s2, x0, 10    # s2 = 10
_loop:
    add  s3, s3, s1    # s3 = s3 + s1
    addi s1, s1, 1     # s1 = s1 + 1
    bne  s1, s2, _loop
_end:
    jr   ra

