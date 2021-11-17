`default_nettype none
`timescale 1ns / 100ps

module br_comparator(
    input wire[31:0]    rdata1,
    input wire[31:0]    rdata2,
    input wire          br_un,
    output wire         br_eq,
    output wire         br_lt,
    output wire         br_a_eqz,
    output wire         br_b_eqz
);

    reg br_eq_reg, br_lt_reg;

    assign br_eq = br_eq_reg, br_lt = br_lt_reg;
    assign br_a_eqz = rdata1 == 32'h00000000 ? 1'b1 : 1'b0;
    assign br_b_eqz = rdata2 == 32'h00000000 ? 1'b1 : 1'b0;

    always @(*) begin
        if (rdata1 == rdata2) begin
            br_eq_reg = 1'b1;
        end
        else begin
            br_eq_reg = 1'b0;
        end

        if (br_un == 0) begin    // signed compare
            if ($signed(rdata1) < $signed(rdata2)) begin
                br_lt_reg = 1'b1;
            end
            else begin
                br_lt_reg = 1'b0;
            end
        end
        else begin               // unsigned compare
            if (rdata1 < rdata2) begin
                br_lt_reg = 1'b1;
            end
            else begin
                br_lt_reg = 1'b0;
            end
        end
    end

endmodule
