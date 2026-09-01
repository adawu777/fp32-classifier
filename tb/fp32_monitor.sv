class fp32_monitor extends uvm_monitor;

    `uvm_component_utils(fp32_monitor)

    virtual fp32_if vif;

    uvm_analysis_port #(fp32_transaction) ap;


    function new(string name, uvm_component parent);
        super.new(name, parent);

        ap = new("ap", this);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual fp32_if)::get(
                this,
                "",
                "vif",
                vif
            )) begin
            `uvm_fatal("NOVIF", "Virtual interface not found")
        end

    endfunction


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

endclass
