class fp32_coverage extends uvm_subscriber #(fp32_transaction);

    `uvm_component_utils(fp32_coverage)

    fp32_transaction tr;

    bit [2:0] input_class;


    // ========================================================
    // Functional Coverage
    // ========================================================
    covergroup fp32_cg;


        // --------------------------------------------------------
        // Input-Decoded FP32 Class Coverage
        // --------------------------------------------------------
        cp_input_class : coverpoint input_class {

            bins zero      = {CLASS_ZERO};
            bins subnormal = {CLASS_SUBNORMAL};
            bins normal    = {CLASS_NORMAL};
            bins infinity  = {CLASS_INFINITY};
            bins nan       = {CLASS_NAN};

        }


        // --------------------------------------------------------
        // DUT-Observed Class Coverage
        // --------------------------------------------------------
        cp_dut_class : coverpoint tr.class_type {

            bins zero      = {CLASS_ZERO};
            bins subnormal = {CLASS_SUBNORMAL};
            bins normal    = {CLASS_NORMAL};
            bins infinity  = {CLASS_INFINITY};
            bins nan       = {CLASS_NAN};

            illegal_bins invalid_encoding = {
                3'b101,
                3'b110,
                3'b111
            };

        }


        // --------------------------------------------------------
        // Sign Coverage
        // --------------------------------------------------------
        cp_sign : coverpoint tr.fp32[31] {

            bins positive = {1'b0};
            bins negative = {1'b1};

        }


        // --------------------------------------------------------
        // Exponent Coverage
        // --------------------------------------------------------
        cp_exp : coverpoint tr.fp32[30:23] {

            bins exp_zero       = {8'h00};

            bins exp_min_normal = {8'h01};

            bins exp_low        = {[8'h02 : 8'h3F]};

            bins exp_mid        = {[8'h40 : 8'hBF]};

            bins exp_high       = {[8'hC0 : 8'hFD]};

            bins exp_max_normal = {8'hFE};

            bins exp_special    = {8'hFF};

        }


        // --------------------------------------------------------
        // Fraction Coverage
        // --------------------------------------------------------
        cp_frac : coverpoint tr.fp32[22:0] {

            bins frac_zero = {23'h000000};

            bins frac_min  = {23'h000001};

            bins frac_low  = {[23'h000002 : 23'h1FFFFF]};

            bins frac_mid  = {[23'h200000 : 23'h5FFFFF]};

            bins frac_high = {[23'h600000 : 23'h7FFFFE]};

            bins frac_max  = {23'h7FFFFF};

        }


        // --------------------------------------------------------
        // FP32 Boundary Coverage
        // --------------------------------------------------------
        cp_boundary : coverpoint tr.fp32 {

            bins pos_zero = {
                32'h00000000
            };

            bins neg_zero = {
                32'h80000000
            };


            bins pos_min_subnormal = {
                32'h00000001
            };

            bins pos_max_subnormal = {
                32'h007FFFFF
            };


            bins neg_min_subnormal = {
                32'h80000001
            };

            bins neg_max_subnormal = {
                32'h807FFFFF
            };


            bins pos_min_normal = {
                32'h00800000
            };

            bins pos_max_normal = {
                32'h7F7FFFFF
            };


            bins neg_min_normal = {
                32'h80800000
            };

            bins neg_max_normal = {
                32'hFF7FFFFF
            };


            bins pos_infinity = {
                32'h7F800000
            };

            bins neg_infinity = {
                32'hFF800000
            };


            bins pos_qnan = {
                32'h7FC00000
            };

            bins neg_qnan = {
                32'hFFC00000
            };


            // Ignore all non-boundary FP32 patterns
            ignore_bins non_boundary = default;

        }


        // --------------------------------------------------------
        // NaN Fraction Coverage
        // --------------------------------------------------------
        cp_nan_frac : coverpoint tr.fp32[22:0]
            iff (input_class == CLASS_NAN) {

            bins nan_min_payload = {
                23'h000001
            };

            bins nan_low_payload = {
                [23'h000002 : 23'h1FFFFF]
            };

            bins nan_mid_payload = {
                [23'h200000 : 23'h5FFFFF]
            };

            bins nan_high_payload = {
                [23'h600000 : 23'h7FFFFE]
            };

            bins nan_max_payload = {
                23'h7FFFFF
            };

        }


        // --------------------------------------------------------
        // Input-Decoded Class x Sign Coverage
        // --------------------------------------------------------
        input_class_sign_cross : cross cp_input_class, cp_sign;


        // --------------------------------------------------------
        // DUT-Observed Class x Sign Coverage
        // --------------------------------------------------------
        dut_class_sign_cross : cross cp_dut_class, cp_sign;


        // --------------------------------------------------------
        // Input-Decoded Class x DUT-Observed Class Coverage
        // --------------------------------------------------------
        input_dut_class_cross : cross cp_input_class, cp_dut_class {

            bins zero_match =
                binsof(cp_input_class.zero) &&
                binsof(cp_dut_class.zero);

            bins subnormal_match =
                binsof(cp_input_class.subnormal) &&
                binsof(cp_dut_class.subnormal);

            bins normal_match =
                binsof(cp_input_class.normal) &&
                binsof(cp_dut_class.normal);

            bins infinity_match =
                binsof(cp_input_class.infinity) &&
                binsof(cp_dut_class.infinity);

            bins nan_match =
                binsof(cp_input_class.nan) &&
                binsof(cp_dut_class.nan);

            ignore_bins mismatches = default;

        }


    endgroup



    // ========================================================
    // Constructor
    // ========================================================
    function new(
        string name,
        uvm_component parent
    );

        super.new(name, parent);

        fp32_cg = new();

    endfunction



    // ========================================================
    // Receive Transaction from Monitor
    // ========================================================
    function void write(fp32_transaction t);

        tr = t;


        // --------------------------------------------------------
        // Decode FP32 Class from Actual Observed Input
        // --------------------------------------------------------

        if ((tr.fp32[30:23] == 8'h00) &&
            (tr.fp32[22:0]  == 23'h000000)) begin

            input_class = CLASS_ZERO;

        end


        else if ((tr.fp32[30:23] == 8'h00) &&
                 (tr.fp32[22:0]  != 23'h000000)) begin

            input_class = CLASS_SUBNORMAL;

        end


        else if ((tr.fp32[30:23] != 8'h00) &&
                 (tr.fp32[30:23] != 8'hFF)) begin

            input_class = CLASS_NORMAL;

        end


        else if ((tr.fp32[30:23] == 8'hFF) &&
                 (tr.fp32[22:0]  == 23'h000000)) begin

            input_class = CLASS_INFINITY;

        end


        else begin

            input_class = CLASS_NAN;

        end


        // --------------------------------------------------------
        // Sample Functional Coverage
        // --------------------------------------------------------
        fp32_cg.sample();

    endfunction



    // ========================================================
    // Coverage Report
    // ========================================================
    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info(
            "COVERAGE",
            $sformatf(
                "Functional Coverage = %0.2f%%",
                fp32_cg.get_inst_coverage()
            ),
            UVM_NONE
        )

    endfunction


endclass
