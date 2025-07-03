//takes the three rows as input and forms the windows.
//3x3 sliding window generator.

//moves across columns using col_idx
//valid output starts from column index 2 onward
//one output window per cycle(once valid)
//stride = 1
//zero padding logic not added

module window_maker #(
    parameter COLS = 28,
    parameter DATA_WIDTH = 16
)

(
    input logic clk,
    input logic rst,
    input logic in_valid,
    input logic [447:0] row0,
    input logic [447:0] row1,
    input logic [447:0] row2,
    //output window pixel by pixel
    output logic [DATA_WIDTH-1:0] win00, win01, win02,
    output logic [DATA_WIDTH-1:0] win10, win11, win12,
    output logic [DATA_WIDTH-1:0] win20, win21, win22,
    output logic o_valid
);

logic [4:0] col_idx; //0 to 27

always_ff @(posedge clk or negedge rst) begin
    if(~rst) begin
        col_idx <= 0;
        o_valid <= 0;
    end else if (i_valid) begin
        o_valid <= 0;

        if(col_idx >= 2 && col_idx <= COLS-1) begin
            //Extract the 3x3 window from bit vectors using
            win00 <= row0[(col_idx-2)*16 +: 16];
            win01 <= row0[(col_idx-1)*16 +: 16];
            win02 <= row0[(col_idx)*16     +: 16];

            win10 <= row1[(col_idx-2)*16 +: 16];
            win11 <= row1[(col_idx-1)*16 +: 16];
            win12 <= row1[(col_idx)*16     +: 16];

            win20 <= row2[(col_idx-2)*16 +: 16];
            win21 <= row2[(col_idx-1)*16 +: 16];
            win22 <= row2[(col_idx)*16     +: 16];

            o_valid <= 1;
        end

        if(col_idx == COLS-1)
            col_idx <= 0;
        else
            col_idx <= col_idx + 1;
    end
end

endmodule