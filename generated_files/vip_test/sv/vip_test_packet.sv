class vip_test_packet extends uvm_sequence_item;
    rand bit [7:0] data_to_send;
         bit [7:0] data_received;

    `uvm_object_utils_begin(vip_test_packet)
        `uvm_field_int(data_to_send, UVM_ALL_ON)
        `uvm_field_int(data_received, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="vip_test_packet");
        super.new();
    endfunction: new

    // Type your constraints!

    function string convert2string();
        string string_aux;

        string_aux = {string_aux, "\n***************************\n"};
        string_aux = {string_aux, $sformatf("** data_to_send value: %2h\n", data_to_send)};
        string_aux = {string_aux, $sformatf("** data_received value: %2h\n", data_received)};

        string_aux = {string_aux, "***************************"};
        return string_aux;
    endfunction: convert2string

    // function void post_randomize();
    // endfunction: post_randomize

endclass: vip_test_packet
