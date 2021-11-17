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
    lui t1, 0x00005 # 6
    lw  t0, (t1)
    lui t1, 0x00006 # 7
    lw  t0, (t1)
    lui t1, 0x00007 # 8
    lw  t0, (t1)
    lui t1, 0x00008 # 9
    lw  t0, (t1)
    lui t1, 0x00009 # 10
    lw  t0, (t1)
    lui t1, 0x0000a # 11
    lw  t0, (t1)
    lui t1, 0x0000b # 12
    lw  t0, (t1)
    lui t1, 0x0000c # 13
    lw  t0, (t1)
    lui t1, 0x0000d # 14
    lw  t0, (t1)
    lui t1, 0x0000e # 15
    lw  t0, (t1)
    lui t1, 0x0000f # 16
    lw  t0, (t1)
    lui t1, 0x00010 # 17
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
    lui t1, 0x00005 # 6
    lw  t0, (t1)
    lui t1, 0x00006 # 7
    lw  t0, (t1)
    lui t1, 0x00007 # 8
    lw  t0, (t1)
    lui t1, 0x00008 # 9
    lw  t0, (t1)
    lui t1, 0x00009 # 10
    lw  t0, (t1)
    lui t1, 0x0000a # 11
    lw  t0, (t1)
    lui t1, 0x0000b # 12
    lw  t0, (t1)
    lui t1, 0x0000c # 13
    lw  t0, (t1)
    lui t1, 0x0000d # 14
    lw  t0, (t1)
    lui t1, 0x0000e # 15
    lw  t0, (t1)
    lui t1, 0x0000f # 16
    lw  t0, (t1)
    lui t1, 0x00010 # 17
    lw  t0, (t1)
_end:
    j _end

