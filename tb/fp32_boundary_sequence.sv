class fp32_boundary_sequence extends uvm_sequence #(fp32_transaction);

    `uvm_object_utils(fp32_boundary_sequence)

    function new(string name = "fp32_boundary_sequence");
        super.new(name);
    endfunction


    task body();

        fp32_transaction req;


        // --------------------------------------------------------
        // Minimum Normal Exponent
        // exponent = 8'h01
        // --------------------------------------------------------

        req = fp32_transaction::type_id::create("req_min_normal");

        start_item(req);

        if (!req.randomize() with {
            class_sel == CLASS_NORMAL;
            fp32[30:23] == 8'h01;
        }) begin

            `uvm_fatal(
                "RAND_FAIL",
                "Failed to generate minimum normal FP32 value"
            )

        end

        finish_item(req);


        // --------------------------------------------------------
        // Maximum Normal Exponent
        // exponent = 8'hFE
        // --------------------------------------------------------

        req = fp32_transaction::type_id::create("req_max_normal");

        start_item(req);

        if (!req.randomize() with {
            class_sel == CLASS_NORMAL;
            fp32[30:23] == 8'hFE;
        }) begin

            `uvm_fatal(
                "RAND_FAIL",
                "Failed to generate maximum normal FP32 value"
            )

        end

        finish_item(req);

    endtask

endclass