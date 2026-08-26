class fp32_agent extends uvm_agent;

    `uvm_component_utils(fp32_agent)

    uvm_sequencer #(fp32_transaction) sequencer;
    fp32_driver                       driver;
    fp32_monitor                      monitor;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sequencer = uvm_sequencer #(fp32_transaction)::
                    type_id::create("sequencer", this);

        driver = fp32_driver::
                 type_id::create("driver", this);

        monitor = fp32_monitor::
                  type_id::create("monitor", this);

    endfunction


    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        driver.seq_item_port.connect(
            sequencer.seq_item_export
        );

    endfunction

endclass