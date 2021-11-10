`timescale 1ns / 1ps
module tb;

wire clk_50M, clk_11M0592;

reg reset_btn = 0;

wire[31:0] base_ram_data;
wire[19:0] base_ram_addr;
wire[3:0] base_ram_be_n;
wire base_ram_ce_n;
wire base_ram_oe_n;
wire base_ram_we_n;

wire[31:0] ext_ram_data;
wire[19:0] ext_ram_addr;
wire[3:0] ext_ram_be_n;
wire ext_ram_ce_n;
wire ext_ram_oe_n;
wire ext_ram_we_n;

wire uart_rdn;
wire uart_wrn;
wire uart_dataready;
wire uart_tbre;
wire uart_tsre;

parameter BASE_RAM_INIT_FILE = "C:\\Users\\86189\\Desktop\\cod21-grp67\\tests\\test_kernel\\kernel_int_quick.bin"; // BaseRAM Initial File
parameter EXT_RAM_INIT_FILE = "C:\\Users\\86189\\Desktop\\cod21-grp67\\tests\\test_int\\test_ecall.bin";//ExtRAM Initial File

initial begin 
    reset_btn = 1;  #100;  reset_btn = 0;
    /*# 3000;
    cpld.pc_send_byte(8'h61);  # 3000;
    cpld.pc_send_byte(8'h62);  # 3000;
    cpld.pc_send_byte(8'h63);  # 3000;
    cpld.pc_send_byte(8'h64);  # 3000;
    cpld.pc_send_byte(8'h65);  # 3000;
    cpld.pc_send_byte(8'h66);  # 3000;
    cpld.pc_send_byte(8'h67);  # 3000;
    cpld.pc_send_byte(8'h68);  # 3000;
    cpld.pc_send_byte(8'h69);  # 3000;
    cpld.pc_send_byte(8'h6a);  # 3000;*/
    #570000;
    // W
    cpld.pc_send_byte(8'h57);  # 10000;
//    // A
//    cpld.pc_send_byte(8'h41);  # 10000;
//    // addr: 0x80100000
//    cpld.pc_send_byte(8'h00);  # 10000;
//    cpld.pc_send_byte(8'h00);  # 10000;
//    cpld.pc_send_byte(8'h10);  # 10000;
//    cpld.pc_send_byte(8'h80);  # 10000;
//    // len: 0x000000004
//    cpld.pc_send_byte(8'h04);  # 10000;
//    cpld.pc_send_byte(8'h00);  # 10000;
//    cpld.pc_send_byte(8'h00);  # 10000;
//    cpld.pc_send_byte(8'h00);  # 10000;
//    // user code: 0x01 0x02 0x03 0x04
//    cpld.pc_send_byte(8'h01);  # 10000;
//    cpld.pc_send_byte(8'h02);  # 10000;
//    cpld.pc_send_byte(8'h03);  # 10000;
//    cpld.pc_send_byte(8'h04);  # 10000;
//    // D
//    cpld.pc_send_byte(8'h44);  # 10000;
//    // addr: 0x80100000
//    cpld.pc_send_byte(8'h00);  # 10000;
//    cpld.pc_send_byte(8'h00);  # 10000;
//    cpld.pc_send_byte(8'h10);  # 10000;
//    cpld.pc_send_byte(8'h80);  # 10000;
//    // len: 0x000000004
//    cpld.pc_send_byte(8'h04);  # 10000;
//    cpld.pc_send_byte(8'h00);  # 10000;
//    cpld.pc_send_byte(8'h00);  # 10000;
//    cpld.pc_send_byte(8'h00);  # 10000;

    // G
    cpld.pc_send_byte(8'h47);  # 10000;
    // addr: 0x80400000
    cpld.pc_send_byte(8'h00);  # 10000;
    cpld.pc_send_byte(8'h00);  # 10000;
    cpld.pc_send_byte(8'h40);  # 10000;
    cpld.pc_send_byte(8'h80);  # 10000;
    
    # 200000;
    // D
    cpld.pc_send_byte(8'h44);  # 10000;
    // addr: 0x80000000
    cpld.pc_send_byte(8'h00);  # 10000;
    cpld.pc_send_byte(8'h00);  # 10000;
    cpld.pc_send_byte(8'h00);  # 10000;
    cpld.pc_send_byte(8'h80);  # 10000;
    // len: 0x000000008
    cpld.pc_send_byte(8'h08);  # 10000;
    cpld.pc_send_byte(8'h00);  # 10000;
    cpld.pc_send_byte(8'h00);  # 10000;
    cpld.pc_send_byte(8'h00);  # 10000;
    
end

thinpad_top dut(
    .clk_50M(clk_50M),
    .clk_11M0592(clk_11M0592),
    .reset_btn(reset_btn),
    .uart_rdn(uart_rdn),
    .uart_wrn(uart_wrn),
    .uart_dataready(uart_dataready),
    .uart_tbre(uart_tbre),
    .uart_tsre(uart_tsre),
    .base_ram_data(base_ram_data),
    .base_ram_addr(base_ram_addr),
    .base_ram_ce_n(base_ram_ce_n),
    .base_ram_oe_n(base_ram_oe_n),
    .base_ram_we_n(base_ram_we_n),
    .base_ram_be_n(base_ram_be_n),
    .ext_ram_data(ext_ram_data),
    .ext_ram_addr(ext_ram_addr),
    .ext_ram_ce_n(ext_ram_ce_n),
    .ext_ram_oe_n(ext_ram_oe_n),
    .ext_ram_we_n(ext_ram_we_n),
    .ext_ram_be_n(ext_ram_be_n)
);

// Clock Model
clock osc(
    .clk_11M0592(clk_11M0592),
    .clk_50M(clk_50M)
);

// CPLD Model
cpld_model cpld(
    .clk_uart(clk_11M0592),
    .uart_rdn(uart_rdn),
    .uart_wrn(uart_wrn),
    .uart_dataready(uart_dataready),
    .uart_tbre(uart_tbre),
    .uart_tsre(uart_tsre),
    .data(base_ram_data[7:0])
);

// BaseRAM Model
sram_model base1(
    .DataIO(base_ram_data[15:0]),
    .Address(base_ram_addr[19:0]),
    .OE_n(base_ram_oe_n),
    .CE_n(base_ram_ce_n),
    .WE_n(base_ram_we_n),
    .LB_n(base_ram_be_n[0]),
    .UB_n(base_ram_be_n[1])
);
sram_model base2(
    .DataIO(base_ram_data[31:16]),
    .Address(base_ram_addr[19:0]),
    .OE_n(base_ram_oe_n),
    .CE_n(base_ram_ce_n),
    .WE_n(base_ram_we_n),
    .LB_n(base_ram_be_n[2]),
    .UB_n(base_ram_be_n[3])
);

// ExtRAM Model
sram_model ext1(
    .DataIO(ext_ram_data[15:0]),
    .Address(ext_ram_addr[19:0]),
    .OE_n(ext_ram_oe_n),
    .CE_n(ext_ram_ce_n),
    .WE_n(ext_ram_we_n),
    .LB_n(ext_ram_be_n[0]),
    .UB_n(ext_ram_be_n[1])
);
sram_model ext2(
    .DataIO(ext_ram_data[31:16]),
    .Address(ext_ram_addr[19:0]),
    .OE_n(ext_ram_oe_n),
    .CE_n(ext_ram_ce_n),
    .WE_n(ext_ram_we_n),
    .LB_n(ext_ram_be_n[2]),
    .UB_n(ext_ram_be_n[3])
);

// BaseRAM Init
initial begin 
    reg [31:0] tmp_array[0:1048575];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(BASE_RAM_INIT_FILE, "rb");
    if(!n_File_ID)begin 
        n_Init_Size = 0;
        $display("Failed to open BaseRAM init file");
    end else begin
        n_Init_Size = $fread(tmp_array, n_File_ID);
        n_Init_Size /= 4;
        $fclose(n_File_ID);
    end
    $display("BaseRAM Init Size(words): %d",n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
        base1.mem_array0[i] = tmp_array[i][24+:8];
        base1.mem_array1[i] = tmp_array[i][16+:8];
        base2.mem_array0[i] = tmp_array[i][8+:8];
        base2.mem_array1[i] = tmp_array[i][0+:8];
    end
end

// ExtRAM Init
initial begin 
    reg [31:0] tmp_array[0:1048575];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(EXT_RAM_INIT_FILE, "rb");
    if(!n_File_ID)begin 
        n_Init_Size = 0;
        $display("Failed to open ExtRAM init file");
    end else begin
        n_Init_Size = $fread(tmp_array, n_File_ID);
        n_Init_Size /= 4;
        $fclose(n_File_ID);
    end
    $display("ExtRAM Init Size(words): %d",n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
        ext1.mem_array0[i] = tmp_array[i][24+:8];
        ext1.mem_array1[i] = tmp_array[i][16+:8];
        ext2.mem_array0[i] = tmp_array[i][8+:8];
        ext2.mem_array1[i] = tmp_array[i][0+:8];
    end
end


endmodule
