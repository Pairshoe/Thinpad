`default_nettype none
`timescale 1ns / 1ps
`include "sram.vh"

module sram(
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

    // interface to SRAM 
    inout wire[31:0]     base_ram_data_wire,
    output wire[19:0]    base_ram_addr,
    output reg[3:0]      base_ram_be_n,
    output wire          base_ram_ce_n,
    output reg           base_ram_oe_n,
    output reg           base_ram_we_n,

    inout wire[31:0]     ext_ram_data_wire,
    output wire[19:0]    ext_ram_addr,
    output reg[3:0]      ext_ram_be_n,
    output wire          ext_ram_ce_n,
    output reg           ext_ram_oe_n,
    output reg           ext_ram_we_n,

    // interface to CPLD 
    output reg           uart_rdn,
    output reg           uart_wrn,
    input wire           uart_dataready,
    input wire           uart_tbre,
    input wire           uart_tsre
);

    // oe
    /*reg                  base_oe_n, ext_oe_n;

    assign               base_ram_oe_n = base_oe_n;
    assign               ext_ram_oe_n = ext_oe_n;

    // we
    reg                  base_we_n, ext_we_n;

    assign               base_ram_we_n = base_we_n;
    assign               ext_ram_we_n = ext_we_n;

    // be
    reg[3:0]             be_n;

    assign               base_ram_be_n = be_n;
    assign               ext_ram_be_n = be_n;

    // rd & wr
    reg                  uart_rd_n, uart_wr_n;

    assign               uart_rdn = uart_rd_n;
    assign               uart_wrn = uart_wr_n;*/

    // inout
    reg                  data_z;
    reg[31:0]            base_ram_data, ext_ram_data;

    assign               base_ram_data_wire = data_z ? 32'bz : base_ram_data;
    assign               ext_ram_data_wire = data_z ? 32'bz : ext_ram_data;

    // address
    assign               base_ram_addr = address[21:2];
    assign               ext_ram_addr = address[21:2];

    // ce
    wire                 use_uart;
    wire                 use_uart_state;
    wire                 use_sram;
    wire                 use_ext;

    assign               use_uart = (address == 32'h10000000);
    assign               use_uart_state = (address == 32'h10000005);
    assign               use_sram = (32'h80000000 <= address && address < 32'h80800000);
    assign               use_ext = (32'h80400000 <= address);
    assign               { base_ram_ce_n, ext_ram_ce_n } = use_uart ? 2'b11 : use_ext ? 2'b10 : 2'b01;

    // data_out
    //reg                  sign;
    //reg[23:0]            sign_ext;
    //reg[31:0]            data;
    //assign               data_out = data;

    // fsm
    reg[7:0]             uart_state_data;
    reg[3:0]             uart_write_state;
    reg[3:0]             uart_read_state;
    reg[3:0]             sram_state;

    always @(*) begin
        if (be) begin
            case(address[1:0])
                2'b00: begin
                    base_ram_be_n = 4'b1110;
                    ext_ram_be_n = 4'b1110;
                end
                2'b01: begin
                    base_ram_be_n = 4'b1101;
                    ext_ram_be_n = 4'b1101;
                end
                2'b10: begin
                    base_ram_be_n = 4'b1011;
                    ext_ram_be_n = 4'b1011;
                end
                2'b11: begin
                    base_ram_be_n = 4'b0111;
                    ext_ram_be_n = 4'b0111;
                end
                default: begin
                    base_ram_be_n = 4'b1111;
                    ext_ram_be_n = 4'b1111;
                end
            endcase
        end
        else begin
            base_ram_be_n = 4'b0000;
            ext_ram_be_n = 4'b0000;
        end
    end

    always @(*) begin
        if (use_uart) begin
            base_ram_data = { 24'h000000, data_in[7:0] };
        end
        else begin
            case({be, address[1:0]})
                3'b100: begin
                    base_ram_data[7:0] = data_in[7:0];
                    ext_ram_data[31:24] = data_in[7:0];
                end
                3'b101: begin
                    base_ram_data[15:8] = data_in[7:0];
                    ext_ram_data[31:24] = data_in[7:0];
                end
                3'b110: begin
                    base_ram_data[23:16] = data_in[7:0];
                    ext_ram_data[31:24] = data_in[7:0];
                end
                3'b111: begin
                    base_ram_data[31:24] = data_in[7:0];
                    ext_ram_data[31:24] = data_in[7:0];
                end
                default: begin
                    base_ram_data = data_in;
                    ext_ram_data = data_in;
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sram_state <= `STATE_SELECT;
            uart_write_state <= `STATE_UART_WRITE_CHECK_0;
            uart_read_state <= `STATE_UART_READ_CHECK;
            data_z <= 1'b0;
            done <= 1'b0;
            base_ram_oe_n <= 1'b1;
            base_ram_we_n <= 1'b1;
            ext_ram_oe_n <= 1'b1;
            ext_ram_we_n <= 1'b1;
            uart_rdn <= 1'b1;
            uart_wrn <= 1'b1;
            uart_state_data <= 8'b00000000;
        end
        else begin
            case(sram_state)
                `STATE_SELECT: begin
                    if (we) begin
                        case({use_sram, use_uart})
                            2'b10: begin
                                sram_state <= `STATE_SRAM_WRITE_0;
                                base_ram_we_n <= use_ext ? 1 : 0;
                                ext_ram_we_n <= use_ext ? 0 : 1;
                                //data_z <= 1'b0;
                                /*if (use_ext) begin
                                    if (be) begin
                                        case(address[1:0])
                                            2'b00: begin
                                                ext_ram_data[7:0] <= data_in[7:0];
                                            end
                                            2'b01: begin
                                                ext_ram_data[15:8] <= data_in[7:0];
                                            end
                                            2'b10: begin
                                                ext_ram_data[23:16] <= data_in[7:0];
                                            end
                                            2'b11: begin
                                                ext_ram_data[31:24] <= data_in[7:0];
                                            end
                                            default: begin
                                            end
                                        endcase
                                    end
                                    else begin
                                        ext_ram_data <= data_in;
                                    end                               
                                end
                                else begin
                                    if (be) begin
                                        case(address[1:0])
                                            2'b00: begin
                                                base_ram_data[7:0] <= data_in[7:0];
                                            end
                                            2'b01: begin
                                                base_ram_data[15:8] <= data_in[7:0];
                                            end
                                            2'b10: begin
                                                base_ram_data[23:16] <= data_in[7:0];
                                            end
                                            2'b11: begin
                                                base_ram_data[31:24] <= data_in[7:0];
                                            end
                                            default: begin
                                            end
                                        endcase
                                    end
                                    else begin
                                        base_ram_data <= data_in;
                                    end
                                    base_we_n <= 1'b0;
                                end*/
                            end
                            2'b01: begin
                                sram_state <= `STATE_UART_WRITE_0;
                                //uart_state_data[0] <= 1'b0;
                                uart_state_data[5] <= 1'b0;
                                //data_z <= 1'b0;
                                uart_wrn <= 1'b0;
                                //base_ram_data <= { 24'h000000, data_in[7:0] };
                            end
                            default: begin
                            end
                        endcase
                    end
                    else if (oe) begin
                        case({ use_sram, use_uart, use_uart_state })
                            3'b100: begin
                                sram_state <= `STATE_SRAM_READ;
                                data_z <= 1'b1;
                                if (use_ext) begin
                                    ext_ram_oe_n <= 1'b0;
                                end
                                else begin
                                    base_ram_oe_n <= 1'b0;
                                end
                            end
                            3'b010: begin
                                sram_state <= `STATE_UART_READ_0;
                                data_z <= 1'b1;
                                uart_state_data[0] <= 1'b0;
                                //uart_state_data[5] <= 1'b0;
                                uart_rdn <= 1'b0;
                            end
                            3'b001: begin
                                sram_state <= `STATE_DATA_UPDATE;
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

                `STATE_SRAM_WRITE_0: begin
                    sram_state <= `STATE_SRAM_WRITE_1;
                    //ext_we_n <= 1'b0;
                end

                `STATE_SRAM_WRITE_1: begin
                    sram_state <= `STATE_SRAM_WRITE_2;
                    base_ram_we_n <= 1'b1;
                    ext_ram_we_n <= 1'b1;
                    //if (use_ext) begin
                        
                    //end
                    //else begin
                        
                    //end
                end

                `STATE_SRAM_WRITE_2: begin
                    sram_state <= `STATE_DATA_UPDATE;
                    //data_z <= 1'b1;
                    done <= 1'b1;
                end

                `STATE_SRAM_READ: begin
                    sram_state <= `STATE_DATA_UPDATE;
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
                        /*if (be) begin
                            case(address[1:0])
                                2'b00: begin
                                    sign = base_ram_data_wire[7];
                                    sign_ext <= { 24{ base_ram_data_wire[7] } };
                                    data <= { { 24{ base_ram_data_wire[7] } }, base_ram_data_wire[7:0] };
                                end
                                2'b01: begin
                                    sign = base_ram_data_wire[15];
                                    sign_ext <= { 24{ base_ram_data_wire[15] } };
                                    data <= { { 24{ base_ram_data_wire[15] } }, base_ram_data_wire[15:8] };
                                end
                                2'b10: begin
                                    sign = base_ram_data_wire[23];
                                    sign_ext <= { 24{ base_ram_data_wire[23] } };
                                    data <= { { 24{ base_ram_data_wire[23] } }, base_ram_data_wire[23:16] };
                                end
                                2'b11: begin
                                    sign = base_ram_data_wire[31];
                                    sign_ext <= { 24{ base_ram_data_wire[31] } };
                                    data <= { { 24{ base_ram_data_wire[31] } }, base_ram_data_wire[31:24] };
                                end
                                default: begin
                                end
                            endcase
                        end
                        else begin
                            data <= base_ram_data_wire;
                        end*/
                    end
                    done <= 1'b1;
                end

                `STATE_UART_WRITE_0: begin // uart write needs 2 cycles
                    sram_state <= `STATE_UART_WRITE_1;
                end

                `STATE_UART_WRITE_1: begin
                    sram_state <= `STATE_DATA_UPDATE;
                    uart_write_state <= `STATE_UART_WRITE_CHECK_0;
                    uart_wrn <= 1'b1;
                    //data_z <= 1'b1;
                    done <= 1'b1;
                end        

                `STATE_UART_READ_0: begin // uart read needs 2 cycles
                    sram_state <= `STATE_UART_READ_1;
                end

                `STATE_UART_READ_1: begin
                    sram_state <= `STATE_DATA_UPDATE;
                    uart_read_state <= `STATE_UART_READ_CHECK;
                    data_out <= { 24'h000000, base_ram_data_wire[7:0] };
                    uart_rdn <= 1'b1;
                    done <= 1'b1;
                end

                `STATE_DATA_UPDATE: begin
                    sram_state <= `STATE_SELECT;
                    data_z <= 1'b0;
                    done <= 1'b0;
                end

                default: begin
                end
            endcase

            case(uart_write_state)
                `STATE_IDLE: begin
                end
                `STATE_UART_WRITE_CHECK_0: begin
                    if (uart_tbre) begin
                        uart_write_state <= `STATE_UART_WRITE_CHECK_1;
                    end
                    else begin
                    end
                end
                `STATE_UART_WRITE_CHECK_1: begin
                    if (uart_tsre) begin
                        uart_write_state <= `STATE_IDLE;
                        uart_state_data[5] <= 1'b1;
                    end
                    else begin
                    end
                end
                default: begin
                end
            endcase

            case(uart_read_state)
                `STATE_IDLE: begin
                end
                `STATE_UART_READ_CHECK: begin
                    if (uart_dataready) begin
                        uart_read_state <= `STATE_IDLE;
                        uart_state_data[0] <= 1'b1;
                    end
                end
                default: begin
                end
            endcase
        end
    end

endmodule
