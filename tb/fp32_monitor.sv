task run_phase(uvm_phase phase);

    fp32_transaction tr;

    forever begin

        @(vif.sample_event);

        tr = fp32_transaction::type_id::create("tr");

        tr.fp32       = vif.fp32;
        tr.class_type = vif.class_type;

        ap.write(tr);

    end

endtask