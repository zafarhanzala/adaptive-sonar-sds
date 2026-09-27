`timescale 1ns / 1ps

module sonar_pynqz2_top (
    input  wire       sysclk,      // PYNQ-Z2 125 MHz Board Clock (Pin H16)
    input  wire       btn0,        // Physical Ping Trigger Pushbutton (Pin D19)
    input  wire       sw0,         // Environment Mode Select Bit 0 (Pin M20)
    input  wire       sw1,         // Environment Mode Select Bit 1 (Pin M19)
    output wire [7:0] ar_dac,      // 8-bit Output to R-2R Ladder (AR0-AR7: T14 to U17)
    output wire       dso_trigger  // Dedicated Scope Sync/Trigger Pulse (AR8: W18)
);

    // -------------------------------------------------------------------------
    // 1. Power-On Reset (POR) Generator
    // -------------------------------------------------------------------------
    // Holds active-low reset low for 256 cycles after bitstream configuration
    reg [7:0] por_cnt = 8'd0;
    reg       sys_rst_n = 1'b0;

    always @(posedge sysclk) begin
        if (por_cnt < 8'hFF) begin
            por_cnt   <= por_cnt + 1'b1;
            sys_rst_n <= 1'b0;
        end else begin
            sys_rst_n <= 1'b1;
        end
    end

    // -------------------------------------------------------------------------
    // 2. Pushbutton Debouncing Logic (10 ms at 125 MHz)
    // -------------------------------------------------------------------------
    reg [20:0] btn_debounce_cnt = 21'd0;
    reg        btn_clean        = 1'b0;

    always @(posedge sysclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            btn_debounce_cnt <= 21'd0;
            btn_clean        <= 1'b0;
        end else begin
            if (btn0 == btn_clean) begin
                btn_debounce_cnt <= 21'd0;
            end else begin
                btn_debounce_cnt <= btn_debounce_cnt + 1'b1;
                if (btn_debounce_cnt >= 21'd1_250_000) begin
                    btn_clean        <= btn0;
                    btn_debounce_cnt <= 21'd0;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // 3. Environmental Sensor Mapping (Switches to Turbidity Values)
    // -------------------------------------------------------------------------
    wire [7:0] simulated_turbidity;
    assign simulated_turbidity = ({sw1, sw0} == 2'b00) ? 8'd50  :  // Clear  (< 85)
                                 ({sw1, sw0} == 2'b01) ? 8'd120 :  // Mixed  (85 - 169)
                                                         8'd200;   // Muddy  (>= 170)

    // -------------------------------------------------------------------------
    // 4. Core Sonar Payload Core Instantiation
    // -------------------------------------------------------------------------
    wire [11:0] internal_dac_data;
    wire        tx_active_sig;

    sonar_payload_top #(
        .PHASE_WIDTH(32),
        .LUT_ADDR_WIDTH(10),
        .DAC_DATA_WIDTH(12)
    ) payload_core (
        .clk(sysclk),
        .rst_n(sys_rst_n),
        .user_trigger(btn_clean),
        .sensor_turbidity(simulated_turbidity),
        .led_transmitting(tx_active_sig),
        .led_ping_done(),
        .led_mode(),
        .dac_data(internal_dac_data)
    );

    // -------------------------------------------------------------------------
    // 5. Physical Outputs
    // -------------------------------------------------------------------------
    // Map the most significant 8 bits to the R-2R ladder
    assign ar_dac      = internal_dac_data[11:4];
    
    // Connect transmitting status to the DSO sync pin
    assign dso_trigger = tx_active_sig;

endmodule