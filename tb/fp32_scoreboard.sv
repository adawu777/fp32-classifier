class fp32_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(fp32_scoreboard)

    uvm_analysis_imp #(fp32_transaction, fp32_scoreboard) analysis_export;

    int total_tests    = 0;
    int passed_tests   = 0;
    int failed_tests   = 0;
    int expected_tests = 0;


    function new(string name, uvm_component parent);
        super.new(name, parent);

        analysis_export = new("analysis_export", this);
    endfunction


    // ========================================================
    // Expected Transaction Count
    // ========================================================
    function void set_expected_count(int count);

        if (count <= 0) begin
            `uvm_fatal(
                "BAD_EXPECTED_COUNT",
                $sformatf(
                    "Expected transaction count must be positive: %0d",
                    count
                )
            )
        end

        expected_tests = count;

    endfunction


    // ========================================================
    // Completion Synchronization
    // ========================================================
    task wait_for_expected_count();

        wait (total_tests >= expected_tests);

    endtask


    // ========================================================
    // Reference Model
    // ========================================================
    function automatic logic [2:0] reference_model(
        input logic [31:0] value
    );

        logic [7:0]  exponent;
        logic [22:0] fraction;

        exponent = value[30:23];
        fraction = value[22:0];

        if ((exponent == 8'h00) &&
            (fraction == 23'h000000)) begin

            return CLASS_ZERO;

        end
        else if ((exponent == 8'h00) &&
                 (fraction != 23'h000000)) begin

            return CLASS_SUBNORMAL;

        end
        else if ((exponent == 8'hFF) &&
                 (fraction == 23'h000000)) begin

            return CLASS_INFINITY;

        end
        else if ((exponent == 8'hFF) &&
                 (fraction != 23'h000000)) begin

            return CLASS_NAN;

        end
        else begin

            return CLASS_NORMAL;

        end

    endfunction


    // ========================================================
    // Transaction Check
    // ========================================================
    function void write(fp32_transaction tr);

        logic [2:0] expected;

        total_tests++;

        expected = reference_model(tr.fp32);


        if (tr.class_type === expected) begin

            passed_tests++;

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "PASS: fp32=%h expected=%b actual=%b",
                    tr.fp32,
                    expected,
                    tr.class_type
                ),
                UVM_LOW
            )

        end
        else begin

            failed_tests++;

            `uvm_error(
                "SCOREBOARD",
                $sformatf(
                    "FAIL: fp32=%h expected=%b actual=%b",
                    tr.fp32,
                    expected,
                    tr.class_type
                )
            )

        end

    endfunction


    // ========================================================
    // End-of-Test Checks
    // ========================================================
    function void check_phase(uvm_phase phase);

        super.check_phase(phase);

        if (expected_tests <= 0) begin
            `uvm_error(
                "ZERO_EXPECTED",
                "No positive expected transaction count was configured"
            )
        end

        if (total_tests != expected_tests) begin
            `uvm_error(
                "COUNT_MISMATCH",
                $sformatf(
                    "Expected %0d transactions, received %0d",
                    expected_tests,
                    total_tests
                )
            )
        end

        if ((passed_tests + failed_tests) != total_tests) begin
            `uvm_error(
                "ACCOUNTING_ERROR",
                $sformatf(
                    "Total=%0d but passed+failed=%0d",
                    total_tests,
                    passed_tests + failed_tests
                )
            )
        end

    endfunction


    // ========================================================
    // Final Test Summary
    // ========================================================
    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info(
            "SCOREBOARD",
            $sformatf(
                "Expected=%0d Total=%0d Passed=%0d Failed=%0d",
                expected_tests,
                total_tests,
                passed_tests,
                failed_tests
            ),
            UVM_NONE
        )


        if ((expected_tests > 0) &&
            (total_tests == expected_tests) &&
            ((passed_tests + failed_tests) == total_tests) &&
            (failed_tests == 0)) begin

            `uvm_info(
                "SCOREBOARD",
                "TEST PASSED",
                UVM_NONE
            )

        end
        else begin

            `uvm_error(
                "SCOREBOARD",
                $sformatf(
                    "TEST FAILED: expected=%0d received=%0d classification_failures=%0d",
                    expected_tests,
                    total_tests,
                    failed_tests
                )
            )

        end

    endfunction


endclass
