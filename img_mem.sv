//in my testbench, drive a read address counter from 0-783, feeding img_mem.data into your next stage



module img_mem(
    input logic clk,
    input logic [15:0] addr, //increment this addr in testbench
    output logic [15:0] data,

);

logic [15:0] mem [0:784]; //784 pixels
initial $readmemb("image_in.txt", mem);

always_ff @(posedge clk)
begin
    data <= mem[addr];
end

endmodule
