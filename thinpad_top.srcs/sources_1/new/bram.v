`default_nettype none
`timescale 1ns / 100ps

module bram #(parameter ADDR_WIDTH = 0, DATA_WIDTH = 0, HSIZE = 0, VSIZE = 0, SCALE = 0)(
    input wire                    clk,
    input wire                    rst,

    // for read
    input wire[11:0]              hdata,
    input wire[11:0]              vdata,
    output wire[2:0]              red_out,
    output wire[2:0]              green_out,
    output wire[1:0]              blue_out,

    // for register showing
    input wire[31:0]              show_num,

    // for life game
    input wire[3:0]               game_row,
    input wire[3:0]               game_column,
    input wire                    game_write,
    input wire                    game_clear,
    input wire                    game_lock,
    input wire                    game_trigger_start,
    input wire                    game_trigger_stop

    // // for common write
    // input wire[DATA_WIDTH - 1:0]  din,
    // input wire[ADDR_WIDTH - 1:0]  addr,
    // input wire                    we
);

    wire wea;
    wire game_start;
    wire[DATA_WIDTH - 1:0] data, douta, doutb;
    wire[ADDR_WIDTH - 1:0] addra, addrb;
    wire[31:0] row, column, column_count, start_column, start_row; // for show_num and life game
    reg[3:0] number; // for show_num
    reg reg_wea; 
    reg[ADDR_WIDTH - 1:0] reg_addra, reg_addrb;
    reg[DATA_WIDTH - 1:0] reg_data;
    reg reg_game_trigger;

    reg[2:0] game_status; 
    integer game_time_counter; 
    integer now_row, now_column, now_aside_count, now_alive_count;
    reg now_alive;

    localparam offset = 10000;
    localparam size = 16;
    localparam IDLE = 3'b000;
    localparam READ_ORI = 3'b001;
    localparam READ_ASIDE = 3'b010;
    localparam WRITE_NEXT = 3'b011;
    localparam READ_NEXT = 3'b100;
    localparam READ_NEXT_1 = 3'b101;
    localparam OVERRIDE = 3'b110;

    assign game_start = game_lock && reg_game_trigger;
    assign red_out = doutb[7:5];
    assign green_out = doutb[4:2];
    assign blue_out = doutb[1:0];
    assign wea = reg_wea; 
    assign data = reg_data; 
    assign addra = reg_addra;
    assign addrb = reg_addrb;
    assign row = (vdata / SCALE) % 24;
    assign column = (hdata / SCALE) % 24;
    assign column_count = (hdata / SCALE) / 24;
    assign start_column = (HSIZE - 5 * size * SCALE) / 2;
    assign start_row = (VSIZE + 24 * SCALE - 5 * size * SCALE) / 2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            game_time_counter <= 0;
            game_status <= 0;
            reg_game_trigger <= 0;
        end
        else begin
            if (game_trigger_start) begin // trigger
                reg_game_trigger <= 1;
            end
            else if (game_trigger_stop) begin
                reg_game_trigger <= 0;
            end

            if (game_start && game_time_counter == 24999999) begin // 0.5s per change
                game_time_counter <= 0;
                game_status <= READ_ORI;
                now_row <= 0;
                now_column <= 0;
            end
            else if (game_start) begin
                game_time_counter <= game_time_counter + 1;
            end
            
            case (game_status)
                IDLE: begin
                    reg_addra <= offset + game_row * size + game_column;
                    reg_data <= game_write ? 0 : 255;
                    reg_wea <= (! game_start) & (game_write | game_clear); // can write only on game stop
                end
                READ_ORI: begin // read original point
                    reg_addra <= offset + size * now_row + now_column;
                    reg_wea <= 1'b0;
                    now_alive_count <= 0;
                    now_aside_count <= 0;
                    game_status <= READ_ASIDE;
                end
                READ_ASIDE: begin // read aside points
                    if (now_aside_count == 1) begin
                        now_alive <= douta == 0 ? 1 : 0;
                    end
                    case (now_aside_count)
                        1: begin
                            reg_addra <= (now_row > 0 && now_column > 0) ? offset + size * (now_row - 1) + (now_column - 1) : 0;
                        end
                        2: begin
                            reg_addra <= (now_row > 0) ? offset + size * (now_row - 1) + (now_column) : 0;
                        end
                        3: begin
                            now_alive_count <= douta == 0 ? now_alive_count + 1 : now_alive_count;
                            reg_addra <= (now_row > 0 && now_column < size - 1 )? offset + size * (now_row - 1) + (now_column + 1) : 0;
                        end
                        4: begin
                            now_alive_count <= douta == 0 ? now_alive_count + 1 : now_alive_count;
                            reg_addra <= (now_column < size - 1) ? offset + size * (now_row) + (now_column + 1) : 0;
                        end
                        5: begin
                            now_alive_count <= douta == 0 ? now_alive_count + 1 : now_alive_count;
                            reg_addra <= (now_row < size - 1 && now_column < size - 1) ? offset + size * (now_row + 1) + (now_column + 1) : 0;
                        end
                        6: begin
                            now_alive_count <= douta == 0 ? now_alive_count + 1 : now_alive_count;
                            reg_addra <= (now_row < size - 1) ? offset + size * (now_row + 1) + (now_column) : 0;
                        end
                        7: begin
                            now_alive_count <= douta == 0 ? now_alive_count + 1 : now_alive_count;
                            reg_addra <= (now_row < size - 1 && now_column > 0) ? offset + size * (now_row + 1) + (now_column - 1) : 0;
                        end
                        8: begin
                            now_alive_count <= douta == 0 ? now_alive_count + 1 : now_alive_count;
                            reg_addra <= (now_column > 0) ? offset + size * (now_row) + (now_column - 1) : 0;
                        end
                        9: begin
                            now_alive_count <= douta == 0 ? now_alive_count + 1 : now_alive_count;
                        end
                        10: begin
                            now_alive_count <= douta == 0 ? now_alive_count + 1 : now_alive_count;
                            game_status <= WRITE_NEXT;
                        end
                    endcase
                    now_aside_count <= now_aside_count + 1;
                end
                WRITE_NEXT: begin // write next state
                    reg_addra <= offset + size * size + size * now_row + now_column;
                    reg_data <= now_alive ? ((now_alive_count == 2 || now_alive_count == 3) ? 0 : 255) : (now_alive_count == 3 ? 0 : 255); // life game basic rule
                    reg_wea <= 1'b1;
                    if (now_column == size - 1 && now_row == size - 1) begin
                        now_row <= 0;
                        now_column <= 0;
                        game_status <= READ_NEXT;
                    end
                    else if (now_column == size - 1) begin
                        now_column <= 0;
                        now_row <= now_row + 1;
                        game_status <= READ_ORI;
                    end
                    else begin
                        now_column <= now_column + 1;
                        game_status <= READ_ORI;
                    end
                end
                READ_NEXT: begin // read next state
                    reg_addra <= offset + size * size + size * now_row + now_column;
                    reg_wea <= 1'b0;
                    game_status <= READ_NEXT_1;
                end
                READ_NEXT_1: begin
                    game_status <= OVERRIDE;
                end
                OVERRIDE: begin // override
                    reg_addra <= offset + size * now_row + now_column;
                    reg_data <= douta;
                    reg_wea <= 1'b1;
                    if (now_column == size - 1 && now_row == size - 1) begin
                        now_row <= 0;
                        now_column <= 0;
                        game_status <= IDLE;
                    end
                    else if (now_column == size - 1) begin
                        now_column <= 0;
                        now_row <= now_row + 1;
                        game_status <= READ_NEXT;
                    end
                    else begin
                        now_column <= now_column + 1;
                        game_status <= READ_NEXT;
                    end
                end
            endcase
        end
    end


    always @(*) begin
        case (column_count)
            0: begin
                number = show_num[31:28];
            end
            1: begin
                number = show_num[27:24];
            end
            2: begin
                number = show_num[23:20];
            end
            3: begin
                number = show_num[19:16];
            end
            4: begin
                number = show_num[15:12];
            end
            5: begin
                number = show_num[11:8];
            end
            6: begin
                number = show_num[7:4];
            end
            7: begin
                number = show_num[3:0];
            end
            default: begin
                number = 4'b0;
            end
        endcase
    end

    always @(*) begin
        // set addrb
        if (hdata < 8 * 24 * SCALE && vdata < 24 * SCALE) begin
            reg_addrb = number * 24 * 24 + row * 24 + column;  
        end
        else if (hdata >= start_column && hdata < start_column + (5 * size + 1) * SCALE && vdata >= start_row && vdata < start_row + (5 * size + 1) * SCALE) begin
            if (((hdata - start_column) / SCALE) % 5 != 0 && ((vdata - start_row) / SCALE) % 5 != 0) begin
                reg_addrb = offset + (((vdata - start_row) / SCALE) / 5) * size + ((hdata - start_column) / SCALE) / 5; 
            end
            else begin
                reg_addrb = 153;
            end
        end
        else begin
            reg_addrb = 0;
        end
    end

    // xpm_memory_dpdistram #(
    //     .ADDR_WIDTH_A(ADDR_WIDTH),      // DECIMAL
    //     .ADDR_WIDTH_B(ADDR_WIDTH),      // DECIMAL
    //     .BYTE_WRITE_WIDTH_A(DATA_WIDTH),// DECIMAL
    //     .CLOCKING_MODE("common_clock"), // String
    //     .MEMORY_INIT_FILE("merge.mem"), // String
    //     .MEMORY_INIT_PARAM("0"),        // String
    //     .MEMORY_OPTIMIZATION("true"),   // String
    //     .MEMORY_SIZE(131072),           // DECIMAL
    //     .MESSAGE_CONTROL(0),            // DECIMAL
    //     .READ_DATA_WIDTH_A(DATA_WIDTH), // DECIMAL
    //     .READ_DATA_WIDTH_B(DATA_WIDTH), // DECIMAL
    //     .READ_LATENCY_A(1),             // DECIMAL
    //     .READ_LATENCY_B(1),             // DECIMAL
    //     .READ_RESET_VALUE_A("0"),       // String
    //     .READ_RESET_VALUE_B("0"),       // String
    //     .RST_MODE_A("SYNC"),            // String
    //     .RST_MODE_B("SYNC"),            // String
    //     .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    //     .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
    //     .USE_MEM_INIT(1),               // DECIMAL
    //     .WRITE_DATA_WIDTH_A(DATA_WIDTH) // DECIMAL
    // )
    // xpm_memory_dpdistram_inst (
    //     .douta(douta),  // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
    //     .doutb(doutb),  // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
    //     .addra(addra),  // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
    //     .addrb(addrb),  // ADDR_WIDTH_B-bit input: Address for port B write and read operations.
    //     .clka(clk),     // 1-bit input: Clock signal for port A. Also clocks port B when parameter CLOCKING_MODE
    //                     // is "common_clock".

    //     .clkb(clk),     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
    //                     // "independent_clock". Unused when parameter CLOCKING_MODE is "common_clock".

    //     .dina(data),     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
    //     .ena(1'b1),     // 1-bit input: Memory enable signal for port A. Must be high on clock cycles when read
    //                     // or write operations are initiated. Pipelined internally.

    //     .enb(1'b1),     // 1-bit input: Memory enable signal for port B. Must be high on clock cycles when read
    //                     // or write operations are initiated. Pipelined internally.

    //     .regcea(1'b1),  // 1-bit input: Clock Enable for the last register stage on the output data path.
    //     .regceb(),      // 1-bit input: Do not change from the provided value.
    //     .rsta(rst),     // 1-bit input: Reset signal for the final port A output register stage. Synchronously
    //                     // resets output port douta to the value specified by parameter READ_RESET_VALUE_A.

    //     .rstb(rst),     // 1-bit input: Reset signal for the final port B output register stage. Synchronously
    //                     // resets output port doutb to the value specified by parameter READ_RESET_VALUE_B.

    //     .wea(wea)        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector for port A input
    //                     // data port dina. 1 bit wide when word-wide writes are used. In byte-wide write
    //                     // configurations, each bit controls the writing one byte of dina to address addra. For
    //                     // example, to synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A is
    //                     // 32, wea would be 4'b0010.
    // );

    xpm_memory_tdpram #(
        .ADDR_WIDTH_A(ADDR_WIDTH),      // DECIMAL
        .ADDR_WIDTH_B(ADDR_WIDTH),      // DECIMAL
        .AUTO_SLEEP_TIME(0),            // DECIMAL
        .BYTE_WRITE_WIDTH_A(8),         // DECIMAL
        .BYTE_WRITE_WIDTH_B(8),         // DECIMAL
        .CASCADE_HEIGHT(0),             // DECIMAL
        .CLOCKING_MODE("common_clock"), // String
        .ECC_MODE("no_ecc"),            // String
        .MEMORY_INIT_FILE("merge.mem"), // String
        .MEMORY_INIT_PARAM("0"),        // String
        .MEMORY_OPTIMIZATION("true"),   // String
        .MEMORY_PRIMITIVE("auto"),      // String
        .MEMORY_SIZE(131072),           // DECIMAL
        .MESSAGE_CONTROL(0),            // DECIMAL
        .READ_DATA_WIDTH_A(8),          // DECIMAL
        .READ_DATA_WIDTH_B(8),          // DECIMAL
        .READ_LATENCY_A(1),             // DECIMAL
        .READ_LATENCY_B(1),             // DECIMAL
        .READ_RESET_VALUE_A("0"),       // String
        .READ_RESET_VALUE_B("0"),       // String
        .RST_MODE_A("SYNC"),            // String
        .RST_MODE_B("SYNC"),            // String
        .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
        .USE_MEM_INIT(1),               // DECIMAL
        .WAKEUP_TIME("disable_sleep"),  // String
        .WRITE_DATA_WIDTH_A(8),         // DECIMAL
        .WRITE_DATA_WIDTH_B(8),         // DECIMAL
        .WRITE_MODE_A("no_change"),     // String
        .WRITE_MODE_B("no_change")      // String
    )
    xpm_memory_tdpram_inst (
        .dbiterra(),                    // 1-bit output: Status signal to indicate double bit error occurrence
                                        // on the data output of port A.

        .dbiterrb(),                    // 1-bit output: Status signal to indicate double bit error occurrence
                                        // on the data output of port A.

        .douta(douta),                  // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
        .doutb(doutb),                  // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
        .sbiterra(),                    // 1-bit output: Status signal to indicate single bit error occurrence
                                        // on the data output of port A.

        .sbiterrb(),                    // 1-bit output: Status signal to indicate single bit error occurrence
                                        // on the data output of port B.

        .addra(addra),                  // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
        .addrb(addrb),                  // ADDR_WIDTH_B-bit input: Address for port B write and read operations.
        .clka(clk),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                        // parameter CLOCKING_MODE is "common_clock".

        .clkb(clk),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                        // "independent_clock". Unused when parameter CLOCKING_MODE is
                                        // "common_clock".

        .dina(data),                    // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
        .dinb(),                        // WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
        .ena(1'b1),                     // 1-bit input: Memory enable signal for port A. Must be high on clock
                                        // cycles when read or write operations are initiated. Pipelined
                                        // internally.

        .enb(1'b1),                     // 1-bit input: Memory enable signal for port B. Must be high on clock
                                        // cycles when read or write operations are initiated. Pipelined
                                        // internally.

        .injectdbiterra(1'b0),          // 1-bit input: Controls double bit error injection on input data when
                                        // ECC enabled (Error injection capability is not available in
                                        // "decode_only" mode).

        .injectdbiterrb(1'b0),          // 1-bit input: Controls double bit error injection on input data when
                                        // ECC enabled (Error injection capability is not available in
                                        // "decode_only" mode).

        .injectsbiterra(1'b0),          // 1-bit input: Controls single bit error injection on input data when
                                        // ECC enabled (Error injection capability is not available in
                                        // "decode_only" mode).

        .injectsbiterrb(1'b0),          // 1-bit input: Controls single bit error injection on input data when
                                        // ECC enabled (Error injection capability is not available in
                                        // "decode_only" mode).

        .regcea(1'b1),                  // 1-bit input: Clock Enable for the last register stage on the output
                                        // data path.

        .regceb(1'b1),                  // 1-bit input: Clock Enable for the last register stage on the output
                                        // data path.

        .rsta(rst),                     // 1-bit input: Reset signal for the final port A output register stage.
                                        // Synchronously resets output port douta to the value specified by
                                        // parameter READ_RESET_VALUE_A.

        .rstb(rst),                     // 1-bit input: Reset signal for the final port B output register stage.
                                        // Synchronously resets output port doutb to the value specified by
                                        // parameter READ_RESET_VALUE_B.

        .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
        .wea(wea),                      // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                        // for port A input data port dina. 1 bit wide when word-wide writes are
                                        // used. In byte-wide write configurations, each bit controls the
                                        // writing one byte of dina to address addra. For example, to
                                        // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                        // is 32, wea would be 4'b0010.

        .web(1'b0)                      // WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector
                                        // for port B input data port dinb. 1 bit wide when word-wide writes are
                                        // used. In byte-wide write configurations, each bit controls the
                                        // writing one byte of dinb to address addrb. For example, to
                                        // synchronously write only bits [15-8] of dinb when WRITE_DATA_WIDTH_B
                                        // is 32, web would be 4'b0010.

    );

endmodule
