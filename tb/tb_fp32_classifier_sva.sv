module fp32_classifier_sva (
    fp32_if vif
);

    localparam logic [2:0] CLASS_ZERO      = 3'b000;
    localparam logic [2:0] CLASS_SUBNORMAL = 3'b001;
    localparam logic [2:0] CLASS_NORMAL    = 3'b010;
    localparam logic [2:0] CLASS_INFINITY  = 3'b011;
    localparam logic [2:0] CLASS_NAN       = 3'b100;


    always @(vif.sample_event) begin

        if ((vif.fp32[30:23] == 8'h00) &&
            (vif.fp32[22:0]  == 23'h000000)) begin

            a_zero:
                assert (vif.class_type === CLASS_ZERO)
                else
                    $error(
                        "ZERO assertion failed: fp32=%h class_type=%b",
                        vif.fp32,
                        vif.class_type
                    );

        end


        if ((vif.fp32[30:23] == 8'h00) &&
            (vif.fp32[22:0]  != 23'h000000)) begin

            a_subnormal:
                assert (vif.class_type === CLASS_SUBNORMAL)
                else
                    $error(
                        "SUBNORMAL assertion failed: fp32=%h class_type=%b",
                        vif.fp32,
                        vif.class_type
                    );

        end


        if ((vif.fp32[30:23] != 8'h00) &&
            (vif.fp32[30:23] != 8'hFF)) begin

            a_normal:
                assert (vif.class_type === CLASS_NORMAL)
                else
                    $error(
                        "NORMAL assertion failed: fp32=%h class_type=%b",
                        vif.fp32,
                        vif.class_type
                    );

        end


        if ((vif.fp32[30:23] == 8'hFF) &&
            (vif.fp32[22:0]  == 23'h000000)) begin

            a_infinity:
                assert (vif.class_type === CLASS_INFINITY)
                else
                    $error(
                        "INFINITY assertion failed: fp32=%h class_type=%b",
                        vif.fp32,
                        vif.class_type
                    );

        end


        if ((vif.fp32[30:23] == 8'hFF) &&
            (vif.fp32[22:0]  != 23'h000000)) begin

            a_nan:
                assert (vif.class_type === CLASS_NAN)
                else
                    $error(
                        "NAN assertion failed: fp32=%h class_type=%b",
                        vif.fp32,
                        vif.class_type
                    );

        end

    end

endmodule
