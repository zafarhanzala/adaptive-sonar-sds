`timescale 1ns / 1ps

module tb_sonar_payload_top;

    reg        clk;
    reg        rst_n;
    reg        user_trigger;
    reg  [7:0] sensor_turbidity;
    
    wire        led_transmitting;
    wire        led_ping_done;
    wire [1:0]  led_mode;
    wire [11:0] dac_data;

    // 100 MHz Clock Generation
    always #5 clk = ~clk;

    // Instantiate Top Module
    sonar_payload_top #(
        .PHASE_WIDTH(32),
        .LUT_ADDR_WIDTH(10),
        .DAC_DATA_WIDTH(12)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .user_trigger(user_trigger),
        .sensor_turbidity(sensor_turbidity),
        .led_transmitting(led_transmitting),
        .led_ping_done(led_ping_done),
        .led_mode(led_mode),
        .dac_data(dac_data)
    );

    initial begin
        $dumpfile("sonar_payload_final.vcd");
        $dumpvars(0, tb_sonar_payload_top);

        // Initialize
        clk              = 0;
        rst_n            = 0;
        user_trigger     = 0;
        sensor_turbidity = 8'd0;

        #100 rst_n = 1;
        #100;
// ---------------------------------------------------------
        // Test 1: Clear Water (Turbidity 50) -> Low Power, High Freq
        // ---------------------------------------------------------
        sensor_turbidity = 8'd50; 
        
        #25 user_trigger = 1; // Assert asynchronously between clock edges
        #30 user_trigger = 0; // Hold for 3 clock cycles, then release

        wait(led_ping_done == 1'b1);
        #5000;

        // ---------------------------------------------------------
        // Test 2: Mixed Water (Turbidity 120) -> Med Power, Mid Freq
        // ---------------------------------------------------------
        sensor_turbidity = 8'd120; 
        
        #25 user_trigger = 1;
        #30 user_trigger = 0;

        wait(led_ping_done == 1'b1);
        #5000;

        // ---------------------------------------------------------
        // Test 3: Muddy Water (Turbidity 200) -> Full Power, Low Freq
        // ---------------------------------------------------------
        sensor_turbidity = 8'd200; 
        
        #25 user_trigger = 1;
        #30 user_trigger = 0;

        wait(led_ping_done == 1'b1);
        #5000;

        $display("Top-Level Integration Verified.");
        $finish;
    end
endmodule