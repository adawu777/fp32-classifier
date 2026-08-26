class fp32_env extends uvm_env;

    `uvm_component_utils(fp32_env)

    fp32_agent      agent;
    fp32_scoreboard scoreboard;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent = fp32_agent::type_id::create(
            "agent",
            this
        );

        scoreboard = fp32_scoreboard::type_id::create(
            "scoreboard",
            this
        );

    endfunction


    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        agent.monitor.ap.connect(
            scoreboard.analysis_export
        );

    endfunction

endclass