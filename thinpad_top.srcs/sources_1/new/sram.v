`default_nettype none
`timescale 1ns / 1ps
`include "sram.vh"

module sram(
    // clock and reset
    input wire          clk,
    input wire          rst,

    // interface to user
    input wire          oe,
    input wire          we,
    input wire          byte,  // if using uart, even without 'byte' set, byte input / output will be used
    input wire          half,
    input wire          unsigned_,
    input wire[31:0]    address,
    input wire[31:0]    data_in,
    output reg[31:0]    data_out,
    output reg          done,

    // interface to BaseRAM
    inout wire[31:0]    base_ram_data_wire,
    output wire[19:0]   base_ram_addr,
    output wire[3:0]    base_ram_be_n,
    output wire         base_ram_ce_n,
    output reg          base_ram_oe_n,
    output reg          base_ram_we_n,

    // interface to ExtRAM
    inout wire[31:0]    ext_ram_data_wire,
    output wire[19:0]   ext_ram_addr,
    output wire[3:0]    ext_ram_be_n,
    output wire         ext_ram_ce_n,
    output reg          ext_ram_oe_n,
    output reg          ext_ram_we_n,

    // interface to UART
    output reg          uart_rdn,
    output reg          uart_wrn,
    input wire          uart_dataready,
    input wire          uart_tbre,
    input wire          uart_tsre,

    // others
    input wire          tlb_clr,
    input wire[31:0]    satp,
    input wire[1:0]     mode,
    output wire         timeout,
    output wire[3:0]    exception
);

    reg                 data_z;
    reg[31:0]           reg_address;
    reg[21:0]           reg_entry;
    wire                use_sram, use_base, use_ext, use_uart, use_uart_state;
    wire[7:0]           uart_state_data;
    reg[31:0]           reg_mtime_lo, reg_mtime_hi, reg_mtimecmp_lo, reg_mtimecmp_hi;
    reg[3:0]            state, uart_write_state, mtime_state;
    reg                 reg_timeout;

    reg[42:0]           TLBs[0:3];

    reg[31:0]           cache_addr[0:31], cache_data[0:31];
    reg[31:0]           valid;
    wire[31:0]          sram_data_wire;

    assign base_ram_data_wire = data_z ? 32'bz : (byte ? (data_in[7:0] << (8 * address[1:0])) : (half ? (data_in[15:0] << (8 * address[1:0])) : data_in));
    assign base_ram_addr = (satp[31] == 1 && mode == 2'b00) ? reg_address[21:2] : address[21:2];
    assign base_ram_be_n = byte ? (~(1'b1 << address[1:0])) : (half ? (~(2'b11 << address[1:0])) : 4'b0000);
    assign base_ram_ce_n = (use_sram == 1) ? 0 : 1;

    assign ext_ram_data_wire = data_z ? 32'bz : (byte ? (data_in[7:0] << (8 * address[1:0])) : (half ? (data_in[15:0] << (8 * address[1:0])) : data_in));
    assign ext_ram_addr = (satp[31] == 1 && mode == 2'b00) ? reg_address[21:2] : address[21:2];
    assign ext_ram_be_n = byte ? (~(1'b1 << address[1:0])) : (half ? (~(2'b11 << address[1:0])) : 4'b0000);
    assign ext_ram_ce_n = (use_sram == 1) ? 0 : 1;

    assign sram_data_wire = use_ext ? ext_ram_data_wire : base_ram_data_wire;
    assign use_uart = (address == 32'h10000000);
    assign use_uart_state = (address == 32'h10000005);
    assign use_sram = (use_base || use_ext);
    assign use_base = (satp[31] == 1 && mode == 2'b00) ?  
                      (((32'h00000000 <= address && address < 32'h00300000) ||
                        (32'h80100000 <= address && address < 32'h80101000) ||
                        (32'h80000000 <= address && address < 32'h80001000) ||
                        (32'h80001000 <= address && address < 32'h80002000)) ? 1 : 0) :
                      ((32'h80000000 <= address && address < 32'h80800000) ? 1 : 0);
    assign use_ext = (satp[31] == 1 && mode == 2'b00) ? ((32'h7fc10000 <= address && address < 32'h80000000) ? 1 : 0) : ((32'h80400000 <= address) ? 1 : 0);
    assign uart_state_data = (state == `STATE_IDLE) ? (((uart_write_state == `STATE_IDLE) << 5) | uart_dataready) : 8'b00000000;
    assign timeout = reg_timeout;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= `STATE_IDLE;
            uart_write_state <= `STATE_IDLE;
            mtime_state <= `STATE_IDLE;
            data_z <= 1'b0;
            done <= 1'b1;
            base_ram_oe_n <= 1'b1;  base_ram_we_n <= 1'b1;  ext_ram_oe_n <= 1'b1;  ext_ram_we_n <= 1'b1;
            uart_rdn <= 1'b1;  uart_wrn <= 1'b1;
            reg_mtime_lo <= 32'b0;  reg_mtime_hi <= 32'b0;  reg_mtimecmp_lo <= 32'b0;  reg_mtimecmp_hi <= 32'b0;  reg_timeout <= 1'b0;
            TLBs[0] <= 43'b0;  TLBs[1] <= 43'b0;  TLBs[2] <= 43'b0;  TLBs[3] <= 43'b0;
            valid <= 32'b0;
        end
        else begin
            case(state)
                `STATE_IDLE: begin
                    if (tlb_clr) begin
                        TLBs[0][42] <= 1'b0;  TLBs[1][42] <= 1'b0;  TLBs[2][42] <= 1'b0;  TLBs[3][42] <= 1'b0;
                    end
                    if (we) begin
                        case({ use_sram, use_uart })
                            2'b10: begin
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
                            2'b01: begin
                                state <= `STATE_UART_READ_WRITE;
                                uart_wrn <= 1'b0;
                                done <= 1'b0;
                            end
                            default: begin
                                state <= `STATE_FINISHED;
                                reg_mtime_lo <= (address == 32'h0200bff8) ? data_in : reg_mtime_lo;
                                reg_mtime_hi <= (address == 32'h0200bffc) ? data_in : reg_mtime_hi;
                                reg_mtimecmp_lo <= (address == 32'h02004000) ? data_in : reg_mtimecmp_lo;
                                reg_mtimecmp_hi <= (address == 32'h02004004) ? data_in : reg_mtimecmp_hi;
                                done <= 1'b1;
                            end
                        endcase
                    end
                    else if (oe) begin
                        case({ use_sram, use_uart, use_uart_state })
                            3'b100: begin
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
                                    if (valid[address[6:2]] == 1 && cache_addr[address[6:2]] == address) begin
                                        state <= `STATE_FINISHED;
                                        /*if (byte == 1) begin
                                            data_out <= unsigned_ ? ((cache_data[address[6:2]] << ((3 - address[1:0]) * 8)) >>> 24) : ((cache_data[address[6:2]] << ((3 - address[1:0]) * 8)) >> 24);
                                        end
                                        else if (half == 1) begin
                                            data_out <= unsigned_ ? ((cache_data[address[6:2]] << ((2 - address[1:0]) * 8)) >>> 16) : ((cache_data[address[6:2]] << ((2 - address[1:0]) * 8)) >> 16);
                                        end
                                        else begin
                                            data_out <= cache_data[address[6:2]];
                                        end*/
                                        case({ byte, half })
                                            2'b10: begin
                                                data_out <= unsigned_ ? ((cache_data[address[6:2]] << ((3 - address[1:0]) * 8)) >>> 24) : ((cache_data[address[6:2]] << ((3 - address[1:0]) * 8)) >> 24);
                                            end
                                            2'b01: begin
                                                data_out <= unsigned_ ? ((cache_data[address[6:2]] << ((2 - address[1:0]) * 8)) >>> 16) : ((cache_data[address[6:2]] << ((2 - address[1:0]) * 8)) >> 16);
                                            end
                                            default: begin
                                                data_out <= cache_data[address[6:2]];
                                            end
                                        endcase
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
                            3'b010: begin
                                state <= `STATE_UART_READ_WRITE;
                                data_z <= 1'b1;
                                uart_rdn <= 1'b0;
                                done <= 1'b0;
                            end
                            3'b001: begin
                                state <= `STATE_FINISHED;
                                data_out <= { 24'h000000, uart_state_data };
                                done <= 1'b1;
                            end
                            default: begin
                                state <= `STATE_FINISHED;
                                data_out <= (address > 32'h0200bff0) ? ((address == 32'h0200bff8) ? reg_mtime_lo : reg_mtime_hi) : ((address == 32'h02004000) ? reg_mtimecmp_lo : reg_mtimecmp_hi);
                                done <= 1'b1;
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
                    if (cache_addr[address[6:2]] == address) begin
                        if (byte == 0 && half == 0) begin
                            cache_addr[address[6:2]] <= address;
                            cache_data[address[6:2]] <= data_in;
                        end
                        else begin
                            valid[address[6:2]] <= 0;
                        end
                    end
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
                    case({ byte, half })
                        2'b10: begin
                            data_out <= unsigned_ ? ((sram_data_wire << ((3 - address[1:0]) * 8)) >>> 24) : ((sram_data_wire << ((3 - address[1:0]) * 8)) >> 24);
                        end
                        2'b01: begin
                            data_out <= unsigned_ ? ((sram_data_wire << ((2 - address[1:0]) * 8)) >>> 16) : ((sram_data_wire << ((2 - address[1:0]) * 8)) >> 16);
                        end
                        default: begin
                            data_out <= sram_data_wire;
                            valid[address[6:2]] <= 1;
                            cache_addr[address[6:2]] <= address;
                            cache_data[address[6:2]] <= sram_data_wire;
                        end
                    endcase
                    done <= 1'b1;
                end

                `STATE_UART_READ_WRITE: begin
                    state <= `STATE_FINISHED;
                    data_out <= { 24'h000000, base_ram_data_wire[7:0] };
                    uart_rdn <= 1'b1;
                    uart_wrn <= 1'b1;
                    done <= 1'b1;
                end

                default: begin
                    state <= `STATE_IDLE;
                    data_z <= 1'b0;
                end
            endcase

            case(uart_write_state)
                `STATE_IDLE: begin
                    if (uart_tbre == 0) begin
                        uart_write_state <= `STATE_UART_READ_WRITE;
                    end
                end

                `STATE_UART_READ_WRITE: begin
                    if (uart_tsre == 0) begin
                        uart_write_state <= `STATE_FINISHED;
                    end
                end

                default: begin
                    if (uart_tsre == 1) begin
                        uart_write_state <= `STATE_IDLE;
                    end
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

                default: begin
                    mtime_state <= `STATE_IDLE;
                    if (reg_mtime_lo == { 32 { 1'b1 } }) begin
                        reg_mtime_lo <= 32'b0;
                        reg_mtime_hi <= reg_mtime_hi + 1;
                    end
                    else begin
                        reg_mtime_lo <= reg_mtime_lo + 1;
                    end
                end
            endcase
        end
    end

endmodule
