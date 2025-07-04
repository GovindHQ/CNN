//each filter has 9 weights
//16 bits per weight
//so 144 bits per filter
//so for 16 filters, total 16x9 = 144 weights

//split across brams for parallel macs
//one bram per mac unit (each filter has one mac unit)

//You will instantiate 16 copies of this with MEM_ID from 0 to 15.

module wt_mem #(parameter MEM_ID = 0) ( //default value is 0 unless you override it when initiating
    input  logic       clk,
    input  logic [3:0] addr,        // Index from 0 to 8
    output logic [15:0] w
);
    logic [15:0] mem [0:8];

    initial begin
        string fname;
        $sformat(fname, "filter%d.txt", MEM_ID); // Loads filter0.txt to filter15.txt
        $readmemh(fname, mem);
    end

    always_ff @(posedge clk)
        w <= mem[addr];
endmodule
