`default_nettype none
`timescale 1ns / 1ps
`include "sram.vh"

module sram(
    // clock and reset
    input wire                                  clk,
    input wire                                  rst,

    // interface to user
    input wire                                  oe,
    input wire                                  we,
    // if using uart, even without 'be' set, byte input/output will be used
    input wire                                  byte,
    input wire                                  half,
    input wire                                  unsigned_,
    input wire[31:0]                            address,
    input wire[31:0]                            data_in,
    output reg[31:0]                            data_out,
    output reg                                  done,

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
    input wire                                  tlb_clr,
    input wire[31:0]                            satp,
    input wire[1:0]                             mode,
    output wire                                 timeout,
    output wire[3:0]                            exception
);

    (* dont_touch = "true" *) reg               data_z;
    (* dont_touch = "true" *) reg[31:0]         reg_address;
    (* dont_touch = "true" *) reg[21:0]         reg_entry;
    (* dont_touch = "true" *) wire              use_sram, use_base, use_ext, use_uart, use_uart_state, use_mtime_lo, use_mtime_hi, use_mtimecmp_lo, use_mtimecmp_hi;
    (* dont_touch = "true" *) wire[7:0]         uart_state_data;
    (* dont_touch = "true" *) reg[31:0]         reg_mtime_lo, reg_mtime_hi, reg_mtimecmp_lo, reg_mtimecmp_hi;
    (* dont_touch = "true" *) reg[3:0]          state, uart_write_state, mtime_state;
    (* dont_touch = "true" *) reg               reg_timeout;

    (* dont_touch = "true" *) reg[42:0]         TLBs[0:3];

    //(* dont_touch = "true" *) reg[31:0]         cache_addr[0:31], cache_data[0:31];
    //(* dont_touch = "true" *) reg               valid[0:31];

    assign base_ram_data_wire = data_z ? 32'bz : (byte ? (data_in[7:0] << (8 * address[1:0])) : (half ? (data_in[15:0] << (8 * address[1:0])) : data_in));
    assign base_ram_addr = (satp[31] == 1 && mode == 2'b00) ? reg_address[21:2] : address[21:2];
    assign base_ram_be_n = oe ? 4'b0000 : (byte ? (~(1'b1 << address[1:0])) : (half ? (~(2'b11 << address[1:0])) : 4'b0000));
    assign base_ram_ce_n = (use_sram == 1) ? 0 : 1;

    assign ext_ram_data_wire = data_z ? 32'bz : (byte ? (data_in[7:0] << (8 * address[1:0])) : (half ? (data_in[15:0] << (8 * address[1:0])) : data_in));
    assign ext_ram_addr = (satp[31] == 1 && mode == 2'b00) ? reg_address[21:2] : address[21:2];
    assign ext_ram_be_n = oe ? 4'b0000 : (byte ? (~(1'b1 << address[1:0])) : (half ? (~(2'b11 << address[1:0])) : 4'b0000));
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
        end
        else begin
            case(state)
                `STATE_IDLE: begin
                    if (tlb_clr) begin
                        TLBs[0][42] <= 1'b0;
                        TLBs[1][42] <= 1'b0;
                        TLBs[2][42] <= 1'b0;
                        TLBs[3][42] <= 1'b0;
                    end
                    if (we) begin
                        case({ use_sram, use_uart, use_mtime_lo, use_mtime_hi, use_mtimecmp_lo, use_mtimecmp_hi })
                            6'b100000: begin
                                if (satp[31] == 1 && mode == 2'b00) begin
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
                                if (satp[31] == 1 && mode == 2'b00) begin
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
                                    else begin
                                        state <= `STATE_SRAM_READ_PAGE_0;
                                        reg_address <= satp[21:0] * `PAGE_SIZE + address[31:22] * `PTE_SIZE;
                                        base_ram_oe_n <= 1'b0;
                                        data_z <= 1'b1;
                                        done <= 1'b0;
                                    end
                                end
                                else begin
                                    /*if (valid[address[6:2]] == 1 && cache_addr[address[6:2]] == address) begin
                                        state <= `STATE_FINISHED;
                                        case({ byte, half, address[1:0] })
                                            4'b1000: begin
                                                data_out <= unsigned_ ? { 24'h0, cache_data[address[6:2]][7:0] } : { { 24{ cache_data[address[6:2]][7] } }, cache_data[address[6:2]][7:0] };
                                            end
                                            4'b1001: begin
                                                data_out <= unsigned_ ? { 24'h0, cache_data[address[6:2]][15:8] } : { { 24{ cache_data[address[6:2]][15] } }, cache_data[address[6:2]][15:8] };
                                            end
                                            4'b1010: begin
                                                data_out <= unsigned_ ? { 24'h0, cache_data[address[6:2]][23:16] } : { { 24{ cache_data[address[6:2]][23] } }, cache_data[address[6:2]][23:16] };
                                            end
                                            4'b1011: begin
                                                data_out <= unsigned_ ? { 24'h0, cache_data[address[6:2]][31:24] } : { { 24{ cache_data[address[6:2]][31] } }, cache_data[address[6:2]][31:24] };
                                            end
                                            4'b0100: begin
                                                data_out <= unsigned_ ? { 16'h0, cache_data[address[6:2]][15:0] } : { { 16{ cache_data[address[6:2]][15] } }, cache_data[address[6:2]][15:0] };
                                            end
                                            4'b0101: begin
                                                data_out <= unsigned_ ? { 16'h0, cache_data[address[6:2]][23:8] } : { { 16{ cache_data[address[6:2]][23] } }, cache_data[address[6:2]][23:8] };
                                            end
                                            4'b0110: begin
                                                data_out <= unsigned_ ? { 16'h0, cache_data[address[6:2]][31:16] } : { { 16{ cache_data[address[6:2]][31] } }, cache_data[address[6:2]][31:16] };
                                            end
                                            default: begin
                                                data_out <= cache_data[address[6:2]];
                                            end
                                        endcase
                                    end
                                    else begin*/
                                        state <= `STATE_SRAM_READ;
                                        data_z <= 1'b1;
                                        base_ram_oe_n <= use_ext ? 1 : 0;
                                        ext_ram_oe_n <= use_ext ? 0 : 1;
                                        done <= 1'b0;
                                    //end
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
                    /*if (cache_addr[address[6:2]] != address) begin
                        valid[address[6:2]] <= 0;
                    end*/
                end

                `STATE_SRAM_READ_PAGE_0: begin
                    state <= `STATE_SRAM_READ_PAGE_1;
                    reg_address <= base_ram_data_wire[31:10] * `PAGE_SIZE + address[21:12] * `PTE_SIZE;
                end

                `STATE_SRAM_READ_PAGE_1: begin
                    state <= `STATE_SRAM_READ_PAGE_2;
                    reg_address <= base_ram_data_wire[31:10] * `PAGE_SIZE + address[11:0];
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
                    /*valid[address[6:2]] <= 1;
                    cache_addr[address[6:2]] <= address;*/
                    if (use_ext) begin
                        case({ byte, half, address[1:0] })
                            4'b1000: begin
                                data_out <= unsigned_ ? { 24'h0, ext_ram_data_wire[7:0] } : { { 24{ ext_ram_data_wire[7] } }, ext_ram_data_wire[7:0] };
                                //cache_data[address[6:2]] <= ext_ram_data_wire;
                            end
                            4'b1001: begin
                                data_out <= unsigned_ ? { 24'h0, ext_ram_data_wire[15:8] } : { { 24{ ext_ram_data_wire[15] } }, ext_ram_data_wire[15:8] };
                                //cache_data[address[6:2]] <= ext_ram_data_wire;
                            end
                            4'b1010: begin
                                data_out <= unsigned_ ? { 24'h0, ext_ram_data_wire[23:16] } : { { 24{ ext_ram_data_wire[23] } }, ext_ram_data_wire[23:16] };
                                //cache_data[address[6:2]] <= ext_ram_data_wire;
                            end
                            4'b1011: begin
                                data_out <= unsigned_ ? { 24'h0, ext_ram_data_wire[31:24] } : { { 24{ ext_ram_data_wire[31] } }, ext_ram_data_wire[31:24] };
                                //cache_data[address[6:2]] <= ext_ram_data_wire;
                            end
                            4'b0100: begin
                                data_out <= unsigned_ ? { 16'h0, ext_ram_data_wire[15:0] } : { { 16{ ext_ram_data_wire[15] } }, ext_ram_data_wire[15:0] };
                                //cache_data[address[6:2]] <= ext_ram_data_wire;
                            end
                            4'b0101: begin
                                data_out <= unsigned_ ? { 16'h0, ext_ram_data_wire[23:8] } : { { 16{ ext_ram_data_wire[23] } }, ext_ram_data_wire[23:8] };
                                //cache_data[address[6:2]] <= ext_ram_data_wire;
                            end
                            4'b0110: begin
                                data_out <= unsigned_ ? { 16'h0, ext_ram_data_wire[31:16] } : { { 16{ ext_ram_data_wire[31] } }, ext_ram_data_wire[31:16] };
                                //cache_data[address[6:2]] <= ext_ram_data_wire;
                            end
                            default: begin
                                data_out <= ext_ram_data_wire;
                                //cache_data[address[6:2]] <= ext_ram_data_wire;
                            end
                        endcase
                    end
                    else begin
                        case({ byte, half, address[1:0] })
                            4'b1000: begin
                                data_out <= unsigned_ ? { 24'h0, base_ram_data_wire[7:0] } : { { 24{ base_ram_data_wire[7] } }, base_ram_data_wire[7:0] };
                                //cache_data[address[6:2]] <= base_ram_data_wire;
                            end
                            4'b1001: begin
                                data_out <= unsigned_ ? { 24'h0, base_ram_data_wire[15:8] } : { { 24{ base_ram_data_wire[15] } }, base_ram_data_wire[15:8] };
                                //cache_data[address[6:2]] <= base_ram_data_wire;
                            end
                            4'b1010: begin
                                data_out <= unsigned_ ? { 24'h0, base_ram_data_wire[23:16] } : { { 24{ base_ram_data_wire[23] } }, base_ram_data_wire[23:16] };
                                //cache_data[address[6:2]] <= base_ram_data_wire;
                            end
                            4'b1011: begin
                                data_out <= unsigned_ ? { 24'h0, base_ram_data_wire[31:24] } : { { 24{ base_ram_data_wire[31] } }, base_ram_data_wire[31:24] };
                                //cache_data[address[6:2]] <= base_ram_data_wire;
                            end
                            4'b0100: begin
                                data_out <= unsigned_ ? { 16'h0, base_ram_data_wire[15:0] } : { { 16{ base_ram_data_wire[15] } }, base_ram_data_wire[15:0] };
                                //cache_data[address[6:2]] <= base_ram_data_wire;
                            end
                            4'b0101: begin
                                data_out <= unsigned_ ? { 16'h0, base_ram_data_wire[23:8] } : { { 16{ base_ram_data_wire[23] } }, base_ram_data_wire[23:8] };
                                //cache_data[address[6:2]] <= base_ram_data_wire;
                            end
                            4'b0110: begin
                                data_out <= unsigned_ ? { 16'h0, base_ram_data_wire[31:16] } : { { 16{ base_ram_data_wire[31] } }, base_ram_data_wire[31:16] };
                                //cache_data[address[6:2]] <= base_ram_data_wire;
                            end
                            default: begin
                                data_out <= base_ram_data_wire;
                                //cache_data[address[6:2]] <= base_ram_data_wire;
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
                    mtime_state <= `STATE_IDLE;
                end
            endcase
        end
    end

endmodule
