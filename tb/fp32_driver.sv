class fp32_driver extends uvm_driver #(fp32_transaction);

    `uvm_component_utils(fp32_driver)

    virtual fp32_if vif;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual fp32_if)::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "NO_VIF",
                "Virtual interface not found"
            )

        end
    endfunction


    task run_phase(uvm_phase phase);

        forever begin

            seq_item_port.get_next_item(req);

            vif.fp32 = req.fp32;

            #1;

            seq_item_port.item_done();

        end

    endtask

endclass