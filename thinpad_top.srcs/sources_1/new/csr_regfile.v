`default_nettype none
`timescale 1ns / 1ps
`include "csr_index.vh"

module csr_regfile(
    input wire          clk,
    input wire          rst,

    // for decoder use 
    input wire[11:0]    csr,
    output reg[31:0]    csr_data,

    // for read
    output wire[31:0]   mtvec,
    output wire[31:0]   mscratch,
    output wire[31:0]   mepc,
    output wire[31:0]   mcause,
    output wire[31:0]   mstatus,
    output wire[31:0]   mie,
    output wire[31:0]   mip,
    output wire[31:0]   mtval,

    // for write
    input wire          mtvec_we,
    input wire          mscratch_we,
    input wire          mepc_we,
    input wire          mcause_we,
    input wire          mstatus_we,
    input wire          mie_we,
    input wire          mip_we,
    input wire          mtval_we,
    input wire[31:0]    mtvec_write_data,
    input wire[31:0]    mscratch_write_data,
    input wire[31:0]    mepc_write_data,
    input wire[31:0]    mcause_write_data,
    input wire[31:0]    mstatus_write_data,
    input wire[31:0]    mie_write_data,
    input wire[31:0]    mip_write_data,
    input wire[31:0]    mtval_write_data,

    // for writeback
    input wire          csr_we,
    input wire[11:0]    csr_write_addr,
    input wire[31:0]    csr_write_data
);
    reg[31:0]           reg_mtvec;
    reg[31:0]           reg_mscratch;
    reg[31:0]           reg_mepc;
    reg[31:0]           reg_mcause;
    reg[31:0]           reg_mstatus;
    reg[31:0]           reg_mie;
    reg[31:0]           reg_mip;
    reg[31:0]           reg_mtval;
    assign              mtvec = reg_mtvec;
    assign              mscratch = reg_mscratch;
    assign              mepc = reg_mepc;
    assign              mcause = reg_mcause;
    assign              mstatus = reg_mstatus;
    assign              mie = reg_mie;
    assign              mip = reg_mip;
    assign              mtval = reg_mtval;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_mtvec <= 32'h00000000;
            reg_mscratch <= 32'h00000000;
            reg_mepc <= 32'h00000000;
            reg_mcause <= 32'h00000000;
            reg_mstatus <= 32'h00000000;
            reg_mie <= 32'h00000000;
            reg_mip <= 32'h00000000;
            reg_mtval <= 32'h00000000;
        end
        else begin
            if (mtvec_we) begin
                reg_mtvec <= mtvec_write_data;
            end
            if (mscratch_we) begin
                reg_mscratch <= mscratch_write_data;
            end
            if (mepc_we) begin
                reg_mepc <= mepc_write_data;
            end
            if (mcause_we) begin
                reg_mcause <= mcause_write_data;
            end
            if (mstatus_we) begin
                reg_mstatus <= mstatus_write_data;
            end
            if (mie_we) begin
                reg_mie <= mie_write_data;
            end
            if (mip_we) begin
                reg_mip <= mip_write_data;
            end
            if (mtval_we) begin
                reg_mtval <= mtval_write_data;
            end
            if (csr_we) begin
                case(csr_write_addr)
                    `MTVEC: begin
                        if (!mtval_we) begin
                            reg_mtvec <= csr_write_data;
                        end
                        else begin
                        end
                    end
                    `MSCRATCH: begin
                        if (!mscratch_we) begin
                            reg_mscratch <= csr_write_data;
                        end
                        else begin
                        end
                    end
                    `MEPC: begin
                        if (!mepc_we) begin
                            reg_mepc <= csr_write_data;
                        end
                        else begin
                        end
                    end
                    `MCAUSE: begin
                        if (!mcause_we) begin
                            reg_mcause <= csr_write_data;
                        end
                        else begin
                        end
                    end
                    `MSTATUS: begin
                        if (!mstatus_we) begin
                            reg_mstatus <= csr_write_data;
                        end
                        else begin
                        end
                    end
                    `MIE: begin
                        if (!mie_we) begin
                            reg_mie <= csr_write_data;
                        end
                        else begin
                        end
                    end
                    `MIP: begin
                        if (!mip_we) begin
                            reg_mip <= csr_write_data;
                        end
                        else begin
                        end
                    end
                    `MTVAL: begin
                        if (!mtval_we) begin
                            reg_mtval <= csr_write_data;
                        end
                        else begin
                        end
                    end
                    default: begin
                    end
                endcase
            end
        end
    end

    always @(*) begin
        case(csr)
            `MTVEC: begin
                csr_data <= reg_mtvec;
            end
            `MSCRATCH: begin
                csr_data <= reg_mscratch;
            end
            `MEPC: begin
                csr_data <= reg_mepc;
            end
            `MCAUSE: begin
                csr_data <= reg_mcause;
            end
            `MSTATUS: begin
                csr_data <= reg_mstatus;
            end
            `MIE: begin
                csr_data <= reg_mie;
            end
            `MIP: begin
                csr_data <= reg_mip;
            end
            `MTVAL: begin
                csr_data <= reg_mtval;
            end
            default: begin
                csr_data <= 32'h00000000;
            end
        endcase
    end

endmodule
