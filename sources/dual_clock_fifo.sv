// Stub for baseline/test branches: compiles but fails hidden test (empty always 1).
// Replace with full dual-clock FIFO implementation for the golden branch.
module dual_clock_fifo(
input  logic wr_clk,
input  logic rd_clk,
input  logic rst,
input  logic wr_en,
input  logic rd_en,
input  logic [7:0] data_in,
output logic [7:0] data_out,
output logic full,
output logic empty
);
assign data_out = 8'b0;
assign full    = 1'b0;
assign empty   = 1'b1;  // Always empty so hidden test fails as required for validation
endmodule
