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

logic [PTR:0] wr_ptr_bin;
logic [PTR:0] rd_ptr_bin;

logic [PTR:0] wr_ptr_gray;
logic [PTR:0] rd_ptr_gray;

logic [PTR:0] wr_ptr_sync1, wr_ptr_sync2;
logic [PTR:0] rd_ptr_sync1, rd_ptr_sync2;

function automatic [PTR:0] bin2gray(input [PTR:0] b);
    return (b >> 1) ^ b;
endfunction

always_ff @(posedge wr_clk or posedge rst)
begin
    if (rst)
        wr_ptr_bin <= 0;
    else if (wr_en && !full)
        wr_ptr_bin <= wr_ptr_bin + 1;
end

assign wr_ptr_gray = bin2gray(wr_ptr_bin);

always_ff @(posedge rd_clk or posedge rst)
begin
    if (rst)
        rd_ptr_bin <= 0;
    else if (rd_en && !empty)
        rd_ptr_bin <= rd_ptr_bin + 1;
end

assign rd_ptr_gray = bin2gray(rd_ptr_bin);

always_ff @(posedge wr_clk or posedge rst)
begin
    if (rst) begin
        rd_ptr_sync1 <= 0;
        rd_ptr_sync2 <= 0;
    end else begin
        rd_ptr_sync1 <= rd_ptr_gray;
        rd_ptr_sync2 <= rd_ptr_sync1;
    end
end

always_ff @(posedge rd_clk or posedge rst)
begin
    if (rst) begin
        wr_ptr_sync1 <= 0;
        wr_ptr_sync2 <= 0;
    end else begin
        wr_ptr_sync1 <= wr_ptr_gray;
        wr_ptr_sync2 <= wr_ptr_sync1;
    end
end

always_ff @(posedge wr_clk)
begin
    if (wr_en && !full)
        mem[wr_ptr_bin[PTR-1:0]] <= data_in;
end

always_ff @(posedge rd_clk or posedge rst)
begin
    if (rst)
        data_out <= 0;
    else if (rd_en && !empty)
        data_out <= mem[rd_ptr_bin[PTR-1:0]];
end

assign empty = (rd_ptr_gray == wr_ptr_sync2);

assign full =
(wr_ptr_gray ==
 {~rd_ptr_sync2[PTR:PTR-1],
  rd_ptr_sync2[PTR-2:0]});

endmodule