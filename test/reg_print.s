    .org 0x0
    .global print_reg
    .text

# print registers, this will override x25 - x31
print_reg:
    lui   x30, 0x10000
    addi  x25, x0, 10

print1:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x1
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print2:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x32        # '2'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x2
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print3:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x33        # '3'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x3
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print4:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x34        # '4'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x4
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print5:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x35        # '5'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x5
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print6:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x36        # '6'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x6
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print7:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x37        # '7'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x7
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print8:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x38        # '8'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x8
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print9:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x39        # '9'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x9
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print10:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x30        # '0'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x10
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print11:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x11
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print12:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x32        # '2'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x12
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print13:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x33        # '3'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x13
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print14:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x34        # '4'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x14
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print15:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x35        # '5'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x15
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print16:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x36        # '6'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x16
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print17:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x37        # '7'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x17
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print18:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x38        # '8'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x18
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print19:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x31        # '1'
    jal   x28, print_x29
    addi  x29, x0, 0x39        # '9'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x19
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

print20:
    addi  x29, x0, 0x24        # '$'
    jal   x28, print_x29
    addi  x29, x0, 0x32        # '2'
    jal   x28, print_x29
    addi  x29, x0, 0x30        # '0'
    jal   x28, print_x29
    addi  x29, x0, 0x3a        # ':'
    jal   x28, print_x29
    add   x29, x0, x20
    jal   x28, print_x29_num
    addi  x29, x0, 0x20        # ' '
    jal   x28, print_x29

end:                           # end here
    beq   x0, x0, end

print_x29:                     # print x29[7:0] as a char
loop:
    lb    x31, 5(x30)
    andi  x31, x31, 0x20
    bne   x31, x0, write_x29
    jal   x0, loop
write_x29:
    sb    x29, 0(x30)
    jalr  x0, 0(x28)

print_x29_num:                 # print x29 as a 32bit number
    srli  x27, x29, 28
    andi  x27, x27, 15
    jal   x26, print_x27_hex
    srli  x27, x29, 24
    andi  x27, x27, 15
    jal   x26, print_x27_hex
    srli  x27, x29, 20
    andi  x27, x27, 15
    jal   x26, print_x27_hex
    srli  x27, x29, 16
    andi  x27, x27, 15
    jal   x26, print_x27_hex
    srli  x27, x29, 12
    andi  x27, x27, 15
    jal   x26, print_x27_hex
    srli  x27, x29, 8
    andi  x27, x27, 15
    jal   x26, print_x27_hex
    srli  x27, x29, 4
    andi  x27, x27, 15
    jal   x26, print_x27_hex
    srli  x27, x29, 0
    andi  x27, x27, 15
    jal   x26, print_x27_hex
    jalr  x0, 0(x28)

print_x27_hex:                 # print x27[3:0] as a hex digit
    blt   x27, x25, print_x27_hex_lt10
print_x27_hex_gt10:            # x27 >= 10 then add 87
    addi  x27, x27, 87
    beq   x0, x0, loop_x27
print_x27_hex_lt10:            # x27 < 10 then add 48
    addi  x27, x27, 48
loop_x27:
    lb    x31, 5(x30)
    andi  x31, x31, 0x20
    bne   x31, x0, write_x27
    jal   x0, loop_x27
write_x27:
    sb    x27, 0(x30)
    jalr  x0, 0(x26)
