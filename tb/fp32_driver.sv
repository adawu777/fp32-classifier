task run_phase(uvm_phase phase);

    forever begin

        seq_item_port.get_next_item(req);

        vif.fp32 = req.fp32;

        @(vif.sample_event);

        -> vif.sample_event;

        seq_item_port.item_done();

    end

endtask