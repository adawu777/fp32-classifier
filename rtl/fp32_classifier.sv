module fp32_classifier (
    input  logic [31:0] fp32,
    output logic [2:0]  class_type
);

    // Classification encoding
    localparam logic [2:0] CLASS_ZERO      = 3'b000;
    localparam logic [2:0] CLASS_SUBNORMAL = 3'b001;
    localparam logic [2:0] CLASS_NORMAL    = 3'b010;
    localparam logic [2:0] CLASS_INFINITY  = 3'b011;
    localparam logic [2:0] CLASS_NAN       = 3'b100;

    // IEEE-754 FP32 fields
    logic        sign;
    logic [7:0]  exponent;
    logic [22:0] fraction;

    assign sign     = fp32[31];
    assign exponent = fp32[30:23];
    assign fraction = fp32[22:0];

    always_comb begin

        if (exponent == 8'h00) begin

            if (fraction == 23'h000000)
                class_type = CLASS_ZERO;
            else
                class_type = CLASS_SUBNORMAL;

        end
        else if (exponent == 8'hFF) begin

            if (fraction == 23'h000000)
                class_type = CLASS_INFINITY;
            else
                class_type = CLASS_NAN;

        end
        else begin

            class_type = CLASS_NORMAL;

        end

    end

endmodule
