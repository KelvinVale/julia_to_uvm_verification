class vip_test_sequencer extends uvm_sequencer#(vip_test_packet);
    `uvm_component_utils(vip_test_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

endclass: vip_test_sequencer
