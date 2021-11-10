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

    /*
    // debug mode signals
    // regs between if and id
    output wire[31:0]          reg_if_id_pc_now,
    output wire[31:0]          reg_if_id_instr,
    output wire                reg_if_id_abort,

    // regs between id and exe
    output wire[31:0]          reg_id_exe_pc_now,
    output wire[31:0]          reg_id_exe_data_a, reg_id_exe_data_b,
    output wire[4:0]           reg_id_exe_reg_d,
    output wire                reg_id_exe_a_select, reg_id_exe_b_select, reg_id_exe_pc_select,
    output wire[4:0]           reg_id_exe_op,
    output wire[4:0]           reg_id_exe_alu_op,
    output wire[31:0]          reg_id_exe_imm,
    output wire                reg_id_exe_mem_wr,
    output wire[1:0]           reg_id_exe_mem_to_reg,
    output wire                reg_id_exe_reg_wr,
    output wire                reg_id_exe_abort,

    // regs between exe and mem
    output wire[31:0]          reg_exe_mem_pc_now,
    output wire[31:0]          reg_exe_mem_data_r, reg_exe_mem_data_b,
    output wire                reg_exe_mem_pc_select,
    output wire[4:0]           reg_exe_mem_reg_d,
    output wire[4:0]           reg_exe_mem_op,
    output wire                reg_exe_mem_mem_wr,
    output wire[1:0]           reg_exe_mem_mem_to_reg,
    output wire                reg_exe_mem_reg_wr,
    output wire                reg_exe_mem_abort,

    // regs between mem and wb
    output wire[31:0]          reg_mem_wb_data,
    output wire[4:0]           reg_mem_wb_reg_d,
    output wire[4:0]           reg_mem_wb_op,
    output wire                reg_mem_wb_reg_wr,
    output wire                reg_mem_wb_abort,

    output wire[3:0]           stall_if, stall_id, stall_exe, stall_mem, stall_wb,
    output wire[31:0]          pc,
    output wire[2:0]           time_counter,
    output wire[1:0]           forwarding_select_a, forwarding_select_b,

    // interface to sram and uart
    output wire                mem_oe, mem_we, mem_be,
    output wire[31:0]          mem_address,
    output wire[31:0]          mem_data_in,
    output wire[31:0]          mem_data_out,

    // interface to decoder
    output wire[31:0]          instr,
    output wire[4:0]           reg_a, reg_b, reg_d,
    output wire[11:0]          csr,
    output wire[4:0]           ins_op,
    output wire[4:0]           ins_alu_op,
    output wire[31:0]          imm,
    output wire[1:0]           mem_to_reg,
    output wire                a_select, b_select, b_dat_select, pc_select, mem_wr, reg_wr, csr_reg_wr,
    output wire[3:0]           exception,

    // interface to br_comparator
    output wire[31:0]          id_dat_a, id_dat_b,
    output wire                br_eq, br_lt, br_un,

    // interface to csr_regfile       
    output wire[11:0]          csr_raddr,
    output wire[31:0]          csr_rdata,
    output wire[31:0]          mtvec,
    output wire[31:0]          mscratch,
    output wire[31:0]          mepc,
    output wire[31:0]          mcause,
    output wire[31:0]          mstatus,
    output wire[31:0]          mie,
    output wire[31:0]          mip,
    output wire[31:0]          mtval,
    output wire                mtvec_we,
    output wire                mscratch_we,
    output wire                mepc_we,
    output wire                mcause_we,
    output wire                mstatus_we,
    output wire                mie_we,
    output wire                mip_we,
    output wire                mtval_we,
    output wire[31:0]          mtvec_wdata,
    output wire[31:0]          mscratch_wdata,
    output wire[31:0]          mepc_wdata,
    output wire[31:0]          mcause_wdata,
    output wire[31:0]          mstatus_wdata,
    output wire[31:0]          mie_wdata,
    output wire[31:0]          mip_wdata,
    output wire[31:0]          mtval_wdata,
    output wire                csr_we,
    output wire[11:0]          csr_waddr,
    output wire[31:0]          csr_wdata,

    // interface to mmio_regfile
    output wire[31:0]          mtime_lo,
    output wire[31:0]          mtime_hi,
    output wire[31:0]          mtimecmp_lo,
    output wire[31:0]          mtimecmp_hi,
    output wire[1:0]           mtime_we,
    output wire[1:0]           mtimecmp_we,
    output wire[31:0]          mtime_wdata,
    output wire[31:0]          mtimecmp_wdata,

    // interface to regfile
    output wire[4:0]           reg_waddr,
    output wire[31:0]          reg_wdata,
    output wire                reg_we,
    output wire[4:0]           reg_raddr1, reg_raddr2,
    output wire[31:0]          reg_rdata1, reg_rdata2,

    // interface to alu
    output wire[4:0]           alu_op,
    output wire[31:0]          alu_data_a, alu_data_b, alu_data_r,
    output wire[3:0]           alu_flag*/
);
    // release mode signals
    
    // regs between if and id
    wire[31:0]          reg_if_id_pc_now;
    wire[31:0]          reg_if_id_instr;
    wire                reg_if_id_abort;
    wire[31:0]          pc;

    // regs between id and exe
    wire[31:0]          reg_id_exe_pc_now;
    wire[31:0]          reg_id_exe_data_a, reg_id_exe_data_b;
    wire[4:0]           reg_id_exe_reg_d;
    wire                reg_id_exe_a_select, reg_id_exe_b_select, reg_id_exe_pc_select;
    wire[4:0]           reg_id_exe_op;
    wire[4:0]           reg_id_exe_alu_op;
    wire[31:0]          reg_id_exe_imm;
    wire                reg_id_exe_mem_wr;
    wire[1:0]           reg_id_exe_mem_to_reg;
    wire                reg_id_exe_reg_wr;
    wire                reg_id_exe_abort;

    // regs between exe and mem
    wire[31:0]          reg_exe_mem_pc_now;
    wire[31:0]          reg_exe_mem_data_r, reg_exe_mem_data_b;
    wire                reg_exe_mem_pc_select;
    wire[4:0]           reg_exe_mem_reg_d;
    wire[4:0]           reg_exe_mem_op;
    wire                reg_exe_mem_mem_wr;
    wire[1:0]           reg_exe_mem_mem_to_reg;
    wire                reg_exe_mem_reg_wr;
    wire                reg_exe_mem_abort;

    // regs between mem and wb
    wire[31:0]          reg_mem_wb_data;
    wire[4:0]           reg_mem_wb_reg_d;
    wire[4:0]           reg_mem_wb_op;
    wire                reg_mem_wb_reg_wr;
    wire                reg_mem_wb_abort;

    wire[3:0]           stall_if, stall_id, stall_exe, stall_mem, stall_wb;
    
    wire[2:0]           time_counter;
    wire[1:0]           forwarding_select_a, forwarding_select_b;

    // interface to sram and uart
    wire                mem_oe, mem_we, mem_be;
    wire[31:0]          mem_address;
    wire[31:0]          mem_data_in;
    wire[31:0]          mem_data_out;

    // interface to decoder
    
    wire[4:0]           reg_a, reg_b, reg_d;
    wire[31:0]          instr;
    wire[11:0]          csr;
    wire[4:0]           ins_op;
    wire[4:0]           ins_alu_op;
    wire[31:0]          imm;
    wire[1:0]           mem_to_reg;
    wire                a_select, b_select, b_dat_select, pc_select, mem_wr, reg_wr, csr_reg_wr;
    wire[3:0]           exception;

    // interface to br_comparator
    wire[31:0]          id_dat_a, id_dat_b;
    wire                br_eq, br_lt, br_un;

    // interface to csr_regfile       
    wire[11:0]          csr_raddr;
    wire[31:0]          csr_rdata;
    wire[31:0]          mtvec;
    wire[31:0]          mscratch;
    wire[31:0]          mepc;
    wire[31:0]          mcause;
    wire[31:0]          mstatus;
    wire[31:0]          mie;
    wire[31:0]          mip;
    wire[31:0]          mtval;
    wire                mtvec_we;
    wire                mscratch_we;
    wire                mepc_we;
    wire                mcause_we;
    wire                mstatus_we;
    wire                mie_we;
    wire                mip_we;
    wire                mtval_we;
    wire[31:0]          mtvec_wdata;
    wire[31:0]          mscratch_wdata;
    wire[31:0]          mepc_wdata;
    wire[31:0]          mcause_wdata;
    wire[31:0]          mstatus_wdata;
    wire[31:0]          mie_wdata;
    wire[31:0]          mip_wdata;
    wire[31:0]          mtval_wdata;
    wire                csr_we;
    wire[11:0]          csr_waddr;
    wire[31:0]          csr_wdata;

    // interface to mmio_regfile
    wire                timeout;
    wire[31:0]          mtime_lo;
    wire[31:0]          mtime_hi;
    wire[31:0]          mtimecmp_lo;
    wire[31:0]          mtimecmp_hi;
    wire[1:0]           mtime_we;
    wire[1:0]           mtimecmp_we;
    wire[31:0]          mtime_wdata;
    wire[31:0]          mtimecmp_wdata;

    // interface to regfile
    wire[4:0]           reg_waddr;
    wire[31:0]          reg_wdata;
    wire                reg_we;
    wire[4:0]           reg_raddr1, reg_raddr2;
    wire[31:0]          reg_rdata1, reg_rdata2;

    // interface to alu
    wire[4:0]           alu_op;
    wire[31:0]          alu_data_a, alu_data_b, alu_data_r;
    wire[3:0]           alu_flag;
    
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
        .csr            (csr),
        .b_dat_select   (b_dat_select),
        .pc_select      (pc_select),
        .mem_wr         (mem_wr),
        .mem_to_reg     (mem_to_reg),
        .reg_wr         (reg_wr),
        .csr_reg_wr     (csr_reg_wr),
        .exception      (exception)
    );

    br_comparator _br_comparator(
        .rdata1         (id_dat_a),
        .rdata2         (id_dat_b),
        .br_eq          (br_eq),
        .br_lt          (br_lt),
        .br_un          (br_un)
    );

    csr_regfile _csr_regfile(
        .clk                (clk_50M),
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

        // for write
        .mtvec_we           (mtvec_we),
        .mscratch_we        (mscratch_we),
        .mepc_we            (mepc_we),
        .mcause_we          (mcause_we),
        .mstatus_we         (mstatus_we),
        .mie_we             (mie_we),
        .mip_we             (mip_we),
        .mtval_we           (mtval_we),
        .mtvec_wdata        (mtvec_wdata),
        .mscratch_wdata     (mscratch_wdata),
        .mepc_wdata         (mepc_wdata),
        .mcause_wdata       (mcause_wdata),
        .mstatus_wdata      (mstatus_wdata),
        .mie_wdata          (mie_wdata),
        .mip_wdata          (mip_wdata),
        .mtval_wdata        (mtval_wdata),

        // for writeback
        .csr_we             (csr_we),
        .csr_waddr          (csr_waddr),
        .csr_wdata          (csr_wdata)
    );

    mmio_regfile _mmio_regfile(
        .clk                (clk_50M),
        .rst                (reset_btn),
        .timeout            (timeout),
        .mtime_lo           (mtime_lo),
        .mtime_hi           (mtime_hi), 
        .mtimecmp_lo        (mtimecmp_lo),
        .mtimecmp_hi        (mtimecmp_hi),
        .mtime_we           (mtime_we),
        .mtimecmp_we        (mtimecmp_we),
        .mtime_wdata        (mtime_wdata),
        .mtimecmp_wdata     (mtimecmp_wdata)
    );

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
        .decoder_exception  (exception),

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
        .mtvec_we       (mtvec_we),
        .mscratch_we    (mscratch_we),
        .mepc_we        (mepc_we),
        .mcause_we      (mcause_we),
        .mstatus_we     (mstatus_we),
        .mie_we         (mie_we),
        .mip_we         (mip_we),
        .mtval_we       (mtval_we),
        .mtvec_wdata    (mtvec_wdata),
        .mscratch_wdata (mscratch_wdata),
        .mepc_wdata     (mepc_wdata),
        .mcause_wdata   (mcause_wdata),
        .mstatus_wdata  (mstatus_wdata),
        .mie_wdata      (mie_wdata),
        .mip_wdata      (mip_wdata),
        .mtval_wdata    (mtval_wdata),
        .csr_we         (csr_we),
        .csr_waddr      (csr_waddr),
        .csr_wdata      (csr_wdata),

        // interface to mmio_regfile
        .timeout            (timeout),
        .mtime_lo           (mtime_lo),
        .mtime_hi           (mtime_hi), 
        .mtimecmp_lo        (mtimecmp_lo),
        .mtimecmp_hi        (mtimecmp_hi),
        .mtime_we           (mtime_we),
        .mtimecmp_we        (mtimecmp_we),
        .mtime_wdata        (mtime_wdata),
        .mtimecmp_wdata     (mtimecmp_wdata),

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
        .alu_flag       (alu_flag),

        // debug mode signals
        .reg_if_id_pc_now       (reg_if_id_pc_now),
        .reg_if_id_instr        (reg_if_id_instr),
        .reg_if_id_abort        (reg_if_id_abort),

        .reg_id_exe_pc_now      (reg_id_exe_pc_now),
        .reg_id_exe_data_a      (reg_id_exe_data_a),
        .reg_id_exe_data_b      (reg_id_exe_data_b),
        .reg_id_exe_reg_d       (reg_id_exe_reg_d),
        .reg_id_exe_a_select    (reg_id_exe_a_select),
        .reg_id_exe_b_select    (reg_id_exe_b_select),
        .reg_id_exe_pc_select   (reg_id_exe_pc_select),
        .reg_id_exe_op          (reg_id_exe_op),
        .reg_id_exe_alu_op      (reg_id_exe_alu_op),
        .reg_id_exe_imm         (reg_id_exe_imm),
        .reg_id_exe_mem_wr      (reg_id_exe_mem_wr),
        .reg_id_exe_mem_to_reg  (reg_id_exe_mem_to_reg),
        .reg_id_exe_reg_wr      (reg_id_exe_reg_wr),
        .reg_id_exe_abort       (reg_id_exe_abort),

        .reg_exe_mem_pc_now     (reg_exe_mem_pc_now),
        .reg_exe_mem_data_r     (reg_exe_mem_data_r),
        .reg_exe_mem_data_b     (reg_exe_mem_data_b),
        .reg_exe_mem_pc_select  (reg_exe_mem_pc_select),
        .reg_exe_mem_reg_d      (reg_exe_mem_reg_d),
        .reg_exe_mem_op         (reg_exe_mem_op),
        .reg_exe_mem_mem_wr     (reg_exe_mem_mem_wr),
        .reg_exe_mem_mem_to_reg (reg_exe_mem_mem_to_reg),
        .reg_exe_mem_reg_wr     (reg_exe_mem_reg_wr),
        .reg_exe_mem_abort      (reg_exe_mem_abort),

        .reg_mem_wb_data        (reg_mem_wb_data),
        .reg_mem_wb_reg_d       (reg_mem_wb_reg_d),
        .reg_mem_wb_op          (reg_mem_wb_op),
        .reg_mem_wb_reg_wr      (reg_mem_wb_reg_wr),
        .reg_mem_wb_abort       (reg_mem_wb_abort),

        .stall_if               (stall_if),
        .stall_id               (stall_id),
        .stall_exe              (stall_exe),
        .stall_mem              (stall_mem),
        .stall_wb               (stall_wb),
        .pc                     (pc),
        .time_counter           (time_counter),
        .forwarding_select_a    (forwarding_select_a),
        .forwarding_select_b    (forwarding_select_b)
    );

endmodule
