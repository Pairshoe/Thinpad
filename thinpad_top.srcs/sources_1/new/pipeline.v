`default_nettype none
`timescale 1ns / 100ps
`include "ops.vh"

module pipeline(
    // clock and reset
    input wire        clk,
    input wire        rst,

    // interface to sram and uart
    output wire       mem_byte,
    output wire       mem_half,
    output wire       mem_unsigned,
    output reg        mem_oe,
    output reg        mem_we,
    output wire       mem_tlb_clr,
    output wire[31:0] mem_address,
    output wire[31:0] mem_data_in,
    input wire[31:0]  mem_data_out,
    input wire        mem_done,
    input wire[3:0]   mem_exception,
    input wire        timeout,

    // interface to decoder
    output wire[31:0] instr,
    input wire[4:0]   ins_reg_s,
    input wire[4:0]   ins_reg_t,
    input wire[4:0]   ins_reg_d,
    input wire[11:0]  ins_csr,
    input wire        ins_a_select,
    input wire        ins_b_select,
    input wire        ins_pc_select,
    input wire        ins_b_dat_select,
    input wire[5:0]   ins_op,
    input wire[4:0]   ins_alu_op,
    input wire[31:0]  ins_imm,
    input wire        ins_mem_wr,
    input wire[1:0]   ins_mem_to_reg,
    input wire        ins_reg_wr,
    input wire        ins_csr_reg_wr,
    input wire        ins_tlb_clr,
    input wire[3:0]   decoder_exception,
    input wire[3:0]   ins_pred,
    input wire[3:0]   ins_succ,

    // interface to csr_regfile
    output wire[11:0] csr_raddr,
    input wire[31:0]  csr_rdata,
    input wire[31:0]  mtvec,
    input wire[31:0]  mscratch,
    input wire[31:0]  mepc,
    input wire[31:0]  mcause,
    input wire[31:0]  mstatus,
    input wire[31:0]  mie,
    input wire[31:0]  mip,
    input wire[31:0]  mtval,
    input wire[31:0]  satp,
    input wire[1:0]   mode,
    output reg        mtvec_we,
    output reg        mscratch_we,
    output reg        mepc_we,
    output reg        mcause_we,
    output reg        mstatus_we,
    output reg        mie_we,
    output reg        mip_we,
    output reg        mtval_we,
    output reg        satp_we,
    output reg        mode_we,
    output reg[31:0]  mtvec_wdata,
    output reg[31:0]  mscratch_wdata,
    output reg[31:0]  mepc_wdata,
    output reg[31:0]  mcause_wdata,
    output reg[31:0]  mstatus_wdata,
    output reg[31:0]  mie_wdata,
    output reg[31:0]  mip_wdata,
    output reg[31:0]  mtval_wdata,
    output reg[31:0]  satp_wdata,
    output reg[1:0]   mode_wdata,
    output reg        csr_we,
    output reg[11:0]  csr_waddr,
    output reg[31:0]  csr_wdata,

    // interface to regfile
    output wire[4:0]  regfile_raddr1,
    input wire[31:0]  regfile_rdata1,
    output wire[4:0]  regfile_raddr2,
    input wire[31:0]  regfile_rdata2,
    output reg        regfile_we,
    output reg[4:0]   regfile_waddr,
    output reg[31:0]  regfile_wdata,
    
    // interface to branch comp
    output reg[31:0]  id_dat_a,
    output reg[31:0]  id_dat_b,

    // interface to alu
    output wire[4:0]  alu_op,
    output wire[31:0] alu_data_a,
    output wire[31:0] alu_data_b,
    input wire[31:0]  alu_data_r,
    input wire[3:0]   alu_flag
);

    // regs between if and id
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_if_id_pc_now;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_if_id_instr;
    /*(* dont_touch = "true" *)*/ reg        reg_if_id_abort;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_if_id_mepc_data;
    /*(* dont_touch = "true" *)*/ reg        reg_if_id_mepc_wr;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_if_id_mcause_data;
    /*(* dont_touch = "true" *)*/ reg        reg_if_id_mcause_wr;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_if_id_mstatus_data;
    /*(* dont_touch = "true" *)*/ reg        reg_if_id_mstatus_wr;
    /*(* dont_touch = "true" *)*/ reg[1:0]   reg_if_id_mode_data;
    /*(* dont_touch = "true" *)*/ reg        reg_if_id_mode_wr;

    // regs between id and exe
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_id_exe_pc_now;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_id_exe_data_a, reg_id_exe_data_b;
    /*(* dont_touch = "true" *)*/ reg[4:0]   reg_id_exe_reg_d;
    /*(* dont_touch = "true" *)*/ reg[11:0]  reg_id_exe_csr;
    /*(* dont_touch = "true" *)*/ reg        reg_id_exe_a_select, reg_id_exe_b_select, reg_id_exe_pc_select;
    /*(* dont_touch = "true" *)*/ reg[4:0]   reg_id_exe_op;
    /*(* dont_touch = "true" *)*/ reg[4:0]   reg_id_exe_alu_op;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_id_exe_imm;
    /*(* dont_touch = "true" *)*/ reg        reg_id_exe_mem_wr;
    /*(* dont_touch = "true" *)*/ reg[1:0]   reg_id_exe_mem_to_reg;
    /*(* dont_touch = "true" *)*/ reg        reg_id_exe_reg_wr;
    /*(* dont_touch = "true" *)*/ reg        reg_id_exe_csr_reg_wr;
    /*(* dont_touch = "true" *)*/ reg        reg_id_exe_abort;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_id_exe_mepc_data;
    /*(* dont_touch = "true" *)*/ reg        reg_id_exe_mepc_wr;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_id_exe_mcause_data;
    /*(* dont_touch = "true" *)*/ reg        reg_id_exe_mcause_wr;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_id_exe_mstatus_data;
    /*(* dont_touch = "true" *)*/ reg        reg_id_exe_mstatus_wr;
    /*(* dont_touch = "true" *)*/ reg[1:0]   reg_id_exe_mode_data;
    /*(* dont_touch = "true" *)*/ reg        reg_id_exe_mode_wr;
    /*(* dont_touch = "true" *)*/ reg        reg_id_exe_tlb_clr;

    // regs between exe and mem
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_exe_mem_pc_now;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_exe_mem_data_r, reg_exe_mem_data_b;
    /*(* dont_touch = "true" *)*/ reg        reg_exe_mem_pc_select;
    /*(* dont_touch = "true" *)*/ reg[4:0]   reg_exe_mem_reg_d;
    /*(* dont_touch = "true" *)*/ reg[11:0]  reg_exe_mem_csr;
    /*(* dont_touch = "true" *)*/ reg[4:0]   reg_exe_mem_op;
    /*(* dont_touch = "true" *)*/ reg        reg_exe_mem_mem_wr;
    /*(* dont_touch = "true" *)*/ reg[1:0]   reg_exe_mem_mem_to_reg;
    /*(* dont_touch = "true" *)*/ reg        reg_exe_mem_reg_wr;
    /*(* dont_touch = "true" *)*/ reg        reg_exe_mem_csr_reg_wr;
    /*(* dont_touch = "true" *)*/ reg        reg_exe_mem_abort;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_exe_mem_mepc_data;
    /*(* dont_touch = "true" *)*/ reg        reg_exe_mem_mepc_wr;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_exe_mem_mcause_data;
    /*(* dont_touch = "true" *)*/ reg        reg_exe_mem_mcause_wr;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_exe_mem_mstatus_data;
    /*(* dont_touch = "true" *)*/ reg        reg_exe_mem_mstatus_wr;
    /*(* dont_touch = "true" *)*/ reg[1:0]   reg_exe_mem_mode_data;
    /*(* dont_touch = "true" *)*/ reg        reg_exe_mem_mode_wr;
    /*(* dont_touch = "true" *)*/ reg        reg_exe_mem_tlb_clr;

    // regs between mem and wb
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_mem_wb_data;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_mem_wb_csr_data;
    /*(* dont_touch = "true" *)*/ reg[4:0]   reg_mem_wb_reg_d;
    /*(* dont_touch = "true" *)*/ reg[11:0]  reg_mem_wb_csr;
    /*(* dont_touch = "true" *)*/ reg[4:0]   reg_mem_wb_op;
    /*(* dont_touch = "true" *)*/ reg        reg_mem_wb_reg_wr;
    /*(* dont_touch = "true" *)*/ reg        reg_mem_wb_csr_reg_wr;
    /*(* dont_touch = "true" *)*/ reg        reg_mem_wb_abort;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_mem_wb_mepc_data;
    /*(* dont_touch = "true" *)*/ reg        reg_mem_wb_mepc_wr;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_mem_wb_mcause_data;
    /*(* dont_touch = "true" *)*/ reg        reg_mem_wb_mcause_wr;
    /*(* dont_touch = "true" *)*/ reg[31:0]  reg_mem_wb_mstatus_data;
    /*(* dont_touch = "true" *)*/ reg        reg_mem_wb_mstatus_wr;
    /*(* dont_touch = "true" *)*/ reg[1:0]   reg_mem_wb_mode_data;
    /*(* dont_touch = "true" *)*/ reg        reg_mem_wb_mode_wr;

    /*(* dont_touch = "true" *)*/ reg[3:0]   stall_structural_hazard, stall_if, stall_id, stall_exe, stall_mem, stall_wb;
    /*(* dont_touch = "true" *)*/ reg[31:0]  pc;
    /*(* dont_touch = "true" *)*/ reg[4:0]   time_counter;
    /*(* dont_touch = "true" *)*/ reg[1:0]   forwarding_select_a, forwarding_select_b;

    assign instr = reg_if_id_instr;
    assign regfile_raddr1 = ins_reg_s;
    assign regfile_raddr2 = ins_reg_t;
    assign csr_raddr = ins_csr;
    //assign br_un = 1'b0;
    assign alu_data_a = (reg_id_exe_a_select ? reg_id_exe_pc_now : reg_id_exe_data_a);
    assign alu_data_b = (reg_id_exe_b_select ? reg_id_exe_data_b : reg_id_exe_imm);
    assign alu_op = reg_id_exe_alu_op;
    assign mem_byte = (stall_mem == 0 && reg_exe_mem_abort == 0 && (reg_exe_mem_op == `OP_LB || reg_exe_mem_op == `OP_LBU || reg_exe_mem_op == `OP_SB));
    assign mem_half = (stall_mem == 0 && reg_exe_mem_abort == 0 && (reg_exe_mem_op == `OP_LH || reg_exe_mem_op == `OP_LHU || reg_exe_mem_op == `OP_SH));
    assign mem_unsigned = (stall_mem == 0 && reg_exe_mem_abort == 0 && (reg_exe_mem_op == `OP_LBU || reg_exe_mem_op == `OP_LHU));
    assign mem_tlb_clr = (stall_mem == 0 && reg_exe_mem_abort == 0 && reg_exe_mem_tlb_clr);
    assign mem_address = (stall_mem == 0 && reg_exe_mem_abort == 0 && (reg_exe_mem_op == `OP_LB || reg_exe_mem_op == `OP_LH || reg_exe_mem_op == `OP_LW || reg_exe_mem_op == `OP_LBU || reg_exe_mem_op == `OP_LHU
        || reg_exe_mem_op == `OP_SB || reg_exe_mem_op == `OP_SH || reg_exe_mem_op == `OP_SW)) ? reg_exe_mem_data_r : pc;
    assign mem_data_in = reg_exe_mem_data_b;


    always @(*) begin
        if (forwarding_select_a == 0) begin
            id_dat_a = regfile_rdata1;
        end
        else if (forwarding_select_a == 1) begin
            id_dat_a = reg_id_exe_mem_to_reg == 2'b01 ? alu_data_r : (reg_id_exe_mem_to_reg == 2'b10 ? reg_id_exe_pc_now + 4 : reg_id_exe_data_b);
        end
        else begin
            id_dat_a = reg_exe_mem_mem_to_reg == 2'b01 ? reg_exe_mem_data_r : (reg_exe_mem_mem_to_reg == 2'b10 ? reg_exe_mem_pc_now + 4 : reg_exe_mem_data_b);
        end

        if (forwarding_select_b == 0) begin
            id_dat_b = ins_b_dat_select == 1'b0 ? regfile_rdata2 : csr_rdata;
        end
        else if (forwarding_select_b == 1) begin
            id_dat_b = ins_b_dat_select == 1'b0 ? (reg_id_exe_mem_to_reg == 2'b01 ? alu_data_r : (reg_id_exe_mem_to_reg == 2'b10 ? reg_id_exe_pc_now + 4 : reg_id_exe_data_b)) : alu_data_r;
        end
        else begin
            id_dat_b = ins_b_dat_select == 1'b0 ? (reg_exe_mem_mem_to_reg == 2'b01 ? reg_exe_mem_data_r : (reg_exe_mem_mem_to_reg == 2'b10 ? reg_exe_mem_pc_now + 4 : reg_exe_mem_data_b)) : reg_exe_mem_data_r;
        end
    end

    reg[31:0] jump_src[0:31], jump_dst[0:31];
    reg reg_if_id_jump, reg_id_exe_jump, reg_exe_mem_jump;
    reg[31:0] valid;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset program counter
            pc <= 32'h80000000;
            // reset memory control signal
            mem_oe <= 1'b0;  mem_we <= 1'b0;
            // reset csr_regfile control signal
            mtvec_we <= 1'b0; mscratch_we <= 1'b0; mepc_we <= 1'b0; mcause_we <= 1'b0; mie_we <= 1'b0; mip_we <= 1'b0; mtval_we <= 1'b0; satp_we <= 1'b0; mode_we <= 1'b0; csr_we <= 1'b0;
            // reset regfile control signal
            regfile_we <= 1'b0;
            // reset stall signal
            stall_structural_hazard <= 0;  stall_if <= 0;  stall_id <= 0;  stall_exe <= 0;  stall_mem <= 0;  stall_wb <= 0;
            // reset time counter
            time_counter <= 0;
            // reset abort signal
            reg_if_id_abort <= 1;  reg_id_exe_abort <= 1;  reg_exe_mem_abort <= 1;  reg_mem_wb_abort <= 1;
            // reset forwarding select
            forwarding_select_a <= 0;  forwarding_select_b <= 0;
            valid <= 32'b0;
        end
        else begin
            // 7 clk posedges for a cycle
            time_counter <= (time_counter >= 2 && mem_done == 1) ? 0 : time_counter + 1;
            // stall signal countdown
            stall_structural_hazard <= (time_counter >= 2 && mem_done == 1) ? (stall_structural_hazard > 0 ? stall_structural_hazard - 1 : 0) : stall_structural_hazard;
            stall_if <= (time_counter >= 2 && mem_done == 1) ? (stall_if > 0 ? stall_if - 1 : 0) : stall_if;
            stall_id <= (time_counter >= 2 && mem_done == 1) ? (stall_id > 0 ? stall_id - 1 : 0) : stall_id;
            stall_exe <= (time_counter >= 2 && mem_done == 1) ? (stall_exe > 0 ? stall_exe - 1 : 0) : stall_exe;
            stall_mem <= (time_counter >= 2 && mem_done == 1) ? (stall_mem > 0 ? stall_mem - 1 : 0) : stall_mem;
            stall_wb <= (time_counter >= 2 && mem_done == 1) ? (stall_wb > 0 ? stall_wb - 1 : 0) : stall_wb;

            if (time_counter == 0) begin
                // interrupt handle, highest priority
                if (timeout && mode == 2'b00) begin //timer interrupt and in user mode
                    // abort this and last instr
                    reg_if_id_abort <= 1;
                    reg_id_exe_abort <= 1;
                    // set pc and csr regs
                    pc <= mtvec[1:0] == 2'b00 ? { mtvec[31:2], 2'b00 } : { mtvec[31:2], 2'b00 } + { { 26{ 1'b0 } }, `M_TIMER_INT, 2'b00 };
                    reg_if_id_mepc_wr <= 1'b0;
                    reg_if_id_mcause_data <= { 1'b1, { 27{ 1'b0 } }, `M_TIMER_INT };
                    reg_if_id_mcause_wr <=  1'b1;
                    reg_if_id_mstatus_data <= { { 19{ 1'b0 } }, 2'b00, { 11{ 1'b0 } } };
                    reg_if_id_mstatus_wr <=  1'b1;
                    reg_if_id_mode_data <= 2'b11; // set machine mode
                    reg_if_id_mode_wr <= 1'b1;
                end
                // control hazard
                else if (stall_mem == 0 && reg_exe_mem_abort == 0 && ((reg_exe_mem_pc_select && reg_exe_mem_jump == 1'b0) ||
                    (reg_exe_mem_jump == 1'b1 && jump_dst[reg_exe_mem_pc_now[6:2]] != ((reg_exe_mem_op == `OP_JAL || reg_exe_mem_op == `OP_JALR) ? (reg_exe_mem_data_r & 32'hfffffffe) : reg_exe_mem_data_r)))) begin
                    /*if (reg_exe_mem_op == `OP_JAL || reg_exe_mem_op == `OP_JALR) begin
                        pc <= reg_exe_mem_data_r & 32'hfffffffe;
                    end
                    else begin
                        pc <= reg_exe_mem_data_r;
                    end*/
                    pc <= (reg_exe_mem_op == `OP_JAL || reg_exe_mem_op == `OP_JALR) ? (reg_exe_mem_data_r & 32'hfffffffe) : reg_exe_mem_data_r;
                    reg_if_id_abort <= 1;
                    reg_id_exe_abort <= 1;
                    reg_if_id_mepc_wr <= 1'b0;
                    reg_if_id_mcause_wr <= 1'b0;
                    reg_if_id_mstatus_wr <= 1'b0;
                    reg_if_id_mode_wr <= 1'b0;
                    valid[reg_exe_mem_pc_now[6:2]] <= 1'b1;
                    jump_src[reg_exe_mem_pc_now[6:2]] <= reg_exe_mem_pc_now;
                    jump_dst[reg_exe_mem_pc_now[6:2]] <= (reg_exe_mem_op == `OP_JAL || reg_exe_mem_op == `OP_JALR) ? (reg_exe_mem_data_r & 32'hfffffffe) : reg_exe_mem_data_r;
                end
                else if (stall_mem == 0 && reg_exe_mem_abort == 0 && !reg_exe_mem_pc_select && reg_exe_mem_jump == 1'b1) begin
                    pc <= reg_exe_mem_pc_now + 4;
                    reg_if_id_abort <= 1;
                    reg_id_exe_abort <= 1;
                    reg_if_id_mepc_wr <= 1'b0;
                    reg_if_id_mcause_wr <= 1'b0;
                    reg_if_id_mstatus_wr <= 1'b0;
                    reg_if_id_mode_wr <= 1'b0;
                    valid[reg_exe_mem_pc_now[6:2]] <= 1'b0;
                end
                // data hazard or interrupt & exception
                else if (stall_id == 0 && reg_if_id_abort == 0) begin
                    // data hazard ( LB & LW )
                    if ((ins_reg_s == reg_id_exe_reg_d || ins_reg_t == reg_id_exe_reg_d) && reg_id_exe_abort == 0 && reg_id_exe_reg_d != 0 && reg_id_exe_reg_wr == 1 && (reg_id_exe_op == `OP_LB || reg_id_exe_op == `OP_LW)) begin
                        stall_if <= 2;
                        stall_id <= 2;
                    end
                    else if ((ins_reg_s == reg_exe_mem_reg_d || ins_reg_t == reg_exe_mem_reg_d) && reg_exe_mem_abort == 0 && reg_exe_mem_reg_d != 0 && reg_exe_mem_reg_wr == 1 && (reg_exe_mem_op == `OP_LB || reg_exe_mem_op == `OP_LW)) begin
                        stall_if <= 1;
                        stall_id <= 1;
                    end
                    // data hazard ( forwarding )
                    else begin
                        if (ins_reg_s == reg_id_exe_reg_d && reg_id_exe_abort == 0 && reg_id_exe_reg_d != 0 && reg_id_exe_reg_wr == 1) begin
                            forwarding_select_a <= 1;
                        end
                        else if (ins_reg_s == reg_exe_mem_reg_d && reg_exe_mem_abort == 0 && reg_exe_mem_reg_d != 0 && reg_exe_mem_reg_wr == 1) begin
                            forwarding_select_a <= 2;
                        end
                        else begin
                            forwarding_select_a <= 0;
                        end

                        if (((ins_reg_t == reg_id_exe_reg_d && reg_id_exe_reg_d != 0 && reg_id_exe_reg_wr == 1) || (ins_csr == reg_id_exe_csr && reg_id_exe_csr_reg_wr == 1)) && reg_id_exe_abort == 0 ) begin
                            forwarding_select_b <= 1;
                        end
                        else if (((ins_reg_t == reg_exe_mem_reg_d && reg_exe_mem_reg_d != 0 && reg_exe_mem_reg_wr == 1) || (ins_csr == reg_exe_mem_csr && reg_exe_mem_csr_reg_wr == 1)) && reg_exe_mem_abort == 0 ) begin
                            forwarding_select_b <= 2;
                        end
                        else begin
                            forwarding_select_b <= 0;
                        end

                        // priority from high to low
                        if (decoder_exception == `ILLEGAL_INSTR_EXC) begin // illegal instruction
                            // stall if for 4 cycles
                            stall_if <= 4;
                            // abort this instr
                            reg_if_id_abort <= 1;
                            // set pc and csr regs 
                            pc <= mtvec[1:0] == 2'b00 ? { mtvec[31:2], 2'b00 } : { mtvec[31:2], 2'b00 } + { { 26{ 1'b0 } }, `ILLEGAL_INSTR_EXC, 2'b00 };
                            reg_if_id_mepc_data <= reg_if_id_pc_now;
                            reg_if_id_mepc_wr <= 1'b1;
                            reg_if_id_mcause_data <= { 1'b0, { 27{ 1'b0 } }, `ILLEGAL_INSTR_EXC };
                            reg_if_id_mcause_wr <=  1'b1;
                            reg_if_id_mstatus_data <= { { 19{ 1'b0 } }, 2'b00, { 11{ 1'b0 } } }; // set user mode as precious mode
                            reg_if_id_mstatus_wr <= 1'b1;
                            reg_if_id_mode_data <= 2'b11; // set machine mode as present mode
                            reg_if_id_mode_wr <= 1'b1;
                        end
                        else begin
                            case(ins_op)
                                `OP_EBREAK: begin // ebreak
                                    // stall if for 4 cycles
                                    stall_if <= 4;
                                    // abort this instr
                                    reg_if_id_abort <= 1;
                                    // set pc and csr regs 
                                    pc <= mtvec[1:0] == 2'b00 ? { mtvec[31:2], 2'b00 } : { mtvec[31:2], 2'b00 } + { { 26{ 1'b0 } }, `BREAKPOINT_EXC, 2'b00 };
                                    reg_if_id_mepc_data <= reg_if_id_pc_now;
                                    reg_if_id_mepc_wr <= 1'b1;
                                    reg_if_id_mcause_data <= { 1'b0, { 27{ 1'b0 } }, `BREAKPOINT_EXC };
                                    reg_if_id_mcause_wr <=  1'b1;
                                    reg_if_id_mstatus_data <= { { 19{ 1'b0 } }, 2'b00, { 11{ 1'b0 } } }; // set user mode as precious mode
                                    reg_if_id_mstatus_wr <= 1'b1;
                                    reg_if_id_mode_data <= 2'b11; // set machine mode as present mode
                                    reg_if_id_mode_wr <= 1'b1;
                                end
                                `OP_ECALL: begin // ecall
                                    // stall if for 4 cycles
                                    stall_if <= 4;
                                    // abort this instr
                                    reg_if_id_abort <= 1;
                                    // set pc and csr regs 
                                    pc <= mtvec[1:0] == 2'b00 ? { mtvec[31:2], 2'b00 } : { mtvec[31:2], 2'b00 } + (mode == 2'b00 ? { { 26{ 1'b0 } }, `ECALL_U_EXC, 2'b00 } : { { 26{ 1'b0 } }, `ECALL_M_EXC, 2'b00 });
                                    reg_if_id_mepc_data <= reg_if_id_pc_now;
                                    reg_if_id_mepc_wr <= 1'b1;
                                    reg_if_id_mcause_data <= mode == 2'b00 ? { 1'b0, { 27{ 1'b0 } }, `ECALL_U_EXC } : { 1'b0, { 27{ 1'b0 } }, `ECALL_M_EXC };
                                    reg_if_id_mcause_wr <=  1'b1;
                                    reg_if_id_mstatus_data <= { { 19{ 1'b0 } }, 2'b00, { 11{ 1'b0 } } }; // set user mode as precious mode
                                    reg_if_id_mstatus_wr <= 1'b1;
                                    reg_if_id_mode_data <= 2'b11; // set machine mode as present mode
                                    reg_if_id_mode_wr <= 1'b1;
                                end
                                `OP_MRET: begin // mret
                                    // stall if for 4 cycles
                                    stall_if <= 4;
                                    // abort this instr
                                    reg_if_id_abort <= 1;
                                    // set pc and csr regs 
                                    pc <= mepc;
                                    reg_if_id_mepc_wr <= 1'b0;
                                    reg_if_id_mcause_wr <=  1'b0;
                                    reg_if_id_mstatus_data <= { { 19{ 1'b0 } }, 2'b11, { 11{ 1'b0 } } }; // set machine mode as precious mode
                                    reg_if_id_mstatus_wr <= 1'b1;
                                    reg_if_id_mode_data <= 2'b00; // set user mode as present mode
                                    reg_if_id_mode_wr <= 1'b1;
                                end
                                default: begin // no exception / interrupt in id
                                    reg_if_id_mepc_wr <= 1'b0;
                                    reg_if_id_mcause_wr <=  1'b0;
                                    reg_if_id_mstatus_wr <= 1'b0;
                                    reg_if_id_mode_wr <= 1'b0;
                                end
                            endcase
                        end
                    end
                end

                // structural hazard
                if (stall_mem == 0 && reg_exe_mem_abort == 0 && (reg_exe_mem_op == `OP_LB || reg_exe_mem_op == `OP_LH || reg_exe_mem_op == `OP_LW || reg_exe_mem_op == `OP_LBU || reg_exe_mem_op == `OP_LHU
                    || reg_exe_mem_op == `OP_SB || reg_exe_mem_op == `OP_SH || reg_exe_mem_op == `OP_SW)) begin
                    stall_structural_hazard <= 1;
                    mem_oe <= reg_exe_mem_mem_wr ^ 1'b1;
                    mem_we <= reg_exe_mem_mem_wr;
                end
                else begin
                    mem_oe <= 1'b1;
                    mem_we <= 1'b0;
                end
            end
            else if (time_counter == 1) begin
                mem_oe <= 1'b0;
                mem_we <= 1'b0;
                forwarding_select_a <= 0;
                forwarding_select_b <= 0;
            end
            // reset forwarding signal
            /*else if (time_counter >= 2 && mem_done == 1) begin
                forwarding_select_a <= 0;
                forwarding_select_b <= 0;
            end*/

            // stage if
            if (stall_structural_hazard == 0 && stall_if == 0 && time_counter >= 2 && mem_done == 1) begin
                // fetch instructions from memory
                if (valid[pc[6:2]] == 1 && jump_src[pc[6:2]] == pc) begin
                    pc <= jump_dst[pc[6:2]];
                    reg_if_id_jump <= 1'b1;
                end
                else begin
                    pc <= pc + 4;
                    reg_if_id_jump <= 1'b0;
                end
                reg_if_id_pc_now <= pc;
                reg_if_id_instr <= mem_data_out;
                reg_if_id_abort <= 0;
            end
            // bubble insertion
            else if (time_counter >= 2 && mem_done == 1 && stall_id == 0) begin
                reg_if_id_abort <= 1;
            end

            // stage id
            if (stall_id == 0 && time_counter >= 2 && mem_done == 1) begin
                reg_id_exe_pc_now <= reg_if_id_pc_now;
                reg_id_exe_data_a <= id_dat_a;
                reg_id_exe_data_b <= id_dat_b;
                reg_id_exe_reg_d <= ins_reg_d;
                reg_id_exe_csr <= ins_csr;
                reg_id_exe_a_select <= ins_a_select;
                reg_id_exe_b_select <= ins_b_select;
                reg_id_exe_pc_select <= ins_pc_select;
                reg_id_exe_op <= ins_op;
                reg_id_exe_alu_op <= ins_alu_op;
                reg_id_exe_imm <= ins_imm;
                reg_id_exe_mem_wr <= ins_mem_wr;
                reg_id_exe_mem_to_reg <= ins_mem_to_reg;
                reg_id_exe_reg_wr <= ins_reg_wr;
                reg_id_exe_csr_reg_wr <= ins_csr_reg_wr;
                reg_id_exe_abort <= reg_if_id_abort;
                reg_id_exe_mepc_data <= reg_if_id_mepc_data;
                reg_id_exe_mepc_wr <= reg_if_id_mepc_wr;
                reg_id_exe_mcause_data <= reg_if_id_mcause_data;
                reg_id_exe_mcause_wr <=  reg_if_id_mcause_wr;
                reg_id_exe_mstatus_data <= reg_if_id_mstatus_data;
                reg_id_exe_mstatus_wr <=  reg_if_id_mstatus_wr;               
                reg_id_exe_mode_data <= reg_if_id_mode_data;
                reg_id_exe_mode_wr <= reg_if_id_mode_wr;
                reg_id_exe_tlb_clr <= ins_tlb_clr;
                reg_id_exe_jump <= reg_if_id_jump;
            end
            // bubble insertion
            else if (time_counter >= 2 && mem_done == 1 && stall_exe == 0) begin
                reg_id_exe_abort <= 1;
            end

            // stage exe
            if (stall_exe == 0 && time_counter >= 2 && mem_done == 1) begin
                reg_exe_mem_pc_now <= reg_id_exe_pc_now;
                reg_exe_mem_data_r <= alu_data_r;
                reg_exe_mem_data_b <= reg_id_exe_data_b;
                reg_exe_mem_reg_d <= reg_id_exe_reg_d;
                reg_exe_mem_csr <= reg_id_exe_csr;
                reg_exe_mem_op <= reg_id_exe_op;
                reg_exe_mem_pc_select <= reg_id_exe_pc_select;
                reg_exe_mem_mem_wr <= reg_id_exe_mem_wr;
                reg_exe_mem_mem_to_reg <= reg_id_exe_mem_to_reg;
                reg_exe_mem_reg_wr <= reg_id_exe_reg_wr;
                reg_exe_mem_csr_reg_wr <= reg_id_exe_csr_reg_wr;
                reg_exe_mem_abort <= reg_id_exe_abort;
                reg_exe_mem_mepc_data <= reg_id_exe_mepc_data;
                reg_exe_mem_mepc_wr <= reg_id_exe_mepc_wr;
                reg_exe_mem_mcause_data <= reg_id_exe_mcause_data;
                reg_exe_mem_mcause_wr <= reg_id_exe_mcause_wr;
                reg_exe_mem_mstatus_data <= reg_id_exe_mstatus_data;
                reg_exe_mem_mstatus_wr <= reg_id_exe_mstatus_wr;
                reg_exe_mem_mode_data <= reg_id_exe_mode_data;
                reg_exe_mem_mode_wr <= reg_id_exe_mode_wr;
                reg_exe_mem_tlb_clr <= reg_id_exe_tlb_clr;
                reg_exe_mem_jump <= reg_id_exe_jump;
            end
            // bubble insertion
            else if (time_counter >= 2 && mem_done == 1 && stall_mem == 0) begin
                reg_exe_mem_abort <= 1;
            end

            // stage mem
            if (stall_mem == 0 && time_counter >= 2 && mem_done == 1) begin
                reg_mem_wb_data <= reg_exe_mem_mem_to_reg == 2'b00 ? mem_data_out : (reg_exe_mem_mem_to_reg == 2'b01 ? reg_exe_mem_data_r : (reg_exe_mem_mem_to_reg == 2'b10 ? reg_exe_mem_pc_now + 4 : reg_exe_mem_data_b));
                reg_mem_wb_csr_data <= reg_exe_mem_data_r;
                reg_mem_wb_reg_d <= reg_exe_mem_reg_d;
                reg_mem_wb_csr <= reg_exe_mem_csr;
                reg_mem_wb_op <= reg_exe_mem_op;
                reg_mem_wb_reg_wr <= reg_exe_mem_reg_wr;
                reg_mem_wb_csr_reg_wr <= reg_exe_mem_csr_reg_wr;
                reg_mem_wb_abort <= reg_exe_mem_abort;
                reg_mem_wb_mepc_data <= reg_exe_mem_mepc_data;
                reg_mem_wb_mepc_wr <= reg_exe_mem_mepc_wr;
                reg_mem_wb_mcause_data <= reg_exe_mem_mcause_data;
                reg_mem_wb_mcause_wr <= reg_exe_mem_mcause_wr;
                reg_mem_wb_mstatus_data <= reg_exe_mem_mstatus_data;
                reg_mem_wb_mstatus_wr <= reg_exe_mem_mstatus_wr;
                reg_mem_wb_mode_data <= reg_exe_mem_mode_data;
                reg_mem_wb_mode_wr <= reg_exe_mem_mode_wr;
            end
            // bubble insertion
            else if (time_counter >= 2 && mem_done == 1 && stall_wb == 0) begin
                reg_mem_wb_abort <= 1;
            end

            // stage wb
            if (stall_wb == 0 && reg_mem_wb_abort == 0) begin
                if (time_counter == 0 && reg_mem_wb_reg_wr) begin
                    regfile_we <= 1'b1;
                    regfile_waddr <= reg_mem_wb_reg_d;
                    regfile_wdata <= reg_mem_wb_data;
                end
                if (time_counter == 0 && reg_mem_wb_csr_reg_wr) begin
                    csr_we <= 1'b1;
                    csr_waddr <= reg_mem_wb_csr;
                    csr_wdata <= reg_mem_wb_csr_data;
                end
                if (time_counter == 1) begin
                    regfile_we <= 1'b0;
                    csr_we <= 1'b0;
                end
            end
            else if (stall_wb == 0) begin
                if (time_counter == 0 && reg_mem_wb_mepc_wr) begin
                    mepc_we <= 1'b1;
                    mepc_wdata <= reg_mem_wb_mepc_data;
                end
                if (time_counter == 0 && reg_mem_wb_mcause_wr) begin
                    mcause_we <= 1'b1;
                    mcause_wdata <= reg_mem_wb_mcause_data;
                end
                if (time_counter == 0 && reg_mem_wb_mstatus_wr) begin
                    mstatus_we <= 1'b1;
                    mstatus_wdata <= reg_mem_wb_mstatus_data;
                end
                if (time_counter == 0 && reg_mem_wb_mode_wr) begin
                    mode_we <= 1'b1;
                    mode_wdata <= reg_mem_wb_mode_data;
                end
                if (time_counter == 1) begin
                    mepc_we <= 1'b0;
                    mcause_we <= 1'b0;
                    mstatus_we <= 1'b0;
                end
            end
        end
    end

endmodule
