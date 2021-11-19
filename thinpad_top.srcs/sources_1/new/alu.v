`default_nettype none
`timescale 1ns / 100ps
`include "alu.vh"

module alu(
    input wire[4:0]         op,
    input wire[31:0]        a,
    input wire[31:0]        b,
    output wire[31:0]       r,
    output wire[3:0]        flags
);

    reg                     zf, cf, sf, vf;
    reg[31:0]               result;

    assign                  flags = { zf, cf, sf, vf };
    assign                  r = result;

    always @(*) begin
        zf = 0;  cf = 0;  sf = 0;  vf = 0;

        case(op)
            `ADD: begin
                result = a + b;
                cf = (result < a) ? 1'b1 : 1'b0;
                vf = ((result[31] != a[31]) && (a[31] == b[31])) ? 1'b1 : 1'b0;
            end

            `SUB: begin
                result = a - b;
                cf = (result > a) ? 1'b1 : 1'b0;
                vf = ((result[31] != a[31]) && (a[31] == b[31])) ? 1'b1 : 1'b0;
            end

            `AND: begin
                result = a & b;
            end

            `ANDN: begin
                result = a & ~b;
            end

            `NANDN: begin
                result = ~a & b;
            end

            `OR: begin
                result = a | b;
            end

            `XOR: begin
                result = a ^ b;
            end

            `XNOR: begin
                result = ~(a ^ b);
            end

            `MINU: begin
                result = a < b ? a : b;
            end

            `SLT: begin
                result = $signed(a) < $signed(b) ? a : b;
            end

            `SLTU: begin
                result = a < b ? 1 : 0;
            end

            `NOT: begin
                result = ~a;
            end

            `SLL: begin
                result = a << b;
            end

            `SRL: begin
                result = a >> b;
            end

            `SRA: begin
                result = $signed(a) >>> b;    
            end

            `ROL: begin
                result = (a << b) | (a >> (32 - b)); 
            end 

            `A: begin
                result = a;
            end

            default: begin
                result = 0;
            end
        endcase

        zf = (result == 0) ? 1'b1 : 1'b0;
        sf = (result[31] == 1'b1) ? 1'b1 : 1'b0;
    end

endmodule
