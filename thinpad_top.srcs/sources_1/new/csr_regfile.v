`default_nettype none
`timescale 1ns / 1ps
`include "csr_index.vh"

module csr_regfile(
    input wire          clk,
    input wire          rst,

    // for read 
    input wire[11:0]    csr_raddr,
    output reg[31:0]    csr_rdata,

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
    input wire[31:0]    mtvec_wdata,
    input wire[31:0]    mscratch_wdata,
    input wire[31:0]    mepc_wdata,
    input wire[31:0]    mcause_wdata,
    input wire[31:0]    mstatus_wdata,
    input wire[31:0]    mie_wdata,
    input wire[31:0]    mip_wdata,
    input wire[31:0]    mtval_wdata,

    // for writeback
    input wire          csr_we,
    input wire[11:0]    csr_waddr,
    input wire[31:0]    csr_wdata
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
            reg_mstatus <= 32'h00001800;
            reg_mie <= 32'h00000000;
            reg_mip <= 32'h00000000;
            reg_mtval <= 32'h00000000;
        end
        else begin
            if (mtvec_we) begin
                reg_mtvec <= mtvec_wdata;
            end
            else begin
            end
            if (mscratch_we) begin
                reg_mscratch <= mscratch_wdata;
            end
            else begin
            end
            if (mepc_we) begin
                reg_mepc <= mepc_wdata;
            end
            else begin
            end
            if (mcause_we) begin
                reg_mcause <= mcause_wdata;
            end
            else begin
            end
            if (mstatus_we) begin
                reg_mstatus <= mstatus_wdata;
            end
            else begin
            end
            if (mie_we) begin
                reg_mie <= mie_wdata;
            end
            else begin
            end
            if (mip_we) begin
                reg_mip <= mip_wdata;
            end
            else begin
            end
            if (mtval_we) begin
                reg_mtval <= mtval_wdata;
            end
            else begin
            end
            if (csr_we) begin
                case(csr_waddr)
                    `MTVEC: begin
                        if (!mtval_we) begin
                            reg_mtvec <= csr_wdata;
                        end
                        else begin
                        end
                    end
                    `MSCRATCH: begin
                        if (!mscratch_we) begin
                            reg_mscratch <= csr_wdata;
                        end
                        else begin
                        end
                    end
                    `MEPC: begin
                        if (!mepc_we) begin
                            reg_mepc <= csr_wdata;
                        end
                        else begin
                        end
                    end
                    `MCAUSE: begin
                        if (!mcause_we) begin
                            reg_mcause <= csr_wdata;
                        end
                        else begin
                        end
                    end
                    `MSTATUS: begin
                        if (!mstatus_we) begin
                            reg_mstatus <= csr_wdata;
                        end
                        else begin
                        end
                    end
                    `MIE: begin
                        if (!mie_we) begin
                            reg_mie <= csr_wdata;
                        end
                        else begin
                        end
                    end
                    `MIP: begin
                        if (!mip_we) begin
                            reg_mip <= csr_wdata;
                        end
                        else begin
                        end
                    end
                    `MTVAL: begin
                        if (!mtval_we) begin
                            reg_mtval <= csr_wdata;
                        end
                        else begin
                        end
                    end
                    default: begin
                    end
                endcase
            end
            else begin
            end
        end
    end

    always @(*) begin
        case(csr_raddr)
            `MTVEC: begin
                csr_rdata = reg_mtvec;
            end
            `MSCRATCH: begin
                csr_rdata = reg_mscratch;
            end
            `MEPC: begin
                csr_rdata = reg_mepc;
            end
            `MCAUSE: begin
                csr_rdata = reg_mcause;
            end
            `MSTATUS: begin
                csr_rdata = reg_mstatus;
            end
            `MIE: begin
                csr_rdata = reg_mie;
            end
            `MIP: begin
                csr_rdata = reg_mip;
            end
            `MTVAL: begin
                csr_rdata = reg_mtval;
            end
            default: begin
                csr_rdata = 32'h00000000;
            end
        endcase
    end

endmodule
