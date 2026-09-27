`timescale 1ns / 1ps

module sonar_control_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        user_trigger,
    input  wire [7:0]  sensor_turbidity,
    output reg  [31:0] cfg_start_ftw,
    output reg  [31:0] cfg_delta_ftw,
    output reg  [19:0] cfg_duration,
    output reg  [7:0]  cfg_amplitude,
    output reg         dds_ping_req
);

    // Dynamic Parameter Sets
   // 1. CLEAR WATER: 400 kHz - 500 kHz | 1.0 ms | 60% Power
localparam [31:0] FTW_START_CLEAR = 32'd13743895; // (400k * 2^32) / 125M
localparam [31:0] DELTA_FTW_CLEAR = 32'd27;        // (100k * 2^32) / (1ms * 125M^2)
localparam [19:0] DUR_CLEAR       = 20'd125_000;   // 1.0 ms * 125 MHz
localparam [7:0]  AMP_CLEAR       = 8'd153;

// 2. MIXED WATER: 200 kHz - 300 kHz | 1.5 ms | 80% Power
localparam [31:0] FTW_START_MIXED = 32'd6871948;  // (200k * 2^32) / 125M
localparam [31:0] DELTA_FTW_MIXED = 32'd19;        // (100k * 2^32) / (1.5ms * 125M^2)
localparam [19:0] DUR_MIXED       = 20'd187_500;   // 1.5 ms * 125 MHz
localparam [7:0]  AMP_MIXED       = 8'd204;

// 3. MUDDY WATER: 80 kHz - 120 kHz  | 2.0 ms | 100% Full Power
localparam [31:0] FTW_START_MUDDY = 32'd2748779;  // (80k * 2^32) / 125M
localparam [31:0] DELTA_FTW_MUDDY = 32'd5;         // (40k * 2^32) / (2.0ms * 125M^2)
localparam [19:0] DUR_MUDDY       = 20'd250_000;   // 2.0 ms * 125 MHz
localparam [7:0]  AMP_MUDDY       = 8'd255;

    reg trigger_q;
    wire trigger_edge = user_trigger & ~trigger_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trigger_q       <= 1'b0;
            dds_ping_req    <= 1'b0;
            cfg_start_ftw   <= 32'd0;
            cfg_delta_ftw   <= 32'd0;
            cfg_duration    <= 20'd0;
            cfg_amplitude   <= 8'd0;
        end else begin
            trigger_q    <= user_trigger;
            dds_ping_req <= 1'b0;

            if (trigger_edge) begin
                dds_ping_req <= 1'b1;
                
                if (sensor_turbidity < 85) begin
                    cfg_start_ftw <= FTW_START_CLEAR;
                    cfg_delta_ftw <= DELTA_FTW_CLEAR;
                    cfg_duration  <= DUR_CLEAR;
                    cfg_amplitude <= AMP_CLEAR;
                end else if (sensor_turbidity < 170) begin
                    cfg_start_ftw <= FTW_START_MIXED;
                    cfg_delta_ftw <= DELTA_FTW_MIXED;
                    cfg_duration  <= DUR_MIXED;
                    cfg_amplitude <= AMP_MIXED;
                end else begin
                    cfg_start_ftw <= FTW_START_MUDDY;
                    cfg_delta_ftw <= DELTA_FTW_MUDDY;
                    cfg_duration  <= DUR_MUDDY;
                    cfg_amplitude <= AMP_MUDDY;
                end
            end
        end
    end

endmodule