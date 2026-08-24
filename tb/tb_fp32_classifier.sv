module tb_fp32_classifier;

    integer total_tests  = 0;
    integer passed_tests = 0;
    integer failed_tests = 0;

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

        function automatic logic [2:0] reference_model(
        input logic [31:0] value
    );

        logic [7:0]  exponent;
        logic [22:0] fraction;

        exponent = value[30:23];
        fraction = value[22:0];

        if (exponent == 8'h00) begin

            if (fraction == 23'h000000)
                reference_model = CLASS_ZERO;
            else
                reference_model = CLASS_SUBNORMAL;

        end
        else if (exponent == 8'hFF) begin

            if (fraction == 23'h000000)
                reference_model = CLASS_INFINITY;
            else
                reference_model = CLASS_NAN;

        end
        else begin

            reference_model = CLASS_NORMAL;

        end

    endfunction

    task automatic check_value(
        input logic [31:0] test_value,
        input string       test_name
    );

        logic [2:0] expected;

        expected = reference_model(test_value);

        fp32 = test_value;
        #1;

        total_tests++;

        if (class_type == expected) begin
            passed_tests++;

            if (test_name != "Random FP32")
                $display("PASS: %-20s fp32=%h", test_name, fp32);

        end
        else begin
            failed_tests++;

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
    check_value(32'h00000000, "Positive Zero");
    check_value(32'h80000000, "Negative Zero");

    check_value(32'h3F800000, "1.0");
    check_value(32'h40000000, "2.0");

    check_value(32'h7F800000, "Positive Infinity");
    check_value(32'hFF800000, "Negative Infinity");

    check_value(32'h7FC00000, "Quiet NaN");

    check_value(32'h00000001, "Smallest Subnormal");
    check_value(32'h007FFFFF, "Largest Subnormal");
    
    repeat (10000) begin
        check_value($urandom(), "Random FP32");
    end

    $display("");
    $display("========================================");
    $display("FP32 CLASSIFIER VERIFICATION");
    $display("========================================");

    $display("Total Tests  : %0d", total_tests);
    $display("Passed       : %0d", passed_tests);
    $display("Failed       : %0d", failed_tests);

    if (failed_tests == 0)
        $display("TEST PASSED");
    else
        $display("TEST FAILED");

    $display("========================================");

        $finish;

    end

endmodule
