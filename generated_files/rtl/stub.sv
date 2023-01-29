module stub (input clk, input rst_n, 
    // Sgnals from vip_test's interface - begin
        output reg       ready_o,
        input            valid_i,
        input      [7:0] data_i,
        output reg [7:0] data_o,
    // Sgnals from vip_test's interface - end

    // Sgnals from kelvin's interface - begin
        output reg       kelvin_ready_o,
        input            kelvin_valid_i,
        input      [7:0] kelvin_data_i,
        output reg [7:0] kelvin_data_o
    // Sgnals from kelvin's interface - end
    );

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
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
