module top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // VIP imports - begin
        import vip_test_pkg::*;
        import kelvin_pkg::*;
        import art_pkg::*;
    // VIP imports - end

    `include "tests.sv"

    bit clk, rst_n;
    bit run_clock;

    // Virtual interfaces instances - begin
        vip_test_if vif_vip_test(.clk(clk), .rst_n(rst_n));
        kelvin_if vif_kelvin(.clk(clk), .rst_n(rst_n));
        art_if vif_art(.clk(clk), .rst_n(rst_n));
    // Virtual interfaces instances - end


    stub dut(
        .clk(clk),
        .rst_n(rst_n),
        // Sgnals from vip_test's interface - begin
            .ready_o(vif_vip_test.ready_o),
            .valid_i(vif_vip_test.valid_i),
            .data_i(vif_vip_test.data_i),
            .data_o(vif_vip_test.data_o),
        // Sgnals from vip_test's interface - end

        // Sgnals from kelvin's interface - begin
            .kelvin_ready_o(vif_kelvin.kelvin_ready_o),
            .kelvin_valid_i(vif_kelvin.kelvin_valid_i),
            .kelvin_data_i(vif_kelvin.kelvin_data_i),
            .kelvin_data_o(vif_kelvin.kelvin_data_o),
        // Sgnals from kelvin's interface - end

        // Sgnals from art's interface - begin
            .art_ready_o(vif_art.art_ready_o),
            .art_valid_i(vif_art.art_valid_i),
            .art_data_i(vif_art.art_data_i),
            .art_data_o(vif_art.art_data_o)
        // Sgnals from art's interface - end
        );

    initial begin
        clk = 0;
        rst_n = 1;
        #3 rst_n = 0;
        #3 rst_n = 1;
    end
    always #2 clk=~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;

        // Virtual interfaces send to VIPs - begin
            vip_test_vif_config::set(null,"uvm_test_top.agent_vip_test.*","vif",vif_vip_test);
            kelvin_vif_config::set(null,"uvm_test_top.agent_kelvin.*","vif",vif_kelvin);
            art_vif_config::set(null,"uvm_test_top.agent_art.*","vif",vif_art);
        // Virtual interfaces instances - end

        run_test("random_test");
    end

endmodule: top
