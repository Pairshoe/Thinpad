`define INSTR_ADDR_MISALIGN_EXC     4'b0000
`define INSTR_ACCESS_FAULT_EXC      4'b0001
`define ILLEGAL_INSTR_EXC           4'b0010
`define BREAKPOINT_EXC              4'b0011
`define LOAD_ADDR_MISALIGN_EXC      4'b0100
`define LOAD_ACCESS_FAULT_EXC       4'b0101
`define STORE_ADDR_MISALIGN_EXC     4'b0110
`define STORE_ACCESS_FAULT_EXC      4'b0111
`define ECALL_U_EXC                 4'b1000
`define ECALL_S_EXC                 4'b1001
`define NO_EXC                      4'b1010
`define ECALL_M_EXC                 4'b1011
`define INSTR_PAGE_FAULT_EXC        4'b1100
`define LOAD_PAGE_FAULT_EXC         4'b1101
`define STORE_PAGE_FAULT_EXC        4'b1111

`define S_SOFTWARE_INT              4'b0001
`define M_SOFTWARE_INT              4'b0011
`define S_TIMER_INT                 4'b0101
`define M_TIMER_INT                 4'b0111
`define S_EXTERNAL_INT              4'b1001
`define M_EXTERNAL_INT              4'b1011

`define MTIME_LO_ADDR               32'h0200bff8
`define MTIME_HI_ADDR               32'h0200bffc
`define MTIMECMP_LO_ADDR            32'h02004000
`define MTIMECMP_HI_ADDR            32'h02004004
