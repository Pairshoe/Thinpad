`default_nettype none
`timescale 1ns / 1ps

module mmio_regfile(
    input wire          clk,
    input wire          rst,

    // for read
    output wire[31:0]   mtime_lo,
    output wire[31:0]   mtime_hi,
    output wire[31:0]   mtimecmp_lo,
    output wire[31:0]   mtimecmp_hi,

    // for write
    input wire[1:0]     mtime_we,
    input wire[1:0]     mtimecmp_we,
    input wire[31:0]    mtime_wdata,
    input wire[31:0]    mtimecmp_wdata
);
    reg[31:0]           reg_mtime_lo;
    reg[31:0]           reg_mtime_hi;
    reg[31:0]           reg_mtimecmp_lo;
    reg[31:0]           reg_mtimecmp_hi;
    assign              mtime_lo = reg_mtime_lo;
    assign              mtime_hi = reg_mtime_hi;
    assign              mtimecmp_lo = reg_mtimecmp_lo;
    assign              mtimecmp_hi = reg_mtimecmp_hi;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_mtime_lo <= 32'h00000000;
            reg_mtime_hi <= 32'h00000000;
        end
        else begin
            if (mtime_we == 2'b01) begin
                reg_mtime_lo <= mtime_wdata;
            end
            else if (mtime_we == 2'b10) begin
                reg_mtime_hi <= mtime_wdata;
            end
            else begin // time count
                if (reg_mtime_lo == { 32 { 1'b1 } }) begin
                    reg_mtime_lo <= 0;
                    reg_mtime_hi <= reg_mtime_hi + 1;
                end
                else begin
                    reg_mtime_lo <= reg_mtime_lo + 1;
                end
            end
            if (mtimecmp_we == 2'b01) begin
                reg_mtimecmp_lo <= mtimecmp_wdata;
            end
            else if (mtimecmp_we == 2'b10) begin
                reg_mtimecmp_hi <= mtimecmp_wdata;
            end
            else begin
            end
        end
    end

endmodule
