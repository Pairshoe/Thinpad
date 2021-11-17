`default_nettype none
`include "alu.vh"

module thinpad_top(
    input wire          clk_50M,
    input wire          clk_11M0592,

    // input wire          clock_btn,
    input wire          reset_btn,

    // input wire[3:0]     touch_btn,
    // input wire[31:0]    dip_sw,
    // output wire[15:0]   leds,
    // output wire[7:0]    dpy0,
    // output wire[7:0]    dpy1,

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
    (* dont_touch = "true" *) wire                mem_oe, mem_we, mem_be, mem_tlb_clr;
    (* dont_touch = "true" *) wire[31:0]          mem_address;
    (* dont_touch = "true" *) wire[31:0]          mem_data_in;
    (* dont_touch = "true" *) wire[31:0]          mem_data_out;
    (* dont_touch = "true" *) wire                mem_done;
    (* dont_touch = "true" *) wire                timeout;
    (* dont_touch = "true" *) wire[3:0]           mem_exception;

    // interface to decoder
    (* dont_touch = "true" *) wire[31:0]          instr;
    (* dont_touch = "true" *) wire[31:0]          csr_data;
    (* dont_touch = "true" *) wire[4:0]           reg_a, reg_b, reg_d;
    (* dont_touch = "true" *) wire[11:0]          csr;
    (* dont_touch = "true" *) wire                b_dat_select;
    (* dont_touch = "true" *) wire[4:0]           ins_op;
    (* dont_touch = "true" *) wire[4:0]           ins_alu_op;
    (* dont_touch = "true" *) wire[31:0]          imm;
    (* dont_touch = "true" *) wire[1:0]           mem_to_reg;
    (* dont_touch = "true" *) wire                a_select, b_select, pc_select, mem_wr, reg_wr, csr_reg_wr;
    (* dont_touch = "true" *) wire                tlb_clr;
    (* dont_touch = "true" *) wire[3:0]           decoder_exception;

    // interface to br_comparator
    (* dont_touch = "true" *) wire[31:0]          id_dat_a, id_dat_b;
    (* dont_touch = "true" *) wire                br_eq, br_lt, br_un, br_a_eqz, br_b_eqz;

    // interface to csr_regfile       
    (* dont_touch = "true" *) wire[11:0]          csr_raddr;
    (* dont_touch = "true" *) wire[31:0]          csr_rdata;
    (* dont_touch = "true" *) wire[31:0]          mtvec;
    (* dont_touch = "true" *) wire[31:0]          mscratch;
    (* dont_touch = "true" *) wire[31:0]          mepc;
    (* dont_touch = "true" *) wire[31:0]          mcause;
    (* dont_touch = "true" *) wire[31:0]          mstatus;
    (* dont_touch = "true" *) wire[31:0]          mie;
    (* dont_touch = "true" *) wire[31:0]          mip;
    (* dont_touch = "true" *) wire[31:0]          mtval;
    (* dont_touch = "true" *) wire[31:0]          satp;
    (* dont_touch = "true" *) wire[1:0]           mode;
    (* dont_touch = "true" *) wire                mtvec_we;
    (* dont_touch = "true" *) wire                mscratch_we;
    (* dont_touch = "true" *) wire                mepc_we;
    (* dont_touch = "true" *) wire                mcause_we;
    (* dont_touch = "true" *) wire                mstatus_we;
    (* dont_touch = "true" *) wire                mie_we;
    (* dont_touch = "true" *) wire                mip_we;
    (* dont_touch = "true" *) wire                mtval_we;
    (* dont_touch = "true" *) wire                satp_we;
    (* dont_touch = "true" *) wire                mode_we;
    (* dont_touch = "true" *) wire[31:0]          mtvec_wdata;
    (* dont_touch = "true" *) wire[31:0]          mscratch_wdata;
    (* dont_touch = "true" *) wire[31:0]          mepc_wdata;
    (* dont_touch = "true" *) wire[31:0]          mcause_wdata;
    (* dont_touch = "true" *) wire[31:0]          mstatus_wdata;
    (* dont_touch = "true" *) wire[31:0]          mie_wdata;
    (* dont_touch = "true" *) wire[31:0]          mip_wdata;
    (* dont_touch = "true" *) wire[31:0]          mtval_wdata;
    (* dont_touch = "true" *) wire[31:0]          satp_wdata;
    (* dont_touch = "true" *) wire[1:0]           mode_wdata;
    (* dont_touch = "true" *) wire                csr_we;
    (* dont_touch = "true" *) wire[11:0]          csr_waddr;
    (* dont_touch = "true" *) wire[31:0]          csr_wdata;

    // interface to regfile
    (* dont_touch = "true" *) wire[4:0]           reg_waddr;
    (* dont_touch = "true" *) wire[31:0]          reg_wdata;
    (* dont_touch = "true" *) wire                reg_we;
    (* dont_touch = "true" *) wire[4:0]           reg_raddr1, reg_raddr2;
    (* dont_touch = "true" *) wire[31:0]          reg_rdata1, reg_rdata2;

    // interface to alu
    (* dont_touch = "true" *) wire[4:0]           alu_op;
    (* dont_touch = "true" *) wire[31:0]          alu_data_a, alu_data_b, alu_data_r;
    (* dont_touch = "true" *) wire[3:0]           alu_flag;

    sram _sram(
        .clk            (clk_11M0592),
        .rst            (reset_btn),

        .be             (mem_be),
        .oe             (mem_oe),
        .we             (mem_we),
        .tlb_clr        (mem_tlb_clr),

        .address        (mem_address),
        .data_in        (mem_data_in),
        .data_out       (mem_data_out),
        .done           (mem_done),

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
        .uart_tsre      (uart_tsre),
        
        .satp           (satp),
        .mode           (mode),
        .timeout        (timeout),
        .exception      (mem_exception)
    );

    decoder _decoder(
        .inst           (instr),
        .br_eq          (br_eq),
        .br_lt          (br_lt),
        .br_a_eqz       (br_a_eqz),
        .br_b_eqz       (br_b_eqz),
        .ext_op         (ins_op),
        .alu_op         (ins_alu_op),
        .imm            (imm),
        .a_select       (a_select),
        .b_select       (b_select),
        .reg_a          (reg_a),
        .reg_b          (reg_b),
        .reg_d          (reg_d),
        .csr            (csr),
        .b_dat_select   (b_dat_select),
        .pc_select      (pc_select),
        .mem_wr         (mem_wr),
        .mem_to_reg     (mem_to_reg),
        .reg_wr         (reg_wr),
        .csr_reg_wr     (csr_reg_wr),
        .tlb_clr        (tlb_clr),
        .exception      (decoder_exception)
    );

    br_comparator _br_comparator(
        .rdata1         (id_dat_a),
        .rdata2         (id_dat_b),
        .br_eq          (br_eq),
        .br_lt          (br_lt),
        .br_un          (br_un),
        .br_a_eqz       (br_a_eqz),
        .br_b_eqz       (br_b_eqz)
    );

    csr_regfile _csr_regfile(
        .clk                (clk_11M0592),
        .rst                (reset_btn),

        // for read
        .csr_raddr          (csr_raddr),
        .csr_rdata          (csr_rdata),

        .mtvec              (mtvec),
        .mscratch           (mscratch),
        .mepc               (mepc),
        .mcause             (mcause),
        .mstatus            (mstatus),
        .mie                (mie),
        .mip                (mip),
        .mtval              (mtval),
        .satp               (satp),
        .mode               (mode),

        // for write
        .mtvec_we           (mtvec_we),
        .mscratch_we        (mscratch_we),
        .mepc_we            (mepc_we),
        .mcause_we          (mcause_we),
        .mstatus_we         (mstatus_we),
        .mie_we             (mie_we),
        .mip_we             (mip_we),
        .mtval_we           (mtval_we),
        .satp_we            (satp_we),
        .mode_we            (mode_we),
        .mtvec_wdata        (mtvec_wdata),
        .mscratch_wdata     (mscratch_wdata),
        .mepc_wdata         (mepc_wdata),
        .mcause_wdata       (mcause_wdata),
        .mstatus_wdata      (mstatus_wdata),
        .mie_wdata          (mie_wdata),
        .mip_wdata          (mip_wdata),
        .mtval_wdata        (mtval_wdata),
        .satp_wdata         (satp_wdata),
        .mode_wdata         (mode_wdata),

        // for writeback
        .csr_we             (csr_we),
        .csr_waddr          (csr_waddr),
        .csr_wdata          (csr_wdata)
    );

    regfile _regfile(
        .clk            (clk_11M0592),
        .rst            (reset_btn),
        .we             (reg_we),
        .waddr          (reg_waddr),
        .wdata          (reg_wdata),
        
        .raddr1         (reg_raddr1),
        .rdata1         (reg_rdata1),
        .raddr2         (reg_raddr2),
        .rdata2         (reg_rdata2)
    );

    alu _alu(
        .op             (alu_op),
        .a              (alu_data_a),
        .b              (alu_data_b),
        .r              (alu_data_r),
        .flags          (alu_flag)
    );

    // pipeline
    pipeline _pipeline(
        // clock and reset
        .clk            (clk_11M0592),
        .rst            (reset_btn),

        // interface to sram and uart
        .mem_be         (mem_be),
        .mem_oe         (mem_oe),
        .mem_we         (mem_we),
        .mem_tlb_clr    (mem_tlb_clr),
        .mem_address    (mem_address),
        .mem_data_in    (mem_data_in),
        .mem_data_out   (mem_data_out),
        .mem_done       (mem_done),
        .mem_exception  (mem_exception),
        .timeout        (timeout),

        // interface to decoder
        .instr              (instr),
        .ins_reg_s          (reg_a),
        .ins_reg_t          (reg_b),
        .ins_reg_d          (reg_d),
        .ins_csr            (csr),
        .ins_b_dat_select   (b_dat_select),
        .ins_a_select       (a_select),
        .ins_b_select       (b_select),
        .ins_pc_select      (pc_select),
        .ins_op             (ins_op),
        .ins_alu_op         (ins_alu_op),
        .ins_imm            (imm),
        .ins_mem_wr         (mem_wr),
        .ins_mem_to_reg     (mem_to_reg),
        .ins_reg_wr         (reg_wr),
        .ins_csr_reg_wr     (csr_reg_wr),
        .ins_tlb_clr        (tlb_clr),
        .decoder_exception  (decoder_exception),

        // interface to csr_regfile
        .csr_raddr      (csr_raddr),
        .csr_rdata      (csr_rdata),
        .mtvec          (mtvec),
        .mscratch       (mscratch),
        .mepc           (mepc),
        .mcause         (mcause),
        .mstatus        (mstatus),
        .mie            (mie),
        .mip            (mip),
        .mtval          (mtval),
        .satp           (satp),
        .mode           (mode),
        .mtvec_we       (mtvec_we),
        .mscratch_we    (mscratch_we),
        .mepc_we        (mepc_we),
        .mcause_we      (mcause_we),
        .mstatus_we     (mstatus_we),
        .mie_we         (mie_we),
        .mip_we         (mip_we),
        .mtval_we       (mtval_we),
        .satp_we        (satp_we),
        .mode_we        (mode_we),
        .mtvec_wdata    (mtvec_wdata),
        .mscratch_wdata (mscratch_wdata),
        .mepc_wdata     (mepc_wdata),
        .mcause_wdata   (mcause_wdata),
        .mstatus_wdata  (mstatus_wdata),
        .mie_wdata      (mie_wdata),
        .mip_wdata      (mip_wdata),
        .mtval_wdata    (mtval_wdata),
        .satp_wdata     (satp_wdata),
        .mode_wdata     (mode_wdata),
        .csr_we         (csr_we),
        .csr_waddr      (csr_waddr),
        .csr_wdata      (csr_wdata),

        // interface to regfile
        .regfile_raddr1 (reg_raddr1),
        .regfile_rdata1 (reg_rdata1),
        .regfile_raddr2 (reg_raddr2),
        .regfile_rdata2 (reg_rdata2),
        .regfile_we     (reg_we),
        .regfile_waddr  (reg_waddr),
        .regfile_wdata  (reg_wdata),
        
        // interface to branch comp
        .id_dat_a       (id_dat_a),
        .id_dat_b       (id_dat_b),
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
