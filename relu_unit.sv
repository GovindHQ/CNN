//should take feature maps from cnn_top and do relu
//only for l2 ouput feature maps

//should take feature maps from cnn_top and do relu and 2x2 max pooling
//only for l2 output feature maps


module relu_unit #(
    parameter WIDTH = 28,
    parameter HEIGHT = 28,
    parameter CHANNELS = 16
)(
    input logic clk,
    input logic rst,
    input logic start,
    input  logic [17:0] fmap_in [0:HEIGHT-1][0:WIDTH-1][0:CHANNELS-1],
    output logic [17:0] fmap_out [0:HEIGHT-1][0:WIDTH-1][0:CHANNELS-1],
    output logic done
);

    // FSM states
    typedef enum logic [1:0] {
        IDLE,
        RELU,
        DONE
    } state_t;

    state_t state, next_state;

    // FSM: transition logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    // FSM: next state logic
    always_comb begin
        case (state)
            IDLE:    next_state = (start) ? RELU : IDLE;
            RELU:    next_state = DONE;
            DONE:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // ReLU logic
    always_ff @(posedge clk) begin
        if (state == RELU) begin
            for (int i = 0; i < HEIGHT; i++) begin
                for (int j = 0; j < WIDTH; j++) begin
                    for (int k = 0; k < CHANNELS; k++) begin
                        if (fmap_in[i][j][k][17] == 1'b1) // negative MSB
                            fmap_out[i][j][k] <= 18'd0;
                        else
                            fmap_out[i][j][k] <= fmap_in[i][j][k];
                    end
                end
            end
        end
    end

    assign done = (state == DONE);

endmodule

