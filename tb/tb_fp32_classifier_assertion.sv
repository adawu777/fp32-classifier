module tb_fp32_classifier_property;

    integer total_tests  = 0;
    integer passed_tests = 0;
    integer failed_tests = 0;

    integer i;

    logic [31:0] fp32;
    logic [2:0]  class_type;

    localparam logic [2:0] CLASS_ZERO      = 3'b000;
    localparam logic [2:0] CLASS_SUBNORMAL = 3'b001;
    localparam logic [2:0] CLASS_NORMAL    = 3'b010;
    localparam logic [2:0] CLASS_INFINITY  = 3'b011;
    localparam logic [2:0] CLASS_NAN       = 3'b100;


    // ============================================================
    // DUT
    // ============================================================

    fp32_classifier dut (
        .fp32       (fp32),
        .class_type (class_type)
    );


    // ============================================================
    // Reference Model
    // ============================================================

    function automatic logic [2:0] reference_model(
        input logic [31:0] value
    );

        logic [7:0]  exponent;
        logic [22:0] fraction;

        begin

            exponent = value[30:23];
            fraction = value[22:0];

            if ((exponent == 8'h00) &&
                (fraction == 23'h000000))

                reference_model = CLASS_ZERO;

            else if ((exponent == 8'h00) &&
                     (fraction != 23'h000000))

                reference_model = CLASS_SUBNORMAL;

            else if ((exponent == 8'hFF) &&
                     (fraction == 23'h000000))

                reference_model = CLASS_INFINITY;

            else if ((exponent == 8'hFF) &&
                     (fraction != 23'h000000))

                reference_model = CLASS_NAN;

            else

                reference_model = CLASS_NORMAL;

        end

    endfunction


    // ============================================================
    // SVA Properties
    // ============================================================

    // ------------------------------------------------------------
    // Property 1: Zero
    // ------------------------------------------------------------

    property p_zero;

        @(*)

        ((fp32[30:23] == 8'h00) &&
         (fp32[22:0]  == 23'h000000))

        |->

        (class_type == CLASS_ZERO);

    endproperty


    a_zero:
        assert property (p_zero)
        else
            $error("ASSERTION FAILED: Zero");


    // ------------------------------------------------------------
    // Property 2: Subnormal
    // ------------------------------------------------------------

    property p_subnormal;

        @(*)

        ((fp32[30:23] == 8'h00) &&
         (fp32[22:0]  != 23'h000000))

        |->

        (class_type == CLASS_SUBNORMAL);

    endproperty


    a_subnormal:
        assert property (p_subnormal)
        else
            $error("ASSERTION FAILED: Subnormal");


    // ------------------------------------------------------------
    // Property 3: Normal
    // ------------------------------------------------------------

    property p_normal;

        @(*)

        ((fp32[30:23] != 8'h00) &&
         (fp32[30:23] != 8'hFF))

        |->

        (class_type == CLASS_NORMAL);

    endproperty


    a_normal:
        assert property (p_normal)
        else
            $error("ASSERTION FAILED: Normal");


    // ------------------------------------------------------------
    // Property 4: Infinity
    // ------------------------------------------------------------

    property p_infinity;

        @(*)

        ((fp32[30:23] == 8'hFF) &&
         (fp32[22:0]  == 23'h000000))

        |->

        (class_type == CLASS_INFINITY);

    endproperty


    a_infinity:
        assert property (p_infinity)
        else
            $error("ASSERTION FAILED: Infinity");


    // ------------------------------------------------------------
    // Property 5: NaN
    // ------------------------------------------------------------

    property p_nan;

        @(*)

        ((fp32[30:23] == 8'hFF) &&
         (fp32[22:0]  != 23'h000000))

        |->

        (class_type == CLASS_NAN);

    endproperty


    a_nan:
        assert property (p_nan)
        else
            $error("ASSERTION FAILED: NaN");


    // ============================================================
    // Check Value
    // ============================================================

    task automatic check_value(
        input logic [31:0] value
    );

        logic [2:0] expected;

        begin

            // Drive DUT
            fp32 = value;

            // Wait for combinational logic to settle
            #1;

            // Calculate expected result
            expected = reference_model(value);

            total_tests = total_tests + 1;


            // Compare DUT with reference model
            if (class_type === expected) begin

                passed_tests = passed_tests + 1;

            end

            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL: fp32=%h expected=%b actual=%b",
                    value,
                    expected,
                    class_type
                );

            end

        end

    endtask


    // ============================================================
    // Test
    // ============================================================

    initial begin

        $display("");
        $display("========================================");
        $display("FP32 CLASSIFIER SVA VERIFICATION");
        $display("========================================");


        // Directed tests

        check_value(32'h00000000); // +Zero
        check_value(32'h80000000); // -Zero

        check_value(32'h00000001); // Subnormal
        check_value(32'h007FFFFF); // Subnormal

        check_value(32'h3F800000); // +1.0
        check_value(32'hBF800000); // -1.0

        check_value(32'h7F800000); // +Infinity
        check_value(32'hFF800000); // -Infinity

        check_value(32'h7FC00000); // NaN


        // Random tests

        for (i = 0; i < 10000; i = i + 1) begin

            check_value($urandom);

        end


        // Summary

        $display("");
        $display("========================================");
        $display("TEST SUMMARY");
        $display("========================================");

        $display("Total Tests : %0d", total_tests);
        $display("Passed      : %0d", passed_tests);
        $display("Failed      : %0d", failed_tests);

        if (failed_tests == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");

        $display("========================================");

        $finish;

    end

endmodule