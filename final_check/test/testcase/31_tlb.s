.section .text
.globl _start
_start:
    lui t1, 0x00000 # 1
    lw  t0, (t1)
    lui t1, 0x00001 # 2
    lw  t0, (t1)
    lui t1, 0x00002 # 3
    lw  t0, (t1)
    lui t1, 0x00003 # 4
    lw  t0, (t1)
    lui t1, 0x00004 # 5
    lw  t0, (t1)
    sfence.vma
    lui t1, 0x00000 # 1
    lw  t0, (t1)
    lui t1, 0x00001 # 2
    lw  t0, (t1)
    lui t1, 0x00002 # 3
    lw  t0, (t1)
    lui t1, 0x00003 # 4
    lw  t0, (t1)
    lui t1, 0x00004 # 5
    lw  t0, (t1)
_end:
    j _end

