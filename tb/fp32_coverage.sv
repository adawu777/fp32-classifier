class fp32_coverage extends uvm_subscriber #(fp32_transaction);

    `uvm_component_utils(fp32_coverage)

    fp32_transaction tr;

    bit [2:0] observed_class;


    covergroup fp32_cg;

        // --------------------------------------------------------
        // FP32 Class Coverage
        // --------------------------------------------------------
        cp_class : coverpoint observed_class {

            bins zero      = {CLASS_ZERO};
            bins subnormal = {CLASS_SUBNORMAL};
            bins normal    = {CLASS_NORMAL};
            bins infinity  = {CLASS_INFINITY};
            bins nan       = {CLASS_NAN};

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

            bins exp_middle[]   = {[8'h02 : 8'hFD]};

            bins exp_max_normal = {8'hFE};

            bins exp_special    = {8'hFF};

        }


        // --------------------------------------------------------
        // Fraction Coverage
        // --------------------------------------------------------
        cp_frac : coverpoint tr.fp32[22:0] {

            bins frac_zero    = {23'h0};

            bins frac_nonzero = {[23'h1 : 23'h7FFFFF]};

        }


        // --------------------------------------------------------
        // Cross Coverage
        // --------------------------------------------------------
        class_sign_cross : cross cp_class, cp_sign;


    endgroup


    function new(
        string name,
        uvm_component parent
    );

        super.new(name, parent);

        fp32_cg = new();

    endfunction


    function void write(fp32_transaction t);

        tr = t;


        // --------------------------------------------------------
        // Decode FP32 Class from Actual Input
        // --------------------------------------------------------

        if ((tr.fp32[30:23] == 8'h00) &&
            (tr.fp32[22:0]  == 23'h0)) begin

            observed_class = CLASS_ZERO;

        end


        else if ((tr.fp32[30:23] == 8'h00) &&
                 (tr.fp32[22:0]  != 23'h0)) begin

            observed_class = CLASS_SUBNORMAL;

        end


        else if ((tr.fp32[30:23] != 8'h00) &&
                 (tr.fp32[30:23] != 8'hFF)) begin

            observed_class = CLASS_NORMAL;

        end


        else if ((tr.fp32[30:23] == 8'hFF) &&
                 (tr.fp32[22:0]  == 23'h0)) begin

            observed_class = CLASS_INFINITY;

        end


        else begin

            observed_class = CLASS_NAN;

        end


        // Sample all coverpoints
        fp32_cg.sample();

    endfunction


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