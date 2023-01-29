class kelvin_sequencer extends uvm_sequencer#(kelvin_packet);
    `uvm_component_utils(kelvin_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

endclass: kelvin_sequencer
