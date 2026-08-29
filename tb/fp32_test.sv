class fp32_test extends uvm_test;

    `uvm_component_utils(fp32_test)

    fp32_env env;


    // ========================================================
    // Constructor
    // ========================================================
    function new(
        string name = "fp32_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ========================================================
    // Build Phase
    // ========================================================
    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env = fp32_env::type_id::create(
            "env",
            this
        );

    endfunction


    // ========================================================
    // Run Phase
    // ========================================================
    task run_phase(uvm_phase phase);

        fp32_sequence          random_seq;
        fp32_boundary_sequence boundary_seq;


        phase.raise_objection(this);


        // ----------------------------------------------------
        // 1. Constrained-Random Test
        // ----------------------------------------------------
        `uvm_info(
            "TEST",
            "Starting constrained-random FP32 sequence",
            UVM_LOW
        )

        random_seq =
            fp32_sequence::type_id::create("random_seq");

        random_seq.start(
            env.agent.sequencer
        );


        // ----------------------------------------------------
        // 2. Directed Boundary Test
        // ----------------------------------------------------
        `uvm_info(
            "TEST",
            "Starting FP32 boundary sequence",
            UVM_LOW
        )

        boundary_seq =
            fp32_boundary_sequence::type_id::create(
                "boundary_seq"
            );

        boundary_seq.start(
            env.agent.sequencer
        );


        // ----------------------------------------------------
        // Test Complete
        // ----------------------------------------------------
        `uvm_info(
            "TEST",
            "All FP32 verification sequences completed",
            UVM_LOW
        )


        phase.drop_objection(this);

    endtask


endclass