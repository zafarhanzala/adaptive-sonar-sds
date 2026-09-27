`timescale 1ns / 1ps

module sonar_payload_top #(
    parameter PHASE_WIDTH    = 32,
    parameter LUT_ADDR_WIDTH = 10,
    parameter DAC_DATA_WIDTH = 12
)(
    input  wire                      clk,              // 100 MHz System Clock (PYNQ-Z2 Fabric)
    input  wire                      rst_n,            // Active-low asynchronous reset
    
    // User / Sensor Interface
    input  wire                      user_trigger,     // Pushbutton trigger to fire sonar ping
    input  wire [7:0]                sensor_turbidity, // 8-bit sensor reading (ADC/Potentiometer)
    
    // Status Indicators (e.g., Onboard LEDs)
    output wire                      led_transmitting, // High when ping is active
    output wire                      led_ping_done,    // 1-cycle pulse flag on completion
    output wire [1:0]                led_mode,         // 00: Clear, 01: Mixed, 10: Muddy
    
    // Parallel DAC Interface (Pmod Header / R-2R Ladder Network)
    output reg  [DAC_DATA_WIDTH-1:0] dac_data
);

    // Internal Interconnects
    wire [31:0]               start_ftw;
    wire [31:0]               delta_ftw;
    wire [19:0]               pulse_duration;
    wire [7:0]                amplitude_scale;
    wire                      dds_trig;
    wire                      tx_active;
    wire                      tx_done;
    
    wire [LUT_ADDR_WIDTH-1:0] lut_addr;
    wire [DAC_DATA_WIDTH-1:0] raw_sine_sample;
    
    // Status Wiring
    assign led_transmitting = tx_active;
    assign led_ping_done    = tx_done;
    assign led_mode         = (sensor_turbidity < 85)  ? 2'b00 :
                              (sensor_turbidity < 170) ? 2'b01 : 2'b10;

    // 1. Environmental Sensor & Adaptation Logic
    sonar_control_unit u_control_unit (
        .clk(clk),
        .rst_n(rst_n),
        .user_trigger(user_trigger),
        .sensor_turbidity(sensor_turbidity),
        .cfg_start_ftw(start_ftw),
        .cfg_delta_ftw(delta_ftw),
        .cfg_duration(pulse_duration),
        .cfg_amplitude(amplitude_scale),
        .dds_ping_req(dds_trig)
    );

    // 2. Direct Digital Synthesis (DDS) LFM Chirp Engine
    dds_lfm_chirp #(
        .PHASE_WIDTH(PHASE_WIDTH),
        .LUT_ADDR_WIDTH(LUT_ADDR_WIDTH)
    ) u_dds_core (
        .clk(clk),
        .rst_n(rst_n),
        .start_ping(dds_trig),
        .cfg_start_ftw(start_ftw),
        .cfg_delta_ftw(delta_ftw),
        .cfg_duration(pulse_duration),
        .lut_address(lut_addr),
        .transmitting(tx_active),
        .ping_done(tx_done)
    );

    // 3. Waveform Look-Up Table (Sine BRAM)
    sine_lut_bram #(
        .ADDR_WIDTH(LUT_ADDR_WIDTH),
        .DATA_WIDTH(DAC_DATA_WIDTH)
    ) u_sine_memory (
        .clk(clk),
        .en(tx_active),
        .addr(lut_addr),
        .dout(raw_sine_sample)
    );

    // 4. Amplitude Scaling, Output Stage & Latency Alignment
    localparam [DAC_DATA_WIDTH-1:0] DAC_MIDPOINT = (1 << (DAC_DATA_WIDTH - 1));
    
    reg signed [12:0] centered_sample;
    reg signed [20:0] scaled_sample;
    
    // 4-stage shift register to delay tx_active alongside the data pipeline
    reg [3:0] tx_active_pipe;
    wire      dac_valid = tx_active_pipe[3]; // The fully delayed enable signal

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            centered_sample <= 13'sd0;
            scaled_sample   <= 21'sd0;
            dac_data        <= DAC_MIDPOINT;
            tx_active_pipe  <= 4'd0;
        end else begin
            // Shift register: ingest the raw tx_active and shift it down
            tx_active_pipe <= {tx_active_pipe[2:0], tx_active};

            // Data Pipeline Stage 1 (Matches tx_active_pipe[0])
            // BRAM read happens here, raw_sine_sample is now valid
            
            // Data Pipeline Stage 2 (Matches tx_active_pipe[1])
            centered_sample <= $signed({1'b0, raw_sine_sample}) - $signed({1'b0, DAC_MIDPOINT});
            
            // Data Pipeline Stage 3 (Matches tx_active_pipe[2])
            scaled_sample   <= centered_sample * $signed({1'b0, amplitude_scale});
            
            // Data Pipeline Stage 4 (Matches tx_active_pipe[3] / dac_valid)
            if (dac_valid) begin
                dac_data <= (scaled_sample >>> 8) + DAC_MIDPOINT;
            end else begin
                dac_data <= DAC_MIDPOINT; // Quiescent baseline
            end
        end
       end 
endmodule