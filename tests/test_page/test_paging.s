.globl _start
.text
_start:
    # user code 
    # [0x00000000, 0x002fffff] -> [0x80100000, 0x803fffff]
    lui  t1, 0x00000
    lw   t0, (t1)
    lui  t1, 0x00300
    addi t1, t1, -1
    lw   t0, (t1)
    # user data 
    # [0x7fc10000, 0x7fffffff] -> [0x80400000, 0x807effff]
    lui  t1, 0x7fc10
    lw   t0, (t1)
    lui  t1, 0x80000
    addi t1, t1, -1
    lw   t0, (t1)
    # kernel 
    # [0x80000000, 0x80000fff] -> [0x80000000, 0x80000fff]
    lui  t1, 0x80000
    lw   t0, (t1)
    lui  t1, 0x80001
    addi t1, t1, -1
    lw   t0, (t1)
    # utest 
    # [0x80001000, 0x80001fff] -> [0x80001000, 0x80001fff]
    lui  t1, 0x80001
    lw   t0, (t1)
    lui  t1, 0x80002
    addi t1, t1, -1
    lw   t0, (t1)
    # test 
    # [0x80100000, 0x80100fff] -> [0x80100000, 0x80100fff]
    lui  t1, 0x80100
    lw   t0, (t1)
    lui  t1, 0x80101
    addi t1, t1, -1
    lw   t0, (t1)
_end:
    j _end
