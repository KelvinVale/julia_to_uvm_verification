open_file(dir) = open(str_aux->read(str_aux, String), dir)
it_has_a_char(str_) = begin
    cont = 1
    for x in str_
        if(Int(x) >= 33 && Int(x) <= 125) #Verify if the char is between A and z in ASCII.
            return true, cont
        end
        cont += 1
    end
    return false, 0
end
output_file_setup(dir; reset_folder=true) = begin
    if isdir(dir)
        if (reset_folder)
            rm(dir, recursive=true, force = true)
            mkdir(dir)
        end
    else
        mkdir(dir)
    end
end
write_file(file_dir, txt_string) = begin
    open(file_dir, "w") do io
        write(io, txt_string)
    end;
end
delete_item(vec, item) = setdiff!(vec, [item])
function_dict = Dict()

include("code_generate_parameters.jl")

pkg_vec = ["sequence_lib", "sequencer", "packet", "agent", "monitor", "driver"]
vec_classes = ["sequence_lib", "sequencer", "packet", "pkg", "if", "agent", "driver", "monitor"]


gen_long_str(vec, tabs, line_gen_func) = begin
    str_aux = ""
    for x in vec
        str_aux *= line_gen_func(x, tabs)
    end
    return str_aux
end


# *******************
# Packet Codes!!!!!
# ***********************************
# Forma do vetor para gerar o packet:
#  is_rand? | type | length | name
# 
# Ex:
# vec = [
#   [true, "bit", "[7:0]", "addr"],
#   [false, "bit", "[7:0]", "data"],
#   [false, "bit", "1", "value"],
#   [true, "bit", "1", "bit_"]]
# ***********************************
gen_line_convert_to_string(vec, tabs) = "$(tabs)string_aux = {string_aux, \$sformatf(\"** $(vec[4]) value: %2h\\n\", $(vec[4]))};\n"
gen_line_object_utils(vec, tabs) = "$(tabs)`uvm_field_int($(vec[4]), UVM_ALL_ON)\n"
gen_line_instanciate_obj(vec, tabs) = "$(tabs)$((vec[1]) ? "rand" : "    ") $(vec[2]) $((vec[3]=="1") ? "     " : vec[3]) $(vec[4]);\n"

gen_packet_base(prefix_name, vec) = """
    class $(prefix_name)_packet extends uvm_sequence_item;
    $(gen_long_str(vec, "    ", gen_line_instanciate_obj))
        `uvm_object_utils_begin($(prefix_name)_packet)
    $(gen_long_str(vec, "        ", gen_line_object_utils))    `uvm_object_utils_end

        function new(string name="$(prefix_name)_packet");
            super.new();
        endfunction: new

        // Type your constraints!

        function string convert2string();
            string string_aux;

            string_aux = {string_aux, "\\n***************************\\n"};
    $(gen_long_str(vec, "        ", gen_line_convert_to_string))
            string_aux = {string_aux, "***************************"};
            return string_aux;
        endfunction: convert2string

        // function void post_randomize();
        // endfunction: post_randomize

    endclass: $(prefix_name)_packet
    """
# *********************************************************


# *******************
# Package Codes!!!!!
# ***********************************
# Forma do vetor para gerar o pkg:
#  Just [name]
# 
# Ex:
# vec = ["agent", "driver", "monitor", "sequence_lib"]
# ***********************************
priority_dict = Dict(
    "packet" => 1,
    "sequence_lib" => 2,
    "monitor" => 3,
    "sequencer" => 3,
    "driver" => 3,
    "agent" => 4
)
gen_line_include(file_name, tabs) = "$(tabs)`include \"$(file_name).sv\"\n"

vector_to_pattern(prefix_name, vec_in) = begin
    vec_aux = []
    vec_out = []
    for x in vec_in
        push!(vec_aux, [x, priority_dict[lowercase(x)]])
    end

    int_aux = 1
    file_cont = 0
    while (file_cont < length(vec_aux))
        for x in vec_aux
            if x[2] == int_aux 
                push!(vec_out, prefix_name*"_"*lowercase(x[1]))
                file_cont += 1
            end
        end
        int_aux += 1
    end
    return vec_out
end

gen_pkg_base(prefix_name, vec_in) = begin
    vec = vector_to_pattern(prefix_name, vec_in)
    return """
        package $(prefix_name)_pkg;
            import uvm_pkg::*;
            `include "uvm_macros.svh"

            typedef uvm_config_db#(virtual interface $(prefix_name)_if) $(prefix_name)_vif_config;
            typedef virtual interface $(prefix_name)_if $(prefix_name)_vif;

        $(gen_long_str(vec, "    ", gen_line_include))
        endpackage: $(prefix_name)_pkg
        """
    end
# *********************************************************


# *******************
# Sequencer Codes!!!!!
# ***********************************
# Não é necessário um vetor!!!
# ***********************************

gen_sequencer_base(prefix_name, vec) = """
    class $(prefix_name)_sequencer extends uvm_sequencer#($(prefix_name)_packet);
        `uvm_component_utils($(prefix_name)_sequencer)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction: new

    endclass: $(prefix_name)_sequencer
    """
# *********************************************************




# *******************
# Sequence Codes!!!!!
# ***********************************
# Não é necessário um vetor!!!
# ***********************************

gen_sequence_base(prefix_name, vec) = """
    class $(prefix_name)_base_sequence extends uvm_sequence#($(prefix_name)_packet);
        `uvm_object_utils($(prefix_name)_base_sequence)

        function new(string name="$(prefix_name)_base_sequence");
            super.new(name);
        endfunction: new

        task pre_body();
            uvm_phase phase = get_starting_phase();
            phase.raise_objection(this, get_type_name());
            `uvm_info("Sequence", "phase.raise_objection", UVM_HIGH)
        endtask: pre_body

        task post_body();
            uvm_phase phase = get_starting_phase();
            phase.drop_objection(this, get_type_name());
            `uvm_info("Sequence", "phase.drop_objection", UVM_HIGH)
        endtask: post_body
    endclass: $(prefix_name)_base_sequence

    class $(prefix_name)_random_seq extends $(prefix_name)_base_sequence;
        `uvm_object_utils($(prefix_name)_random_seq)

        function new(string name="$(prefix_name)_random_seq");
            super.new(name);
        endfunction: new
        
        virtual task body();
            `uvm_create(req)
                void'(req.randomize());
                // It is possible to put constraints into randomize, like below.
                // void'(req.randomize() with {field_1==value_1; field_2==value_2;});
            `uvm_send(req)
        endtask: body
    endclass: $(prefix_name)_random_seq
    """
# *********************************************************


# *******************
# Interface Codes!!!!!
# ***********************************
# Forma do vetor para gerar a interface:
#  [clock_name , 
#       [reset_name , is_negedge?] , 
#       [[type , length , name] , [] , [] ...] 
#       ]
# 
# Ex:
# signals_if_config = [
#     ["bit", "[7:0]", "addr"],
#     ["bit", "[7:0]", "data"],
#     ["bit", "1", "bit_"],
#     ["logic", "[12:0]", "oioi3"] ]
# vec = ["clock_name", ["reset_name", true], signals_if_config]
# ***********************************
gen_line_if_signal(vec, tabs; end_of_line=";") = "$(tabs)$(vec[1]) $((vec[2]=="1") ? "     " : vec[2]) $(vec[3])$(end_of_line)\n"

gen_if_base(prefix_name, vec) = """
    interface $(prefix_name)_if (input $(vec[1]), input $(vec[2][1]) );
        import uvm_pkg::*;    
        `include "uvm_macros.svh"
        import $(prefix_name)_pkg::*;

        // Interface Signals - Begin
    $(gen_long_str(vec[3], "    ", gen_line_if_signal))    // Interface Signals - End

        // signal for transaction recording
        bit monstart, drvstart;

        task $(prefix_name)_reset();
            @($((vec[2][2]) ? "negedge" : "posedge") $(vec[2][1]));
            monstart = 0;
            drvstart = 0;
            disable send_to_dut;
        endtask

        // Gets a packet and drive it into the DUT
        task send_to_dut($(prefix_name)_packet req);
            // Logic to start recording transaction

            // trigger for transaction recording
            #1;
            drvstart = 1'b1;

            // Driver logic 
            `uvm_info("$(uppercase(prefix_name)) INTERFACE", req.convert2string(), UVM_HIGH)

            // Reset trigger
            drvstart = 1'b0;
        endtask : send_to_dut

        // Collect Packets
        task collect_packet($(prefix_name)_packet req);
            // Logic to start recording transaction

            // trigger for transaction recording
            monstart = 1'b1;

            // Driver logic 

            // Reset trigger
            monstart = 1'b0;
        endtask : collect_packet

    endinterface : $(prefix_name)_if
    """
# *********************************************************


# *******************
# Driver Codes!!!!!
# ***********************************
# Forma do vetor para gerar o driver:
#  [clock_name , [reset_name , is_negedge?] ]
# 
# OBS: Recomendo pegar o vetor da interface. "if_vec[1:2]"
# 
# Ex:
# vec = ["clock_name", ["reset_name", true]]
# ***********************************

gen_driver_base(prefix_name, vec) = """
    class $(prefix_name)_driver extends uvm_driver#($(prefix_name)_packet);
        `uvm_component_utils($(prefix_name)_driver)
    
        $(prefix_name)_vif vif;
        int num_sent;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            num_sent = 0;
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            if($(prefix_name)_vif_config::get(this, "", "vif", vif))
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Virtual interface was successfully get!", UVM_MEDIUM)
            else
                `uvm_error("$(uppercase(prefix_name)) DRIVER", "None interface was setted!")        
        endfunction: build_phase

        virtual task run_phase (uvm_phase phase);
            super.run_phase(phase);
            fork
                get_and_drive();
                reset_signals();
            join
        endtask: run_phase

        task get_and_drive();
            @($((vec[2][2]) ? "negedge" : "posedge") vif.$(vec[2][1]));
            @($((vec[2][2]) ? "posedge" : "negedge") vif.$(vec[2][1]));

            `uvm_info("$(uppercase(prefix_name)) DRIVER", "Reset dropped", UVM_MEDIUM)

            forever begin
                // Get new item from the sequencer
                seq_item_port.get_next_item(req);
                `uvm_info("$(uppercase(prefix_name)) DRIVER", \$sformatf("Packet is:%s", req.convert2string()), UVM_LOW)

                // concurrent blocks for packet driving and transaction recording
                fork
                    // send packet
                    begin
                        // send packet via interface
                        vif.send_to_dut(req);
                    end

                    // Start transaction recording at start of packet (vif.drvstart triggered from interface.send_to_dut())
                    begin
                        //@(posedge vif.drvstart) void'(begin_tr(req, "$(uppercase(prefix_name))_DRIVER_Packet"));
                    end
                join

                //end_tr(req);
                num_sent++;
                seq_item_port.item_done();
            end
        endtask : get_and_drive

        task reset_signals();
            forever begin
                vif.$(prefix_name)_reset();
                `uvm_info("$(uppercase(prefix_name)) DRIVER", "Reset done", UVM_NONE)
            end
        endtask : reset_signals

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) DRIVER", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

        function void report_phase(uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) DRIVER", \$sformatf("Report: $(uppercase(prefix_name)) DRIVER sent %0d packets", num_sent), UVM_LOW)
        endfunction : report_phase
    endclass: $(prefix_name)_driver
    """
# *********************************************************


# *******************
# Monitor Codes!!!!!
# ***********************************
# Forma do vetor para gerar o monitor:
#  [clock_name , [reset_name , is_negedge?] ]
# 
# OBS: Recomendo pegar o vetor da interface. "if_vec[1:2]"
# 
# Ex:
# vec = ["clock_name", ["reset_name", true]]
# ***********************************

gen_monitor_base(prefix_name, vec) = """
    class $(prefix_name)_monitor extends uvm_monitor;
        `uvm_component_utils($(prefix_name)_monitor)
    
        $(prefix_name)_vif vif;
        $(prefix_name)_packet pkt;
        int num_pkt_col;

        uvm_analysis_port#($(prefix_name)_packet) item_collected_port;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            num_pkt_col = 0;
            item_collected_port = new("item_collected_port", this);
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            if($(prefix_name)_vif_config::get(this, "", "vif", vif))
                `uvm_info("$(uppercase(prefix_name)) MONITOR", "Virtual interface was successfully get!", UVM_MEDIUM)
            else
                `uvm_error("$(uppercase(prefix_name)) MONITOR", "None interface was setted!")        
        endfunction: build_phase

        virtual task run_phase (uvm_phase phase);
            super.run_phase(phase);
            @($((vec[2][2]) ? "negedge" : "posedge") vif.$(vec[2][1]));
            @($((vec[2][2]) ? "posedge" : "negedge") vif.$(vec[2][1]));

            `uvm_info("$(uppercase(prefix_name)) MONITOR", "Reset dropped", UVM_MEDIUM)

            forever begin
                pkt = $(prefix_name)_packet::type_id::create("pkt", this);

                // concurrent blocks for packet driving and transaction recording
                fork
                    // collect packet
                    begin
                        // collect packet from interface
                        vif.collect_packet(pkt);
                    end

                    // Start transaction recording at start of packet (vif.monstart triggered from interface.collect_packet())
                    begin
                        @(posedge vif.monstart) void'(begin_tr(pkt, "$(uppercase(prefix_name))_monitor_Packet"));
                    end
                join

                end_tr(pkt);
                `uvm_info("$(uppercase(prefix_name)) MONITOR", \$sformatf("Packet Collected:\\n%s", pkt.convert2string()), UVM_LOW)
                item_collected_port.write(pkt);
                num_pkt_col++;
            end
        endtask : run_phase

        function void start_of_simulation_phase (uvm_phase phase);
            super.start_of_simulation_phase(phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", "Simulation initialized", UVM_HIGH)
        endfunction: start_of_simulation_phase

        function void report_phase(uvm_phase phase);
            `uvm_info("$(uppercase(prefix_name)) MONITOR", \$sformatf("Report: $(uppercase(prefix_name)) MONITOR collected %0d packets", num_pkt_col), UVM_LOW)
        endfunction : report_phase
    endclass: $(prefix_name)_monitor
    """
# *********************************************************


# *******************
# Agent Codes!!!!!
# ***********************************
# Não é necessário um vetor!!!
# ***********************************

gen_agent_base(prefix_name, vec) = """
    class $(prefix_name)_agent extends uvm_agent;
        uvm_active_passive_enum is_active = UVM_ACTIVE;

        `uvm_component_utils_begin($(prefix_name)_agent)
            `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_component_utils_end

        $(prefix_name)_monitor     monitor;
        $(prefix_name)_driver      driver;
        $(prefix_name)_sequencer   sequencer;

        uvm_analysis_port#($(prefix_name)_packet) item_from_monitor_port;

        function new (string name, uvm_component parent);
            super.new(name, parent);
            item_from_monitor_port = new("item_from_monitor_port", this);
        endfunction: new

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);

            monitor      = $(prefix_name)_monitor::type_id::create("monitor", this);
            if (is_active) begin
                sequencer    = $(prefix_name)_sequencer::type_id::create("sequencer", this);
                driver       = $(prefix_name)_driver::type_id::create("driver", this);
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

    endclass: $(prefix_name)_agent
    """
# *********************************************************







# *******************
# Tests Codes!!!!!
# ***********************************
# É necessário um vetor!!!
# stub_if_names = ["vip_test"] Liste o nove das interfaces (VIPs)
# ***********************************
gen_instance_line(vip_name, tabs) = """$(tabs)$(vip_name)_agent agent_$(vip_name);\n"""
gen_creation_line(vip_name, tabs) = """$(tabs)agent_$(vip_name) = $(vip_name)_agent::type_id::create("agent_$(vip_name)", this);\n"""
gen_sequences_config_line(vip_name, tabs) = """$(tabs)uvm_config_wrapper::set(this, "agent_$(vip_name).sequencer.run_phase", "default_sequence", $(vip_name)_random_seq::get_type());\n"""

test_gen() = (!run_test_gen) ? "" : begin
    output_file_setup("generated_files/test_top")
    write_file("generated_files/test_top/test.sv", gen_test_base())
end

gen_test_base() = """
    class base_test extends uvm_test;
        `uvm_component_utils(base_test)

        // VIPs instances - begin
    $( gen_long_str(stub_if_names, "    ", gen_instance_line) )    // VIPs instances - end

        uvm_objection obj;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);

            // VIPs creation - begin
    $( gen_long_str(stub_if_names, "        ", gen_creation_line) )        // VIPs creation - end

            `uvm_info("BASE TEST", "Build phase runnig", UVM_HIGH)
            uvm_config_db#(int)::set(this, "*", "recording_detail", 1);
        endfunction

        function void end_of_elaboration_phase (uvm_phase phase);
            super.end_of_elaboration_phase(phase);
            uvm_top.print_topology();
        endfunction

        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            check_config_usage();
        endfunction

        virtual task run_phase(uvm_phase phase);
            super.run_phase(phase);
            obj = phase.get_objection();
            obj.set_drain_time(this, 200ns);
        endtask: run_phase
    endclass: base_test

    class random_test extends base_test;
        `uvm_component_utils(random_test)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction: new

        function void build_phase(uvm_phase phase);
            // Override packet types, eg:
            //      first_type_name::type_id::set_type_override(second_type_name::get_type());
            super.build_phase(phase);

            // Random sequences config - begin
    $( gen_long_str(stub_if_names, "        ", gen_sequences_config_line) )        // Random sequences config - end
            
        endfunction: build_phase
    endclass: random_test
    """
# *********************************************************


# *******************
# Top Codes!!!!!
# ***********************************
# É necessário ter gerado o STUB para gerar o arquivo stub_parameters.jl!!!!
# ***********************************
gen_import_line(vip_name, tabs) = """$(tabs)import $(vip_name)_pkg::*;\n"""
gen_interfaces_instances_line(vip_name, tabs) = """$(tabs)$(vip_name)_if vif_$(vip_name)(.$(clk_rst_names[1])($(clk_rst_names[1])), .$(clk_rst_names[2][1])($(clk_rst_names[2][1])));\n"""
gen_send_if_to_vip_line(vip_name, tabs) = """$(tabs)$(vip_name)_vif_config::set(null,"uvm_test_top.agent_$(vip_name).*","vif",vif_$(vip_name));\n"""
gen_if_connection_line(signal_name, vip_name, tabs) = """$(tabs).$(signal_name[3])(vif_$(vip_name).$(signal_name[3])),\n"""
gen_top_if_connection_signals(if_vector, tabs) = begin
    str = ""
    for x in if_vector
        str *= "\n$(tabs)// Sgnals from $(x[1])'s interface - begin\n"
        gen_line(signal_name, tabs) = gen_if_connection_line(signal_name, x[1], tabs)
        str *= gen_long_str(x[2], tabs*"    ", gen_line)
        str = (x == if_vector[end]) ? str[1:end-2]*"\n" : str
        str *= "$(tabs)// Sgnals from $(x[1])'s interface - end\n"
    end
    return str
end


top_gen() = (!run_top_gen) ? "" : begin
    include("generated_files/rtl/stub_parameters.jl")
    output_file_setup("generated_files/test_top"; reset_folder=false)
    write_file("generated_files/test_top/top.sv", gen_top_base())
end

gen_top_base() = """
    module top;
        import uvm_pkg::*;
        `include "uvm_macros.svh"

        // VIP imports - begin
    $( gen_long_str(stub_if_names, "        ", gen_import_line) )    // VIP imports - end

        `include "tests.sv"

        bit $(clk_rst_names[1]), $(clk_rst_names[2][1]);
        bit run_clock;

        // Virtual interfaces instances - begin
    $( gen_long_str(stub_if_names, "        ", gen_interfaces_instances_line) )    // Virtual interfaces instances - end


        stub dut(
            .$(clk_rst_names[1])($(clk_rst_names[1])),
            .$(clk_rst_names[2][1])($(clk_rst_names[2][1])),$( gen_top_if_connection_signals(if_vector, "        ") )        );

        initial begin
            $(clk_rst_names[1]) = 0;
            $(clk_rst_names[2][1]) = 1;
            #3 $(clk_rst_names[2][1]) = 0;
            #3 $(clk_rst_names[2][1]) = 1;
        end
        always #2 $(clk_rst_names[1])=~$(clk_rst_names[1]);

        initial begin
            \$dumpfile("dump.vcd");
            \$dumpvars;

            // Virtual interfaces send to VIPs - begin
    $( gen_long_str(stub_if_names, "            ", gen_send_if_to_vip_line) )        // Virtual interfaces instances - end

            run_test("random_test");
        end

    endmodule: top
    """
# *********************************************************








# *******************
# Stub Codes!!!!!
# ***********************************
# É necessário um vetor!!!
# stub_if_names = ["vip_test"] Liste o nove das interfaces (VIPs)
# ***********************************
gen_stub_if_signals_line(vec, tabs) = gen_line_if_signal(vec, tabs; end_of_line=",")
gen_stub_if_signals(if_vector, gen_line, tabs) = begin
    str = ""
    for x in if_vector
        str *= "\n$(tabs)// Sgnals from $(x[1])'s interface - begin\n"
        str *= gen_long_str(x[2], tabs*"    ", gen_line)
        str = (x == if_vector[end]) ? str[1:end-2]*"\n" : str
        str *= "$(tabs)// Sgnals from $(x[1])'s interface - end\n"
    end
    return str
end
stub_parameters_str_file_gen(if_vector, stub_if_names, clk_name, rst_name) = "if_vector = $(if_vector)\nstub_if_names = $(stub_if_names)\nclk_rst_names = $([clk_name, rst_name])"

update_signals_if_config(signals_if_config) = begin
    out_vec = []
    for x in signals_if_config
        if x[3][end-1:end] == "_o"
            push!(out_vec, ["output reg", x[2], x[3]])
        elseif x[3][end-1:end] == "_i"
            push!(out_vec, ["input     ", x[2], x[3]])
        else
            push!(out_vec, ["NOTYPE    ", x[2], x[3]])
        end
    end
    return out_vec
end

get_interface_signals() = begin
    if_gather = []
    item_to_deleat = []
    for x in stub_if_names
        try
            include(pwd()*"/generated_files/"*x*"/parameter_folder/"*x*"_parameters.jl")
            push!(if_gather,[x,update_signals_if_config(signals_if_config)])
        catch
            println("It was not possible to open the VIP '$(x)'")
            push!(item_to_deleat,x) 
        end
    end
    setdiff!(stub_if_names, item_to_deleat)
    return if_gather
end

stub_gen() = (!run_stub_gen) ? "" : begin
    if_vector = get_interface_signals()
    clk_name = if_vec[1]
    rst_name = if_vec[2]

    output_file_setup("generated_files/rtl")
    write_file("generated_files/rtl/stub.sv", gen_stub_base([clk_name, rst_name], if_vector))
    write_file("generated_files/rtl/stub_parameters.jl", stub_parameters_str_file_gen(if_vector, stub_if_names, clk_name, rst_name))
end

gen_stub_base(clk_rst_names, vec) = """
    module stub (input $(clk_rst_names[1]), input $(clk_rst_names[2][1]), $(gen_stub_if_signals(vec, gen_stub_if_signals_line, "    "))    );

        always @(posedge $(clk_rst_names[1]) or $( (clk_rst_names[2][2]) ? "negedge" : "posedge" ) $(clk_rst_names[2][1])) begin
            if($( (clk_rst_names[2][2]) ? "~" : "" )$(clk_rst_names[2][1])) begin
                // Reset logic
            end
            else begin
                // Sequencial logic
            end
        end

        always @(*) begin
            // Combinational logic
        end

    endmodule: stub
    """
# *********************************************************








gen_files(vec_classes, vip_name) = begin
    for class_name in vec_classes
        vec_aux = function_dict[uppercase(class_name)]
        write_file("generated_files/"*vip_name*"/sv/$(vip_name)_$(class_name).sv", vec_aux[1](vip_name, vec_aux[2]))
    end
end

vip_files_gen() = (!run_vip_gen) ? "" : begin
    output_file_setup("generated_files"; reset_folder=reset_generated_files_folder)

    for vip_name in vip_names
        include("VIP_parameters/"*vip_name*"_parameters.jl")

        function_dict[uppercase("packet")] = [gen_packet_base, packet_vec]
        function_dict[uppercase("pkg")] = [gen_pkg_base, pkg_vec]
        function_dict[uppercase("sequencer")] = [gen_sequencer_base,[]]
        function_dict[uppercase("sequence_lib")] = [gen_sequence_base,[]]
        function_dict[uppercase("if")] = [gen_if_base, if_vec]
        function_dict[uppercase("driver")] = [gen_driver_base, if_vec[1:2]]
        function_dict[uppercase("monitor")] = [gen_monitor_base, if_vec[1:2]]
        function_dict[uppercase("agent")] = [gen_agent_base,[]]

        output_file_setup("generated_files/"*vip_name)
        output_file_setup("generated_files/"*vip_name*"/sv")
        output_file_setup("generated_files/"*vip_name*"/parameter_folder")

        gen_files(vec_classes, vip_name)
        write_file("generated_files/"*vip_name*"/parameter_folder/"*vip_name*"_parameters.jl", open_file("VIP_parameters/"*vip_name*"_parameters.jl"))
    end
end



