`default_nettype none
`timescale 1ns / 1ps
`include "sram.vh"

module sram(
    // clock and reset
    input wire                                  clk,
    input wire                                  rst,

    // interface to user
    (* dont_touch = "true" *) input wire        oe,
    (* dont_touch = "true" *) input wire        we,
    // if using uart, even without 'be' set, byte input/output will be used
    (* dont_touch = "true" *) input wire        be,
    (* dont_touch = "true" *) input wire[31:0]  address,
    (* dont_touch = "true" *) input wire[31:0]  data_in,
    (* dont_touch = "true" *) output reg[31:0]  data_out,
    (* dont_touch = "true" *) output reg        done,

    // interface to BaseRAM
    inout wire[31:0]                            base_ram_data_wire,
    output wire[19:0]                           base_ram_addr,
    output wire[3:0]                            base_ram_be_n,
    output wire                                 base_ram_ce_n,
    output reg                                  base_ram_oe_n,
    output reg                                  base_ram_we_n,

    // interface to ExtRAM
    inout wire[31:0]                            ext_ram_data_wire,
    output wire[19:0]                           ext_ram_addr,
    output wire[3:0]                            ext_ram_be_n,
    output wire                                 ext_ram_ce_n,
    output reg                                  ext_ram_oe_n,
    output reg                                  ext_ram_we_n,

    // interface to UART
    output reg                                  uart_rdn,
    output reg                                  uart_wrn,
    input wire                                  uart_dataready,
    input wire                                  uart_tbre,
    input wire                                  uart_tsre,

    // others
    (* dont_touch = "true" *) input wire        tlb_clr,
    (* dont_touch = "true" *) input wire[31:0]  satp,
    (* dont_touch = "true" *) input wire[1:0]   mode,
    (* dont_touch = "true" *) output wire       timeout,
    (* dont_touch = "true" *) output wire[3:0]  exception
);

    (* dont_touch = "true" *) reg               data_z;
    (* dont_touch = "true" *) reg[31:0]         reg_address;
    (* dont_touch = "true" *) reg[21:0]         reg_entry;
    (* dont_touch = "true" *) wire              use_sram, use_base, use_ext, use_uart, 
                                                use_uart_state, use_mtime_lo, use_mtime_hi, use_mtimecmp_lo, use_mtimecmp_hi;
    (* dont_touch = "true" *) wire[7:0]         uart_state_data;
    (* dont_touch = "true" *) reg[31:0]         reg_mtime_lo, reg_mtime_hi, reg_mtimecmp_lo, reg_mtimecmp_hi;
    (* dont_touch = "true" *) reg[3:0]          state, uart_write_state, mtime_state;
    (* dont_touch = "true" *) reg               reg_timeout;
    
    (* dont_touch = "true" *) reg[42:0]         TLBs[0:15];
    (* dont_touch = "true" *) reg[63:0]         caches[0:63];

    assign base_ram_data_wire = data_z ? 32'bz : (be ? (data_in[7:0] << (8 * address[1:0])) : data_in);
    assign base_ram_addr = (satp[31] == 1 && mode == 2'b00) ? reg_address[21:2] : address[21:2];
    assign base_ram_be_n = be ? (~(1 << address[1:0])) : 4'b0000;
    assign base_ram_ce_n = (use_sram == 1) ? 0 : 1;

    assign ext_ram_data_wire = data_z ? 32'bz : (be ? (data_in[7:0] << (8 * address[1:0])) : data_in);
    assign ext_ram_addr = (satp[31] == 1 && mode == 2'b00) ? reg_address[21:2] : address[21:2];
    assign ext_ram_be_n = be ? (~(1 << address[1:0])) : 4'b0000;
    assign ext_ram_ce_n = (use_sram == 1) ? 0 : 1;

    assign use_uart = (address == 32'h10000000);
    assign use_uart_state = (address == 32'h10000005);
    assign use_mtime_lo = (address == 32'h0200bff8);
    assign use_mtime_hi = (address == 32'h0200bffc);
    assign use_mtimecmp_lo = (address == 32'h02004000);
    assign use_mtimecmp_hi = (address == 32'h02004004);
    assign use_sram = (use_base || use_ext);
    assign use_base = (satp[31] == 1 && mode == 2'b00) ?  
                      (((32'h00000000 <= address && address < 32'h00300000) ||
                        (32'h80100000 <= address && address < 32'h80101000) ||
                        (32'h80000000 <= address && address < 32'h80001000) ||
                        (32'h80001000 <= address && address < 32'h80002000)) ? 1 : 0) :
                      ((32'h80000000 <= address && address < 32'h80800000) ? 1 : 0);
    assign use_ext = (satp[31] == 1 && mode == 2'b00) ? 
                     ((32'h7fc10000 <= address && address < 32'h80000000) ? 1 : 0) :
                     ((32'h80400000 <= address) ? 1 : 0);                          
    assign uart_state_data = (state == `STATE_IDLE) ? (((uart_write_state == `STATE_IDLE) << 5) | uart_dataready) : 8'b00000000;
    assign timeout = reg_timeout;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= `STATE_IDLE;
            uart_write_state <= `STATE_IDLE;
            mtime_state <= `STATE_IDLE;
            data_z <= 1'b0;
            done <= 1'b1;
            base_ram_oe_n <= 1'b1;
            base_ram_we_n <= 1'b1;
            ext_ram_oe_n <= 1'b1;
            ext_ram_we_n <= 1'b1;
            uart_rdn <= 1'b1;
            uart_wrn <= 1'b1;
 
            reg_mtime_lo <= 32'b0;
            reg_mtime_hi <= 32'b0;
            reg_mtimecmp_lo <= 32'b0;
            reg_mtimecmp_hi <= 32'b0;
            reg_timeout <= 1'b0;
            
            TLBs[0] <= 43'b0;
            TLBs[1] <= 43'b0;
            TLBs[2] <= 43'b0;
            TLBs[3] <= 43'b0;
            TLBs[4] <= 43'b0;
            TLBs[5] <= 43'b0;
            TLBs[6] <= 43'b0;
            TLBs[7] <= 43'b0;
            TLBs[8] <= 43'b0;
            TLBs[9] <= 43'b0;
            TLBs[10] <= 43'b0;
            TLBs[11] <= 43'b0;
            TLBs[12] <= 43'b0;
            TLBs[13] <= 43'b0;
            TLBs[14] <= 43'b0;
            TLBs[15] <= 43'b0;
            
            caches[0] <= 64'b0;
            caches[1] <= 64'b0;
            caches[2] <= 64'b0;
            caches[3] <= 64'b0;
            caches[4] <= 64'b0;
            caches[5] <= 64'b0;
            caches[6] <= 64'b0;
            caches[7] <= 64'b0;
            caches[8] <= 64'b0;
            caches[9] <= 64'b0;            
            caches[10] <= 64'b0;
            caches[11] <= 64'b0;
            caches[12] <= 64'b0;
            caches[13] <= 64'b0;
            caches[14] <= 64'b0;
            caches[15] <= 64'b0;
            caches[16] <= 64'b0;
            caches[17] <= 64'b0;
            caches[18] <= 64'b0;
            caches[19] <= 64'b0;
            caches[20] <= 64'b0;
            caches[21] <= 64'b0;
            caches[22] <= 64'b0;
            caches[23] <= 64'b0;
            caches[24] <= 64'b0;
            caches[25] <= 64'b0;
            caches[26] <= 64'b0;
            caches[27] <= 64'b0;
            caches[28] <= 64'b0;
            caches[29] <= 64'b0;
            caches[30] <= 64'b0;
            caches[31] <= 64'b0;
            caches[32] <= 64'b0;
            caches[33] <= 64'b0;
            caches[34] <= 64'b0;
            caches[35] <= 64'b0;
            caches[36] <= 64'b0;
            caches[37] <= 64'b0;
            caches[38] <= 64'b0;
            caches[39] <= 64'b0;
            caches[40] <= 64'b0;
            caches[41] <= 64'b0;
            caches[42] <= 64'b0;
            caches[43] <= 64'b0;
            caches[44] <= 64'b0;
            caches[45] <= 64'b0;
            caches[46] <= 64'b0;
            caches[47] <= 64'b0;
            caches[48] <= 64'b0;
            caches[49] <= 64'b0;
            caches[50] <= 64'b0;
            caches[51] <= 64'b0;
            caches[52] <= 64'b0;
            caches[53] <= 64'b0;
            caches[54] <= 64'b0;
            caches[55] <= 64'b0;
            caches[56] <= 64'b0;
            caches[57] <= 64'b0;
            caches[58] <= 64'b0;
            caches[59] <= 64'b0;
            caches[60] <= 64'b0;
            caches[61] <= 64'b0;
            caches[62] <= 64'b0;
            caches[63] <= 64'b0;
        end
        else begin
            case(state)
                `STATE_IDLE: begin
                    if (tlb_clr) begin
                        TLBs[0][42] <= 1'b0;
                        TLBs[1][42] <= 1'b0;
                        TLBs[2][42] <= 1'b0;
                        TLBs[3][42] <= 1'b0;
                        TLBs[4][42] <= 1'b0;
                        TLBs[5][42] <= 1'b0;
                        TLBs[6][42] <= 1'b0;
                        TLBs[7][42] <= 1'b0;
                        TLBs[8][42] <= 1'b0;
                        TLBs[9][42] <= 1'b0;
                        TLBs[10][42] <= 1'b0;
                        TLBs[11][42] <= 1'b0;
                        TLBs[12][42] <= 1'b0;
                        TLBs[13][42] <= 1'b0;
                        TLBs[14][42] <= 1'b0;
                        TLBs[15][42] <= 1'b0;
                    end
                    if (we) begin
                        case({ use_sram, use_uart, use_mtime_lo, use_mtime_hi, use_mtimecmp_lo, use_mtimecmp_hi })
                            6'b100000: begin
                                if (satp[31] == 1'b1 && mode == 2'b00) begin
                                    if (address[31:12] == TLBs[0][41:22] && TLBs[0][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[0][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[1][41:22] && TLBs[1][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[1][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[2][41:22] && TLBs[2][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[2][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[3][41:22] && TLBs[3][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[3][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[4][41:22] && TLBs[4][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[4][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[5][41:22] && TLBs[5][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[5][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[6][41:22] && TLBs[6][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[6][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[7][41:22] && TLBs[7][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[7][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[8][41:22] && TLBs[8][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[8][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[9][41:22] && TLBs[9][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[9][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[10][41:22] && TLBs[10][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[10][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[11][41:22] && TLBs[11][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[11][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[12][41:22] && TLBs[12][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[12][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[13][41:22] && TLBs[13][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[13][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[14][41:22] && TLBs[14][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[14][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[15][41:22] && TLBs[15][42] == 1) begin
                                        state <= `STATE_SRAM_WRITE;
                                        reg_address <= TLBs[15][21:0] * `PAGE_SIZE + address[11:0];
                                        base_ram_we_n <= use_ext ? 1 : 0;
                                        ext_ram_we_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else begin
                                        state <= `STATE_SRAM_WRITE_PAGE_0;
                                        reg_address <= satp[21:0] * `PAGE_SIZE + address[31:22] * `PTE_SIZE;
                                        base_ram_oe_n <= 1'b0;
                                        data_z <= 1'b1;
                                        done <= 1'b0;
                                    end
                                end
                                else begin
                                    state <= `STATE_SRAM_WRITE;
                                    base_ram_we_n <= use_ext ? 1 : 0;
                                    ext_ram_we_n <= use_ext ? 0 : 1;
                                    done <= 1'b0; 
                                end
                            end
                            6'b010000: begin
                                state <= `STATE_UART_WRITE;
                                uart_wrn <= 1'b0;
                                done <= 1'b0;
                            end
                            6'b001000: begin
                                state <= `STATE_FINISHED;
                                reg_mtime_lo <= data_in;
                                done <= 1'b1;
                            end
                            6'b000100: begin
                                state <= `STATE_FINISHED;
                                reg_mtime_hi <= data_in;
                                done <= 1'b1;
                            end
                            6'b000010: begin
                                state <= `STATE_FINISHED;
                                reg_mtimecmp_lo <= data_in;
                                done <= 1'b1;
                            end
                            6'b000001: begin
                                state <= `STATE_FINISHED;
                                reg_mtimecmp_hi <= data_in;
                                done <= 1'b1;
                            end
                            default: begin
                                state <= `STATE_IDLE;
                            end
                        endcase
                    end
                    else if (oe) begin
                        case({ use_sram, use_uart, use_uart_state, use_mtime_lo, use_mtime_hi, use_mtimecmp_lo, use_mtimecmp_hi })
                            7'b1000000: begin
                                if (satp[31] == 1'b1 && mode == 2'b00) begin
                                    // check if address is in TLBs
                                    if (address[31:12] == TLBs[0][41:22] && TLBs[0][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[0][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[1][41:22] && TLBs[1][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[1][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[2][41:22] && TLBs[2][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[2][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[3][41:22] && TLBs[3][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[3][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[4][41:22] && TLBs[4][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[4][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[5][41:22] && TLBs[5][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[5][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[6][41:22] && TLBs[6][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[6][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[7][41:22] && TLBs[7][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[7][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[8][41:22] && TLBs[8][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[8][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[9][41:22] && TLBs[9][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[9][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[10][41:22] && TLBs[10][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[10][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[11][41:22] && TLBs[11][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[11][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[12][41:22] && TLBs[12][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[12][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[13][41:22] && TLBs[13][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[13][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[14][41:22] && TLBs[14][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[14][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else if (address[31:12] == TLBs[15][41:22] && TLBs[15][42] == 1) begin
                                        state <= `STATE_SRAM_READ;
                                        reg_address <= TLBs[15][21:0] * `PAGE_SIZE + address[11:0];
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0; 
                                    end
                                    else begin
                                        state <= `STATE_SRAM_READ_PAGE_0;
                                        reg_address <= satp[21:0] * `PAGE_SIZE + address[31:22] * `PTE_SIZE;
                                        base_ram_oe_n <= 1'b0;
                                        data_z <= 1'b1;
                                        done <= 1'b0;
                                    end
                                end
                                else begin
                                    // check if data is in caches
                                    if (address == caches[0][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[0][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[1][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[1][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[2][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[2][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[3][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[3][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[4][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[4][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[5][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[5][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[6][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[6][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[7][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[7][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[8][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[8][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[9][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[9][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[10][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[10][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[11][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[11][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[12][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[12][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[13][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[13][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[14][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[14][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[5][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[5][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[16][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[16][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[17][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[17][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[18][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[18][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[19][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[19][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[20][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[20][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[21][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[21][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[22][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[22][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[23][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[23][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[24][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[24][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[25][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[25][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[26][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[26][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[27][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[27][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[28][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[28][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[29][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[29][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[30][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[30][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[31][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[31][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[32][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[32][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[33][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[33][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[34][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[34][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[35][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[35][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[36][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[36][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[37][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[37][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[38][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[38][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[39][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[39][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[40][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[40][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[41][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[41][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[42][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[42][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[43][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[43][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[44][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[44][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[45][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[45][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[46][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[46][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[47][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[47][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[48][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[48][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[49][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[49][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[50][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[50][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[51][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[51][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[52][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[52][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[53][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[53][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[54][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[54][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[55][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[55][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[56][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[56][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[57][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[57][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[58][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[58][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[59][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[59][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[60][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[60][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[61][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[61][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[62][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[62][31:0];
                                        done <= 1'b1;
                                    end
                                    else if (address == caches[63][63:32]) begin
                                        state <= `STATE_FINISHED;
                                        data_out <= caches[63][31:0];
                                        done <= 1'b1;
                                    end
                                    else begin
                                        state <= `STATE_SRAM_READ;
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0;
                                    end
                                end
                            end
                            7'b0100000: begin
                                state <= `STATE_UART_READ;
                                data_z <= 1'b1;
                                uart_rdn <= 1'b0;
                                done <= 1'b0;
                            end
                            7'b0010000: begin
                                state <= `STATE_FINISHED;
                                data_out <= { 24'h000000, uart_state_data };
                                done <= 1'b1;
                            end
                            7'b0001000: begin
                                state <= `STATE_FINISHED;
                                data_out <= reg_mtime_lo;
                                done <= 1'b1;
                            end
                            7'b0000100: begin
                                state <= `STATE_FINISHED;
                                data_out <= reg_mtime_hi;
                                done <= 1'b1;
                            end
                            7'b0000010: begin
                                state <= `STATE_FINISHED;
                                data_out <= reg_mtimecmp_lo;
                                done <= 1'b1;
                            end
                            7'b0000001: begin
                                state <= `STATE_FINISHED;
                                data_out <= reg_mtimecmp_hi;
                                done <= 1'b1;
                            end
                            default: begin
                                state <= `STATE_IDLE;
                            end
                        endcase
                    end
                end

                `STATE_SRAM_WRITE_PAGE_0: begin
                    state <= `STATE_SRAM_WRITE_PAGE_1;
                    reg_address <= base_ram_data_wire[31:10] * `PAGE_SIZE + address[21:12] * `PTE_SIZE;
                end

                `STATE_SRAM_WRITE_PAGE_1: begin
                    state <= `STATE_SRAM_WRITE_PAGE_2;
                    reg_address <= base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0];
                    // update TLBs
                    if (TLBs[0][42] == 0) begin
                        TLBs[0] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[1][42] == 0) begin
                        TLBs[1] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[2][42] == 0) begin
                        TLBs[2] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[3][42] == 0) begin
                        TLBs[3] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[4][42] == 0) begin
                        TLBs[4] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[5][42] == 0) begin
                        TLBs[5] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[6][42] == 0) begin
                        TLBs[6] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[7][42] == 0) begin
                        TLBs[7] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[8][42] == 0) begin
                        TLBs[8] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[9][42] == 0) begin
                        TLBs[9] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[10][42] == 0) begin
                        TLBs[10] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[11][42] == 0) begin
                        TLBs[11] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[12][42] == 0) begin
                        TLBs[12] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[13][42] == 0) begin
                        TLBs[13] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[14][42] == 0) begin
                        TLBs[14] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[15][42] == 0) begin
                        TLBs[15] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                end

                `STATE_SRAM_WRITE_PAGE_2: begin
                    state <= `STATE_SRAM_WRITE;
                    base_ram_oe_n <= 1'b1;
                    base_ram_we_n <= use_ext ? 1'b1 : 1'b0;
                    ext_ram_we_n <= use_ext ? 1'b0 : 1'b1;
                    data_z <= 1'b0;
                end

                `STATE_SRAM_WRITE: begin
                    state <= `STATE_FINISHED;
                    base_ram_we_n <= 1'b1;
                    ext_ram_we_n <= 1'b1;
                    done <= 1'b1;
                    // update caches
                    if (satp[31] == 1'b1 && mode == 2'b00) begin
                        if (reg_address == caches[0][63:32]) begin
                            caches[0][31:0] <= data_in;
                        end
                        else if (reg_address == caches[1][63:32]) begin
                            caches[1][31:0] <= data_in;
                        end
                        else if (reg_address == caches[2][63:32]) begin
                            caches[2][31:0] <= data_in;
                        end
                        else if (reg_address == caches[3][63:32]) begin
                            caches[3][31:0] <= data_in;
                        end
                        else if (reg_address == caches[4][63:32]) begin
                            caches[4][31:0] <= data_in;
                        end
                        else if (reg_address == caches[5][63:32]) begin
                            caches[5][31:0] <= data_in;
                        end
                        else if (reg_address == caches[6][63:32]) begin
                            caches[6][31:0] <= data_in;
                        end
                        else if (reg_address == caches[7][63:32]) begin
                            caches[7][31:0] <= data_in;
                        end
                        else if (reg_address == caches[8][63:32]) begin
                            caches[8][31:0] <= data_in;
                        end
                        else if (reg_address == caches[9][63:32]) begin
                            caches[9][31:0] <= data_in;
                        end
                        else if (reg_address == caches[10][63:32]) begin
                            caches[10][31:0] <= data_in;
                        end
                        else if (reg_address == caches[11][63:32]) begin
                            caches[11][31:0] <= data_in;
                        end
                        else if (reg_address == caches[12][63:32]) begin
                            caches[12][31:0] <= data_in;
                        end
                        else if (reg_address == caches[13][63:32]) begin
                            caches[13][31:0] <= data_in;
                        end
                        else if (reg_address == caches[14][63:32]) begin
                            caches[14][31:0] <= data_in;
                        end
                        else if (reg_address == caches[15][63:32]) begin
                            caches[15][31:0] <= data_in;
                        end
                        else if (reg_address == caches[16][63:32]) begin
                            caches[16][31:0] <= data_in;
                        end
                        else if (reg_address == caches[17][63:32]) begin
                            caches[17][31:0] <= data_in;
                        end
                        else if (reg_address == caches[18][63:32]) begin
                            caches[18][31:0] <= data_in;
                        end
                        else if (reg_address == caches[19][63:32]) begin
                            caches[19][31:0] <= data_in;
                        end
                        else if (reg_address == caches[20][63:32]) begin
                            caches[20][31:0] <= data_in;
                        end
                        else if (reg_address == caches[21][63:32]) begin
                            caches[21][31:0] <= data_in;
                        end
                        else if (reg_address == caches[22][63:32]) begin
                            caches[22][31:0] <= data_in;
                        end
                        else if (reg_address == caches[23][63:32]) begin
                            caches[23][31:0] <= data_in;
                        end
                        else if (reg_address == caches[24][63:32]) begin
                            caches[24][31:0] <= data_in;
                        end
                        else if (reg_address == caches[25][63:32]) begin
                            caches[25][31:0] <= data_in;
                        end
                        else if (reg_address == caches[26][63:32]) begin
                            caches[26][31:0] <= data_in;
                        end
                        else if (reg_address == caches[27][63:32]) begin
                            caches[27][31:0] <= data_in;
                        end
                        else if (reg_address == caches[28][63:32]) begin
                            caches[28][31:0] <= data_in;
                        end
                        else if (reg_address == caches[29][63:32]) begin
                            caches[29][31:0] <= data_in;
                        end
                        else if (reg_address == caches[30][63:32]) begin
                            caches[30][31:0] <= data_in;
                        end
                        else if (reg_address == caches[31][63:32]) begin
                            caches[31][31:0] <= data_in;
                        end
                        else if (reg_address == caches[32][63:32]) begin
                            caches[32][31:0] <= data_in;
                        end
                        else if (reg_address == caches[33][63:32]) begin
                            caches[33][31:0] <= data_in;
                        end
                        else if (reg_address == caches[34][63:32]) begin
                            caches[34][31:0] <= data_in;
                        end
                        else if (reg_address == caches[35][63:32]) begin
                            caches[35][31:0] <= data_in;
                        end
                        else if (reg_address == caches[36][63:32]) begin
                            caches[36][31:0] <= data_in;
                        end
                        else if (reg_address == caches[37][63:32]) begin
                            caches[37][31:0] <= data_in;
                        end
                        else if (reg_address == caches[38][63:32]) begin
                            caches[38][31:0] <= data_in;
                        end
                        else if (reg_address == caches[39][63:32]) begin
                            caches[39][31:0] <= data_in;
                        end
                        else if (reg_address == caches[40][63:32]) begin
                            caches[40][31:0] <= data_in;
                        end
                        else if (reg_address == caches[41][63:32]) begin
                            caches[41][31:0] <= data_in;
                        end
                        else if (reg_address == caches[42][63:32]) begin
                            caches[42][31:0] <= data_in;
                        end
                        else if (reg_address == caches[43][63:32]) begin
                            caches[43][31:0] <= data_in;
                        end
                        else if (reg_address == caches[44][63:32]) begin
                            caches[44][31:0] <= data_in;
                        end
                        else if (reg_address == caches[45][63:32]) begin
                            caches[45][31:0] <= data_in;
                        end
                        else if (reg_address == caches[46][63:32]) begin
                            caches[46][31:0] <= data_in;
                        end
                        else if (reg_address == caches[47][63:32]) begin
                            caches[47][31:0] <= data_in;
                        end
                        else if (reg_address == caches[48][63:32]) begin
                            caches[48][31:0] <= data_in;
                        end
                        else if (reg_address == caches[49][63:32]) begin
                            caches[49][31:0] <= data_in;
                        end
                        else if (reg_address == caches[50][63:32]) begin
                            caches[50][31:0] <= data_in;
                        end
                        else if (reg_address == caches[51][63:32]) begin
                            caches[51][31:0] <= data_in;
                        end
                        else if (reg_address == caches[52][63:32]) begin
                            caches[52][31:0] <= data_in;
                        end
                        else if (reg_address == caches[53][63:32]) begin
                            caches[53][31:0] <= data_in;
                        end
                        else if (reg_address == caches[54][63:32]) begin
                            caches[54][31:0] <= data_in;
                        end
                        else if (reg_address == caches[55][63:32]) begin
                            caches[55][31:0] <= data_in;
                        end
                        else if (reg_address == caches[56][63:32]) begin
                            caches[56][31:0] <= data_in;
                        end
                        else if (reg_address == caches[57][63:32]) begin
                            caches[57][31:0] <= data_in;
                        end
                        else if (reg_address == caches[58][63:32]) begin
                            caches[58][31:0] <= data_in;
                        end
                        else if (reg_address == caches[59][63:32]) begin
                            caches[59][31:0] <= data_in;
                        end
                        else if (reg_address == caches[60][63:32]) begin
                            caches[60][31:0] <= data_in;
                        end
                        else if (reg_address == caches[61][63:32]) begin
                            caches[61][31:0] <= data_in;
                        end
                        else if (reg_address == caches[62][63:32]) begin
                            caches[62][31:0] <= data_in;
                        end
                        else if (reg_address == caches[63][63:32]) begin
                            caches[63][31:0] <= data_in;
                        end
                        else begin
                            caches[reg_mtime_lo[5:0]] <= {reg_address, data_in};
                        end
                    end
                    else begin
                        if (address == caches[0][63:32]) begin
                            caches[0][31:0] <= data_in;
                        end
                        else if (address == caches[1][63:32]) begin
                            caches[1][31:0] <= data_in;
                        end
                        else if (address == caches[2][63:32]) begin
                            caches[2][31:0] <= data_in;
                        end
                        else if (address == caches[3][63:32]) begin
                            caches[3][31:0] <= data_in;
                        end
                        else if (address == caches[4][63:32]) begin
                            caches[4][31:0] <= data_in;
                        end
                        else if (address == caches[5][63:32]) begin
                            caches[5][31:0] <= data_in;
                        end
                        else if (address == caches[6][63:32]) begin
                            caches[6][31:0] <= data_in;
                        end
                        else if (address == caches[7][63:32]) begin
                            caches[7][31:0] <= data_in;
                        end
                        else if (address == caches[8][63:32]) begin
                            caches[8][31:0] <= data_in;
                        end
                        else if (address == caches[9][63:32]) begin
                            caches[9][31:0] <= data_in;
                        end
                        else if (address == caches[10][63:32]) begin
                            caches[10][31:0] <= data_in;
                        end
                        else if (address == caches[11][63:32]) begin
                            caches[11][31:0] <= data_in;
                        end
                        else if (address == caches[12][63:32]) begin
                            caches[12][31:0] <= data_in;
                        end
                        else if (address == caches[13][63:32]) begin
                            caches[13][31:0] <= data_in;
                        end
                        else if (address == caches[14][63:32]) begin
                            caches[14][31:0] <= data_in;
                        end
                        else if (address == caches[15][63:32]) begin
                            caches[15][31:0] <= data_in;
                        end
                        else if (address == caches[16][63:32]) begin
                            caches[16][31:0] <= data_in;
                        end
                        else if (address == caches[17][63:32]) begin
                            caches[17][31:0] <= data_in;
                        end
                        else if (address == caches[18][63:32]) begin
                            caches[18][31:0] <= data_in;
                        end
                        else if (address == caches[19][63:32]) begin
                            caches[19][31:0] <= data_in;
                        end
                        else if (address == caches[20][63:32]) begin
                            caches[20][31:0] <= data_in;
                        end
                        else if (address == caches[21][63:32]) begin
                            caches[21][31:0] <= data_in;
                        end
                        else if (address == caches[22][63:32]) begin
                            caches[22][31:0] <= data_in;
                        end
                        else if (address == caches[23][63:32]) begin
                            caches[23][31:0] <= data_in;
                        end
                        else if (address == caches[24][63:32]) begin
                            caches[24][31:0] <= data_in;
                        end
                        else if (address == caches[25][63:32]) begin
                            caches[25][31:0] <= data_in;
                        end
                        else if (address == caches[26][63:32]) begin
                            caches[26][31:0] <= data_in;
                        end
                        else if (address == caches[27][63:32]) begin
                            caches[27][31:0] <= data_in;
                        end
                        else if (address == caches[28][63:32]) begin
                            caches[28][31:0] <= data_in;
                        end
                        else if (address == caches[29][63:32]) begin
                            caches[29][31:0] <= data_in;
                        end
                        else if (address == caches[30][63:32]) begin
                            caches[30][31:0] <= data_in;
                        end
                        else if (address == caches[31][63:32]) begin
                            caches[31][31:0] <= data_in;
                        end
                        else if (address == caches[32][63:32]) begin
                            caches[32][31:0] <= data_in;
                        end
                        else if (address == caches[33][63:32]) begin
                            caches[33][31:0] <= data_in;
                        end
                        else if (address == caches[34][63:32]) begin
                            caches[34][31:0] <= data_in;
                        end
                        else if (address == caches[35][63:32]) begin
                            caches[35][31:0] <= data_in;
                        end
                        else if (address == caches[36][63:32]) begin
                            caches[36][31:0] <= data_in;
                        end
                        else if (address == caches[37][63:32]) begin
                            caches[37][31:0] <= data_in;
                        end
                        else if (address == caches[38][63:32]) begin
                            caches[38][31:0] <= data_in;
                        end
                        else if (address == caches[39][63:32]) begin
                            caches[39][31:0] <= data_in;
                        end
                        else if (address == caches[40][63:32]) begin
                            caches[40][31:0] <= data_in;
                        end
                        else if (address == caches[41][63:32]) begin
                            caches[41][31:0] <= data_in;
                        end
                        else if (address == caches[42][63:32]) begin
                            caches[42][31:0] <= data_in;
                        end
                        else if (address == caches[43][63:32]) begin
                            caches[43][31:0] <= data_in;
                        end
                        else if (address == caches[44][63:32]) begin
                            caches[44][31:0] <= data_in;
                        end
                        else if (address == caches[45][63:32]) begin
                            caches[45][31:0] <= data_in;
                        end
                        else if (address == caches[46][63:32]) begin
                            caches[46][31:0] <= data_in;
                        end
                        else if (address == caches[47][63:32]) begin
                            caches[47][31:0] <= data_in;
                        end
                        else if (address == caches[48][63:32]) begin
                            caches[48][31:0] <= data_in;
                        end
                        else if (address == caches[49][63:32]) begin
                            caches[49][31:0] <= data_in;
                        end
                        else if (address == caches[50][63:32]) begin
                            caches[50][31:0] <= data_in;
                        end
                        else if (address == caches[51][63:32]) begin
                            caches[51][31:0] <= data_in;
                        end
                        else if (address == caches[52][63:32]) begin
                            caches[52][31:0] <= data_in;
                        end
                        else if (address == caches[53][63:32]) begin
                            caches[53][31:0] <= data_in;
                        end
                        else if (address == caches[54][63:32]) begin
                            caches[54][31:0] <= data_in;
                        end
                        else if (address == caches[55][63:32]) begin
                            caches[55][31:0] <= data_in;
                        end
                        else if (address == caches[56][63:32]) begin
                            caches[56][31:0] <= data_in;
                        end
                        else if (address == caches[57][63:32]) begin
                            caches[57][31:0] <= data_in;
                        end
                        else if (address == caches[58][63:32]) begin
                            caches[58][31:0] <= data_in;
                        end
                        else if (address == caches[59][63:32]) begin
                            caches[59][31:0] <= data_in;
                        end
                        else if (address == caches[60][63:32]) begin
                            caches[60][31:0] <= data_in;
                        end
                        else if (address == caches[61][63:32]) begin
                            caches[61][31:0] <= data_in;
                        end
                        else if (address == caches[62][63:32]) begin
                            caches[62][31:0] <= data_in;
                        end
                        else if (address == caches[63][63:32]) begin
                            caches[63][31:0] <= data_in;
                        end
                        else begin
                            caches[reg_mtime_lo[5:0]] <= {address, data_in};
                        end
                    end
                end

                `STATE_SRAM_READ_PAGE_0: begin
                    state <= `STATE_SRAM_READ_PAGE_1;
                    reg_address <= base_ram_data_wire[31:10] * `PAGE_SIZE + address[21:12] * `PTE_SIZE;
                end

                `STATE_SRAM_READ_PAGE_1: begin
                    // update TLBs
                    if (TLBs[0][42] == 0) begin
                        TLBs[0] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[1][42] == 0) begin
                        TLBs[1] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[2][42] == 0) begin
                        TLBs[2] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[3][42] == 0) begin
                        TLBs[3] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[4][42] == 0) begin
                        TLBs[4] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[5][42] == 0) begin
                        TLBs[5] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[6][42] == 0) begin
                        TLBs[6] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[7][42] == 0) begin
                        TLBs[7] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[8][42] == 0) begin
                        TLBs[8] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[9][42] == 0) begin
                        TLBs[9] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[10][42] == 0) begin
                        TLBs[10] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[11][42] == 0) begin
                        TLBs[11] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[12][42] == 0) begin
                        TLBs[12] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[13][42] == 0) begin
                        TLBs[13] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[14][42] == 0) begin
                        TLBs[14] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    else if (TLBs[15][42] == 0) begin
                        TLBs[15] <= { 1'b1, address[31:12], base_ram_data_wire[31:10] };
                    end
                    // check if data is in caches
                    if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[0][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[0][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[1][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[1][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[2][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[2][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[3][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[3][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[4][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[4][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[5][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[5][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[6][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[6][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[7][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[7][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[8][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[8][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[9][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[9][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[10][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[10][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[11][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[11][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[12][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[12][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[13][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[13][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[14][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[14][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[5][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[5][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[16][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[16][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[17][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[17][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[18][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[18][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[19][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[19][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[20][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[20][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[21][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[21][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[22][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[22][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[23][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[23][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[24][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[24][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[25][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[25][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[26][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[26][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[27][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[27][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[28][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[28][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[29][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[29][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[30][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[30][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[31][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[31][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[32][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[32][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[33][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[33][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[34][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[34][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[35][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[35][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[36][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[36][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[37][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[37][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[38][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[38][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[39][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[39][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[40][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[40][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[41][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[41][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[42][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[42][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[43][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[43][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[44][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[44][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[45][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[45][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[46][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[46][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[47][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[47][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[48][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[48][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[49][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[49][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[50][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[50][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[51][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[51][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[52][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[52][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[53][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[53][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[54][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[54][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[55][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[55][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[56][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[56][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[57][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[57][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[58][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[58][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[59][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[59][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[60][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[60][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[61][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[61][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[62][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[62][31:0];
                        done <= 1'b1;
                    end
                    else if ((base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0]) == caches[63][63:32]) begin
                        state <= `STATE_FINISHED;
                        data_out <= caches[63][31:0];
                        done <= 1'b1;
                    end
                    else begin
                        state <= `STATE_SRAM_READ_PAGE_2;
                        reg_address <= base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0];
                    end
                end

                `STATE_SRAM_READ_PAGE_2: begin
                    state <= `STATE_SRAM_READ;
                    base_ram_oe_n <= use_ext ? 1'b1 : 1'b0;
                    ext_ram_oe_n <= use_ext ? 1'b0 : 1'b1;
                end

                `STATE_SRAM_READ: begin
                    state <= `STATE_FINISHED;
                    base_ram_oe_n <= 1'b1;
                    ext_ram_oe_n <= 1'b1;
                    if (use_ext) begin
                        case({ be, address[1:0] })
                            3'b100: begin
                                data_out <= { { 24{ ext_ram_data_wire[7] } }, ext_ram_data_wire[7:0] };
                            end
                            3'b101: begin
                                data_out <= { { 24{ ext_ram_data_wire[15] } }, ext_ram_data_wire[15:8] };
                            end
                            3'b110: begin
                                data_out <= { { 24{ ext_ram_data_wire[23] } }, ext_ram_data_wire[23:16] };
                            end
                            3'b111: begin
                                data_out <= { { 24{ ext_ram_data_wire[31] } }, ext_ram_data_wire[31:24] };
                            end
                            default: begin
                                data_out <= ext_ram_data_wire;
                            end
                        endcase
                    end
                    else begin
                        case({ be, address[1:0] })
                            3'b100: begin
                                data_out <= { { 24{ base_ram_data_wire[7] } }, base_ram_data_wire[7:0] };
                            end
                            3'b101: begin
                                data_out <= { { 24{ base_ram_data_wire[15] } }, base_ram_data_wire[15:8] };
                            end
                            3'b110: begin
                                data_out <= { { 24{ base_ram_data_wire[23] } }, base_ram_data_wire[23:16] };
                            end
                            3'b111: begin
                                data_out <= { { 24{ base_ram_data_wire[31] } }, base_ram_data_wire[31:24] };
                            end
                            default: begin
                                data_out <= base_ram_data_wire;
                            end
                        endcase
                    end
                    done <= 1'b1;
                end

                `STATE_UART_WRITE: begin
                    state <= `STATE_FINISHED;
                    uart_wrn <= 1'b1;
                    done <= 1'b1;
                end

                `STATE_UART_READ: begin
                    state <= `STATE_FINISHED;
                    data_out <= { 24'h000000, base_ram_data_wire[7:0] };
                    uart_rdn <= 1'b1;
                    done <= 1'b1;
                end

                `STATE_FINISHED: begin
                    state <= `STATE_IDLE;
                    data_z <= 1'b0;
                end

                default: begin
                    state <= `STATE_IDLE;
                end
            endcase

            case(uart_write_state)
                `STATE_IDLE: begin
                    if (uart_tbre == 0) begin
                        uart_write_state <= `STATE_UART_WRITE;
                    end
                end

                `STATE_UART_WRITE: begin
                    if (uart_tsre == 0) begin
                        uart_write_state <= `STATE_FINISHED;
                    end
                end

                `STATE_FINISHED: begin
                    if (uart_tsre == 1) begin
                        uart_write_state <= `STATE_IDLE;
                    end
                end

                default: begin
                    uart_write_state <= `STATE_IDLE;
                end
            endcase

            case(mtime_state) 
                `STATE_IDLE: begin
                    if (mode == 2'b00) begin
                        mtime_state <= `STATE_FINISHED;
                        if ((reg_mtimecmp_hi < reg_mtime_hi) || (reg_mtime_hi == reg_mtimecmp_hi && reg_mtimecmp_lo < reg_mtime_lo)) begin
                            reg_timeout <= 1'b1;
                            reg_mtime_lo <= 32'b0;
                            reg_mtime_hi <= 32'b0;
                        end
                    end
                    else begin
                        reg_timeout <= 1'b0;
                    end
                end
                
                `STATE_FINISHED: begin
                    mtime_state <= `STATE_IDLE;
                    if (reg_mtime_lo == { 32 { 1'b1 } }) begin
                        reg_mtime_lo <= 32'b0;
                        reg_mtime_hi <= reg_mtime_hi + 1;
                    end
                    else begin
                        reg_mtime_lo <= reg_mtime_lo + 1;
                    end
                end
                
                default: begin
                end
            endcase
        end
    end

endmodule
