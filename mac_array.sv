//performs 16 parallel 3x3 convolutions
//16 multiply-accumulate(MAC) units
//input: 16 windows of ifmap(inChunk) and corresponding weights, each of 3x3
//output: 16 outputs(if generating layer two), or a single accumulated value otherwise
//bandwidth: fixed point: 16 bit per total element(2 bits decimal + 14 bits mantissa)

module mac_array #(
    DEC_BITS = 2, //bits after decimal
    MANTISSA_BITS = 14, //bits before decimal(signed)
    NUM_MACS = 16, //16 MACs in parallel
    MULTS_PER_MAC = 9 //3x3 kernel 
)
(


);
endmodule