`define STATE_IDLE                  4'b0000
`define STATE_SRAM_WRITE_PAGE_0     4'b0001
`define STATE_SRAM_WRITE_PAGE_1     4'b0010
`define STATE_SRAM_WRITE_PAGE_2     4'b0011
`define STATE_SRAM_WRITE            4'b0100
`define STATE_SRAM_READ_PAGE_0      4'b0101
`define STATE_SRAM_READ_PAGE_1      4'b0110
`define STATE_SRAM_READ_PAGE_2      4'b0111
`define STATE_SRAM_READ             4'b1000
`define STATE_UART_WRITE            4'b1001
`define STATE_UART_READ             4'b1010
`define STATE_FINISHED              4'b1011

`define PAGE_SIZE                   4096
`define PTE_SIZE                    4
