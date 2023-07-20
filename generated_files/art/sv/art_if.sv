interface art_if (input clk, input rst_n );
    import uvm_pkg::*;    
    `include "uvm_macros.svh"
    import art_pkg::*;

    // Interface Signals - Begin
    logic       art_ready_o;
    logic       art_valid_i;
    logic [7:0] art_data_i;
    logic [7:0] art_data_o;
    // Interface Signals - End

    // signal for transaction recording
    bit monstart, drvstart;

    task art_reset();
        @(negedge rst_n);
        monstart = 0;
        drvstart = 0;
        disable send_to_dut;
    endtask

    // Gets a packet and drive it into the DUT
    task send_to_dut(art_packet req);
        // Logic to start recording transaction

        // trigger for transaction recording
        #1;
        drvstart = 1'b1;

        // Driver logic 
        `uvm_info("ART INTERFACE", req.convert2string(), UVM_HIGH)

        // Reset trigger
        drvstart = 1'b0;
    endtask : send_to_dut

    // Collect Packets
    task collect_packet(art_packet req);
        // Logic to start recording transaction

        // trigger for transaction recording
        monstart = 1'b1;

        // Driver logic 

        // Reset trigger
        monstart = 1'b0;
    endtask : collect_packet

endinterface : art_if
