module tb_fp32_classifier;

    // ============================================================
    // Test statistics
    // ============================================================

    integer total_tests  = 0;
    integer passed_tests = 0;
    integer failed_tests = 0;

    integer i;

    logic [31:0] fp32;
    logic [2:0]  class_type;


    // ============================================================
    // Class definitions
    // ============================================================

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
    // Functional Coverage
    // ============================================================

    covergroup fp32_cg;

        cp_class : coverpoint class_type {

            bins zero      = {CLASS_ZERO};
            bins subnormal = {CLASS_SUBNORMAL};
            bins normal    = {CLASS_NORMAL};
            bins infinity  = {CLASS_INFINITY};
            bins nan       = {CLASS_NAN};

        }


        cp_sign : coverpoint fp32[31] {

            bins positive = {1'b0};
            bins negative = {1'b1};

        }


        class_sign_cross : cross cp_class, cp_sign;

    endgroup


    fp32_cg cg;


    // ============================================================
    // Reference Model
    // ============================================================

    function automatic logic [2:0]
        reference_model(input logic [31:0] value);

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
    // Check Task
    // ============================================================

    task automatic check_value(
        input logic [31:0] value
    );

        logic [2:0] expected;

        begin

            fp32 = value;

            #1;

            expected = reference_model(value);

            total_tests = total_tests + 1;


            // ----------------------------------------------------
            // Functional coverage sampling
            // ----------------------------------------------------

            cg.sample();


            // ----------------------------------------------------
            // Self checking
            // ----------------------------------------------------

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

        // Create coverage object

        cg = new();


        $display("");
        $display("========================================");
        $display("FP32 CLASSIFIER VERIFICATION");
        $display("========================================");


        // ========================================================
        // Directed tests
        // ========================================================

        // +0
        check_value(32'h00000000);

        // -0
        check_value(32'h80000000);


        // Smallest positive subnormal
        check_value(32'h00000001);

        // Largest positive subnormal
        check_value(32'h007FFFFF);


        // +1.0
        check_value(32'h3F800000);

        // -1.0
        check_value(32'hBF800000);


        // Largest positive normal
        check_value(32'h7F7FFFFF);


        // +Infinity
        check_value(32'h7F800000);

        // -Infinity
        check_value(32'hFF800000);


        // NaN
        check_value(32'h7FC00000);


        // ========================================================
        // Randomized tests
        // ========================================================

        for (i = 0; i < 10000; i = i + 1) begin

            check_value($urandom);

        end


        // ========================================================
        // Test summary
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST SUMMARY");
        $display("========================================");

        $display("Total Tests  : %0d", total_tests);
        $display("Passed       : %0d", passed_tests);
        $display("Failed       : %0d", failed_tests);

        $display("----------------------------------------");

        $display(
            "Functional Coverage : %0.2f%%",
            cg.get_coverage()
        );

        $display("----------------------------------------");


        if (failed_tests == 0)

            $display("TEST PASSED");

        else

            $display("TEST FAILED");


        $display("========================================");
        $display("");

        $finish;

    end


endmodule