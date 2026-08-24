module tb_fp32_classifier;

    logic [31:0] fp32;
    logic [2:0]  class_type;

    localparam logic [2:0] CLASS_ZERO      = 3'b000;
    localparam logic [2:0] CLASS_SUBNORMAL = 3'b001;
    localparam logic [2:0] CLASS_NORMAL    = 3'b010;
    localparam logic [2:0] CLASS_INFINITY  = 3'b011;
    localparam logic [2:0] CLASS_NAN       = 3'b100;

    // DUT
    fp32_classifier dut (
        .fp32       (fp32),
        .class_type (class_type)
    );

    // Self-checking test
    task automatic check_value(
        input logic [31:0] test_value,
        input logic [2:0]  expected,
        input string       test_name
    );

        fp32 = test_value;
        #1;

        if (class_type == expected) begin
            $display(
                "PASS: %-20s fp32=%h",
                test_name,
                fp32
            );
        end
        else begin
            $display(
                "FAIL: %-20s fp32=%h expected=%b actual=%b",
                test_name,
                fp32,
                expected,
                class_type
            );
        end

    endtask

    initial begin

        // Zero
        check_value(
            32'h00000000,
            CLASS_ZERO,
            "Positive Zero"
        );

        check_value(
            32'h80000000,
            CLASS_ZERO,
            "Negative Zero"
        );

        // Normal
        check_value(
            32'h3F800000,
            CLASS_NORMAL,
            "1.0"
        );

        check_value(
            32'h40000000,
            CLASS_NORMAL,
            "2.0"
        );

        // Infinity
        check_value(
            32'h7F800000,
            CLASS_INFINITY,
            "Positive Infinity"
        );

        check_value(
            32'hFF800000,
            CLASS_INFINITY,
            "Negative Infinity"
        );

        // NaN
        check_value(
            32'h7FC00000,
            CLASS_NAN,
            "Quiet NaN"
        );

        // Subnormal
        check_value(
            32'h00000001,
            CLASS_SUBNORMAL,
            "Smallest Subnormal"
        );

        check_value(
            32'h007FFFFF,
            CLASS_SUBNORMAL,
            "Largest Subnormal"
        );

        $display("");
        $display("======================================");
        $display("FP32 CLASSIFIER TEST COMPLETE");
        $display("======================================");

        $finish;

    end

endmodule
