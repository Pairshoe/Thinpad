#### Commands in brief

```assembly
ADD   0000000SSSSSsssss000ddddd0110011
ADDI  iiiiiiiiiiiisssss000ddddd0010011
AND   0000000SSSSSsssss111ddddd0110011
ANDI  iiiiiiiiiiiisssss111ddddd0010011
AUIPC iiiiiiiiiiiiiiiiiiiiddddd0010111
BEQ   iiiiiiiSSSSSsssss000iiiii1100011
BNE   iiiiiiiSSSSSsssss001iiiii1100011
JAL   iiiiiiiiiiiiiiiiiiiiddddd1101111
JALR  iiiiiiiiiiiisssss000ddddd1100111
LB    iiiiiiiiiiiisssss000ddddd0000011
LUI   iiiiiiiiiiiiiiiiiiiiddddd0110111
LW    iiiiiiiiiiiisssss010ddddd0000011
OR    0000000SSSSSsssss110ddddd0110011
ORI   iiiiiiiiiiiisssss110ddddd0010011
SB    iiiiiiiSSSSSsssss000iiiii0100011
SLLI  0000000iiiiisssss001ddddd0010011
SRLI  0000000iiiiisssss101ddddd0010011
SW    iiiiiiiSSSSSsssss010iiiii0100011
XOR   0000000SSSSSsssss100ddddd0110011
```

#### +3

```assembly
ANDN  0100000SSSSSsssss111ddddd0110011
MINU  0000101SSSSSsssss110ddddd0110011
XNOR  0100000SSSSSsssss100ddddd0110011
```

#### supplementary

```assembly
BLT   iiiiiiiSSSSSsssss100iiiii1100011
```



#### br_comparator

| 信号 | rdata1        | rdata2        | br_eq              | br_lt              |
| ---- | ------------- | ------------- | ------------------ | ------------------ |
| 属性 | in wire[31:0] | in wire[31:0] | out wire           | out wire           |
| 描述 |               |               | rdata1=rdata2才为1 | rdata1<rdata2才为1 |



#### decoder

sign_ext = 20{inst[31]}

sign_ext_jal = 11{inst[31]}

unsign_ext = 27{0}

| 信号    | inst          | br_eq          | br_lt          | ext_op         | alu_op        | imm                                                          | b_select            | a_select           | reg_a         | reg_b         | reg_d         | pc_select                   | mem_wr       | mem_to_reg                     | reg_wr   |                      |
| ------- | ------------- | -------------- | -------------- | -------------- | ------------- | ------------------------------------------------------------ | ------------------- | ------------------ | ------------- | ------------- | ------------- | --------------------------- | ------------ | ------------------------------ | -------- | -------------------- |
| 属性    | in wire[31:0] | in wire        | in wire        | out wire[4:0]  | out wire[3:0] | out wire[31:0]                                               | out wire            | out wire           | out wire[4:0] | out wire[4:0] | out wire[4:0] | out wire                    | out wire     | out wire[1:0]                  | out wire |                      |
| 描述    |               | a=b为1,否则为0 | a<b为1,否则为0 | 执行阶段操作码 | alu操作码     |                                                              | 选imm代替reg_b则为0 | 选pc代替reg_a则为1 |               |               |               | pc<-pc+4为0，pc<-alu结果为1 | 读为0，写为1 | 选内存为0,选alu为1,选(PC+4)为2 | 写为1    |                      |
| add     |               |                |                | OP_ADD         | ADD           | /                                                            | 1                   | 0                  | inst[19:15]   | inst[24:20]   | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| addi    |               |                |                | OP_ADD         | ADD           | {sign_ext,inst[31:20]}                                       | 0                   | 0                  | inst[19:15]   | /             | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| and     |               |                |                | OP_AND         | AND           | /                                                            | 1                   | 0                  | inst[19:15]   | inst[24:20]   | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| andn    |               |                |                | OP_AND         | ANDN          | /                                                            | 1                   | 0                  | inst[19:15]   | inst[24:20]   | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| andi    |               |                |                | OP_AND         | AND           | {sign_ext,inst[31:20]}                                       | 0                   | 0                  | inst[19:15]   | /             | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| or      |               |                |                | OP_OR          | OR            | /                                                            | 1                   | 0                  | inst[19:15]   | inst[24:20]   | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| ori     |               |                |                | OP_OR          | OR            | {sign_ext,inst[31:20]}                                       | 0                   | 0                  | inst[19:15]   | /             | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| xor     |               |                |                | OP_XOR         | XOR           | /                                                            | 1                   | 0                  | inst[19:15]   | inst[24:20]   | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| xnor    |               |                |                | OP_XOR         | XNOR          | /                                                            | 1                   | 0                  | inst[19:15]   | inst[24:20]   | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| minu    |               |                |                | OP_MIN         | MINU          | /                                                            | 1                   | 0                  | inst[19:15]   | inst[24:20]   | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| slli    |               |                |                | OP_SLL         | SLL           | {unsign_ext,inst[24:20]}                                     | 0                   | 0                  | inst[19:15]   | /             | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| srli    |               |                |                | OP_SRL         | SRL           | {unsign_ext,inst[24:20]}                                     | 0                   | 0                  | inst[19:15]   | /             | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| lui     |               |                |                | OP_LUI         | ADD           | {inst[31:12],12'h000}                                        | 0                   | 0                  | 0             | /             | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| auipc   |               |                |                | OP_AUIPC       | ADD           | {inst[31:12],12'h000}                                        | 0                   | 1                  | /             | /             | inst[11:7]    | 0                           | 0            | 1                              | 1        |                      |
| lb      |               |                |                | OP_LB          | ADD           | {sign_ext, inst[31:20]}                                      | 0                   | 0                  | inst[19:15]   | /             | inst[11:7]    | 0                           | 0            | 0                              | 1        |                      |
| lw      |               |                |                | OP_LW          | ADD           | {sign_ext, inst[31:20]}                                      | 0                   | 0                  | inst[19:15]   | /             | inst[11:7]    | 0                           | 0            | 0                              | 1        |                      |
| sb      |               |                |                | OP_SB          | ADD           | {sign_ext, inst[31:25], inst[11:7]}                          | 0                   | 0                  | inst[19:15]   | inst[24:20]   | inst[11:7]    | 0                           | 1            | /                              | 0        | 存的值为reg_d的低8位 |
| sw      |               |                |                | OP_SW          | ADD           | {sign_ext, inst[31:25], inst[11:7]}                          | 0                   | 0                  | inst[19:15]   | inst[24:20]   | inst[11:7]    | 0                           | 1            | /                              | 0        | 存的值为reg_d        |
| beq     |               | 1              |                | OP_BEQ         | ADD           | {sign_ext,inst[7],inst[30:25],inst[11:8],1'b0}               | 0                   | 1                  | /             | /             | /             | 1                           | 0            | /                              | 0        |                      |
|         |               | 0              |                | OP_BEQ         | ADD           | /                                                            | /                   | /                  | /             | /             | /             | 0                           | 0            | /                              | 0        |                      |
| bne     |               | 0              |                | OP_BNE         | ADD           | /                                                            | /                   | /                  | /             | /             | /             | 0                           | 0            | /                              | 0        |                      |
|         |               | 1              |                | OP_BNE         | ADD           | {sign_ext,inst[7],inst[30:25],inst[11:8],1'b0}               | 0                   | 1                  | /             | /             | /             | 1                           | 0            | /                              | 0        |                      |
| **blt** |               |                | 1              | OP_BLT         | ADD           | {sign_ext,inst[7],inst[30:25],inst[11:8],1'b0}               | 0                   | 1                  | /             | /             | /             | 1                           | 0            | /                              | 0        |                      |
|         |               |                | 0              | OP_BLT         | ADD           | /                                                            | /                   | /                  | /             | /             | /             | 0                           | 0            | /                              | 0        |                      |
| jal     |               |                |                | OP_JAL         | ADD           | {sign_ext_jal,inst[31],inst[19:12],inst[20],inst[30:21],1'b0} | 0                   | 1                  | /             | /             | inst[11:7]    | 1                           | 0            | 2                              | 1        |                      |
| jalr    |               |                |                | OP_JALR        | ADD           | {sign_ext,inst[31:20]}                                       | 0                   | 0                  | inst[19:15]   | /             | inst[11:7]    | 1                           | 0            | 2                              | 1        | ALU结果最低位清零    |

