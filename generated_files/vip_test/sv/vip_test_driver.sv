class vip_test_driver extends uvm_driver#(vip_test_packet);
    `uvm_component_utils(vip_test_driver)

    vip_test_vif vif;
    int num_sent;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        num_sent = 0;
    endfunction: new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        if(vip_test_vif_config::get(this, "", "vif", vif))
            `uvm_info("VIP_TEST DRIVER", "Virtual interface was successfully get!", UVM_MEDIUM)
        else
            `uvm_error("VIP_TEST DRIVER", "None interface was setted!")        
    endfunction: build_phase

    virtual task run_phase (uvm_phase phase);
        super.run_phase(phase);
        fork
            get_and_drive();
            reset_signals();
        join
    endtask: run_phase

    task get_and_drive();
        @(negedge vif.rst_n);
        @(posedge vif.rst_n);

        `uvm_info("VIP_TEST DRIVER", "Reset dropped", UVM_MEDIUM)

        forever begin
            // Get new item from the sequencer
            seq_item_port.get_next_item(req);
            `uvm_info("VIP_TEST DRIVER", $sformatf("Packet is:%s", req.convert2string()), UVM_LOW)

            // concurrent blocks for packet driving and transaction recording
            fork
                // send packet
                begin
                    // send packet via interface
                    vif.send_to_dut(req);
                end

                // Start transaction recording at start of packet (vif.drvstart triggered from interface.send_to_dut())
                begin
                    //@(posedge vif.drvstart) void'(begin_tr(req, "VIP_TEST_DRIVER_Packet"));
                end
            join

            //end_tr(req);
            num_sent++;
            seq_item_port.item_done();
        end
    endtask : get_and_drive

    task reset_signals();
        forever begin
            vif.vip_test_reset();
            `uvm_info("VIP_TEST DRIVER", "Reset done", UVM_NONE)
        end
    endtask : reset_signals

    function void start_of_simulation_phase (uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info("VIP_TEST DRIVER", "Simulation initialized", UVM_HIGH)
    endfunction: start_of_simulation_phase

    function void report_phase(uvm_phase phase);
        `uvm_info("VIP_TEST DRIVER", $sformatf("Report: VIP_TEST DRIVER sent %0d packets", num_sent), UVM_LOW)
    endfunction : report_phase
endclass: vip_test_driver
