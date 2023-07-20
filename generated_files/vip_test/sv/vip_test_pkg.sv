package vip_test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef uvm_config_db#(virtual interface vip_test_if) vip_test_vif_config;
    typedef virtual interface vip_test_if vip_test_vif;

    `include "vip_test_packet.sv"
    `include "vip_test_sequence_lib.sv"
    `include "vip_test_sequencer.sv"
    `include "vip_test_monitor.sv"
    `include "vip_test_driver.sv"
    `include "vip_test_agent.sv"

endpackage: vip_test_pkg
