`default_nettype none
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
    output wire[31:0]   satp,
    output wire[1:0]    mode, 

    // for write
    input wire          mtvec_we,
    input wire          mscratch_we,
    input wire          mepc_we,
    input wire          mcause_we,
    input wire          mstatus_we,
    input wire          mie_we,
    input wire          mip_we,
    input wire          mtval_we,
    input wire          satp_we,
    input wire          mode_we,
    input wire[31:0]    mtvec_wdata,
    input wire[31:0]    mscratch_wdata,
    input wire[31:0]    mepc_wdata,
    input wire[31:0]    mcause_wdata,
    input wire[31:0]    mstatus_wdata,
    input wire[31:0]    mie_wdata,
    input wire[31:0]    mip_wdata,
    input wire[31:0]    mtval_wdata,
    input wire[31:0]    satp_wdata,
    input wire[1:0]     mode_wdata,

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
    reg[31:0]           reg_satp;
    reg[1:0]            reg_mode;
    assign              mtvec = reg_mtvec;
    assign              mscratch = reg_mscratch;
    assign              mepc = reg_mepc;
    assign              mcause = reg_mcause;
    assign              mstatus = reg_mstatus;
    assign              mie = reg_mie;
    assign              mip = reg_mip;
    assign              mtval = reg_mtval;
    assign              satp = reg_satp;
    assign              mode = reg_mode;

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
            reg_satp <= 32'h00000000;
            reg_mode <= 2'b11;
        end
        else begin
            if (mtvec_we) begin
                reg_mtvec <= mtvec_wdata;
            end
            if (mscratch_we) begin
                reg_mscratch <= mscratch_wdata;
            end
            if (mepc_we) begin
                reg_mepc <= mepc_wdata;
            end
            if (mcause_we) begin
                reg_mcause <= mcause_wdata;
            end
            if (mstatus_we) begin
                reg_mstatus <= mstatus_wdata;
            end
            if (mie_we) begin
                reg_mie <= mie_wdata;
            end
            if (mip_we) begin
                reg_mip <= mip_wdata;
            end
            if (mtval_we) begin
                reg_mtval <= mtval_wdata;
            end
            if (satp_we) begin
                reg_satp <= satp_wdata;
            end
            if (mode_we) begin
                reg_mode <= mode_wdata;
            end
            if (csr_we) begin
                case(csr_waddr)
                    `MTVEC: begin
                        if (!mtvec_we) begin
                            reg_mtvec <= csr_wdata;
                        end
                    end
                    `MSCRATCH: begin
                        if (!mscratch_we) begin
                            reg_mscratch <= csr_wdata;
                        end
                    end
                    `MEPC: begin
                        if (!mepc_we) begin
                            reg_mepc <= csr_wdata;
                        end
                    end
                    `MCAUSE: begin
                        if (!mcause_we) begin
                            reg_mcause <= csr_wdata;
                        end
                    end
                    `MSTATUS: begin
                        if (!mstatus_we) begin
                            reg_mstatus <= csr_wdata;
                        end
                    end
                    `MIE: begin
                        if (!mie_we) begin
                            reg_mie <= csr_wdata;
                        end
                    end
                    `MIP: begin
                        if (!mip_we) begin
                            reg_mip <= csr_wdata;
                        end
                    end
                    `MTVAL: begin
                        if (!mtval_we) begin
                            reg_mtval <= csr_wdata;
                        end
                    end
                    `SATP: begin
                        if (!satp_we) begin
                            reg_satp <= csr_wdata;
                        end
                    end
                    default: begin
                    end
                endcase
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
            `SATP: begin
                csr_rdata = reg_satp;
            end
            default: begin
                csr_rdata = 32'h00000000;
            end
        endcase
    end

endmodule
