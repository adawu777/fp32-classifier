class fp32_boundary_sequence extends uvm_sequence #(fp32_transaction);

    `uvm_object_utils(fp32_boundary_sequence)

    function new(string name = "fp32_boundary_sequence");
        super.new(name);
    endfunction


    task body();

        fp32_transaction req;

        logic [31:0] boundary_values[] = '{

            32'h00000000,   // +0
            32'h80000000,   // -0

            32'h00000001,   // min positive subnormal
            32'h007FFFFF,   // max positive subnormal

            32'h80000001,   // min magnitude negative subnormal
            32'h807FFFFF,   // max magnitude negative subnormal

            32'h00800000,   // min positive normal
            32'h7F7FFFFF,   // max positive normal

            32'h80800000,   // min magnitude negative normal
            32'hFF7FFFFF,   // max magnitude negative normal

            32'h7F800000,   // +Infinity
            32'hFF800000,   // -Infinity

            32'h7FC00000,   // +qNaN
            32'hFFC00000    // -qNaN

        };


        foreach (boundary_values[i]) begin

            req = fp32_transaction::type_id::create("req");

            start_item(req);

            // ----------------------------------------------------
            // Drive exact boundary value
            // ----------------------------------------------------
            req.fp32 = boundary_values[i];


            // ----------------------------------------------------
            // Keep class_sel consistent with fp32
            // ----------------------------------------------------
            if ((req.fp32[30:23] == 8'h00) &&
                (req.fp32[22:0]  == 23'h0)) begin

                req.class_sel = CLASS_ZERO;

            end

            else if ((req.fp32[30:23] == 8'h00) &&
                     (req.fp32[22:0]  != 23'h0)) begin

                req.class_sel = CLASS_SUBNORMAL;

            end

            else if ((req.fp32[30:23] != 8'h00) &&
                     (req.fp32[30:23] != 8'hFF)) begin

                req.class_sel = CLASS_NORMAL;

            end

            else if ((req.fp32[30:23] == 8'hFF) &&
                     (req.fp32[22:0]  == 23'h0)) begin

                req.class_sel = CLASS_INFINITY;

            end

            else begin

                req.class_sel = CLASS_NAN;

            end


            finish_item(req);

        end

    endtask


endclass