`default_nettype none
`timescale 1ns / 1ps
`include "ops.vh"

module pipeline(
    // clock and reset
    input wire        clk,
    input wire        rst,

    // interface to sram and uart
    output reg        mem_be,
    output reg        mem_oe,
    output reg        mem_we,
    output reg[31:0]  mem_address,
    output reg[31:0]  mem_data_in,
    input wire[31:0]  mem_data_out,

    // interface to decoder
    output wire[31:0] instr,
    input wire[4:0]   ins_reg_s,
    input wire[4:0]   ins_reg_t,
    input wire[4:0]   ins_reg_d,
    input wire[11:0]  csr,
    input wire        ins_a_select,
    input wire        ins_b_select,
    input wire        ins_pc_select,
    input wire[4:0]   ins_op,
    input wire[4:0]   ins_alu_op,
    input wire[31:0]  ins_imm,
    input wire        ins_mem_wr,
    input wire[1:0]   ins_mem_to_reg,
    input wire        ins_reg_wr,
    input wire        ins_csr_reg_wr,
    input wire[3:0]   decoder_exception,

    // interface to csr_regfile
    input wire[31:0]  mtvec,
    input wire[31:0]  mscratch,
    input wire[31:0]  mepc,
    input wire[31:0]  mcause,
    input wire[31:0]  mstatus,
    input wire[31:0]  mie,
    input wire[31:0]  mip,
    input wire[31:0]  mtval,
    output reg        mtvec_we,
    output reg        mscratch_we,
    output reg        mepc_we,
    output reg        mcause_we,
    output reg        mstatus_we,
    output reg        mie_we,
    output reg        mip_we,
    output reg        mtval_we,
    output reg[31:0]  mtvec_wdata,
    output reg[31:0]  mscratch_wdata,
    output reg[31:0]  mepc_wdata,
    output reg[31:0]  mcause_wdata,
    output reg[31:0]  mstatus_wdata,
    output reg[31:0]  mie_wdata,
    output reg[31:0]  mip_wdata,
    output reg[31:0]  mtval_wdata,
    output reg        csr_we,
    output reg[11:0]  csr_waddr,
    output reg[31:0]  csr_wdata,

    // interface to mmio_regfile
    input wire[31:0]  mtime_lo,
    input wire[31:0]  mtime_hi,
    input wire[31:0]  mtimecmp_lo,
    input wire[31:0]  mtimecmp_hi,
    output reg[1:0]   mtime_we,
    output reg[1:0]   mtimecmp_we,
    output reg[31:0]  mtime_wdata,
    output reg[31:0]  mtimecmp_wdata,

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
    output wire       br_un,
    input wire        br_eq,
    input wire        br_lt,

    // interface to alu
    output wire[4:0]  alu_op,
    output wire[31:0] alu_data_a,
    output wire[31:0] alu_data_b,
    input wire[31:0]  alu_data_r,
    input wire[3:0]   alu_flag,

    // debug mode signals
    output reg[31:0]  reg_if_id_pc_now,
    output reg[31:0]  reg_if_id_instr,
    output reg        reg_if_id_abort,

    output reg[31:0]  reg_id_exe_pc_now,
    output reg[31:0]  reg_id_exe_data_a,
    output reg[31:0]  reg_id_exe_data_b,
    output reg[4:0]   reg_id_exe_reg_d,
    output reg[11:0]  reg_id_exe_csr,
    output reg        reg_id_exe_a_select,
    output reg        reg_id_exe_b_select,
    output reg        reg_id_exe_pc_select,
    output reg[4:0]   reg_id_exe_op,
    output reg[4:0]   reg_id_exe_alu_op,
    output reg[31:0]  reg_id_exe_imm,
    output reg        reg_id_exe_mem_wr,
    output reg[1:0]   reg_id_exe_mem_to_reg,
    output reg        reg_id_exe_reg_wr,
    output reg        reg_id_exe_csr_reg_wr,
    output reg        reg_id_exe_abort,

    output reg[31:0]  reg_exe_mem_pc_now,
    output reg[31:0]  reg_exe_mem_data_r,
    output reg[31:0]  reg_exe_mem_data_b,
    output reg        reg_exe_mem_pc_select,
    output reg[4:0]   reg_exe_mem_reg_d,
    output reg[11:0]  reg_exe_mem_csr,
    output reg[4:0]   reg_exe_mem_op,
    output reg        reg_exe_mem_mem_wr,
    output reg[1:0]   reg_exe_mem_mem_to_reg,
    output reg        reg_exe_mem_reg_wr,
    output reg        reg_exe_mem_csr_reg_wr,
    output reg        reg_exe_mem_abort,

    output reg[31:0]  reg_mem_wb_data,
    output reg[31:0]  reg_mem_wb_csr_data,
    output reg[31:0]  reg_mem_wb_mtime_data,
    output reg[31:0]  reg_mem_wb_mtimecmp_data,
    output reg[4:0]   reg_mem_wb_reg_d,
    output reg[11:0]  reg_mem_wb_csr,
    output reg[4:0]   reg_mem_wb_op,
    output reg        reg_mem_wb_reg_wr,
    output reg        reg_mem_wb_csr_reg_wr,
    output reg[1:0]   reg_mem_wb_mtime_reg_wr,
    output reg[1:0]   reg_mem_wb_mtimecmp_reg_wr,
    output reg        reg_mem_wb_abort,

    output reg[3:0]   stall_if,
    output reg[3:0]   stall_id,
    output reg[3:0]   stall_exe,
    output reg[3:0]   stall_mem,
    output reg[3:0]   stall_wb,
    output reg[31:0]  pc,
    output reg[2:0]   time_counter,
    output reg[1:0]   forwarding_select_a,
    output reg[1:0]   forwarding_select_b
);

    /* release mode signals
    // regs between if and id
    reg[31:0]         reg_if_id_pc_now;
    reg[31:0]         reg_if_id_instr;
    reg               reg_if_id_abort;

    // regs between id and exe
    reg[31:0]         reg_id_exe_pc_now;
    reg[31:0]         reg_id_exe_data_a, reg_id_exe_data_b;
    reg[4:0]          reg_id_exe_reg_d;
    reg               reg_id_exe_a_select, reg_id_exe_b_select, reg_id_exe_pc_select;
    reg[4:0]          reg_id_exe_op;
    reg[4:0]          reg_id_exe_alu_op;
    reg[31:0]         reg_id_exe_imm;
    reg               reg_id_exe_mem_wr;
    reg[1:0]          reg_id_exe_mem_to_reg;
    reg               reg_id_exe_reg_wr;
    reg               reg_id_exe_abort;

    // regs between exe and mem
    reg[31:0]         reg_exe_mem_pc_now;
    reg[31:0]         reg_exe_mem_data_r, reg_exe_mem_data_b;
    reg               reg_exe_mem_pc_select;
    reg[4:0]          reg_exe_mem_reg_d;
    reg[4:0]          reg_exe_mem_op;
    reg               reg_exe_mem_mem_wr;
    reg[1:0]          reg_exe_mem_mem_to_reg;
    reg               reg_exe_mem_reg_wr;
    reg               reg_exe_mem_abort;

    // regs between mem and wb
    reg[31:0]         reg_mem_wb_data;
    reg[4:0]          reg_mem_wb_reg_d;
    reg[4:0]          reg_mem_wb_op;
    reg               reg_mem_wb_reg_wr;
    reg               reg_mem_wb_abort;

    reg[3:0]          stall_if, stall_id, stall_exe, stall_mem, stall_wb;
    reg[31:0]         pc;
    reg[2:0]          time_counter;
    reg[1:0]          forwarding_select_a, forwarding_select_b;*/

    assign instr = reg_if_id_instr;
    assign regfile_raddr1 = ins_reg_s;
    assign regfile_raddr2 = ins_reg_t;
    assign br_un = 1'b0;
    assign alu_data_a = (reg_id_exe_a_select ? reg_id_exe_pc_now : reg_id_exe_data_a);
    assign alu_data_b = (reg_id_exe_b_select ? reg_id_exe_data_b : reg_id_exe_imm);
    assign alu_op = reg_id_exe_alu_op;

    always @(*) begin
        if (forwarding_select_a == 0) begin
            id_dat_a = regfile_rdata1;
        end
        else if (forwarding_select_a == 1) begin
            id_dat_a = reg_id_exe_mem_to_reg == 2'b01 ? alu_data_r : (reg_exe_mem_mem_to_reg == 2'b10 ? reg_id_exe_pc_now + 4 : reg_id_exe_data_b);
        end
        else begin
            id_dat_a = reg_exe_mem_mem_to_reg == 2'b01 ? reg_exe_mem_data_r : (reg_exe_mem_mem_to_reg == 2'b10 ? reg_exe_mem_pc_now + 4 : reg_exe_mem_data_b);
        end

        if (forwarding_select_b == 0) begin
            id_dat_b = regfile_rdata2;
        end
        else if (forwarding_select_b == 1) begin
            id_dat_b = reg_id_exe_mem_to_reg == 2'b01 ? alu_data_r : (reg_exe_mem_mem_to_reg == 2'b10 ? reg_id_exe_pc_now + 4 : reg_id_exe_data_b);
        end
        else begin
            id_dat_b = reg_exe_mem_mem_to_reg == 2'b01 ? reg_exe_mem_data_r : (reg_exe_mem_mem_to_reg == 2'b10 ? reg_exe_mem_pc_now + 4 : reg_exe_mem_data_b);
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset program counter
            pc <= 32'h80000000;
            // reset memory control signal
            mem_be <= 0;  mem_oe <= 0;  mem_we <= 0;
            // reset csr_regfile control signal
            mtvec_we <= 0; mscratch_we <= 0; mepc_we <= 0; mcause_we <= 0; mstatus_we <=0; mie_we <= 0; mip_we <= 0; mtval_we <=0;
            // reset mmio_regfile control signal
            mtime_we <= 0; mtimecmp_we <= 0;
            // reset regfile control signal
            regfile_we <= 0;
            // reset stall signal
            stall_if <= 0;  stall_id <= 0;  stall_exe <= 0;  stall_mem <= 0;  stall_wb <= 0;
            // reset time counter
            time_counter <= 0;
            // reset abort signal
            reg_if_id_abort <= 1;  reg_id_exe_abort <= 1;  reg_exe_mem_abort <= 1;  reg_mem_wb_abort <= 1;
            // reset forwarding select
            forwarding_select_a <= 0;  forwarding_select_b <= 0;
        end
        else begin
            // 7 clk posedges for a cycle
            time_counter <= time_counter == 6 ? 0 : time_counter + 1;
            // stall signal countdown
            stall_if <= time_counter == 6 ? (stall_if > 0 ? stall_if - 1 : 0) : stall_if;
            stall_id <= time_counter == 6 ? (stall_id > 0 ? stall_id - 1 : 0) : stall_id;
            stall_exe <= time_counter == 6 ? (stall_exe > 0 ? stall_exe - 1 : 0) : stall_exe;
            stall_mem <= time_counter == 6 ? (stall_mem > 0 ? stall_mem - 1 : 0) : stall_mem;
            stall_wb <= time_counter == 6 ? (stall_wb > 0 ? stall_wb - 1 : 0) : stall_wb;

            if (time_counter == 0) begin
                // control hazard
                if (stall_mem == 0 && reg_exe_mem_abort == 0 && reg_exe_mem_pc_select) begin
                    if (reg_exe_mem_op == `OP_JAL || reg_exe_mem_op == `OP_JALR) begin
                        pc <= reg_exe_mem_data_r & 32'hfffffffe;
                    end
                    else begin
                        pc <= reg_exe_mem_data_r;
                    end
                    reg_if_id_abort <= 1;
                    reg_id_exe_abort <= 1;
                    if (reg_exe_mem_op == `OP_LB || reg_exe_mem_op == `OP_LW || reg_exe_mem_op == `OP_SB || reg_exe_mem_op == `OP_SW) begin
                        stall_if <= 1;
                    end
                    else begin
                    end
                end
                else begin
                    if (stall_id == 0 && reg_if_id_abort == 0) begin
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

                            if (ins_reg_t == reg_id_exe_reg_d && reg_id_exe_abort == 0 && reg_id_exe_reg_d != 0 && reg_id_exe_reg_wr == 1) begin
                                forwarding_select_b <= 1;
                            end
                            else if (ins_reg_t == reg_exe_mem_reg_d && reg_exe_mem_abort == 0 && reg_exe_mem_reg_d != 0 && reg_exe_mem_reg_wr == 1) begin
                                forwarding_select_b <= 2;
                            end
                            else begin
                                forwarding_select_b <= 0;
                            end
                            // structural hazard
                            if (stall_mem == 0 && reg_exe_mem_abort == 0 && (reg_exe_mem_op == `OP_LB || reg_exe_mem_op == `OP_LW || reg_exe_mem_op == `OP_SB || reg_exe_mem_op == `OP_SW)) begin
                                stall_if <= 1;
                            end
                            else begin
                            end
                        end
                    end
                    // structural hazard
                    else if (stall_mem == 0 && reg_exe_mem_abort == 0 && (reg_exe_mem_op == `OP_LB || reg_exe_mem_op == `OP_LW || reg_exe_mem_op == `OP_SB || reg_exe_mem_op == `OP_SW)) begin
                        stall_if <= 1;
                    end
                    else begin
                    end
                end
            end
            // reset forwarding signal
            else if (time_counter == 6) begin
                forwarding_select_a <= 0;
                forwarding_select_b <= 0;
            end
            else begin
            end

            // stage if
            if (stall_if == 0) begin
                // fetch instructions from memory
                case(time_counter)
                    1: begin
                        mem_be <= 0;
                        mem_oe <= 1;
                        mem_address <= pc;
                    end
                    2: begin 
                        mem_oe <= 0;
                    end
                    6: begin
                        // update program counter
                        pc <= pc + 4;
                        reg_if_id_pc_now <= pc;
                        reg_if_id_instr <= mem_data_out;
                        reg_if_id_abort <= 0;
                    end
                    default: begin
                    end
                endcase
            end
            else begin
                // bubble insertion
                if (time_counter == 6 && stall_id == 0) begin
                    reg_if_id_abort <= 1;
                end
                else begin
                end
            end

            // stage id
            if (stall_id == 0) begin
                case (time_counter)
                    1: begin
                        // priority from high to low
                        if (ins_op == `OP_MRET && mstatus[12:11] != 2'b11) begin // permission denied
                            // suspend the pipeline
                            stall_if <= 2;
                            stall_id <= 2;
                            // set pc and csr regs 
                            pc <= mtvec[1:0] == 2'b00 ? { mtvec[31:2], 2'b00 } : { mtvec[31:2], 2'b00 } + { mcause[29:0], 2'b00 };
                            mepc_wdata <= reg_if_id_pc_now + 4;
                            mepc_we <= 1'b1;
                            mcause_wdata <= { 1'b0, { 27{ 1'b0 } }, `INSTR_ACCESS_FAULT_EXC };
                            mcause_we <= 1'b1;
                            mstatus_wdata <= { { 19{ 1'b0 } }, 2'b11, { 11{ 1'b0 } } };
                            mstatus_we <= 1'b1;
                        end
                        else if (decoder_exception == `ILLEGAL_INSTR_EXC) begin 
                            // suspend the pipeline
                            stall_if <= 2;
                            stall_id <= 2;
                            // set pc and csr regs 
                            pc <= mtvec[1:0] == 2'b00 ? { mtvec[31:2], 2'b00 } : { mtvec[31:2], 2'b00 } + { mcause[29:0], 2'b00 };
                            mepc_wdata <= reg_if_id_pc_now + 4;
                            mepc_we <= 1'b1;
                            mcause_wdata <= { 1'b0, { 27{ 1'b0 } }, `ILLEGAL_INSTR_EXC };
                            mcause_we <= 1'b1;
                            mstatus_wdata <= { { 19{ 1'b0 } }, 2'b11, { 11{ 1'b0 } } };
                            mstatus_we <= 1'b1;
                        end
                        else if (ins_op == `OP_EBREAK) begin
                            // suspend the pipeline
                            stall_if <= 2;
                            stall_id <= 2;
                            // set pc and csr regs 
                            pc <= mtvec[1:0] == 2'b00 ? { mtvec[31:2], 2'b00 } : { mtvec[31:2], 2'b00 } + { mcause[29:0], 2'b00 };
                            mepc_wdata <= reg_if_id_pc_now + 4;
                            mepc_we <= 1'b1;
                            mcause_wdata <= { 1'b0, { 27{ 1'b0 } }, `BREAKPOINT_EXC };
                            mcause_we <= 1'b1;
                            mstatus_wdata <= { { 19{ 1'b0 } }, 2'b11, { 11{ 1'b0 } } };
                            mstatus_we <= 1'b1;
                        end
                        else if (ins_op == `OP_ECALL) begin
                            // suspend the pipeline
                            stall_if <= 2;
                            stall_id <= 2;
                            // set pc and csr regs 
                            pc <= mtvec[1:0] == 2'b00 ? { mtvec[31:2], 2'b00 } : { mtvec[31:2], 2'b00 } + { mcause[29:0], 2'b00 };
                            mepc_wdata <= reg_if_id_pc_now + 4;
                            mepc_we <= 1'b1;
                            mcause_wdata <= mstatus[12:11] == 2'b00 ? { 1'b0, { 27{ 1'b0 } }, `ECALL_U_EXC } : { 1'b0, { 27{ 1'b0 } }, `ECALL_M_EXC };
                            mcause_we <= 1'b1;
                            mstatus_wdata <= { { 19{ 1'b0 } }, 2'b11, { 11{ 1'b0 } } };
                            mstatus_we <= 1'b1;
                        end
                        else if (ins_op == `OP_MRET) begin
                            // suspend the pipeline
                            stall_if <= 2;
                            stall_id <= 2;
                            // set pc and csr regs 
                            pc <= mepc;
                            mstatus_wdata <= { { 19{ 1'b0 } }, 2'b00, { 11{ 1'b0 } } };
                            mstatus_we <= 1'b1;
                        end
                    end
                    2: begin
                        mepc_we <= 1'b0;
                        mcause_we <= 1'b0;
                        mstatus_we <= 1'b0;
                    end
                    6: begin
                        reg_id_exe_pc_now <= reg_if_id_pc_now;
                        reg_id_exe_data_a <= id_dat_a;
                        reg_id_exe_data_b <= id_dat_b;
                        reg_id_exe_reg_d <= ins_reg_d;
                        reg_id_exe_csr <= csr;
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
                    end
                    default: begin
                    end
                endcase
            end
            else begin
                // bubble insertion
                if (time_counter == 6 && stall_exe == 0) begin
                    reg_id_exe_abort <= 1;
                end
                else begin
                end
            end

            // stage exe
            if (stall_exe == 0) begin
                if (time_counter == 6) begin
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
                end
                else begin
                end
            end
            else begin
                // bubble insertion
                if (time_counter == 6 && stall_mem == 0) begin
                    reg_exe_mem_abort <= 1;
                end
                else begin
                end
            end

            // stage mem
            if (stall_mem == 0) begin
                if (reg_exe_mem_abort == 0) begin
                    // fetch data from memory
                    case(time_counter)
                        1: begin
                            if (reg_exe_mem_op == `OP_LB || reg_exe_mem_op == `OP_LW || reg_exe_mem_op == `OP_SB || reg_exe_mem_op == `OP_SW) begin
                                case (reg_exe_mem_data_r)
                                    //TODO: modify mem_to_reg and data_r here, may have bugs
                                    //TODO: only consider LW and SW to mtime and mtimecmp 
                                    `MTIME_LO_ADDR: begin
                                        case (reg_exe_mem_op)
                                            `OP_LW: begin
                                                reg_exe_mem_mem_to_reg <= 2'b01;
                                                reg_exe_mem_data_r <= mtime_lo;
                                                reg_mem_wb_mtime_reg_wr <= 2'b00;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                            end
                                            `OP_SW: begin
                                                reg_mem_wb_mtime_reg_wr <= 2'b01;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                                reg_mem_wb_mtime_data <= reg_exe_mem_data_r;
                                            end
                                            default: begin
                                                reg_mem_wb_mtime_reg_wr <= 2'b00;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                            end
                                        endcase
                                    end
                                    `MTIME_HI_ADDR: begin
                                        case (reg_exe_mem_op)
                                            `OP_LW: begin
                                                reg_exe_mem_mem_to_reg <= 2'b01;
                                                reg_exe_mem_data_r <= mtime_hi;
                                                reg_mem_wb_mtime_reg_wr <= 2'b00;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                            end
                                            `OP_SW: begin
                                                reg_mem_wb_mtime_reg_wr <= 2'b10;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                                reg_mem_wb_mtime_data <= reg_exe_mem_data_r;
                                            end
                                            default: begin
                                                reg_mem_wb_mtime_reg_wr <= 2'b00;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                            end
                                        endcase
                                    end
                                    `MTIMECMP_LO_ADDR: begin
                                        case (reg_exe_mem_op)
                                            `OP_LW: begin
                                                reg_exe_mem_mem_to_reg <= 2'b01;
                                                reg_exe_mem_data_r <= mtimecmp_lo;
                                                reg_mem_wb_mtime_reg_wr <= 2'b00;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                            end
                                            `OP_SW: begin
                                                reg_mem_wb_mtime_reg_wr <= 2'b00;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b01;
                                                reg_mem_wb_mtimecmp_data <= reg_exe_mem_data_r;
                                            end
                                            default: begin
                                                reg_mem_wb_mtime_reg_wr <= 2'b00;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                            end
                                        endcase
                                    end
                                    `MTIMECMP_HI_ADDR: begin
                                        case (reg_exe_mem_op)
                                            `OP_LW: begin
                                                reg_exe_mem_mem_to_reg <= 2'b01;
                                                reg_exe_mem_data_r <= mtimecmp_hi;
                                                reg_mem_wb_mtime_reg_wr <= 2'b00;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                            end
                                            `OP_SW: begin
                                                reg_mem_wb_mtime_reg_wr <= 2'b00;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b10;
                                                reg_mem_wb_mtimecmp_data <= reg_exe_mem_data_r;
                                            end
                                            default: begin
                                                reg_mem_wb_mtime_reg_wr <= 2'b00;
                                                reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                            end
                                        endcase
                                    end
                                    default: begin
                                        mem_be <= ((reg_exe_mem_op == `OP_LB || reg_exe_mem_op == `OP_SB) ? 1 : 0);
                                        mem_oe <= reg_exe_mem_mem_wr ^ 1'b1;
                                        mem_we <= reg_exe_mem_mem_wr;
                                        mem_address <= reg_exe_mem_data_r;
                                        mem_data_in <= reg_exe_mem_data_b;
                                        reg_mem_wb_mtime_reg_wr <= 2'b00;
                                        reg_mem_wb_mtimecmp_reg_wr <= 2'b00;
                                    end
                                endcase
                                
                            end
                            else begin
                            end
                        end
                        2: begin 
                            mem_oe <= 0;
                            mem_we <= 0;
                        end
                        default: begin
                        end
                    endcase
                end
                else begin
                end

                if (time_counter == 6) begin
                    reg_mem_wb_data <= reg_exe_mem_mem_to_reg == 2'b00 ? mem_data_out : (reg_exe_mem_mem_to_reg == 2'b01 ? reg_exe_mem_data_r : (reg_exe_mem_mem_to_reg == 2'b10 ? reg_exe_mem_pc_now + 4 : reg_exe_mem_data_b));
                    reg_mem_wb_csr_data <= reg_exe_mem_data_r;
                    reg_mem_wb_reg_d <= reg_exe_mem_reg_d;
                    reg_mem_wb_csr <= reg_exe_mem_csr;
                    reg_mem_wb_op <= reg_exe_mem_op;
                    reg_mem_wb_reg_wr <= reg_exe_mem_reg_wr;
                    reg_mem_wb_csr_reg_wr <= reg_exe_mem_csr_reg_wr;
                    reg_mem_wb_abort <= reg_exe_mem_abort;
                end
                else begin
                end
            end
            else begin
                // bubble insertion
                if (time_counter == 6 && stall_wb == 0) begin
                    reg_mem_wb_abort <= 1;
                end
                else begin
                end
            end

            // stage wb
            if (stall_wb == 0) begin
                if (reg_mem_wb_abort == 0) begin
                    case(time_counter)
                        1: begin
                            if (reg_mem_wb_reg_wr) begin
                                regfile_we <= 1;
                                regfile_waddr <= reg_mem_wb_reg_d;
                                regfile_wdata <= reg_mem_wb_data;
                            end
                            else begin
                            end
                            if (reg_mem_wb_csr_reg_wr) begin
                                csr_we <= 1;
                                csr_waddr <= reg_mem_wb_csr;
                                csr_wdata <= reg_mem_wb_csr_data;
                            end
                            else begin
                            end
                            if (reg_mem_wb_mtime_reg_wr != 2'b00) begin
                                mtime_we <= reg_mem_wb_mtime_reg_wr;
                                mtime_wdata <= reg_mem_wb_mtime_data;
                            end
                            else begin
                            end
                            if (reg_mem_wb_mtimecmp_reg_wr != 2'b00) begin
                                mtimecmp_we <= reg_mem_wb_mtimecmp_reg_wr;
                                mtimecmp_wdata <= reg_mem_wb_mtimecmp_data;
                            end
                            else begin
                            end
                        end
                        2: begin
                            regfile_we <= 0;
                            csr_we <= 0;
                            mtime_we <= 0;
                            mtimecmp_we <= 0;
                        end
                        default: begin
                        end
                    endcase
                end
                else begin
                end
            end
            else begin
            end
        end
    end

endmodule
