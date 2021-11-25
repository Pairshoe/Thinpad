.section .text
.globl _start
_start:
    addi t0, x0, 0x1
    # store
    lui  t1, 0x00000 # 1
    sw   t0, (t1)
    lui  t1, 0x00001 # 2
    sw   t0, (t1)
    lui  t1, 0x00002 # 3
    sw   t0, (t1)
    lui  t1, 0x00003 # 4
    sw   t0, (t1)
    lui  t1, 0x00004 # 5
    sw   t0, (t1)
    lui  t1, 0x00005 # 6
    sw   t0, (t1)
    lui  t1, 0x00006 # 7
    sw   t0, (t1)
    lui  t1, 0x00007 # 8
    sw   t0, (t1)
    lui  t1, 0x00008 # 9
    sw   t0, (t1)
    lui  t1, 0x00009 # 10
    sw   t0, (t1)
    lui  t1, 0x0000a # 10
    sw   t0, (t1)    
    lui  t1, 0x0000b # 12
    sw   t0, (t1)
    lui  t1, 0x0000c # 13
    sw   t0, (t1)
    lui  t1, 0x0000d # 14
    sw   t0, (t1)
    lui  t1, 0x0000e # 15
    sw   t0, (t1)
    lui  t1, 0x0000f # 16
    sw   t0, (t1)
    lui  t1, 0x00010 # 17
    sw   t0, (t1)
    lui  t1, 0x00011 # 18
    sw   t0, (t1)
    lui  t1, 0x00012 # 19
    sw   t0, (t1)
    lui  t1, 0x00013 # 20
    sw   t0, (t1)
    lui  t1, 0x00014 # 21
    sw   t0, (t1)
    lui  t1, 0x00015 # 22
    sw   t0, (t1)
    lui  t1, 0x00016 # 23
    sw   t0, (t1)
    lui  t1, 0x00017 # 24
    sw   t0, (t1)
    lui  t1, 0x00018 # 25
    sw   t0, (t1)
    lui  t1, 0x00019 # 26
    sw   t0, (t1)
    lui  t1, 0x0001a # 27
    sw   t0, (t1)
    lui  t1, 0x0001b # 28
    sw   t0, (t1)
    lui  t1, 0x0001c # 29
    sw   t0, (t1)
    lui  t1, 0x0001d # 30
    sw   t0, (t1)
    lui  t1, 0x0001e # 31
    sw   t0, (t1)
    lui  t1, 0x0001f # 32
    sw   t0, (t1)
    # load
    lui  t1, 0x00000 # 1
    lw   t0, (t1)
    lui  t1, 0x00001 # 2
    lw   t0, (t1)
    lui  t1, 0x00002 # 3
    lw   t0, (t1)
    lui  t1, 0x00003 # 4
    lw   t0, (t1)
    lui  t1, 0x00004 # 5
    lw   t0, (t1)
    lui  t1, 0x00005 # 6
    lw   t0, (t1)
    lui  t1, 0x00006 # 7
    lw   t0, (t1)
    lui  t1, 0x00007 # 8
    lw   t0, (t1)
    lui  t1, 0x00008 # 9
    lw   t0, (t1)
    lui  t1, 0x00009 # 10
    lw   t0, (t1)
    lui  t1, 0x0000a # 10
    lw   t0, (t1)    
    lui  t1, 0x0000b # 12
    lw   t0, (t1)
    lui  t1, 0x0000c # 13
    lw   t0, (t1)
    lui  t1, 0x0000d # 14
    lw   t0, (t1)
    lui  t1, 0x0000e # 15
    lw   t0, (t1)
    lui  t1, 0x0000f # 16
    lw   t0, (t1)
    lui  t1, 0x00010 # 17
    lw   t0, (t1)
    lui  t1, 0x00011 # 18
    lw   t0, (t1)
    lui  t1, 0x00012 # 19
    lw   t0, (t1)
    lui  t1, 0x00013 # 20
    lw   t0, (t1)
    lui  t1, 0x00014 # 21
    lw   t0, (t1)
    lui  t1, 0x00015 # 22
    lw   t0, (t1)
    lui  t1, 0x00016 # 23
    lw   t0, (t1)
    lui  t1, 0x00017 # 24
    lw   t0, (t1)
    lui  t1, 0x00018 # 25
    lw   t0, (t1)
    lui  t1, 0x00019 # 26
    lw   t0, (t1)
    lui  t1, 0x0001a # 27
    lw   t0, (t1)
    lui  t1, 0x0001b # 28
    lw   t0, (t1)
    lui  t1, 0x0001c # 29
    lw   t0, (t1)
    lui  t1, 0x0001d # 30
    lw   t0, (t1)
    lui  t1, 0x0001e # 31
    lw   t0, (t1)
    lui  t1, 0x0001f # 32
    lw   t0, (t1)
_end:
    j _end
