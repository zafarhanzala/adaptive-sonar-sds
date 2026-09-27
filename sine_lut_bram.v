`timescale 1ns / 1ps

module sine_lut_bram #(
    parameter ADDR_WIDTH = 10,   // 1024 depth
    parameter DATA_WIDTH = 12    // 12-bit DAC resolution
)(
    input  wire                  clk,
    input  wire                  en,
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [DATA_WIDTH-1:0] dout
);

    // 1024 x 12-bit memory array (Infers Block RAM in Vivado)
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    // Initialize the LUT from a hex memory file
    initial begin
        $readmemh("sine_lut_1024x12.mem", rom);
    end

    // Synchronous read (registers output to ensure maximum fmax timing closure)
    always @(posedge clk) begin
        if (en) begin
            dout <= rom[addr];
        end
    end

endmodule