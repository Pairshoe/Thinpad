module seg7_lut(
    input wire[3:0]   idig,
    output wire[7:0]  oseg_out
);

    reg[6:0]          oseg;

    assign            oseg_out = { ~oseg, 1'b0 };

    always @(idig) begin
        case(idig)
            4'h1: oseg = 7'b1110110;    // ---t----
            4'h2: oseg = 7'b0100001;    // |      |
            4'h3: oseg = 7'b0100100;    // lt    rt
            4'h4: oseg = 7'b0010110;    // |      |
            4'h5: oseg = 7'b0001100;    // ---m----
            4'h6: oseg = 7'b0001000;    // |      |
            4'h7: oseg = 7'b1100110;    // lb    rb
            4'h8: oseg = 7'b0000000;    // |      |
            4'h9: oseg = 7'b0000110;    // ---b----
            4'ha: oseg = 7'b0000010;
            4'hb: oseg = 7'b0011000;
            4'hc: oseg = 7'b1001001;
            4'hd: oseg = 7'b0110000;
            4'he: oseg = 7'b0001001;
            4'hf: oseg = 7'b0001011;
            4'h0: oseg = 7'b1000000;
        endcase
    end

endmodule
