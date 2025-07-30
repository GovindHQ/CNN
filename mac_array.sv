//performs 16 parallel 3x3 convolutions
//16 multiply-accumulate(MAC) units
//input: 16 windows of ifmap(inChunk) and corresponding weights, each of 3x3
//output: 16 outputs(if generating layer two), or a single accumulated value otherwise
//bandwidth: fixed point: 16 bit per total element(2 bits decimal + 14 bits mantissa)

module mac_array #( parameter 
    DEC_BITS = 2, //bits after decimal
    MANTISSA_BITS = 14, //bits before decimal(signed)
    NUM_MACS = 16, //16 MACs in parallel
    MULTS_PER_MAC = 9 //3x3 kernel 
)
(
input clk,
input rst,
input RCV_L2, //receive layer 2 - this mac array is being used to compute the feature maps of layer 2
//controls whether the output of the mac array should be 16 outputs if generating layer 2 outputs or a sngle
//accumulated value if ur using this layer in deeper layers of the CNN.
input valid_i;
output valid_o;
output ready_o; //Ready to accept windows from windowmaker
input [(MULTS_PER_MAC*(DEC_BITS+MANTISSA_BITS))-1:0] ifmap_chunk [NUM_MACS-1:0],   // A flattened 3x3 window of 16-bit input feature map pixels
input [(MULTS_PER_MAC*(DEC_BITS+MANTISSA_BITS))-1:0] wt [NUM_MACS-1:0],           // A flattened 3x3 window of 16-bit weights
output reg [17:0] accum_o [NUM_MACS-1:0]


);

localparam TOTAL_BITS = DEC_BITS + MANTISSA_BITS;
localparam MAX_DELAY = 5;

//valid_i signal delay logic to aligh with the latency of macs
//If valid data is coming in, valid_i is high
//Depending on which layer we are performing convolutions for, we will send out the valid_o
//Signal either exactly 3 or 5 cycles layer, hence the 5-dff chain
reg [MAX_DELAY-1:0] delay_sreg;
//If the output convolution will be the layer 2 output, we need only delay by 3 cycles
//otherwise 5(3 cycles for one window convolutio, 2 more to accumulate all window convolutions)
assign valid_o = (RCV_L2) ? delay_sreg[2] : delay_sreg[4]

reg busy; //set when you accept a new window, clear when output is valid

//ready_o: if not busy we can accept a new valid_i
assign ready_o = ~busy;


//Accumulation registers to accumulae all window convolutions. Only used for layer after layer 2
wire signed [17:0] accum1, accum2, accum3, accum4;
reg signed [17:0] accum1_reg, accum2_reg, accum3_reg, accum4_reg;
wire signed [17:0] accum_final;
reg signed [17:0] accum_final_reg;

//outputs of every individual mac unit
//each res[i] is the result of a 3x3 dot product (already scled and truncated)
wire signed [17:0] res [NUM_MACS-1:0];

//Assign the output of the mac_array
always_comb 
begin
    //if generating layer 2 feature maps, all 16 accum_o outputs are straight from the 16x MACs
    for (int i = 0; i<16:i++)
    begin
        accum_o[i] = res[i]
    end
    //otherwise if not generating layer 2 feature maps, ONLY use accum_o[0] as the fmap port
    if(~RCV_L2)
    begin
        accum_o = accum_final_reg;
    end


end


//Accumulation of all 16x MAC outputs in a 2 level tree structure, each accumN is a 18 bit signed value
//sum happen combinationally in one logic level
assign accum1 = res[0] + res[1] + res[2] + res[3];
assign accum2 = res[4] + res[5] + res[6] + res[7];
assign accum3 = res[8] + res[9] + res[10] + res[11];
assign accum4 = res[12] + res[13] + res[14] + res[15]; 
assign accum_final = accum1_reg + accum2_reg + accum3_reg + accum4_reg;



always_ff@(posedge clk or negedge rst)
begin
    if(~rst) begin//on each clock, we capture those four partial sums into registers
        //this adds one cycle of latency but balances the adder-tree timing
        //on the same clock edge, we register the final sum of previous adder tree too
        accum1_reg <= 0;
        accum2_reg <= 0;
        accum3_reg <= 0;
        accum4_reg <= 0;
        accum_final_reg <= 0;
        delay_sreg <= 0;
        busy <= 1'b0;
    end else begin
        accum1_reg <= accum1;
        accum2_reg <= accum2;
        accum3_reg <= accum3;
        accum4_reg <= accum4;
        accum_final_reg <= accum_final; //the stable final convolution result after two pipelinestages of additon
        
        //The module must serve two modes:
        //Layer 2 mode(RCV_L2 = 1) : We want all 16 raw mac outputs
        //deeper layer mode : we want the single accumulaed result from all 16
        //downstream logic will only read from accm_o[0] in deeper layers
    end

// valid signal pipelining:
    //mac mult takes 1 cycle in mac
    //first level addition(combinational)
    //register(1 cycle)
    //second level addition(combinational)
    //register(1cycle)

    //if RCL_L2 = 1 use delay_sreg[2] aligns with 3 cycle mac + adder pipeline
    //if otherwise use delay_sreg[4] aligns with 5 cycle mac + two stage adder 

    if (RCV_L2) begin
            delay_sreg[4] <= delay_sreg[4];
            delay_sreg[3] <= delay_sreg[3];
        end else begin
            delay_sreg[4] <= delay_sreg[3];
            delay_sreg[3] <= delay_sreg[2];
        end

        delay_sreg[2] <= delay_sreg[1];
        delay_sreg[1] <= delay_sreg[0];
        delay_sreg[0] <= valid_i;

        //update busy flag for the valid-ready handshake
        if (valid_i && ~busy) begin
        //we just accepted a new window, go busy
        busy <= 1'b1;
        end else if (valid_o) begin
        //our output is now valid, free up for next window
        busy <= 1'b0;
        end

end


//16 mac units instantiation
genvar a;

generate
    for (a = 0; a < NUM_MACS; a = a + 1)
    begin : mac_gen
        mac #(
            .TOTAL_BITS(TOTAL_BITS),
            .MULTS(MULTS_PER_MAC)
        ) 
        mac_u 
        (
            .clk (clk),
            .rst (rst),
            .ifmap_chunk (ifmap_chunk[a]),
            .weight (wt[a]),
            .mac_output (res[a])
        );
    end
endgenerate


endmodule
