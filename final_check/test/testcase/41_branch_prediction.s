    .global _start
    .text
_start:
    ori t0, zero, 1000
.LC2_0:
    bne t0, zero, .LC2_1
    jr ra
.LC2_1:
    j .LC2_2
.LC2_2:
    addi t0, t0, -1
    j .LC2_0
    addi t0, t0, -1
