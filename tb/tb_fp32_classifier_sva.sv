module tb_fp32_classifier_sva;

    // ============================================================
    // DUT signals
    // ============================================================

    logic [31:0] fp32;
    logic [2:0]  class_type;


    // ============================================================
    // FP32 class definitions
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
    // SVA Properties
    // ============================================================

    // ------------------------------------------------------------
    // ZERO
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
            $error(
                "ASSERTION FAILED: ZERO fp32=%h class=%b",
                fp32,
                class_type
            );


    // ------------------------------------------------------------
    // SUBNORMAL
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
            $error(
                "ASSERTION FAILED: SUBNORMAL fp32=%h class=%b",
                fp32,
                class_type
            );


    // ------------------------------------------------------------
    // NORMAL
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
            $error(
                "ASSERTION FAILED: NORMAL fp32=%h class=%b",
                fp32,
                class_type
            );


    // ------------------------------------------------------------
    // INFINITY
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
            $error(
                "ASSERTION FAILED: INFINITY fp32=%h class=%b",
                fp32,
                class_type
            );


    // ------------------------------------------------------------
    // NaN
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
            $error(
                "ASSERTION FAILED: NaN fp32=%h class=%b",
                fp32,
                class_type
            );


    // ============================================================
    // Test stimulus
    //
    // NOTE:
    // This testbench demonstrates standard SystemVerilog
    // concurrent assertions using property / assert property.
    //
    // The current simulator environment uses Icarus Verilog,
    // which does not provide full support for these SVA constructs.
    //
    // Therefore this file is currently kept as a reference /
    // learning implementation and is not executed in simulation.
    // ============================================================

    initial begin

        fp32 = 32'h00000000;

        #1;

        fp32 = 32'h00000001;

        #1;

        fp32 = 32'h3F800000;

        #1;

        fp32 = 32'h7F800000;

        #1;

        fp32 = 32'h7FC00000;

        #1;

        $finish;

    end

endmodule