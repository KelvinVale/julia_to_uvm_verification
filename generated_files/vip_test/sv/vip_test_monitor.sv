class vip_test_monitor extends uvm_monitor;
    `uvm_component_utils(vip_test_monitor)

    vip_test_vif vif;
    vip_test_packet pkt;
    int num_pkt_col;

    uvm_analysis_port#(vip_test_packet) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        num_pkt_col = 0;
        item_collected_port = new("item_collected_port", this);
    endfunction: new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        if(vip_test_vif_config::get(this, "", "vif", vif))
            `uvm_info("VIP_TEST MONITOR", "Virtual interface was successfully get!", UVM_MEDIUM)
        else
            `uvm_error("VIP_TEST MONITOR", "None interface was setted!")        
    endfunction: build_phase

    virtual task run_phase (uvm_phase phase);
        super.run_phase(phase);
        @(negedge vif.rst_n);
        @(posedge vif.rst_n);

        `uvm_info("VIP_TEST MONITOR", "Reset dropped", UVM_MEDIUM)

        forever begin
            pkt = vip_test_packet::type_id::create("pkt", this);

            // concurrent blocks for packet driving and transaction recording
            fork
                // collect packet
                begin
                    // collect packet from interface
                    vif.collect_packet(pkt);
                end

                // Start transaction recording at start of packet (vif.monstart triggered from interface.collect_packet())
                begin
                    @(posedge vif.monstart) void'(begin_tr(pkt, "VIP_TEST_monitor_Packet"));
                end
            join

            end_tr(pkt);
            `uvm_info("VIP_TEST MONITOR", $sformatf("Packet Collected:\n%s", pkt.convert2string()), UVM_LOW)
            item_collected_port.write(pkt);
            num_pkt_col++;
        end
    endtask : run_phase

    function void start_of_simulation_phase (uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info("VIP_TEST MONITOR", "Simulation initialized", UVM_HIGH)
    endfunction: start_of_simulation_phase

    function void report_phase(uvm_phase phase);
        `uvm_info("VIP_TEST MONITOR", $sformatf("Report: VIP_TEST MONITOR collected %0d packets", num_pkt_col), UVM_LOW)
    endfunction : report_phase
endclass: vip_test_monitor
