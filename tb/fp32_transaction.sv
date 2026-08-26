class fp32_transaction extends uvm_sequence_item;

    rand logic [31:0] fp32;

    `uvm_object_utils(fp32_transaction)

    function new(string name = "fp32_transaction");
        super.new(name);
    endfunction

endclass