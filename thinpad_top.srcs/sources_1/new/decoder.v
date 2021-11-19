`default_nettype none
`timescale 1ns / 100ps
`include "ops.vh"
`include "alu.vh"
`include "exception_interrupt.vh"

module decoder(
    input wire[31:0]        inst,
    input wire[31:0]        data1,
    input wire[31:0]        data2,
    /*input wire              br_eq,
    input wire              br_lt,
    input wire              br_a_eqz,
    input wire              br_b_eqz,*/
    output wire[5:0]        ext_op,
    output wire[4:0]        alu_op,
    output wire[31:0]       imm,
    output wire             b_select,
    output wire             a_select,
    output wire[4:0]        reg_a,
    output wire[4:0]        reg_b,
    output wire[4:0]        reg_d,
    output wire[11:0]       csr,
    output wire             b_dat_select,
    output wire             pc_select,
    output wire             mem_wr,
    output wire[1:0]        mem_to_reg,
    output wire             reg_wr,
    output wire             csr_reg_wr,
    output wire             tlb_clr,
    output wire[3:0]        exception
);

    wire        sign;
    wire[26:0]  unsign_ext;
    wire[19:0]  sign_ext;
    wire[10:0]  sign_ext_jal;

    reg[4:0]    ext_op_reg;
    reg[4:0]    alu_op_reg;
    reg[31:0]   imm_reg;
    reg[1:0]    mem_to_reg_reg;
    reg         a_select_reg, b_select_reg, pc_select_reg, b_dat_select_reg, mem_wr_reg, reg_wr_reg, csr_reg_wr_reg;
    reg         exception_reg;
    reg         tlb_clr_reg;

    assign sign = inst[31];
    assign unsign_ext = { 27{ 1'b0 } };
    assign sign_ext = { 20{ sign } };
    assign sign_ext_jal = { 11{ sign } };
    assign reg_d = inst[11:7];
    assign reg_a = ext_op == `OP_LUI ? 5'b00000 : inst[19:15];
    assign reg_b = inst[24:20];
    assign csr = inst[31:20];

    assign ext_op = ext_op_reg;
    assign alu_op = alu_op_reg;
    assign imm = imm_reg;
    assign a_select = a_select_reg, b_select = b_select_reg, pc_select = pc_select_reg, b_dat_select = b_dat_select_reg;
    assign mem_wr = mem_wr_reg, mem_to_reg = mem_to_reg_reg, reg_wr = reg_wr_reg, csr_reg_wr = csr_reg_wr_reg;
    assign tlb_clr = tlb_clr_reg;
    assign exception = exception_reg;

    always @(*) begin
        ext_op_reg = `OP_INVALID;
        alu_op_reg = `ZERO;
        imm_reg = 32'h0;
        b_select_reg = 1'b0;
        a_select_reg = 1'b0;
        pc_select_reg = 1'b0;
        b_dat_select_reg = 1'b0;
        mem_wr_reg = 1'b0;
        mem_to_reg_reg = 2'b00;
        reg_wr_reg = 1'b0;
        csr_reg_wr_reg = 1'b0;
        tlb_clr_reg = 1'b0;
        exception_reg = `NO_EXC;
        
        case(inst[6:0])
            7'b0000011: begin // LW, LB
                case(inst[14:12])
                    3'b000: begin
                        ext_op_reg = `OP_LB;
                    end
                    3'b010: begin
                        ext_op_reg = `OP_LW;
                    end
                    default: begin
                        exception_reg = `ILLEGAL_INSTR_EXC;
                    end
                endcase
                alu_op_reg = `ADD;
                imm_reg = { sign_ext, inst[31:20] };
                reg_wr_reg = 1'b1;
            end

            7'b0100011: begin // SW, SB
                case(inst[14:12])
                    3'b000: begin
                        ext_op_reg = `OP_SB;
                    end
                    3'b010: begin
                        ext_op_reg = `OP_SW;
                    end
                    default: begin
                        exception_reg = `ILLEGAL_INSTR_EXC;
                    end
                endcase
                alu_op_reg = `ADD;
                imm_reg = { sign_ext, inst[31:25], inst[11:7] };
                mem_wr_reg = 1'b1;
            end

            7'b0010011: begin // ADDI, ANDI, ORI, SLLI, SRLI
                case(inst[14:12])
                    3'b000: begin
                        ext_op_reg = `OP_ADD;
                        alu_op_reg = `ADD;
                        imm_reg = { sign_ext, inst[31:20] };
                    end
                    3'b110: begin
                        ext_op_reg = `OP_OR;
                        alu_op_reg = `OR;
                        imm_reg = { sign_ext, inst[31:20] };
                    end
                    3'b111: begin
                        ext_op_reg = `OP_AND;
                        alu_op_reg = `AND;
                        imm_reg = { sign_ext, inst[31:20] };
                    end
                    3'b001: begin
                        ext_op_reg = `OP_SLL;
                        alu_op_reg = `SLL;
                        imm_reg = { unsign_ext, inst[24:20] };
                    end
                    3'b101: begin
                        ext_op_reg = `OP_SRL;
                        alu_op_reg = `SRL;
                        imm_reg = { unsign_ext, inst[24:20] };
                    end
                    default: begin
                        exception_reg = `ILLEGAL_INSTR_EXC;
                    end
                endcase
                mem_to_reg_reg = 2'b01;
                reg_wr_reg = 1'b1;
            end

            7'b0110011: begin // ADD, AND, ANDN, OR, XOR, XNOR, MINU, SLTU
                case({ inst[31:25], inst[14:12] })
                    10'b0000000_000: begin
                        ext_op_reg = `OP_ADD;
                        alu_op_reg = `ADD;
                    end
                    10'b0000000_110: begin
                        ext_op_reg = `OP_OR;
                        alu_op_reg = `OR;
                    end
                    10'b0000000_111: begin
                        ext_op_reg = `OP_AND;
                        alu_op_reg = `AND;
                    end
                    10'b0000000_100: begin
                        ext_op_reg = `OP_XOR;
                        alu_op_reg = `XOR;
                    end
                    10'b0100000_111: begin
                        ext_op_reg = `OP_AND;
                        alu_op_reg = `ANDN;
                    end
                    10'b0100000_100: begin
                        ext_op_reg = `OP_XOR;
                        alu_op_reg = `XNOR;
                    end
                    10'b0000101_110: begin
                        ext_op_reg = `OP_MIN;
                        alu_op_reg = `MINU;
                    end
                    10'b0000000_011: begin
                        ext_op_reg = `OP_SLT;
                        alu_op_reg = `SLTU;
                    end
                    default: begin
                        exception_reg = `ILLEGAL_INSTR_EXC;
                    end
                endcase
                b_select_reg = 1'b1;
                mem_to_reg_reg = 2'b01;
                reg_wr_reg = 1'b1;
            end

            7'b0110111: begin // LUI
                ext_op_reg = `OP_LUI;
                alu_op_reg = `ADD;
                imm_reg = { inst[31:12], 12'h000 };
                mem_to_reg_reg = 2'b01;
                reg_wr_reg = 1'b1;
            end

            7'b0010111: begin // AUIPC
                ext_op_reg = `OP_AUIPC;
                alu_op_reg = `ADD;
                a_select_reg = 1'b1;
                imm_reg = { inst[31:12], 12'h000 };
                mem_to_reg_reg = 2'b01;
                reg_wr_reg = 1'b1;
            end

            7'b1100011: begin // BEQ, BNE, BLT
                alu_op_reg = `ADD;
                imm_reg = { sign_ext, inst[7], inst[30:25], inst[11:8], 1'b0 };
                a_select_reg = 1'b1;
                case(inst[14:12])
                    3'b000: begin // BEQ
                        ext_op_reg = `OP_BEQ;
                        if(data1 == data2) begin
                            pc_select_reg = 1'b1;
                        end
                    end
                    3'b001: begin // BNE
                        ext_op_reg = `OP_BNE;
                        if(data1 != data2) begin
                            pc_select_reg = 1'b1;
                        end
                    end
                    3'b100: begin // BLT
                        ext_op_reg = `OP_BLT;
                        if($signed(data1) < $signed(data2)) begin
                            pc_select_reg = 1'b1;
                        end
                    end
                    3'b101: begin // BGE
                        ext_op_reg = `OP_BGE;
                        if($signed(data1) >= $signed(data2)) begin
                            pc_select_reg = 1'b1;
                        end
                    end
                    3'b110: begin // BLTU
                        ext_op_reg = `OP_BLTU;
                        if(data1 < data2) begin
                            pc_select_reg = 1'b1;
                        end
                    end
                    3'b111: begin // BGEU
                        ext_op_reg = `OP_BGEU;
                        if(data1 >= data2) begin
                            pc_select_reg = 1'b1;
                        end
                    end
                    default: begin
                        exception_reg = `ILLEGAL_INSTR_EXC;
                    end
                endcase
            end

            7'b1101111: begin // JAL
                ext_op_reg = `OP_JAL;
                alu_op_reg = `ADD;
                imm_reg = { sign_ext_jal, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0 };
                a_select_reg = 1'b1;
                pc_select_reg = 1'b1;
                mem_to_reg_reg = 2'b10;
                reg_wr_reg = 1'b1;
            end

            7'b1100111: begin // JALR
                ext_op_reg = `OP_JALR;
                alu_op_reg = `ADD;
                imm_reg = { sign_ext, inst[31:20] };
                pc_select_reg = 1'b1;
                mem_to_reg_reg = 2'b10;
                reg_wr_reg = 1'b1;
            end

            7'b1110011: begin // CSRRC, CSRRS, CSRRW, EBREAK, ECALL, MRET, SFENCE_VMA
                case(inst[14:12])
                    3'b000: begin // ECALL, EBREAK, MRET, SFENCE_VMA
                        case(inst[31:25])
                            7'b0000000: begin // ECALL, EBREAK
                                case(inst[24:20])
                                    5'b00000: begin // ECALL
                                        ext_op_reg = `OP_ECALL;
                                        alu_op_reg = `ADD;
                                    end
                                    5'b00001: begin // EBREAK
                                        ext_op_reg = `OP_EBREAK;
                                        alu_op_reg = `ADD;
                                    end
                                    default: begin
                                        exception_reg = `ILLEGAL_INSTR_EXC;
                                    end
                                endcase
                            end
                            7'b0011000: begin // MRET
                                case(inst[24:20])
                                    5'b00010: begin
                                        ext_op_reg = `OP_MRET;
                                        alu_op_reg = `ADD;
                                    end
                                    default: begin
                                        exception_reg = `ILLEGAL_INSTR_EXC;
                                    end
                                endcase
                            end
                            7'b0001001: begin // SFENCE_VMA
                                ext_op_reg = `OP_SFENCE_VMA;
                                if (data1 == 32'h00000000 && data2 == 32'h00000000) begin
                                    tlb_clr_reg = 1'b1;
                                end
                                else begin
                                    tlb_clr_reg = 1'b0;
                                end 
                            end
                            default: begin
                                exception_reg = `ILLEGAL_INSTR_EXC;
                            end
                        endcase
                    end
                    3'b011: begin // CSRRC
                        ext_op_reg = `OP_CSRR;
                        alu_op_reg = `NANDN;
                        b_select_reg = 1'b1;
                        b_dat_select_reg = 1'b1;
                        mem_to_reg_reg = 2'b11;
                        reg_wr_reg = 1'b1;
                        csr_reg_wr_reg = 1'b1;
                    end
                    3'b010: begin // CSRRS
                        ext_op_reg = `OP_CSRR;
                        alu_op_reg = `OR;
                        b_select_reg = 1'b1;
                        b_dat_select_reg = 1'b1;
                        mem_to_reg_reg = 2'b11;
                        reg_wr_reg = 1'b1;
                        csr_reg_wr_reg = 1'b1;
                    end
                    3'b001: begin // CSRRW
                        ext_op_reg = `OP_CSRR;
                        alu_op_reg = `A;
                        b_select_reg = 1'b1;
                        b_dat_select_reg = 1'b1;
                        mem_to_reg_reg = 2'b11;
                        reg_wr_reg = 1'b1;
                        csr_reg_wr_reg = 1'b1;
                    end
                    default: begin
                        exception_reg = `ILLEGAL_INSTR_EXC;
                    end
                endcase
            end
            default: begin
                exception_reg = `ILLEGAL_INSTR_EXC;
            end
        endcase
    end

endmodule
