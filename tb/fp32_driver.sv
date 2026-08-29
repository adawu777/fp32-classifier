task run_phase(uvm_phase phase);

    forever begin

        seq_item_port.get_next_item(req);

        // Drive transaction to DUT
        vif.fp32 = req.fp32;

        // Allow combinational DUT output to settle
        #1;

        // Notify monitor that a valid transaction is ready
        -> vif.sample_event;

        // Tell sequencer transaction is complete
        seq_item_port.item_done();

    end

endtask