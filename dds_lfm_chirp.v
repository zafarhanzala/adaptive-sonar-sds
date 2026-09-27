`timescale 1ns / 1ps

module dds_lfm_chirp #(
    parameter PHASE_WIDTH    = 32,      // 32-bit phase accumulator resolution
    parameter LUT_ADDR_WIDTH = 10       // 10-bit address for 1024-entry Sine LUT
)(
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Control & Trigger Interface
    input  wire                      start_ping,       // 1-cycle trigger pulse
    
    // Dynamic Spectral Configuration (Driven by Sensor/ADC Mapping Logic)
    input  wire [PHASE_WIDTH-1:0]    cfg_start_ftw,    // Start Frequency Tuning Word (f_start)
    input  wire [PHASE_WIDTH-1:0]    cfg_delta_ftw,    // Frequency step added per cycle (Chirp rate)
    input  wire [19:0]               cfg_duration,     // Total active pulse duration in clock cycles
    
    // Waveform Phase Output to LUT
    output wire [LUT_ADDR_WIDTH-1:0] lut_address,
    output reg                       transmitting,
    output reg                       ping_done
);

    // Internal Registers
    reg [PHASE_WIDTH-1:0] phase_acc;
    reg [PHASE_WIDTH-1:0] current_ftw;
    reg [PHASE_WIDTH-1:0] active_delta_ftw;
    reg [19:0]            chirp_timer;
    reg [19:0]            active_duration;

    // The top LUT_ADDR_WIDTH bits of the phase accumulator address the Sine BRAM
    assign lut_address = phase_acc[PHASE_WIDTH-1 : PHASE_WIDTH-LUT_ADDR_WIDTH];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc        <= {PHASE_WIDTH{1'b0}};
            current_ftw      <= {PHASE_WIDTH{1'b0}};
            active_delta_ftw <= {PHASE_WIDTH{1'b0}};
            chirp_timer      <= 20'd0;
            active_duration  <= 20'd0;
            transmitting     <= 1'b0;
            ping_done        <= 1'b0;
        end else begin
            // Default pulse state
            ping_done <= 1'b0;

            if (start_ping && !transmitting) begin
                // Latch configuration parameters dynamically on trigger
                transmitting     <= 1'b1;
                phase_acc        <= {PHASE_WIDTH{1'b0}};
                chirp_timer      <= 20'd0;
                current_ftw      <= cfg_start_ftw;
                active_delta_ftw <= cfg_delta_ftw;
                active_duration  <= cfg_duration;
            end else if (transmitting) begin
                if (chirp_timer < active_duration) begin
                    // Dual-accumulation: update phase and sweep instantaneous frequency
                    phase_acc        <= phase_acc + current_ftw;
                    current_ftw      <= current_ftw + active_delta_ftw;
                    chirp_timer      <= chirp_timer + 1'b1;
                end else begin
                    // Transmission complete
                    transmitting     <= 1'b0;
                    ping_done        <= 1'b1;
                    phase_acc        <= {PHASE_WIDTH{1'b0}};
                    current_ftw      <= {PHASE_WIDTH{1'b0}};
                    active_delta_ftw <= {PHASE_WIDTH{1'b0}};
                end
            end
        end
    end

endmodule