
//should take feature maps from cnn_top and do relu and 2x2 max pooling
//only for l2 output feature maps


module relu_pool_unit #(
    parameter WIDTH = 28,
    parameter HEIGHT = 28,
    parameter CHANNELS = 16
)(
    input logic clk,
    input logic rst,
    input logic start,
    input  logic [17:0] fmap_in [0:HEIGHT-1][0:WIDTH-1][0:CHANNELS-1],
    output logic [17:0] fmap_out [0:(HEIGHT/2)-1][0:(WIDTH/2)-1][0:CHANNELS-1],

);
    //Coordinates and FSM
    typedef enum logic [1:0]{
        IDLE,
        RELU,
        MAXPOOL,
        DONE
    } state_t;

    state_t state, next_state;
    int y, x, c;

    //combinational maxpool operation(2x2)

    function automatic [17:0] max4(
        input [17:0] a,
        input [17:0] b,
        input [17:0] c,
        input [17:0] d

    );
    return (a > b ? a : b) > (c > d ? c : d) ? (a > b ? a : b) : (c > d ? c : d);

    endfunction

    // FSM: state transition

    always_ff @(posedge clk) begin
        if(rst) state <= IDLE;
        else state <= next_state;

    end

    //FSM next state logic
    always_comb begin
        case (state)
            IDLE:     next_state = (start) ? RELU : IDLE;
            RELU:     next_state = MAXPOOL;
            MAXPOOL:  next_state = DONE;
            DONE:     next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end


    // RELU pass (in-place overwrite)
    always_ff @(posedge clk) begin
        if(state == RELU) begin
            for(int i = 0; i < HEIGHT; i++) begin
                for(int j = 0; j < WIDTH; j++) begin
                    for(int k = 0; k < CHANNELS; k++) begin
                        if(fmap_in[i][j][k][17] == 1'b1) //if the MSB is 1 - negative
                            fmap_in[i][j][k] <= 18'b0; //set to zero then
                    end
                end
            end
        end
    end


    //MAXPOOL pass (output assignment)
    always_ff @(posedge clk) begin
        if(state == MAXPOOL) begin
            for (int i = 0; i < HEIGHT/2; i++) begin
                for (int j = 0; j < WIDTH/2; j++) begin
                    for (int k = 0; k < CHANNELS; k++) begin
                        fmap_out[i][j][k] <= max4(
                            fmap_in[2*i][2*j][k],
                            fmap_in[2*i][2*j+1][k],
                            fmap_in[2*i+1][2*j][k],
                            fmap_in[2*i+1][2*j+1][k]
                        );
                    end
                end
            end
        end
    end

    assign done = (state == DONE);





endmodule
