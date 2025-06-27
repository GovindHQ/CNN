//Mac-module 
//for a 3x3 module

`timescale 1ns/1ns

module mac#(
    TOTAL_BITS = 16,
    MULTS = 9,
    RESOLUTION = 16,
    WINDOW_ELEMENTS = 9
)

(
    input clk,
    input rst,
    input [WINDOW_ELEMENTS*RESOLUTION-1:0] inChunk, //the input volume window
    input [WINDOW_ELEMENTS*RESOLUTION-1:0] weight, // the filter elements
    
    output reg signed [17:0] mac_output //output of the convolution
);

//extract from input

// subwindow pixels

wire signed [TOTAL_BITS-1:0] p1_1;
wire signed [TOTAL_BITS-1:0] p1_2;
wire signed [TOTAL_BITS-1:0] p1_3;
wire signed [TOTAL_BITS-1:0] p2_1;
wire signed [TOTAL_BITS-1:0] p2_2;
wire signed [TOTAL_BITS-1:0] p2_3;
wire signed [TOTAL_BITS-1:0] p3_1;
wire signed [TOTAL_BITS-1:0] p3_2;
wire signed [TOTAL_BITS-1:0] p3_3;

// weights
wire signed [TOTAL_BITS-1:0] w1_1;
wire signed [TOTAL_BITS-1:0] w1_2;
wire signed [TOTAL_BITS-1:0] w1_3;
wire signed [TOTAL_BITS-1:0] w2_1;
wire signed [TOTAL_BITS-1:0] w2_2;
wire signed [TOTAL_BITS-1:0] w2_3;
wire signed [TOTAL_BITS-1:0] w3_1;
wire signed [TOTAL_BITS-1:0] w3_2;
wire signed [TOTAL_BITS-1:0] w3_3;


// product
reg signed [31:0] q1_1;
reg signed [31:0] q1_2;
reg signed [31:0] q1_3;
reg signed [31:0] q2_1;
reg signed [31:0] q2_2;
reg signed [31:0] q2_3;
reg signed [31:0] q3_1;
reg signed [31:0] q3_2;
reg signed [31:0] q3_3;

// now we map each pixel to the input_chunk

assign p1_1 = inChunk[143:128]; 
assign p1_2 = inChunk[127:112]; 
assign p1_3 = inChunk[111:96];
assign p2_1 = inChunk[95:80];
assign p2_2 = inChunk[79:64];
assign p2_3 = inChunk[63:48];
assign p3_1 = inChunk[47:32];
assign p3_2 = inChunk[31:16];
assign p3_3 = inChunk[15:0];
//mapping the weights
assign w1_1 = weight[143:128];
assign w1_2 = weight[127:112];
assign w1_3 = weight[111:96];
assign w2_1 = weight[95:80];
assign w2_2 = weight[79:64];
assign w2_3 = weight[63:48];
assign w3_1 = weight[47:32];
assign w3_2 = weight[31:16];
assign w3_3 = weight[15:0];

wire signed [31:0] accum_row1, accum_row2, accum_row3;
reg  signed [31:0] accum_row1, accum_row2, accum_row3;
wire signed [31:0] accum_all;


// three partial row-wise accumulations are performed
assign accum_row1 = q1_1 + q1_2 + q1_3;
assign accum_row2 = q2_1 + q2_2 + q2_3;
assign accum_row3 = q3_1 + q3_2 + q3_3;
assign accum_all = accum_row

// then each rows accumulation is stored in a register

always_ff @(posedge clk or negedge rst) //one input per clock - pipelined
begin
    if(~rst)
    begin
        q1_1 <= 0;
        q1_2 <= 0;
        q1_3 <= 0;
        q2_1 <= 0;
        q2_2 <= 0;
        q2_3 <= 0;
        q3_1 <= 0;
        q3_2 <= 0;
        q3_3 <= 0;
        accum_row1_reg <= 0;
        accum_row2_reg <= 0;
        accum_row3_reg <= 0;
        mac_output <= 0;
    end else begin
        q1_1 <= p1_1 * w1_1;
        q1_2 <= p1_2 * w1_2;
        q1_3 <= p1_3 * w1_3;
        q2_1 <= p2_1 * w2_1;
        q2_2 <= p2_2 * w2_2;
        q2_3 <= p2_3 * w2_3;
        q3_1 <= p3_1 * w3_1;
        q3_2 <= p3_2 * w3_2;
        q3_3 <= p3_3 * w3_3;
        accum_row1_reg <= accum_row1;
        accum_row2_reg <= accum_row2;
        accum_row3_reg <= accum_row3;
        mac_output <= accum_all[31:14]; //right shift by 14 bits - truncating so the output is also 16 bits
        //truncates the less significant digits
    end
end

endmodule