class art_agent extends uvm_agent;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    `uvm_component_utils_begin(art_agent)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_component_utils_end

    art_monitor     monitor;
    art_driver      driver;
    art_sequencer   sequencer;

    uvm_analysis_port#(art_packet) item_from_monitor_port;

    function new (string name, uvm_component parent);
        super.new(name, parent);
        item_from_monitor_port = new("item_from_monitor_port", this);
    endfunction: new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);

        monitor      = art_monitor::type_id::create("monitor", this);
        if (is_active) begin
            sequencer    = art_sequencer::type_id::create("sequencer", this);
            driver       = art_driver::type_id::create("driver", this);
        end
    endfunction: build_phase

    function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);

        item_from_monitor_port.connect(monitor.item_collected_port);
        
        if (is_active) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction: connect_phase

    function void start_of_simulation_phase (uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info(get_type_name(), "Simulation initialized", UVM_HIGH)
    endfunction: start_of_simulation_phase

endclass: art_agent
