package art_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef uvm_config_db#(virtual interface art_if) art_vif_config;
    typedef virtual interface art_if art_vif;

    `include "art_packet.sv"
    `include "art_sequence_lib.sv"
    `include "art_sequencer.sv"
    `include "art_driver.sv"
    `include "art_agent.sv"

endpackage: art_pkg
