package kelvin_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef uvm_config_db#(virtual interface kelvin_if) kelvin_vif_config;
    typedef virtual interface kelvin_if kelvin_vif;

    `include "kelvin_packet.sv"
    `include "kelvin_sequence_lib.sv"
    `include "kelvin_sequencer.sv"
    `include "kelvin_monitor.sv"
    `include "kelvin_driver.sv"
    `include "kelvin_agent.sv"

endpackage: kelvin_pkg
