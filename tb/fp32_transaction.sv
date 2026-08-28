class fp32_transaction extends uvm_sequence_item;

    rand logic [31:0] fp32;

    rand bit [2:0] class_sel;

    logic [2:0] class_type;

    constraint c_class_sel {
    class_sel dist {
        CLASS_ZERO      := 20,
        CLASS_SUBNORMAL := 20,
        CLASS_NORMAL    := 20,
        CLASS_INFINITY  := 20,
        CLASS_NAN       := 20
    };
    }

   `uvm_object_utils_begin(fp32_transaction)
    `uvm_field_int(fp32,       UVM_ALL_ON)
    `uvm_field_int(class_sel,  UVM_ALL_ON)
    `uvm_field_int(class_type, UVM_ALL_ON)
`uvm_object_utils_end

    function new(string name = "fp32_transaction");
        super.new(name);
    endfunction

    constraint c_zero {

    if (class_sel == CLASS_ZERO) {
        fp32[30:23] == 8'h00;
        fp32[22:0]  == 23'h0;
    }

    }    

    constraint c_subnormal {

    if (class_sel == CLASS_SUBNORMAL) {
        fp32[30:23] == 8'h00;
        fp32[22:0]  != 23'h0;
    }

    }

    constraint c_normal {

    if (class_sel == CLASS_NORMAL) {
        fp32[30:23] inside {[8'h01 : 8'hFE]};
    }

    }

    constraint c_infinity {

    if (class_sel == CLASS_INFINITY) {
        fp32[30:23] == 8'hFF;
        fp32[22:0]  == 23'h0;
    }

    }

    constraint c_nan {

    if (class_sel == CLASS_NAN) {
        fp32[30:23] == 8'hFF;
        fp32[22:0]  != 23'h0;
    }

    }


endclass