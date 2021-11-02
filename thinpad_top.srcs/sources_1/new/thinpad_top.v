`default_nettype none
`include "alu.vh"

module thinpad_top(
    input wire          clk_50M,
    input wire          clk_11M0592,

    input wire          clock_btn,
    input wire          reset_btn,

    input wire[3:0]     touch_btn,
    input wire[31:0]    dip_sw,
    output wire[15:0]   leds,
    output wire[7:0]    dpy0,
    output wire[7:0]    dpy1,

    // uart signal
    output wire         uart_rdn,
    output wire         uart_wrn,
    input wire          uart_dataready,
    input wire          uart_tbre,
    input wire          uart_tsre,

    // BaseRAM signal
    inout wire[31:0]    base_ram_data,
    output wire[19:0]   base_ram_addr,
    output wire[3:0]    base_ram_be_n,
    output wire         base_ram_ce_n,
    output wire         base_ram_oe_n,
    output wire         base_ram_we_n,

    // ExtRAM signal
    inout wire[31:0]    ext_ram_data,
    output wire[19:0]   ext_ram_addr,
    output wire[3:0]    ext_ram_be_n,
    output wire         ext_ram_ce_n,
    output wire         ext_ram_oe_n,
    output wire         ext_ram_we_n
);

    // interface to sram and uart
    wire                mem_oe, mem_we, mem_be;
    wire[31:0]          mem_address;
    wire[31:0]          mem_data_in;
    wire[31:0]          mem_data_out;

    sram _sram(
        .clk            (clk_50M),
        .rst            (reset_btn),

        .be             (mem_be),
        .oe             (mem_oe),
        .we             (mem_we),

        .address        (mem_address),
        .data_in        (mem_data_in),
        .data_out       (mem_data_out),

        .base_ram_data_wire (base_ram_data),
        .base_ram_addr      (base_ram_addr),
        .base_ram_be_n      (base_ram_be_n),
        .base_ram_ce_n      (base_ram_ce_n),
        .base_ram_oe_n      (base_ram_oe_n),
        .base_ram_we_n      (base_ram_we_n),

        .ext_ram_data_wire  (ext_ram_data),
        .ext_ram_addr       (ext_ram_addr),
        .ext_ram_be_n       (ext_ram_be_n),
        .ext_ram_ce_n       (ext_ram_ce_n),
        .ext_ram_oe_n       (ext_ram_oe_n),
        .ext_ram_we_n       (ext_ram_we_n),

        .uart_rdn       (uart_rdn),
        .uart_wrn       (uart_wrn),
        .uart_dataready (uart_dataready),
        .uart_tbre      (uart_tbre),
        .uart_tsre      (uart_tsre)
);

    // interface to decoder
    wire[31:0]          instr;
    wire[4:0]           reg_a, reg_b, reg_d;
    wire[4:0]           ins_op;
    wire[4:0]           ins_alu_op;
    wire[31:0]          imm;
    wire[1:0]           mem_to_reg;
    wire                a_select, b_select, pc_select, mem_wr, reg_wr;

    decoder _decoder(
        .inst           (instr),
        .br_eq          (br_eq),
        .br_lt          (br_lt),
        .ext_op         (ins_op),
        .alu_op         (ins_alu_op),
        .imm            (imm),
        .a_select       (a_select),
        .b_select       (b_select),
        .reg_a          (reg_a),
        .reg_b          (reg_b),
        .reg_d          (reg_d),
        .pc_select      (pc_select),
        .mem_wr         (mem_wr),
        .mem_to_reg     (mem_to_reg),
        .reg_wr         (reg_wr)
    );

    // interface to br_comparator
    wire                br_eq, br_lt, br_un;

    br_comparator _br_comparator(
        .rdata1         (reg_rdata1),
        .rdata2         (reg_rdata2),
        .br_eq          (br_eq),
        .br_lt          (br_lt),
        .br_un          (br_un)
    );

    // interface to regfile
    wire[4:0]           reg_waddr;
    wire[31:0]          reg_wdata;
    wire                reg_we;
    wire[4:0]           reg_raddr1, reg_raddr2;
    wire[31:0]          reg_rdata1, reg_rdata2;

    regfile _regfile(
        .clk            (clk_50M),
        .rst            (reset_btn),
        .we             (reg_we),
        .waddr          (reg_waddr),
        .wdata          (reg_wdata),
        
        .raddr1         (reg_raddr1),
        .rdata1         (reg_rdata1),
        .raddr2         (reg_raddr2),
        .rdata2         (reg_rdata2)
    );

    // interface to alu
    wire[4:0]           alu_op;
    wire[31:0]          alu_data_a, alu_data_b, alu_data_r;
    wire[3:0]           alu_flag;

    alu _alu(
        .op             (alu_op),
        .a              (alu_data_a),
        .b              (alu_data_b),
        .r              (alu_data_r),
        .flags          (alu_flag)
    );

    //pipeline
    pipeline _pipeline(
        // clock and reset
        .clk            (clk_50M),
        .rst            (reset_btn),

        // interface to sram and uart
        .mem_be         (mem_be),
        .mem_oe         (mem_oe),
        .mem_we         (mem_we),
        .mem_address    (mem_address),
        .mem_data_in    (mem_data_in),
        .mem_data_out   (mem_data_out),

        // interface to decoder
        .instr          (instr),
        .ins_reg_s      (reg_a),
        .ins_reg_t      (reg_b),
        .ins_reg_d      (reg_d),
        .ins_a_select   (a_select),
        .ins_b_select   (b_select),
        .ins_pc_select  (pc_select),
        .ins_op         (ins_op),
        .ins_alu_op     (ins_alu_op),
        .ins_imm        (imm),
        .ins_mem_wr     (mem_wr),
        .ins_mem_to_reg (mem_to_reg),
        .ins_reg_wr     (reg_wr),

        // interface to regfile
        .regfile_raddr1 (reg_raddr1),
        .regfile_rdata1 (reg_rdata1),
        .regfile_raddr2 (reg_raddr2),
        .regfile_rdata2 (reg_rdata2),
        .regfile_we     (reg_we),
        .regfile_waddr  (reg_waddr),
        .regfile_wdata  (reg_wdata),
        
        // interface to branch comp
        .br_un          (br_un),
        .br_eq          (br_eq),
        .br_lt          (br_lt),

        // interface to alu
        .alu_op         (alu_op),
        .alu_data_a     (alu_data_a),
        .alu_data_b     (alu_data_b),
        .alu_data_r     (alu_data_r),
        .alu_flag       (alu_flag)
    );

endmodule
