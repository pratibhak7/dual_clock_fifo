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

parameter DEPTH = 8;
parameter PTR = 3;

logic [7:0] mem [0:DEPTH-1];

logic [PTR:0] wr_ptr;
logic [PTR:0] rd_ptr;

always_ff @(posedge wr_clk)
begin
    if (wr_en)
    begin
        mem[wr_ptr] <= data_in;
        wr_ptr <= wr_ptr + 1;
    end
end

always_ff @(posedge rd_clk)
begin
    if (rd_en)
    begin
        data_out <= mem[rd_ptr];
        rd_ptr <= rd_ptr + 1;
    end
end

assign full  = 0;
assign empty = 0;

endmodule