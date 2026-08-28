class fp32_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(fp32_scoreboard)

    uvm_analysis_imp #(fp32_transaction, fp32_scoreboard) analysis_export;

    integer total_tests  = 0;
    integer passed_tests = 0;
    integer failed_tests = 0;


    function new(string name, uvm_component parent);
        super.new(name, parent);

        analysis_export = new("analysis_export", this);
    endfunction


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


    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info(
            "SCOREBOARD",
            $sformatf(
                "Total=%0d Passed=%0d Failed=%0d",
                total_tests,
                passed_tests,
                failed_tests
            ),
            UVM_NONE
        )

    endfunction

endclass