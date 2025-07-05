// Here's your cnn_top module that initiates and integrats:

// lineBuffer

// windowMaker

// 16 wt_mem memories (parameterized)

// weight_sender

// mac_array

// version for only one layer

//now writing the version for both layer 2 and 3


module cnn_top(
    input logic clk,
    input logic rst
    input logic in_valid,
    input logic [15:0] pixel_in; //for the linebuffer
    output logic valid_out_l2,
    output logic valid_out_l3,
    output logic [17:0] fmap_mem_l2 [0:27][0:27][15:0],
    output logic [17:0] fmap_mem_l3 [0:27][0:27] //output feature map values from mac_array of layer 2
     //output of layer 3 (accumulated)

);
    //----Intermediate wires----(between modules)

    // from lineBuffer to windowMaker
    logic [447:0] row0, row1, row2;
    logic rows_ready;

    //to fetch the window from windowMaker
    logic [15:0] win00, win01, win02,
                 win10, win11, win12,
                 win20, win21, win22;

    logic win_valid;

    //for the weight sender module
    logic [3:0] wt_addr; //for the weight sender which will send it to weight mem
    logic [15:0] wt_vals [15:0]; //from weight mem to weight sender
    logic [(9*16)-1:0] wt_flat [15:0]; //from weight sender to mac array
    logic wt_done; 

    logic [(9*16)-1:0] ifmap_flat [15:0];
    logic win_trigger;

    logic [17:0] mac_out [15:0];
    logic [17:0] mac_l3_result;

    //--initiation--

    //---Line Buffer---
    lineBuffer lb_inst(
        .clk(clk), .rst(rst), .data(pixel_in), .in_valid(in_valid),
        .row0(row0), .row1(row1), .row2(row2), .o_valid(rows_ready),
    );

    //---window maker---
    window_maker wm_inst(
        .clk(clk), .rst(rst), .in_valid(rows_ready),
        .win00(win00), .win01(win01), .win02(win02),
        .win10(win10), .win11(win11), .win12(win12),
        .win20(win20), .win21(21), .win22(win22) 
        .o_valid(win_valid)
    );

    assign win_trigger = win_valid; //to be send to window sender

    //---Flatten IFMAP chunks for each mac(same window send to all)---
    always_comb begin
        for(int i = 0; i < 16; i++) begin
            ifmap_flat[i] = {
                win00, win01, win02,
                win10, win11, win12,
                win20, win21, win22
            };
        end
    end

    // --- Weight Memories Instantiation ---
    wt_mem wt_mem_array [15:0] (
        .clk(clk),
        .addr(wt_addr),
        .w(wt_vals)
    );

    generate
        for (genvar i = 0; i < 16; i++) begin: wt_bind
            defparam wt_mem_array[i].MEM_ID = i;
        end
    endgenerate


    //---weight sender---
    weight_sender ws_inst(
        .clk(clk), .rst(rst), .start(win_trigger),
        .done(wt_done), .addr(wt_addr), .wt_in(wt_vals), 
        .wt_flat(wt_flat)
    );

    //---Layer 2 MAC array---
    mac_array mac_arr_inst(
        .clk(clk), .rst(rst), .RCL_L2(1'b1), //assume layer 2 output
        .valid_i(wt_done), .valid_o(valid_out_l2),
        .ifmap_chunk(ifmap_flat), .wt(wt_flat),
        .accum_o(mac_out)
    );



    //---Write to layer 2 feature map ram---
    always_ff @(posedge clk) begin
        if(valid_out_l2) begin
            for(int i = 0; i < 16; i++) begin
                fmap_mem_l2[fmap_y][fmap_x][i] <= mac_out[i];
            end
        end
    end

    //---Layer 3 MAC array---
    mac_array mac_arr_l3 (
        .clk(clk), .rst(rst), .RCV_L2(1'b0),
        .valid_i(valid_out_l2), .valid_o(valid_out_l3),
        .ifmap_chunk(ifmap_flat), .wt(wt_flat),
        .accum_o({mac_l3_result, {15{18'd0}}}) // only accum_o[0] used
    );



    // --- Write to Layer 3 Feature Map RAM ---
    always_ff @(posedge clk) begin
        if (valid_out_l3)
            fmap_mem_l3[fmap_y][fmap_x] <= mac_l3_result;
    end

    //---Feature map coordinate tracking---
    always_ff @(posedge clk or negedge rst) begin
        if (rst) begin
            fmap_x <= 0;
            fmap_y <= 0;
        end else if (valid_out_l2) begin
            if(fmap_x == 27) begin
                fmap_x <= 0;
                if(fmap_y == 27)
                    fmap_y <= 0;
                else
                    fmap_y <= fmap_y + 1;
                end else begin
                    fmap_x <= fmap_x + 1;
                end
            end
        end


endmodule




   
