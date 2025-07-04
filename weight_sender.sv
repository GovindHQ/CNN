//This module gathers 9 weights from each wt_mem across 9 cycles and outputs wt_flat[mac_id]
//wt_flat[mac_id] is 144 bits (9 × 16-bit weights) ready for mac_array


module weight_sender(// 9 cycle parallel weight gatherer 
    input logic clk,
    input logic rst,
    input logic start, //triggered one per window
    input logic done, //high after 9 weights are fetched

    output logic [3:0] addr, //Address sent to all wt_memX
    input logic [15:0] wt_in [15:0]; //16 weights per cycle for each mac
    //wt_flat goes to wt input of macarray
    output logic [(9*16)-1:0] wt_flat [15:0] // 16 sets of 9 weights, flattened for mac_array


)

    logic [3:0] counter;
    logic [15:0] weights [15:0][0:8]; //weights[mac][0...8]

    always_ff @(posedge clk or negedge rst) begin
        if(~rst) begin
            counter <= 0;
            addr <= 0;
            done <= 0;
        end else begin
            if(start && counter < 9) begin
                addr <= counter;
                for(int i = 0;i<16;i++) begin
                    weights[i][counter] <= wt_in[i];
                end
                counter <= counter + 1;
                done <= 0;
            end else if (counter == 9) begin
                counter <= 0;
                done <= 1;
            end else begin
                done <= 0;
            end
            
        end
    end

    always_comb begin
        for(int m = 0; m < 16; m++) begin
            for(int i = 0;i<9;i++) begin
                wt_flat[m][(i*16) +: 16] = weights[m][i];
            end
        end
    end
    
endmodule