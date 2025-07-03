//for th 3x3 convolution, you need to feed the mac array with 9 pixels per cycle
//but read only one new pixel per each cycle

//Two- row BRAM bank
//Dual port RAM that stores two most recent rows of 28 pixels

module lineBuffer(
    input logic clk,
    input logic rst,
    input logic [15:0] data,
    input logic in_valid,
    output logic [447:0] row0,
    output logic [447:0] row1,
    output logic [447:0] row2,
    output logic o_valid
);

//pixelcount - counts how many pixels of the row have been loaded into the ram
logic [4:0] pixelcount; //needs to count from 0 to 27
logic [1:0] row_select; //0 = writing row0 etc
logic row0_full, row1_full, row2_full;

//stores pixel data into buffer sequentially
always_ff @(posedge clk or negedge rst)
begin
    if(~rst) begin
        pixelcount <= 0;
        row_selec <= 0;
        row0 <= 0;
        row1 <= 0;
        row3 <= 0;
        o_valid <= 0;
        row1_full <= 0;
        row0_full <= 0;
        row2_full <= 0;
    end
    else begin
        o_valid <= 0; //default unless row completes
        end 
    if(in_valid) begin
        //store incoming pixel into the correct slice of the buffer
         case (row_select)
                    2'd0: row0[16 * pixelcount +: 16] <= data;
                    2'd1: row1[16 * pixelcount +: 16] <= data;
                    2'd2: row2[16 * pixelcount +: 16] <= data;
                endcase

        pixelcount <= pixelcount + 1;

       

        if(pixelcount == 27) begin
            pixelcount <= 0;
            case (row_select)
                        2'd0: row0_full <= 1;
                        2'd1: row1_full <= 1;
                        2'd2: row2_full <= 1;
                    endcase
            row_select <= (row_select == 2) ? 0 : row_select + 1;
        end
        end
        if(row0_full && row1_full && row2_full) begin
            o_valid <= 1;
            row0_full <= 0;
            row1_full <= 0;
            row2_full <= 0;
        end
    

end

endmodule

//shift register window
//Shift in each new pixel; shift older ones "right" and "down" to maintain the 3x3 patch

