class fp32_test extends uvm_test;

    `uvm_component_utils(fp32_test)

    fp32_env env;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = fp32_env::type_id::create(
            "env",
            this
        );

    endfunction


    task run_phase(uvm_phase phase);

        fp32_sequence seq;

        phase.raise_objection(this);

        seq = fp32_sequence::type_id::create("seq");

        seq.start(env.agent.sequencer);

        phase.drop_objection(this);

    endtask

endclass