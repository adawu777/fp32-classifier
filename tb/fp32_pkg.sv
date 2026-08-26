package fp32_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"


    // ============================================================
    // FP32 Class Definitions
    // ============================================================

    localparam logic [2:0] CLASS_ZERO      = 3'b000;
    localparam logic [2:0] CLASS_SUBNORMAL = 3'b001;
    localparam logic [2:0] CLASS_NORMAL    = 3'b010;
    localparam logic [2:0] CLASS_INFINITY  = 3'b011;
    localparam logic [2:0] CLASS_NAN       = 3'b100;


    // ============================================================
    // UVM Classes
    // ============================================================

    `include "fp32_transaction.sv"
    `include "fp32_sequence.sv"
    `include "fp32_driver.sv"
    `include "fp32_monitor.sv"
    `include "fp32_scoreboard.sv"


endpackage