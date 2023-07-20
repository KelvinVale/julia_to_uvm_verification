class art_sequencer extends uvm_sequencer#(art_packet);
    `uvm_component_utils(art_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

endclass: art_sequencer
