class fp32_sequence extends uvm_sequence #(fp32_transaction);

    `uvm_object_utils(fp32_sequence)

    localparam int unsigned TRANSACTION_COUNT = 10000;

    function new(string name = "fp32_sequence");
        super.new(name);
    endfunction


    task body();

        fp32_transaction req;

        repeat (TRANSACTION_COUNT) begin

            req = fp32_transaction::type_id::create("req");

            start_item(req);

            if (!req.randomize()) begin
                `uvm_fatal(
                    "RAND_FAIL",
                    "fp32_transaction randomization failed"
                )
            end

            finish_item(req);

        end

    endtask

endclass
