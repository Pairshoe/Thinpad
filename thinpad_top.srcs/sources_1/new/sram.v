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
    output wire[31:0]    data_out,
    output reg           done,

    // interface to SRAM 
    inout wire[31:0]     base_ram_data_wire,
    output wire[19:0]    base_ram_addr,
    output wire[3:0]     base_ram_be_n,
    output wire          base_ram_ce_n,
    output wire          base_ram_oe_n,
    output wire          base_ram_we_n,

    inout wire[31:0]     ext_ram_data_wire,
    output wire[19:0]    ext_ram_addr,
    output wire[3:0]     ext_ram_be_n,
    output wire          ext_ram_ce_n,
    output wire          ext_ram_oe_n,
    output wire          ext_ram_we_n,

    // interface to CPLD 
    output wire          uart_rdn,
    output wire          uart_wrn,
    input wire           uart_dataready,
    input wire           uart_tbre,
    input wire           uart_tsre
);

    // oe
    reg                  base_oe_n, ext_oe_n;

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

    always @(*) begin
        if (be) begin
            case(address[1:0])
                2'b00: begin
                    be_n = 4'b1110;
                end
                2'b01: begin
                    be_n = 4'b1101;
                end
                2'b10: begin
                    be_n = 4'b1011;
                end
                2'b11: begin
                    be_n = 4'b0111;
                end
                default: begin
                    be_n = 4'b1111;
                end
            endcase
        end
        else begin
            be_n = 4'b0000;
        end
    end

    // rd & wr
    reg                  uart_rd_n, uart_wr_n;

    assign               uart_rdn = uart_rd_n;
    assign               uart_wrn = uart_wr_n;

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
    reg                  sign;
    reg[23:0]            sign_ext;
    reg[31:0]            data;
    assign               data_out = data;

    // fsm
    reg[7:0]             uart_state_data;
    reg[3:0]             uart_write_state;
    reg[3:0]             uart_read_state;
    reg[3:0]             sram_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sram_state <= `STATE_IDLE;
            uart_write_state <= `STATE_IDLE;
            uart_read_state <= `STATE_IDLE;
            data_z <= 1'b1;
            done <= 1'b0;
            base_oe_n <= 1'b1;
            base_we_n <= 1'b1;
            ext_oe_n <= 1'b1;
            ext_we_n <= 1'b1;
            uart_rd_n <= 1'b1;
            uart_wr_n <= 1'b1;
            uart_state_data <= 8'b00000000;
        end
        else begin
            case(sram_state)
                `STATE_IDLE: begin
                    sram_state <= `STATE_SELECT;
                    uart_write_state <= `STATE_UART_WRITE_CHECK_0;
                    uart_read_state <= `STATE_UART_READ_CHECK;
                    done <= 1'b0;
                end

                `STATE_SELECT: begin
                    if (we) begin
                        case({use_sram, use_uart})
                            2'b10: begin
                                sram_state <= `STATE_SRAM_WRITE;
                                data_z <= 1'b0;
                                if (use_ext) begin
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
                                    ext_we_n <= 1'b0;
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
                                end
                            end
                            2'b01: begin
                                sram_state <= `STATE_UART_WRITE_WAIT;
                                uart_state_data[5] <= 1'b0;
                                data_z <= 1'b0;
                                uart_wr_n <= 1'b0;
                                base_ram_data <= { 24'h000000, data_in[7:0] };
                            end
                            default: begin
                            end
                        endcase
                    end
                    else begin
                    end
                    if (oe) begin
                        case({ use_sram, use_uart, use_uart_state })
                            3'b100: begin
                                sram_state <= `STATE_SRAM_READ;
                                if (use_ext) begin
                                    ext_oe_n <= 1'b0;
                                end
                                else begin
                                    base_oe_n <= 1'b0;
                                end
                            end
                            3'b010: begin
                                sram_state <= `STATE_UART_READ_WAIT;
                                uart_state_data[0] <= 1'b0;
                                uart_rd_n <= 1'b0;
                            end
                            3'b001: begin
                                sram_state <= `STATE_IDLE;
                                data <= { 24'h000000, uart_state_data };
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
                    sram_state <= `STATE_IDLE;
                    if (use_ext) begin
                        ext_we_n <= 1'b1;
                    end
                    else begin
                        base_we_n <= 1'b1;
                    end
                    data_z <= 1'b1;
                    done <= 1'b1;
                end

                `STATE_SRAM_READ: begin
                    sram_state <= `STATE_IDLE;
                    if (use_ext) begin
                        ext_oe_n <= 1'b1;
                        if (be) begin
                            case(address[1:0])
                                2'b00: begin
                                    sign = ext_ram_data_wire[7];
                                    sign_ext <= { 24{ sign } };
                                    data <= { sign_ext, ext_ram_data_wire[7:0] };
                                end
                                2'b01: begin
                                    sign = ext_ram_data_wire[15];
                                    sign_ext <= { 24{ sign } };
                                    data <= { sign_ext, ext_ram_data_wire[15:8] };
                                end
                                2'b10: begin
                                    sign = ext_ram_data_wire[23];
                                    sign_ext <= { 24{ sign } };
                                    data <= { sign_ext, ext_ram_data_wire[23:16] };
                                end
                                2'b11: begin
                                    sign = ext_ram_data_wire[31];
                                    sign_ext <= { 24{ sign } };
                                    data <= { sign_ext, ext_ram_data_wire[31:24] };
                                end
                                default: begin
                                end
                            endcase
                        end
                        else begin
                            data <= ext_ram_data_wire;
                        end
                    end
                    else begin
                        base_oe_n <= 1'b1;
                        if (be) begin
                            case(address[1:0])
                                2'b00: begin
                                    sign = base_ram_data_wire[7];
                                    sign_ext <= { 24{ sign } };
                                    data <= { sign_ext, base_ram_data_wire[7:0] };
                                end
                                2'b01: begin
                                    sign = base_ram_data_wire[15];
                                    sign_ext <= { 24{ sign } };
                                    data <= { sign_ext, base_ram_data_wire[15:8] };
                                end
                                2'b10: begin
                                    sign = base_ram_data_wire[23];
                                    sign_ext <= { 24{ sign } };
                                    data <= { sign_ext, base_ram_data_wire[23:16] };
                                end
                                2'b11: begin
                                    sign = base_ram_data_wire[31];
                                    sign_ext <= { 24{ sign } };
                                    data <= { sign_ext, base_ram_data_wire[31:24] };
                                end
                                default: begin
                                end
                            endcase
                        end
                        else begin
                            data <= base_ram_data_wire;
                        end
                    end
                    done <= 1'b1;
                end

                `STATE_UART_WRITE_WAIT: begin // uart write needs 2 cycles
                    sram_state <= `STATE_UART_WRITE;
                end

                `STATE_UART_WRITE: begin
                    sram_state <= `STATE_IDLE;
                    uart_wr_n <= 1'b1;
                    data_z <= 1'b1;
                    done <= 1'b1;
                end

                `STATE_UART_READ_WAIT: begin // uart read needs 2 cycles
                    sram_state <= `STATE_UART_READ;
                end

                `STATE_UART_READ: begin
                    sram_state <= `STATE_IDLE;
                    data <= base_ram_data_wire;
                    uart_rd_n <= 1'b1;
                    done <= 1'b1;
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
