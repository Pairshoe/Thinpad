`default_nettype none
`timescale 1ns / 1ps
`include "sram.vh"

module sram(
    // clock and reset
    input wire           clk,
    input wire           rst,

    // interface to user
    input wire           oe,
    input wire           we,
    input wire           be, // if uart, even without be set, byte input/output will be used
    input wire[31:0]     address,
    input wire[31:0]     data_in,
    output reg[31:0]     data_out,
    output reg           done,

    // interface to BaseRAM 
    inout wire[31:0]     base_ram_data_wire,
    output wire[19:0]    base_ram_addr,
    output wire[3:0]     base_ram_be_n,
    output wire          base_ram_ce_n,
    output reg           base_ram_oe_n,
    output reg           base_ram_we_n,

    // interface to ExtRAM
    inout wire[31:0]     ext_ram_data_wire,
    output wire[19:0]    ext_ram_addr,
    output wire[3:0]     ext_ram_be_n,
    output wire          ext_ram_ce_n,
    output reg           ext_ram_oe_n,
    output reg           ext_ram_we_n,

    // interface to UART 
    output reg           uart_rdn,
    output reg           uart_wrn,
    input wire           uart_dataready,
    input wire           uart_tbre,
    input wire           uart_tsre
);

    reg                  data_z;
    wire                 use_sram, use_ext, use_uart, use_uart_state;
    wire[7:0]            uart_state_data;
    reg[3:0]             state;

    assign               base_ram_data_wire = data_z ? 32'bz : (be ? (data_in[7:0] << (8 * address[1:0])) : data_in);
    assign               base_ram_addr = address[21:2];
    assign               base_ram_be_n = be ? (~(1 << address[1:0])) : 4'b0000;
    assign               base_ram_ce_n = (use_uart == 0 && use_ext == 0) ? 0 : 1;

    assign               ext_ram_data_wire = data_z ? 32'bz : (be ? (data_in[7:0] << (8 * address[1:0])) : data_in);
    assign               ext_ram_addr = address[21:2];
    assign               ext_ram_be_n = be ? (~(1 << address[1:0])) : 4'b0000;
    assign               ext_ram_ce_n = (use_uart == 0 && use_ext == 1) ? 0 : 1;

    assign               use_uart = (address == 32'h10000000);
    assign               use_uart_state = (address == 32'h10000005);
    assign               use_sram = (32'h80000000 <= address && address < 32'h80800000);
    assign               use_ext = (32'h80400000 <= address);
    assign               uart_state_data = sram_state == `STATE_SELECT ? (((uart_tbre == 1 && uart_tsre == 1) << 5) | uart_dataready) : 8'b00000000;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= `STATE_IDLE;
            data_z <= 1'b0;
            done <= 1'b0;
            base_ram_oe_n <= 1'b1;
            base_ram_we_n <= 1'b1;
            ext_ram_oe_n <= 1'b1;
            ext_ram_we_n <= 1'b1;
            uart_rdn <= 1'b1;
            uart_wrn <= 1'b1;
        end
        else begin
            case(state)
                `STATE_IDLE: begin
                    if (we) begin
                        case({use_sram, use_uart})
                            2'b10: begin
                                state <= `STATE_SRAM_WRITE;
                                base_ram_we_n <= use_ext ? 1 : 0;
                                ext_ram_we_n <= use_ext ? 0 : 1;
                            end
                            2'b01: begin
                                state <= `STATE_UART_WRITE_0;
                                uart_wrn <= 1'b0;
                            end
                            default: begin
                            end
                        endcase
                    end
                    else if (oe) begin
                        case({ use_sram, use_uart, use_uart_state })
                            3'b100: begin
                                state <= `STATE_SRAM_READ;
                                data_z <= 1'b1;
                                if (use_ext) begin
                                    ext_ram_oe_n <= 1'b0;
                                end
                                else begin
                                    base_ram_oe_n <= 1'b0;
                                end
                            end
                            3'b010: begin
                                state <= `STATE_UART_READ_0;
                                data_z <= 1'b1;
                                uart_rdn <= 1'b0;
                            end
                            3'b001: begin
                                state <= `STATE_FINISHED;
                                data_out <= { 24'h000000, uart_state_data };
                                done <= 1'b1;
                            end
                            default: begin
                            end
                        endcase
                    end
                    else begin
                    end
                end

                `STATE_SRAM_WRITE: begin
                    state <= `STATE_FINISHED;
                    base_ram_we_n <= 1'b1;
                    ext_ram_we_n <= 1'b1;
                    done <= 1'b1;
                end

                `STATE_SRAM_READ: begin
                    state <= `STATE_FINISHED;
                    base_ram_oe_n <= 1'b1;
                    ext_ram_oe_n <= 1'b1;
                    if (use_ext) begin
                        case({ be, address[1:0] })
                            3'b100: begin
                                data_out <= { 24'h000000, ext_ram_data_wire[7:0] };
                            end
                            3'b101: begin
                                data_out <= { 24'h000000, ext_ram_data_wire[15:8] };
                            end
                            3'b110: begin
                                data_out <= { 24'h000000, ext_ram_data_wire[23:16] };
                            end
                            3'b111: begin
                                data_out <= { 24'h000000, ext_ram_data_wire[31:24] };
                            end
                            default: begin
                                data_out <= ext_ram_data_wire;
                            end
                        endcase
                    end
                    else begin
                        case({ be, address[1:0] })
                            3'b100: begin
                                data_out <= { 24'h000000, base_ram_data_wire[7:0] };
                            end
                            3'b101: begin
                                data_out <= { 24'h000000, base_ram_data_wire[15:8] };
                            end
                            3'b110: begin
                                data_out <= { 24'h000000, base_ram_data_wire[23:16] };
                            end
                            3'b111: begin
                                data_out <= { 24'h000000, base_ram_data_wire[31:24] };
                            end
                            default: begin
                                data_out <= base_ram_data_wire;
                            end
                        endcase
                    end
                    done <= 1'b1;
                end

                `STATE_UART_WRITE_0: begin // uart write needs 2 cycles
                    state <= `STATE_UART_WRITE_1;
                end

                `STATE_UART_WRITE_1: begin
                    state <= `STATE_FINISHED;
                    uart_wrn <= 1'b1;
                    done <= 1'b1;
                end        

                `STATE_UART_READ_0: begin // uart read needs 2 cycles
                    state <= `STATE_UART_READ_1;
                end

                `STATE_UART_READ_1: begin
                    state <= `STATE_FINISHED;
                    data_out <= { 24'h000000, base_ram_data_wire[7:0] };
                    uart_rdn <= 1'b1;
                    done <= 1'b1;
                end

                `STATE_FINISHED: begin
                    state <= `STATE_IDLE;
                    data_z <= 1'b0;
                    done <= 1'b0;
                end

                default: begin
                end
            endcase
        end
    end

endmodule
