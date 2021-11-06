.globl _start
.text
_start:
    li s0, 0x80100000
    li s1, 0
    li a1, 0x86 # selection
    li a2, 0xe8d40710 # random
    addi gp, s0, 0x10 # gp = s0 + 0x10
t_pcnt: # popcount
    andi t0, a1, 1
    beqz t0, t_andn # skip test

    li t1, 0xFFF0
    pcnt t1, t1
    li  t2, 12
    bne t1, t2, t_andn

    li  t1, 0x7
    pcnt t1, t1
    li  t2, 3
    bne t1, t2, t_andn

    pcnt t1, a2
    sw t1, 0(gp) # *gp = pcnt(a2)
    addi gp, gp, 4
    ori s1, s1, 1
t_andn:
    andi t0, a1, 2
    beqz t0, t_xnor # skip test

    li t1, 0x0001
    andn t1, t1, t1
    li t2, 0
    bne t1, t2, t_xnor

    li t1, 32
    andn t1, t1, zero
    li t2, 32
    bne t1, t2, t_xnor

    li t1, 0xFFFF
    andn t1, a2, t1
    sw t1, 0(gp) # gp = andn(a2, 0xFFFF)
    addi gp, gp, 4
    ori s1, s1, 2
t_xnor:
    andi t0, a1, 4
    beqz t0, t_clz # skip test

    li  t1, 0xa1b2c3d4
    xnor t1, t1, t1
    li  t2, 0xFFFFFFFF
    bne t1, t2, t_clz

    li t1, 0xa1b2c3d4
    li t2, 0xFFFFFFFF
    xnor t1, t1, t2
    li  t2, 0xa1b2c3d4
    bne t1, t2, t_clz

    li t1, 0x11223344
    li t2, 0x0
    xnor t1, t1, t2
    li t2, 0xEEDDCCBB
    bne t1, t2, t_clz

    li t2, 0xFFFF
    xnor t1, a2, t2
    sw t1, 0(gp) # *gp = xnor(a2, 0xFFFF)
    addi gp, gp, 4
    ori s1, s1, 4
t_clz:
    andi t0, a1, 8
    beqz t0, t_ctz # skip test

    li  t1, 0xFFFF0000
    clz t1, t1
    li  t2, 0
    bne t1, t2, t_ctz

    li  t1, 0x0000FFFF
    clz t1, t1
    li  t2, 16
    bne t1, t2, t_ctz

    clz t1, a2
    sw t1, 0(gp) # *gp = clz(a2)
    addi gp, gp, 4
    ori s1, s1, 8
t_ctz:
    andi t0, a1, 16
    beqz t0, t_pack # skip test

    li  t1, 0xFFFF0000
    ctz t1, t1
    li  t2, 16
    bne t1, t2, t_pack

    li  t1, 0x0000FFFF
    ctz t1, t1
    li  t2, 0
    bne t1, t2, t_pack

    ctz t1, a2
    sw t1, 0(gp) # *gp = ctz(a2)
    addi gp, gp, 4
    ori s1, s1, 16
t_pack:
    andi t0, a1, 32
    beqz t0,  t_min # skip test

    li t1, 0xFFFF0002
    li t2, 3
    pack t1, t1, t2
    li t2, 0x00030002
    bne t1, t2, t_min

    li t1, 0x00000003
    li t2, 0xFFFF1112
    pack t1, t1, t2
    li t2, 0x11120003
    bne t1, t2, t_min

    li t2, 0xAAAA5555
    pack t1, a2, t2
    sw t1, 0(gp) # *gp = pack(a2, 0xAAAA5555)
    addi gp, gp, 4
    ori s1, s1, 32
t_min:
    andi t0, a1, 64
    beqz t0, t_minu # skip test

    li t1, 0x1
    li t2, 0x2
    min t1, t1, t2
    li t2, 0x1
    bne t1, t2, t_minu

    li t1, 0x2
    li t2, 0x1
    min t1, t1, t2
    li t2, 0x1
    bne t1, t2, t_minu

    li t1, 0xFFFFFFFF
    li t2, 0x1
    min t1, t1, t2
    li t2, 0xFFFFFFFF
    bne t1, t2, t_minu

    li t1, 0xAAAA5555
    min t1, a2, t1
    sw t1, 0(gp) # *gp = min(a2, 0xAAAA5555)
    addi gp, gp, 4
    ori s1, s1, 64
t_minu:
    andi t0, a1, 128
    beqz t0, sbset # skip test

    li t1, 0x1
    li t2, 0x2
    minu t1, t1, t2
    li t2, 0x1
    bne t1, t2, sbset

    li t1, 0x2
    li t2, 0x1
    minu t1, t1, t2
    li t2, 0x1
    bne t1, t2, sbset

    li t1, 0xFFFFFFFF
    li t2, 0x1
    minu t1, t1, t2
    li t2, 0x1
    bne t1, t2, sbset

    li t1, 0xAAAA5555
    minu t1, a2, t1
    sw t1, 0(gp) # *gp = minu(a2, 0xAAAA5555)
    addi gp, gp, 4
    ori s1, s1, 128
sbset:
    andi t0, a1, 256
    beqz t0, sbclr # skip test

    li t1, 0x00000000
    li t2, 0xFF000000
    sbset t1, t1, t2
    li t2, 0x00000001
    bne t1, t2, sbclr

    li t1, 0x12340000
    li t2, 32
    sbset t1, t1, t2
    li t2, 0x12340001
    bne t1, t2, sbclr

    li t1, 0x12340000
    li t2, 31
    sbset t1, t1, t2
    li t2, 0x92340000
    bne t1, t2, sbclr

    li t1, 0xAAAA5555
    sbset t1, t1, a2
    sw t1, 0(gp) # *gp = sbset(0xAAAA5555, a2)
    addi gp, gp, 4
    ori s1, s1, 256
sbclr:
    andi t0, a1, 512
    beqz t0, tret # skip test

    li t1, 0xFFFFFFFF
    li t2, 0xFF000000
    sbclr t1, t1, t2
    li t2, 0xFFFFFFFE
    bne t1, t2, tret

    li t1, 0x1234FFFF
    li t2, 32
    sbclr t1, t1, t2
    li t2, 0x1234FFFE
    bne t1, t2, tret

    li t1, 0x80000000
    li t2, 31
    sbclr t1, t1, t2
    li t2, 0x00000000
    bne t1, t2, tret

    li t1, 0xAAAA5555
    sbclr t1, t1, a2
    sw t1, 0(gp) # *gp = sbclr(0xAAAA5555, a2)
    addi gp, gp, 4
    ori s1, s1, 512
tret:
    li t0, 0xfeed0000
    or t0, t0, s1
    xor t0, t0, a2
    sw t0, 0(s0) # *s0 = t0
    sw gp, 0xc(s0) # *(s0+0xc) = gp
end:
    j  end
